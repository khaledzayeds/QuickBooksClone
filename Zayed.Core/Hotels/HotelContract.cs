using Zayed.Core.Common;

namespace Zayed.Core.Hotels;

public sealed class HotelContract : EntityBase, ITenantEntity
{
    private readonly List<HotelContractRate> _rates = [];

    private HotelContract()
    {
        CompanyId = Guid.Empty;
        ContractNumber = string.Empty;
        Currency = string.Empty;
    }

    public HotelContract(
        string contractNumber,
        Guid hotelId,
        Guid? agentId,
        DateOnly startDate,
        DateOnly endDate,
        string currency,
        string? notes,
        Guid companyId)
    {
        CompanyId = companyId;
        ContractNumber = NormalizeRequired(contractNumber, nameof(contractNumber));
        HotelId = hotelId;
        AgentId = agentId;
        StartDate = startDate;
        EndDate = endDate < startDate ? startDate : endDate;
        Currency = string.IsNullOrWhiteSpace(currency) ? "SAR" : currency.Trim().ToUpperInvariant();
        Notes = NormalizeOptional(notes);
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string ContractNumber { get; private set; }
    public Guid HotelId { get; private set; }
    public Guid? AgentId { get; private set; }
    public DateOnly StartDate { get; private set; }
    public DateOnly EndDate { get; private set; }
    public string Currency { get; private set; }
    public string? Notes { get; private set; }
    public bool IsActive { get; private set; }
    public IReadOnlyCollection<HotelContractRate> Rates => _rates;

    public void Update(string contractNumber, Guid hotelId, Guid? agentId, DateOnly startDate, DateOnly endDate, string currency, string? notes)
    {
        ContractNumber = NormalizeRequired(contractNumber, nameof(contractNumber));
        HotelId = hotelId;
        AgentId = agentId;
        StartDate = startDate;
        EndDate = endDate < startDate ? startDate : endDate;
        Currency = string.IsNullOrWhiteSpace(currency) ? "SAR" : currency.Trim().ToUpperInvariant();
        Notes = NormalizeOptional(notes);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ReplaceRates(IEnumerable<HotelContractRate> rates)
    {
        _rates.Clear();
        _rates.AddRange(rates);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private static string NormalizeRequired(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value)) throw new ArgumentException("Value is required.", parameterName);
        return value.Trim();
    }

    private static string? NormalizeOptional(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
