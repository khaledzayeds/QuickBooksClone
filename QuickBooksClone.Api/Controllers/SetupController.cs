using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Setup;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Companies;
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
    private readonly ICompanyRuntimeService _companyRuntime;
    private readonly ILogger<SetupController> _logger;

    public SetupController(
        ICompanySettingsRepository companySettings,
        ISecurityRepository security,
        IPasswordHasher passwordHasher,
        IDefaultAccountsSeeder defaultAccountsSeeder,
        ICompanyRuntimeService companyRuntime,
        ILogger<SetupController> logger)
    {
        _companySettings = companySettings;
        _security = security;
        _passwordHasher = passwordHasher;
        _defaultAccountsSeeder = defaultAccountsSeeder;
        _companyRuntime = companyRuntime;
        _logger = logger;
    }

    [HttpGet("status")]
    [ProducesResponseType(typeof(SetupStatusResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<SetupStatusResponse>> GetStatus(CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Setup status requested: before BuildStatusAsync.");
            var status = await BuildStatusAsync(cancellationToken);
            _logger.LogInformation(
                "Setup status completed: initialized={IsInitialized}, company={CompanyName}.",
                status.IsInitialized,
                status.CompanyName);

            return Ok(status);
        }
        catch (Exception exception)
        {
            _logger.LogError(exception, "Setup status failed.");
            return Problem(
                title: "Setup status failed",
                detail: exception.Message,
                statusCode: StatusCodes.Status500InternalServerError);
        }
    }

    [HttpPost("initialize-company")]
    [ProducesResponseType(typeof(InitializeCompanyResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<InitializeCompanyResponse>> InitializeCompany(InitializeCompanyRequest request, CancellationToken cancellationToken = default)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(45));
        var setupCancellationToken = timeout.Token;

        try
        {
            _logger.LogInformation("Initialize company requested for {CompanyName}: before BuildStatusAsync.", request.CompanyName);
            var status = await BuildStatusAsync(setupCancellationToken);
            _logger.LogInformation("Initialize company for {CompanyName}: BuildStatusAsync completed.", request.CompanyName);

            if (status.IsInitialized)
            {
                return Conflict("Company is already initialized.");
            }

            if (string.IsNullOrWhiteSpace(request.InitialAdminSecret) || request.InitialAdminSecret.Length < 8)
            {
                return BadRequest("Initial admin secret must be at least 8 characters.");
            }

            if (await _security.UserNameExistsAsync(request.AdminUserName, null, setupCancellationToken))
            {
                return Conflict("Admin user name already exists.");
            }

            if (!string.IsNullOrWhiteSpace(request.AdminEmail) && await _security.UserEmailExistsAsync(request.AdminEmail, null, setupCancellationToken))
            {
                return Conflict("Admin email already exists.");
            }

            _logger.LogInformation("Initialize company for {CompanyName}: before EnsureCompanySettingsAsync.", request.CompanyName);
            var company = await EnsureCompanySettingsAsync(request, setupCancellationToken);
            _logger.LogInformation("Initialize company for {CompanyName}: EnsureCompanySettingsAsync completed.", request.CompanyName);

            _logger.LogInformation("Initialize company for {CompanyName}: before EnsureAdminRoleAsync.", request.CompanyName);
            var adminRole = await EnsureAdminRoleAsync(setupCancellationToken);
            _logger.LogInformation("Initialize company for {CompanyName}: EnsureAdminRoleAsync completed.", request.CompanyName);

            _logger.LogInformation("Initialize company for {CompanyName}: before AddUserAsync.", request.CompanyName);
            var adminUser = new SecurityUser(
                request.AdminUserName,
                request.AdminDisplayName,
                request.AdminEmail,
                _passwordHasher.HashPassword(request.InitialAdminSecret));

            await _security.AddUserAsync(adminUser, [adminRole.Id], setupCancellationToken);
            _logger.LogInformation("Initialize company for {CompanyName}: AddUserAsync completed.", request.CompanyName);

            _logger.LogInformation("Initialize company for {CompanyName}: before DefaultAccountsSeeder.SeedAsync.", request.CompanyName);
            await _defaultAccountsSeeder.SeedAsync(setupCancellationToken);
            _logger.LogInformation("Initialize company for {CompanyName}: DefaultAccountsSeeder.SeedAsync completed.", request.CompanyName);

            _logger.LogInformation("Initialize company for {CompanyName}: before MarkSetupInitializedAsync.", request.CompanyName);
            await _companyRuntime.MarkSetupInitializedAsync(setupCancellationToken);
            _logger.LogInformation("Initialize company for {CompanyName}: MarkSetupInitializedAsync completed.", request.CompanyName);

            _logger.LogInformation("Initialize company for {CompanyName}: before returning OK.", request.CompanyName);
            return Ok(new InitializeCompanyResponse(true, company.CompanyName, adminUser.UserName, adminRole.RoleKey));
        }
        catch (ArgumentException exception)
        {
            _logger.LogWarning(exception, "Initialize company validation failed for {CompanyName}.", request.CompanyName);
            return BadRequest(exception.Message);
        }
        catch (InvalidOperationException exception)
        {
            _logger.LogWarning(exception, "Initialize company operation failed for {CompanyName}.", request.CompanyName);
            return BadRequest(exception.Message);
        }
        catch (OperationCanceledException exception) when (!cancellationToken.IsCancellationRequested)
        {
            _logger.LogError(exception, "Initialize company timed out for {CompanyName}.", request.CompanyName);
            return Problem(
                title: "Company setup timed out",
                detail: "Company setup did not finish within the expected time. Check the server log for the last completed setup step.",
                statusCode: StatusCodes.Status504GatewayTimeout);
        }
        catch (Exception exception)
        {
            _logger.LogError(exception, "Initialize company failed for {CompanyName}.", request.CompanyName);
            return Problem(
                title: "Company setup failed",
                detail: exception.Message,
                statusCode: StatusCodes.Status500InternalServerError);
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
        var runtime = await _companyRuntime.GetActiveAsync(cancellationToken);
        if (!runtime.IsActive)
        {
            return new SetupStatusResponse(false, false, false, null, null);
        }

        if (!runtime.IsSetupInitialized)
        {
            return new SetupStatusResponse(false, false, false, runtime.CompanyName, null);
        }

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
