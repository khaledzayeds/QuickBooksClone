using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Estimates;

public sealed class Estimate : SyncDocumentBase, ITenantEntity
{
    private readonly List<EstimateLine> _lines = [];

    private Estimate()
    {
        CompanyId = Guid.Empty;
        EstimateNumber = string.Empty;
    }

    public Estimate(Guid customerId, DateOnly estimateDate, DateOnly expirationDate, string? estimateNumber = null, Guid? companyId = null)
    {
        if (customerId == Guid.Empty)
        {
            throw new ArgumentException("Customer is required.", nameof(customerId));
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        CustomerId = customerId;
        EstimateNumber = string.IsNullOrWhiteSpace(estimateNumber) ? $"EST-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : estimateNumber.Trim();
        EstimateDate = estimateDate;
        ExpirationDate = expirationDate;
        Status = EstimateStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid CustomerId { get; }
    public string EstimateNumber { get; }
    public DateOnly EstimateDate { get; }
    public DateOnly ExpirationDate { get; private set; }
    public EstimateStatus Status { get; private set; }
    public IReadOnlyList<EstimateLine> Lines => _lines;
    public decimal TotalAmount => _lines.Sum(line => line.LineTotal);
    public DateTimeOffset? SentAt { get; private set; }
    public DateTimeOffset? AcceptedAt { get; private set; }
    public DateTimeOffset? DeclinedAt { get; private set; }
    public DateTimeOffset? CancelledAt { get; private set; }

    public void AddLine(EstimateLine line)
    {
        if (Status is EstimateStatus.Accepted or EstimateStatus.Declined or EstimateStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot change a closed estimate.");
        }

        _lines.Add(line);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkSent()
    {
        if (Status is EstimateStatus.Accepted or EstimateStatus.Declined or EstimateStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot send a closed estimate.");
        }

        Status = EstimateStatus.Sent;
        SentAt ??= DateTimeOffset.UtcNow;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Accept()
    {
        if (Status is EstimateStatus.Declined or EstimateStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot accept a declined or cancelled estimate.");
        }

        if (Status == EstimateStatus.Accepted)
        {
            return;
        }

        Status = EstimateStatus.Accepted;
        AcceptedAt = DateTimeOffset.UtcNow;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Decline()
    {
        if (Status is EstimateStatus.Accepted or EstimateStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot decline an accepted or cancelled estimate.");
        }

        if (Status == EstimateStatus.Declined)
        {
            return;
        }

        Status = EstimateStatus.Declined;
        DeclinedAt = DateTimeOffset.UtcNow;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Cancel()
    {
        if (Status is EstimateStatus.Accepted or EstimateStatus.Declined)
        {
            throw new InvalidOperationException("Cannot cancel an estimate that is already accepted or declined.");
        }

        if (Status == EstimateStatus.Cancelled)
        {
            return;
        }

        Status = EstimateStatus.Cancelled;
        CancelledAt = DateTimeOffset.UtcNow;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
