using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.TimeTracking;

public sealed class TimeEntry : EntityBase, ITenantEntity
{
    private TimeEntry()
    {
        CompanyId = Guid.Empty;
        PersonName = string.Empty;
        Activity = string.Empty;
    }

    public TimeEntry(
        DateOnly workDate,
        string personName,
        decimal hours,
        string activity,
        string? notes = null,
        Guid? customerId = null,
        Guid? serviceItemId = null,
        bool isBillable = false,
        Guid? companyId = null)
    {
        Validate(workDate, personName, hours, activity);

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        WorkDate = workDate;
        PersonName = personName.Trim();
        Hours = hours;
        Activity = activity.Trim();
        Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim();
        CustomerId = customerId;
        ServiceItemId = serviceItemId;
        IsBillable = isBillable;
        Status = TimeEntryStatus.Open;
    }

    public Guid CompanyId { get; }
    public DateOnly WorkDate { get; private set; }
    public string PersonName { get; private set; }
    public decimal Hours { get; private set; }
    public string Activity { get; private set; }
    public string? Notes { get; private set; }
    public Guid? CustomerId { get; private set; }
    public Guid? ServiceItemId { get; private set; }
    public bool IsBillable { get; private set; }
    public TimeEntryStatus Status { get; private set; }

    public void Update(
        DateOnly workDate,
        string personName,
        decimal hours,
        string activity,
        string? notes,
        Guid? customerId,
        Guid? serviceItemId,
        bool isBillable)
    {
        EnsureEditable();
        Validate(workDate, personName, hours, activity);

        WorkDate = workDate;
        PersonName = personName.Trim();
        Hours = hours;
        Activity = activity.Trim();
        Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim();
        CustomerId = customerId;
        ServiceItemId = serviceItemId;
        IsBillable = isBillable;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Approve()
    {
        if (Status == TimeEntryStatus.Void)
        {
            throw new InvalidOperationException("Cannot approve a void time entry.");
        }

        Status = TimeEntryStatus.Approved;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkInvoiced()
    {
        if (Status != TimeEntryStatus.Approved)
        {
            throw new InvalidOperationException("Only approved time entries can be marked as invoiced.");
        }

        Status = TimeEntryStatus.Invoiced;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Void()
    {
        if (Status == TimeEntryStatus.Invoiced)
        {
            throw new InvalidOperationException("Cannot void an invoiced time entry.");
        }

        Status = TimeEntryStatus.Void;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private void EnsureEditable()
    {
        if (Status is TimeEntryStatus.Invoiced or TimeEntryStatus.Void)
        {
            throw new InvalidOperationException("Invoiced or void time entries cannot be edited.");
        }
    }

    private static void Validate(DateOnly workDate, string personName, decimal hours, string activity)
    {
        if (workDate == default)
        {
            throw new ArgumentException("Work date is required.", nameof(workDate));
        }

        if (string.IsNullOrWhiteSpace(personName))
        {
            throw new ArgumentException("Person name is required.", nameof(personName));
        }

        if (personName.Trim().Length > 160)
        {
            throw new ArgumentException("Person name cannot exceed 160 characters.", nameof(personName));
        }

        if (hours <= 0 || hours > 24)
        {
            throw new ArgumentOutOfRangeException(nameof(hours), "Hours must be greater than 0 and no more than 24.");
        }

        if (string.IsNullOrWhiteSpace(activity))
        {
            throw new ArgumentException("Activity is required.", nameof(activity));
        }

        if (activity.Trim().Length > 200)
        {
            throw new ArgumentException("Activity cannot exceed 200 characters.", nameof(activity));
        }
    }
}
