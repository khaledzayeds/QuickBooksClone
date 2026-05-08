namespace QuickBooksClone.Api.Contracts.TimeTracking;

public sealed record TimeEntryLookupsDto(
    IReadOnlyList<TimeEntryCustomerLookupDto> Customers,
    IReadOnlyList<TimeEntryServiceItemLookupDto> ServiceItems);

public sealed record TimeEntryCustomerLookupDto(
    Guid Id,
    string DisplayName);

public sealed record TimeEntryServiceItemLookupDto(
    Guid Id,
    string Name);
