using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Banking;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/banking/reconcile")]
[RequirePermission("Accounting.View")]
public sealed class BankReconciliationController : ControllerBase
{
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public BankReconciliationController(IAccountRepository accounts, IAccountingTransactionRepository transactions)
    {
        _accounts = accounts;
        _transactions = transactions;
    }

    [HttpPost("preview")]
    [RequirePermission("Accounting.Manage")]
    [ProducesResponseType(typeof(BankReconcilePreviewResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<BankReconcilePreviewResponse>> Preview(BankReconcilePreviewRequest request, CancellationToken cancellationToken = default)
    {
        if (request.AccountId == Guid.Empty)
        {
            return BadRequest("Bank account is required.");
        }

        var account = await _accounts.GetByIdAsync(request.AccountId, cancellationToken);
        if (account is null || !IsBankingAccount(account))
        {
            return BadRequest("Banking account does not exist.");
        }

        var transactions = await _transactions.SearchAsync(new AccountingTransactionSearch(null, IncludeVoided: false, PageSize: 1000), cancellationToken);
        var runningBalance = 0m;
        var lines = new List<BankRegisterLineDto>();

        foreach (var transaction in transactions.Items.OrderBy(t => t.TransactionDate).ThenBy(t => t.CreatedAt))
        {
            if (transaction.Status == AccountingTransactionStatus.Voided || transaction.TransactionDate > request.StatementDate)
            {
                continue;
            }

            foreach (var line in transaction.Lines.Where(line => line.AccountId == account.Id))
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

        var difference = request.StatementEndingBalance - runningBalance;
        return Ok(new BankReconcilePreviewResponse(
            account.Id,
            account.Name,
            request.StatementDate,
            runningBalance,
            request.StatementEndingBalance,
            difference,
            Math.Abs(difference) < 0.005m,
            lines));
    }

    private static bool IsBankingAccount(Account account) =>
        account.AccountType is AccountType.Bank or AccountType.OtherCurrentAsset or AccountType.CreditCard;

    private static decimal SignedAmount(AccountType accountType, decimal debit, decimal credit) =>
        IsDebitNormal(accountType) ? debit - credit : credit - debit;

    private static bool IsDebitNormal(AccountType accountType) =>
        accountType is AccountType.Bank
            or AccountType.AccountsReceivable
            or AccountType.OtherCurrentAsset
            or AccountType.InventoryAsset
            or AccountType.FixedAsset
            or AccountType.CostOfGoodsSold
            or AccountType.Expense
            or AccountType.OtherExpense;
}
