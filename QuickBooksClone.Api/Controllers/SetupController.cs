using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Setup;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Security;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Infrastructure.Security;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/setup")]
[AllowAnonymous]
public sealed class SetupController : ControllerBase
{
    private const string AdminRoleKey = "ADMIN";

    private readonly ICompanySettingsRepository _companySettings;
    private readonly ISecurityRepository _security;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IDefaultAccountsSeeder _defaultAccountsSeeder;

    public SetupController(
        ICompanySettingsRepository companySettings,
        ISecurityRepository security,
        IPasswordHasher passwordHasher,
        IDefaultAccountsSeeder defaultAccountsSeeder)
    {
        _companySettings = companySettings;
        _security = security;
        _passwordHasher = passwordHasher;
        _defaultAccountsSeeder = defaultAccountsSeeder;
    }

    [HttpGet("status")]
    [ProducesResponseType(typeof(SetupStatusResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<SetupStatusResponse>> GetStatus(CancellationToken cancellationToken = default)
    {
        return Ok(await BuildStatusAsync(cancellationToken));
    }

    [HttpPost("initialize-company")]
    [ProducesResponseType(typeof(InitializeCompanyResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<InitializeCompanyResponse>> InitializeCompany(InitializeCompanyRequest request, CancellationToken cancellationToken = default)
    {
        var status = await BuildStatusAsync(cancellationToken);
        if (status.IsInitialized)
        {
            return Conflict("Company is already initialized.");
        }

        if (string.IsNullOrWhiteSpace(request.InitialAdminSecret) || request.InitialAdminSecret.Length < 8)
        {
            return BadRequest("Initial admin secret must be at least 8 characters.");
        }

        if (await _security.UserNameExistsAsync(request.AdminUserName, null, cancellationToken))
        {
            return Conflict("Admin user name already exists.");
        }

        if (!string.IsNullOrWhiteSpace(request.AdminEmail) && await _security.UserEmailExistsAsync(request.AdminEmail, null, cancellationToken))
        {
            return Conflict("Admin email already exists.");
        }

        try
        {
            var company = await EnsureCompanySettingsAsync(request, cancellationToken);
            var adminRole = await EnsureAdminRoleAsync(cancellationToken);
            var adminUser = new SecurityUser(
                request.AdminUserName,
                request.AdminDisplayName,
                request.AdminEmail,
                _passwordHasher.HashPassword(request.InitialAdminSecret));

            await _security.AddUserAsync(adminUser, [adminRole.Id], cancellationToken);
            await _defaultAccountsSeeder.SeedAsync(cancellationToken);

            return Ok(new InitializeCompanyResponse(true, company.CompanyName, adminUser.UserName, adminRole.RoleKey));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("seed-default-accounts")]
    [ProducesResponseType(typeof(DefaultAccountsSeedResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<DefaultAccountsSeedResponse>> SeedDefaultAccounts(CancellationToken cancellationToken = default)
    {
        var result = await _defaultAccountsSeeder.SeedAsync(cancellationToken);
        return Ok(new DefaultAccountsSeedResponse(
            result.CreatedCount,
            result.SkippedCount,
            result.CreatedCodes,
            result.SkippedCodes));
    }

    private async Task<SetupStatusResponse> BuildStatusAsync(CancellationToken cancellationToken)
    {
        var company = await _companySettings.GetAsync(cancellationToken);
        var adminRole = await _security.GetRoleByKeyAsync(AdminRoleKey, cancellationToken);
        var hasAdminUser = false;
        string? adminUserName = null;

        if (adminRole is not null)
        {
            var users = await _security.SearchUsersAsync(new SecurityUserSearch(null, true, 1, 100), cancellationToken);
            var adminUser = users.Items.FirstOrDefault(user => user.RoleAssignments.Any(role => role.RoleId == adminRole.Id));
            hasAdminUser = adminUser is not null;
            adminUserName = adminUser?.UserName;
        }

        return new SetupStatusResponse(
            company is not null,
            hasAdminUser,
            company is not null && hasAdminUser,
            company?.CompanyName,
            adminUserName);
    }

    private async Task<CompanySettings> EnsureCompanySettingsAsync(InitializeCompanyRequest request, CancellationToken cancellationToken)
    {
        var existing = await _companySettings.GetAsync(cancellationToken);
        if (existing is not null)
        {
            return existing;
        }

        var settings = new CompanySettings(
            request.CompanyName,
            string.IsNullOrWhiteSpace(request.Currency) ? "EGP" : request.Currency,
            string.IsNullOrWhiteSpace(request.Country) ? "Egypt" : request.Country,
            string.IsNullOrWhiteSpace(request.TimeZoneId) ? "Africa/Cairo" : request.TimeZoneId,
            string.IsNullOrWhiteSpace(request.DefaultLanguage) ? "ar" : request.DefaultLanguage,
            request.LegalName,
            request.Email,
            request.Phone);

        return await _companySettings.AddAsync(settings, cancellationToken);
    }

    private async Task<SecurityRole> EnsureAdminRoleAsync(CancellationToken cancellationToken)
    {
        var existing = await _security.GetRoleByKeyAsync(AdminRoleKey, cancellationToken);
        if (existing is not null)
        {
            return existing;
        }

        var role = new SecurityRole(AdminRoleKey, "Owner / Administrator", "Full system access created during first setup.", isSystem: true);
        role.ReplacePermissions(PermissionCatalog.ForRole(AdminRoleKey));
        return await _security.AddRoleAsync(role, cancellationToken);
    }
}
