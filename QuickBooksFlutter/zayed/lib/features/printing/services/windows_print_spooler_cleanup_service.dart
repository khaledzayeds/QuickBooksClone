import 'dart:io';

class WindowsPrintSpoolerCleanupService {
  const WindowsPrintSpoolerCleanupService();

  static const delayedCleanupDelay = Duration(minutes: 15);

  Future<void> clearProblemJobs(String? printerName) async {
    final name = printerName?.trim();
    if (!Platform.isWindows || name == null || name.isEmpty) return;

    try {
      await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          _problemJobCleanupScript,
        ],
        environment: {'ZAYED_PRINTER_NAME': name},
      );
    } catch (_) {
      // Some printer drivers do not expose queue state. Printing should continue.
    }
  }

  Future<void> scheduleDelayedCleanup({
    required String? printerName,
    required String documentName,
    Duration delay = delayedCleanupDelay,
  }) async {
    final name = printerName?.trim();
    if (!Platform.isWindows || name == null || name.isEmpty) return;

    try {
      await Process.start(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-WindowStyle',
          'Hidden',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          _delayedDocumentCleanupScript,
        ],
        mode: ProcessStartMode.detached,
        environment: {
          'ZAYED_PRINTER_NAME': name,
          'ZAYED_PRINT_DOCUMENT_NAME': documentName.trim(),
          'ZAYED_PRINT_CLEANUP_SECONDS': delay.inSeconds.toString(),
        },
      );
    } catch (_) {
      // Best-effort cleanup only; failed scheduling must not fail printing.
    }
  }

  Future<void> clearStartupProblemJobs(Iterable<String?> printerNames) async {
    final seen = <String>{};
    for (final printerName in printerNames) {
      final name = printerName?.trim();
      if (name == null || name.isEmpty) continue;
      final key = name.toLowerCase();
      if (!seen.add(key)) continue;
      await clearProblemJobs(name);
    }
  }
}

const _problemJobCleanupScript = r'''
$printerName = $env:ZAYED_PRINTER_NAME
if ([string]::IsNullOrWhiteSpace($printerName)) { exit 0 }

Get-PrintJob -PrinterName $printerName -ErrorAction SilentlyContinue |
  Where-Object {
    $status = "$($_.JobStatus) $($_.JobState)"
    $status -match 'Error|Paused|Offline|Blocked|UserIntervention'
  } |
  Remove-PrintJob -ErrorAction SilentlyContinue
''';

const _delayedDocumentCleanupScript = r'''
$printerName = $env:ZAYED_PRINTER_NAME
$documentName = $env:ZAYED_PRINT_DOCUMENT_NAME
$delaySeconds = 900
if ([int]::TryParse($env:ZAYED_PRINT_CLEANUP_SECONDS, [ref]$delaySeconds) -eq $false) {
  $delaySeconds = 900
}
if ($delaySeconds -lt 900) { $delaySeconds = 900 }

Start-Sleep -Seconds $delaySeconds

if ([string]::IsNullOrWhiteSpace($printerName)) { exit 0 }
$cutoff = (Get-Date).AddSeconds(-1 * $delaySeconds)

Get-PrintJob -PrinterName $printerName -ErrorAction SilentlyContinue |
  Where-Object {
    $jobDocument = "$($_.DocumentName) $($_.Name)"
    $matchesDocument = [string]::IsNullOrWhiteSpace($documentName) -or
      $jobDocument.IndexOf($documentName, [System.StringComparison]::OrdinalIgnoreCase) -ge 0

    $submitted = $_.SubmittedTime
    $isOld = $true
    if ($submitted -ne $null) {
      $isOld = ([datetime]$submitted -le $cutoff)
    }

    $status = "$($_.JobStatus) $($_.JobState)"
    $isActivelyPrinting = $status -match 'Printing|Processing'

    $matchesDocument -and $isOld -and -not $isActivelyPrinting
  } |
  Remove-PrintJob -ErrorAction SilentlyContinue
''';
