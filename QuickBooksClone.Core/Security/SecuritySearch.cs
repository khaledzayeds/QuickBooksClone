namespace QuickBooksClone.Core.Security;

public sealed record SecurityUserSearch(string? Search, bool IncludeInactive = false, int Page = 1, int PageSize = 25);

public sealed record SecurityRoleSearch(string? Search, bool IncludeInactive = false, int Page = 1, int PageSize = 25);

public sealed record SecurityUserListResult(IReadOnlyList<SecurityUser> Items, int TotalCount, int Page, int PageSize);

public sealed record SecurityRoleListResult(IReadOnlyList<SecurityRole> Items, int TotalCount, int Page, int PageSize);
