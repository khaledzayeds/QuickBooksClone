using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Banking;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/banking")]
[RequirePermission("Accounting.View")]
public sealed class BankingController : ControllerBase
{
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public BankingController(IAccountRepository accounts, IAccountingTransactionRepository transactions)
    {
        _accounts = accounts;
        _transactions = transactions;
    }

    [HttpGet("accounts")]
    [ProducesResponseType(typeof(IReadOnlyList<BankAccountDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<BankAccountDto>>> GetBankAccounts(CancellationToken cancellationToken = default)
    {
        var accounts = await _accounts.SearchAsync(new AccountSearch(null, null, true, 1, 500), cancellationToken);
        var balances = await GetAccountBalancesAsync(cancellationToken);

        var result = accounts.Items
            .Where(IsBankingAccount)
            .OrderBy(account => account.Code)
            .Select(account => new BankAccountDto(
                account.Id,
                account.Code,
                account.Name,
                account.AccountType,
                balances.GetValueOrDefault(account.Id),
                account.IsActive))
            .ToList();

        return Ok(result);
    }

    [HttpGet("register")]
    [ProducesResponseType(typeof(BankRegisterResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<BankRegisterResponse>> GetRegister(
        [FromQuery] Guid accountId,
        [FromQuery] bool includeVoided = false,
        CancellationToken cancellationToken = default)
    {
        var account = await _accounts.GetByIdAsync(accountId, cancellationToken);
        if (account is null || !IsBankingAccount(account))
        {
            return NotFound("Banking account does not exist.");
        }

        var transactions = await _transactions.SearchAsync(new AccountingTransactionSearch(null, includeVoided, 1, 1000), cancellationToken);
        var runningBalance = 0m;
        var lines = new List<BankRegisterLineDto>();

        foreach (var transaction in transactions.Items.OrderBy(t => t.TransactionDate).ThenBy(t => t.CreatedAt))
        {
            if (!includeVoided && transaction.Status == AccountingTransactionStatus.Voided)
            {
                continue;
            }

            foreach (var line in transaction.Lines.Where(line => line.AccountId == accountId))
            {
                var amount = SignedAmount(account.AccountType, line.Debit, line.Credit);
                runningBalance += amount;
                lines.Add(new BankRegisterLineDto(
                    transaction.Id,
                    transaction.TransactionDate,
                    transaction.TransactionType,
                    transaction.ReferenceNumber,
                    line.Description,
                    line.Debit,
                    line.Credit,
                    amount,
                    runningBalance,
                    transaction.SourceEntityType,
                    transaction.SourceEntityId));
            }
        }

        return Ok(new BankRegisterResponse(account.Id, account.Name, 0m, runningBalance, lines));
    }

    [HttpPost("transfers")]
    [RequirePermission("Accounting.Manage")]
    [ProducesResponseType(typeof(BankRegisterLineDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<BankRegisterLineDto>> CreateTransfer(CreateBankTransferRequest request, CancellationToken cancellationToken = default)
    {
        if (request.FromAccountId == Guid.Empty || request.ToAccountId == Guid.Empty)
        {
            return BadRequest("Both transfer accounts are required.");
        }

        if (request.FromAccountId == request.ToAccountId)
        {
            return BadRequest("Transfer accounts must be different.");
        }

        if (request.Amount <= 0)
        {
            return BadRequest("Transfer amount must be greater than zero.");
        }

        var fromAccount = await _accounts.GetByIdAsync(request.FromAccountId, cancellationToken);
        var toAccount = await _accounts.GetByIdAsync(request.ToAccountId, cancellationToken);
        if (fromAccount is null || toAccount is null)
        {
            return BadRequest("Transfer account does not exist.");
        }

        if (!IsBankingAccount(fromAccount) || !IsBankingAccount(toAccount))
        {
            return BadRequest("Transfers are allowed only between bank/cash style accounts.");
        }

        if (!fromAccount.IsActive || !toAccount.IsActive)
        {
            return BadRequest("Inactive accounts cannot be used in a bank transfer.");
        }

        var memo = string.IsNullOrWhiteSpace(request.Memo) ? "Bank transfer" : request.Memo.Trim();
        var reference = $"BT-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}";
        var transaction = new AccountingTransaction("BankTransfer", request.TransferDate, reference, "BankTransfer", null);
        transaction.AddLine(new AccountingTransactionLine(request.ToAccountId, memo, request.Amount, 0m));
        transaction.AddLine(new AccountingTransactionLine(request.FromAccountId, memo, 0m, request.Amount));
        transaction.ValidateBalanced();

        await _transactions.AddAsync(transaction, cancellationToken);

        var line = new BankRegisterLineDto(
            transaction.Id,
            transaction.TransactionDate,
            transaction.TransactionType,
            transaction.ReferenceNumber,
            memo,
            0m,
            request.Amount,
            -request.Amount,
            0m,
            transaction.SourceEntityType,
            transaction.SourceEntityId);

        return CreatedAtAction(nameof(GetRegister), new { accountId = request.FromAccountId }, line);
    }

    [HttpPost("deposits")]
    [RequirePermission("Accounting.Manage")]
    [ProducesResponseType(typeof(BankRegisterLineDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<BankRegisterLineDto>> CreateDeposit(CreateBankDepositRequest request, CancellationToken cancellationToken = default)
    {
        if (request.DepositAccountId == Guid.Empty || request.OffsetAccountId == Guid.Empty)
        {
            return BadRequest("Deposit and offset accounts are required.");
        }

        if (request.DepositAccountId == request.OffsetAccountId)
        {
            return BadRequest("Deposit and offset accounts must be different.");
        }

        if (request.Amount <= 0)
        {
            return BadRequest("Deposit amount must be greater than zero.");
        }

        var depositAccount = await _accounts.GetByIdAsync(request.DepositAccountId, cancellationToken);
        var offsetAccount = await _accounts.GetByIdAsync(request.OffsetAccountId, cancellationToken);
        if (depositAccount is null || offsetAccount is null)
        {
            return BadRequest("Deposit account does not exist.");
        }

        if (!IsBankingAccount(depositAccount))
        {
            return BadRequest("Deposit account must be a bank/cash style account.");
        }

        if (!depositAccount.IsActive || !offsetAccount.IsActive)
        {
            return BadRequest("Inactive accounts cannot be used in a deposit.");
        }

        if (offsetAccount.AccountType is AccountType.AccountsReceivable or AccountType.AccountsPayable)
        {
            return BadRequest("Use customer/vendor documents instead of posting deposits directly to AR/AP.");
        }

        var memo = string.IsNullOrWhiteSpace(request.Memo) ? "Bank deposit" : request.Memo.Trim();
        var description = string.IsNullOrWhiteSpace(request.ReceivedFrom) ? memo : $"{request.ReceivedFrom.Trim()} - {memo}";
        var reference = $"DEP-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}";
        var transaction = new AccountingTransaction("BankDeposit", request.DepositDate, reference, "BankDeposit", null);
        transaction.AddLine(new AccountingTransactionLine(request.DepositAccountId, description, request.Amount, 0m));
        transaction.AddLine(new AccountingTransactionLine(request.OffsetAccountId, description, 0m, request.Amount));
        transaction.ValidateBalanced();

        await _transactions.AddAsync(transaction, cancellationToken);

        var line = new BankRegisterLineDto(
            transaction.Id,
            transaction.TransactionDate,
            transaction.TransactionType,
            transaction.ReferenceNumber,
            description,
            request.Amount,
            0m,
            request.Amount,
            0m,
            transaction.SourceEntityType,
            transaction.SourceEntityId);

        return CreatedAtAction(nameof(GetRegister), new { accountId = request.DepositAccountId }, line);
    }

    [HttpPost("checks")]
    [RequirePermission("Accounting.Manage")]
    [ProducesResponseType(typeof(BankRegisterLineDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<BankRegisterLineDto>> CreateCheck(CreateBankCheckRequest request, CancellationToken cancellationToken = default)
    {
        if (request.BankAccountId == Guid.Empty || request.ExpenseAccountId == Guid.Empty)
        {
            return BadRequest("Bank and expense/offset accounts are required.");
        }

        if (request.BankAccountId == request.ExpenseAccountId)
        {
            return BadRequest("Bank and offset accounts must be different.");
        }

        if (request.Amount <= 0)
        {
            return BadRequest("Check amount must be greater than zero.");
        }

        var bankAccount = await _accounts.GetByIdAsync(request.BankAccountId, cancellationToken);
        var expenseAccount = await _accounts.GetByIdAsync(request.ExpenseAccountId, cancellationToken);
        if (bankAccount is null || expenseAccount is null)
        {
            return BadRequest("Check account does not exist.");
        }

        if (!IsBankingAccount(bankAccount))
        {
            return BadRequest("Bank account must be a bank/cash style account.");
        }

        if (!bankAccount.IsActive || !expenseAccount.IsActive)
        {
            return BadRequest("Inactive accounts cannot be used in a check.");
        }

        if (expenseAccount.AccountType is AccountType.AccountsReceivable or AccountType.AccountsPayable)
        {
            return BadRequest("Use customer/vendor documents instead of posting checks directly to AR/AP.");
        }

        var memo = string.IsNullOrWhiteSpace(request.Memo) ? "Write check" : request.Memo.Trim();
        var description = string.IsNullOrWhiteSpace(request.Payee) ? memo : $"{request.Payee.Trim()} - {memo}";
        var reference = $"CHK-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}";
        var transaction = new AccountingTransaction("BankCheck", request.CheckDate, reference, "BankCheck", null);
        transaction.AddLine(new AccountingTransactionLine(request.ExpenseAccountId, description, request.Amount, 0m));
        transaction.AddLine(new AccountingTransactionLine(request.BankAccountId, description, 0m, request.Amount));
        transaction.ValidateBalanced();

        await _transactions.AddAsync(transaction, cancellationToken);

        var line = new BankRegisterLineDto(
            transaction.Id,
            transaction.TransactionDate,
            transaction.TransactionType,
            transaction.ReferenceNumber,
            description,
            0m,
            request.Amount,
            -request.Amount,
            0m,
            transaction.SourceEntityType,
            transaction.SourceEntityId);

        return CreatedAtAction(nameof(GetRegister), new { accountId = request.BankAccountId }, line);
    }

    private async Task<Dictionary<Guid, decimal>> GetAccountBalancesAsync(CancellationToken cancellationToken)
    {
        var result = await _transactions.SearchAsync(new AccountingTransactionSearch(null, IncludeVoided: false, PageSize: 1000), cancellationToken);
        var accounts = await _accounts.SearchAsync(new AccountSearch(null, null, true, 1, 500), cancellationToken);
        var accountTypes = accounts.Items.ToDictionary(account => account.Id, account => account.AccountType);
        var balances = new Dictionary<Guid, decimal>();

        foreach (var transaction in result.Items)
        {
            foreach (var line in transaction.Lines)
            {
                accountTypes.TryGetValue(line.AccountId, out var accountType);
                balances[line.AccountId] = balances.GetValueOrDefault(line.AccountId) + SignedAmount(accountType, line.Debit, line.Credit);
            }
        }

        return balances;
    }

    private static bool IsBankingAccount(Account account)
    {
        return account.AccountType is AccountType.Bank or AccountType.OtherCurrentAsset or AccountType.CreditCard;
    }

    private static decimal SignedAmount(AccountType accountType, decimal debit, decimal credit)
    {
        return IsDebitNormal(accountType) ? debit - credit : credit - debit;
    }

    private static bool IsDebitNormal(AccountType accountType)
    {
        return accountType is AccountType.Bank
            or AccountType.AccountsReceivable
            or AccountType.OtherCurrentAsset
            or AccountType.InventoryAsset
            or AccountType.FixedAsset
            or AccountType.CostOfGoodsSold
            or AccountType.Expense
            or AccountType.OtherExpense;
    }
}
