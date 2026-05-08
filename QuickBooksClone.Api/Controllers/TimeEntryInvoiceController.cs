using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.TimeTracking;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.TimeTracking;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/time-entries")]
[RequirePermission("TimeTracking.Manage")]
public sealed class TimeEntryInvoiceController : ControllerBase
{
    private const string DefaultCompanyId = "11111111-1111-1111-1111-111111111111";
    private readonly QuickBooksCloneDbContext _db;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IInvoiceRepository _invoices;
    private readonly ISalesInvoicePostingService _postingService;
    private readonly IDocumentNumberService _documentNumbers;

    public TimeEntryInvoiceController(
        QuickBooksCloneDbContext db,
        ICustomerRepository customers,
        IItemRepository items,
        IInvoiceRepository invoices,
        ISalesInvoicePostingService postingService,
        IDocumentNumberService documentNumbers)
    {
        _db = db;
        _customers = customers;
        _items = items;
        _invoices = invoices;
        _postingService = postingService;
        _documentNumbers = documentNumbers;
    }

    [HttpPost("create-invoice")]
    [ProducesResponseType(typeof(CreateInvoiceFromTimeResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CreateInvoiceFromTimeResponse>> CreateInvoice(CreateInvoiceFromTimeRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureInvoiceColumnAsync(cancellationToken);

        if (request.CustomerId == Guid.Empty)
        {
            return BadRequest("Customer is required.");
        }
        if (request.InvoiceDate == default || request.DueDate == default)
        {
            return BadRequest("Invoice and due dates are required.");
        }
        if (request.DueDate < request.InvoiceDate)
        {
            return BadRequest("Invoice due date cannot be before invoice date.");
        }
        if (request.TimeEntryIds.Count == 0)
        {
            return BadRequest("Select at least one time entry.");
        }

        var customer = await _customers.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer is null || !customer.IsActive)
        {
            return BadRequest("Customer does not exist or is inactive.");
        }

        var entries = await GetTimeEntryRowsAsync(request.TimeEntryIds.Distinct().ToArray(), cancellationToken);
        if (entries.Count != request.TimeEntryIds.Distinct().Count())
        {
            return BadRequest("One or more time entries do not exist.");
        }

        var invalid = ValidateEntries(request.CustomerId, entries);
        if (invalid is not null)
        {
            return BadRequest(invalid);
        }

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.Invoice, cancellationToken);
        var invoice = new Invoice(request.CustomerId, request.InvoiceDate, request.DueDate, null, allocation.DocumentNo);
        invoice.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);

        foreach (var entry in entries.OrderBy(row => row.WorkDate).ThenBy(row => row.PersonName))
        {
            var item = await _items.GetByIdAsync(entry.ServiceItemId!.Value, cancellationToken);
            if (item is null || !item.IsActive)
            {
                return BadRequest($"Service item does not exist or is inactive: {entry.ServiceItemId}");
            }
            if (item.ItemType == ItemType.Bundle)
            {
                return BadRequest($"Bundle item '{item.Name}' cannot be used for time billing.");
            }

            var description = $"{entry.WorkDate:yyyy-MM-dd} - {entry.PersonName}: {entry.Activity}";
            var unitPrice = item.SalesPrice;
            invoice.AddLine(new InvoiceLine(item.Id, description, entry.Hours, unitPrice));
        }

        await _invoices.AddAsync(invoice, cancellationToken);

        var posted = false;
        if (request.PostInvoice)
        {
            var postingResult = await _postingService.PostAsync(invoice.Id, cancellationToken);
            if (!postingResult.Succeeded)
            {
                return BadRequest(postingResult.ErrorMessage);
            }
            posted = true;
        }

        await LinkEntriesToInvoiceAsync(entries.Select(row => row.Id).ToArray(), invoice.Id, cancellationToken);

        var saved = await _invoices.GetByIdAsync(invoice.Id, cancellationToken);
        return Created($"/api/invoices/{invoice.Id}", new CreateInvoiceFromTimeResponse(
            invoice.Id,
            invoice.InvoiceNumber,
            invoice.CustomerId,
            entries.Count,
            entries.Sum(row => row.Hours),
            saved?.TotalAmount ?? invoice.TotalAmount,
            posted));
    }

