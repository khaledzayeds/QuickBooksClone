namespace QuickBooksClone.Core.Common;

public sealed record DocumentNumberAllocation(string DeviceId, string DocumentNo, string DocumentType, int Year, int Sequence);
