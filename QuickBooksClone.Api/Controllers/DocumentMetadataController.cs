using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.Documents;
using QuickBooksClone.Core.Documents;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/documents/{documentType}/{documentId:guid}/metadata")]
[RequirePermission("Documents.Metadata.Manage")]
public sealed class DocumentMetadataController : ControllerBase
{
    private readonly IDocumentMetadataService _metadata;

    public DocumentMetadataController(IDocumentMetadataService metadata)
    {
        _metadata = metadata;
    }

    [HttpGet]
    [ProducesResponseType(typeof(DocumentMetadataDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<DocumentMetadataDto>> Get(string documentType, Guid documentId, CancellationToken cancellationToken = default)
    {
        try
        {
            var metadata = await _metadata.GetOrCreateAsync(documentType, documentId, cancellationToken);
            return Ok(ToDto(metadata));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPut]
    [ProducesResponseType(typeof(DocumentMetadataDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<DocumentMetadataDto>> Update(
        string documentType,
        Guid documentId,
        UpdateDocumentMetadataRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var metadata = await _metadata.UpdateAsync(
                documentType,
                documentId,
                request.PublicMemo,
                request.InternalNote,
                request.ExternalReference,
                request.TemplateName,
                request.ShipToName,
                request.ShipToAddressLine1,
                request.ShipToAddressLine2,
                request.ShipToCity,
                request.ShipToRegion,
                request.ShipToPostalCode,
                request.ShipToCountry,
                cancellationToken);

            return Ok(ToDto(metadata));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("attachments")]
    [ProducesResponseType(typeof(DocumentAttachmentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<DocumentAttachmentDto>> AddAttachment(
        string documentType,
        Guid documentId,
        AddDocumentAttachmentRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var attachment = await _metadata.AddAttachmentAsync(
                documentType,
                documentId,
                request.FileName,
                request.ContentType,
                request.FileSizeBytes,
                request.StorageKey,
                cancellationToken);

            return CreatedAtAction(nameof(Get), new { documentType, documentId }, ToDto(attachment));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpDelete("attachments/{attachmentId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult> RemoveAttachment(
        string documentType,
        Guid documentId,
        Guid attachmentId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var removed = await _metadata.RemoveAttachmentAsync(documentType, documentId, attachmentId, cancellationToken);
            return removed ? NoContent() : NotFound();
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    private static DocumentMetadataDto ToDto(DocumentMetadata metadata) =>
        new(
            metadata.Id,
            metadata.DocumentType,
            metadata.DocumentId,
            metadata.DocumentNo,
            metadata.DeviceId,
            metadata.SyncStatus,
            metadata.SyncVersion,
            metadata.LastModifiedAt,
            metadata.PublicMemo,
            metadata.InternalNote,
            metadata.ExternalReference,
            metadata.TemplateName,
            metadata.ShipToName,
            metadata.ShipToAddressLine1,
            metadata.ShipToAddressLine2,
            metadata.ShipToCity,
            metadata.ShipToRegion,
            metadata.ShipToPostalCode,
            metadata.ShipToCountry,
            metadata.Attachments.Select(ToDto).ToList());

    private static DocumentAttachmentDto ToDto(DocumentAttachmentMetadata attachment) =>
        new(
            attachment.Id,
            attachment.FileName,
            attachment.ContentType,
            attachment.FileSizeBytes,
            attachment.StorageKey,
            attachment.UploadedAt);
}