    private static string? ValidateEntries(Guid customerId, IReadOnlyList<TimeEntryInvoiceRow> entries)
    {
        foreach (var entry in entries)
        {
            if (!entry.IsBillable)
            {
                return $"Time entry {entry.Id} is not billable.";
            }
            if (entry.Status is not TimeEntryStatus.Approved and not TimeEntryStatus.Billable)
            {
                return $"Time entry {entry.Id} must be Approved or Billable before invoicing.";
            }
            if (entry.InvoiceId is not null)
            {
                return $"Time entry {entry.Id} is already linked to an invoice.";
            }
            if (entry.CustomerId != customerId)
            {
                return "All selected time entries must belong to the selected customer.";
            }
            if (entry.ServiceItemId is null)
            {
                return $"Time entry {entry.Id} is missing a service item.";
            }
            if (entry.Hours <= 0)
            {
                return $"Time entry {entry.Id} has invalid hours.";
            }
        }

        return null;
    }

    private async Task<IReadOnlyList<TimeEntryInvoiceRow>> GetTimeEntryRowsAsync(IReadOnlyList<Guid> ids, CancellationToken cancellationToken)
    {
        if (ids.Count == 0) return [];
        var names = ids.Select((_, index) => $"@Id{index}").ToArray();
        var parameters = ids.Select((id, index) => new KeyValuePair<string, object?>($"Id{index}", id)).ToDictionary(pair => pair.Key, pair => pair.Value);
        var sql = $"""
            SELECT Id, WorkDate, PersonName, Hours, Activity, CustomerId, ServiceItemId, InvoiceId, IsBillable, Status
            FROM time_entries
            WHERE Id IN ({string.Join(", ", names)})
            """;

        return await QueryAsync(
            sql,
            parameters,
            reader => new TimeEntryInvoiceRow(
                reader.GetGuid(0),
                DateOnly.FromDateTime(reader.GetDateTime(1)),
                reader.GetString(2),
                reader.GetDecimal(3),
                reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetGuid(5),
                reader.IsDBNull(6) ? null : reader.GetGuid(6),
                reader.IsDBNull(7) ? null : reader.GetGuid(7),
                reader.GetBoolean(8),
                (TimeEntryStatus)reader.GetInt32(9)),
            cancellationToken);
    }

    private async Task LinkEntriesToInvoiceAsync(IReadOnlyList<Guid> ids, Guid invoiceId, CancellationToken cancellationToken)
    {
        if (ids.Count == 0) return;
        var names = ids.Select((_, index) => $"@Id{index}").ToArray();
        var parameters = ids.Select((id, index) => new KeyValuePair<string, object?>($"Id{index}", id)).ToDictionary(pair => pair.Key, pair => pair.Value);
        parameters["InvoiceId"] = invoiceId;
        parameters["Status"] = (int)TimeEntryStatus.Invoiced;
        parameters["UpdatedAt"] = DateTimeOffset.UtcNow;

        await ExecuteNonQueryAsync(
            $"""
            UPDATE time_entries
            SET InvoiceId = @InvoiceId,
                Status = @Status,
                UpdatedAt = @UpdatedAt
            WHERE Id IN ({string.Join(", ", names)})
            """,
            parameters,
            cancellationToken);
    }

    private async Task EnsureInvoiceColumnAsync(CancellationToken cancellationToken)
    {
        await ExecuteNonQueryAsync(
            """
            IF OBJECT_ID(N'time_entries', N'U') IS NOT NULL AND COL_LENGTH('time_entries', 'InvoiceId') IS NULL
            BEGIN
                ALTER TABLE time_entries ADD InvoiceId uniqueidentifier NULL;
                CREATE INDEX IX_time_entries_InvoiceId ON time_entries (InvoiceId);
            END
            """,
            new Dictionary<string, object?>(),
            cancellationToken);
    }

    private async Task ExecuteNonQueryAsync(string sql, IReadOnlyDictionary<string, object?> parameters, CancellationToken cancellationToken)
    {
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task<IReadOnlyList<T>> QueryAsync<T>(string sql, IReadOnlyDictionary<string, object?> parameters, Func<IDataRecord, T> mapper, CancellationToken cancellationToken)
    {
        var result = new List<T>();
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) result.Add(mapper(reader));
        return result;
    }

    private static void AddParameters(IDbCommand command, IReadOnlyDictionary<string, object?> parameters)
    {
        foreach (var (name, value) in parameters)
        {
            var parameter = command.CreateParameter();
            parameter.ParameterName = $"@{name}";
            parameter.Value = value ?? DBNull.Value;
            command.Parameters.Add(parameter);
        }
    }

    private sealed record TimeEntryInvoiceRow(
        Guid Id,
        DateOnly WorkDate,
        string PersonName,
        decimal Hours,
        string Activity,
        Guid? CustomerId,
        Guid? ServiceItemId,
        Guid? InvoiceId,
        bool IsBillable,
        TimeEntryStatus Status);
}
