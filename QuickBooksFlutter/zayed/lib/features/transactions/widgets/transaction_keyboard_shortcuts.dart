import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransactionKeyboardShortcuts extends StatelessWidget {
  const TransactionKeyboardShortcuts({
    super.key,
    required this.child,
    this.onAddLine,
    this.onPreviousQuantity,
    this.onFocusBarcode,
    this.onLookup,
    this.onToggleSidePanel,
    this.onSave,
    this.onPrint,
    this.onDuplicateLine,
    this.onClearLine,
    this.onEscape,
  });

  final Widget child;
  final VoidCallback? onAddLine;
  final VoidCallback? onPreviousQuantity;
  final VoidCallback? onFocusBarcode;
  final VoidCallback? onLookup;
  final VoidCallback? onToggleSidePanel;
  final VoidCallback? onSave;
  final VoidCallback? onPrint;
  final VoidCallback? onDuplicateLine;
  final VoidCallback? onClearLine;
  final VoidCallback? onEscape;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true): const _TransactionIntent(_TransactionShortcut.addLine),
        const SingleActivator(LogicalKeyboardKey.f4): const _TransactionIntent(_TransactionShortcut.focusBarcode),
        const SingleActivator(LogicalKeyboardKey.f5): const _TransactionIntent(_TransactionShortcut.previousQuantity),
        const SingleActivator(LogicalKeyboardKey.f7): const _TransactionIntent(_TransactionShortcut.lookup),
        const SingleActivator(LogicalKeyboardKey.f8): const _TransactionIntent(_TransactionShortcut.toggleSidePanel),
        const SingleActivator(LogicalKeyboardKey.f9): const _TransactionIntent(_TransactionShortcut.save),
        const SingleActivator(LogicalKeyboardKey.f10): const _TransactionIntent(_TransactionShortcut.print),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): const _TransactionIntent(_TransactionShortcut.save),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): const _TransactionIntent(_TransactionShortcut.print),
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): const _TransactionIntent(_TransactionShortcut.duplicateLine),
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): const _TransactionIntent(_TransactionShortcut.clearLine),
        const SingleActivator(LogicalKeyboardKey.escape): const _TransactionIntent(_TransactionShortcut.escape),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _TransactionIntent: CallbackAction<_TransactionIntent>(
            onInvoke: (intent) {
              switch (intent.shortcut) {
                case _TransactionShortcut.addLine:
                  onAddLine?.call();
                  break;
                case _TransactionShortcut.previousQuantity:
                  onPreviousQuantity?.call();
                  break;
                case _TransactionShortcut.focusBarcode:
                  onFocusBarcode?.call();
                  break;
                case _TransactionShortcut.lookup:
                  onLookup?.call();
                  break;
                case _TransactionShortcut.toggleSidePanel:
                  onToggleSidePanel?.call();
                  break;
                case _TransactionShortcut.save:
                  onSave?.call();
                  break;
                case _TransactionShortcut.print:
                  onPrint?.call();
                  break;
                case _TransactionShortcut.duplicateLine:
                  onDuplicateLine?.call();
                  break;
                case _TransactionShortcut.clearLine:
                  onClearLine?.call();
                  break;
                case _TransactionShortcut.escape:
                  onEscape?.call();
                  break;
              }
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

enum _TransactionShortcut {
  addLine,
  previousQuantity,
  focusBarcode,
  lookup,
  toggleSidePanel,
  save,
  print,
  duplicateLine,
  clearLine,
  escape,
}

class _TransactionIntent extends Intent {
  const _TransactionIntent(this.shortcut);
  final _TransactionShortcut shortcut;
}
