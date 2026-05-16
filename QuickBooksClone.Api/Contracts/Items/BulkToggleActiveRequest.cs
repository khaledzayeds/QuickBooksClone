namespace QuickBooksClone.Api.Contracts.Items;

public sealed record BulkToggleActiveRequest(List<Guid> ItemIds, bool IsActive);
public sealed record BulkToggleActiveResponse(int UpdatedCount);
