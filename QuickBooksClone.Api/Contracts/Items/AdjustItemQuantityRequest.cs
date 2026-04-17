using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Items;

public sealed record AdjustItemQuantityRequest(
    [Range(0, 999999999)] decimal QuantityOnHand);
