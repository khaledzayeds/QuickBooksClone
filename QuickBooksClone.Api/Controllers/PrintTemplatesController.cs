using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.PrintTemplates;
using QuickBooksClone.Core.PrintTemplates;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/print-templates")]
public sealed class PrintTemplatesController : ControllerBase
{
    private readonly IPrintTemplateRepository _repository;

    public PrintTemplatesController(IPrintTemplateRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<PrintTemplateResponse>>> List([FromQuery] string? documentType, CancellationToken cancellationToken = default)
    {
        var templates = await _repository.ListAsync(documentType, cancellationToken);
        return Ok(templates.Select(ToResponse).ToList());
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<PrintTemplateResponse>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var template = await _repository.GetAsync(id, cancellationToken);
        if (template is null) return NotFound();
        return Ok(ToResponse(template));
    }

    [HttpPost]
    public async Task<ActionResult<PrintTemplateResponse>> Create(SavePrintTemplateRequest request, CancellationToken cancellationToken = default)
    {
        var template = PrintTemplate.Create(request.Name, request.DocumentType, request.PageSize, request.JsonContent, request.IsDefault);
        var saved = await _repository.AddAsync(template, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = saved.Id }, ToResponse(saved));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<PrintTemplateResponse>> Update(Guid id, SavePrintTemplateRequest request, CancellationToken cancellationToken = default)
    {
        var existing = await _repository.GetAsync(id, cancellationToken);
        if (existing is null) return NotFound();

        var updated = existing.WithUpdate(request.Name, request.DocumentType, request.PageSize, request.JsonContent, request.IsDefault);
        var saved = await _repository.UpdateAsync(updated, cancellationToken);
        return Ok(ToResponse(saved));
    }

    [HttpPost("{id:guid}/clone")]
    public async Task<ActionResult<PrintTemplateResponse>> Clone(Guid id, ClonePrintTemplateRequest request, CancellationToken cancellationToken = default)
    {
        var existing = await _repository.GetAsync(id, cancellationToken);
        if (existing is null) return NotFound();

        var saved = await _repository.AddAsync(existing.Clone(request.Name), cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = saved.Id }, ToResponse(saved));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken = default)
    {
        await _repository.DeleteAsync(id, cancellationToken);
        return NoContent();
    }

    private static PrintTemplateResponse ToResponse(PrintTemplate template)
    {
        return new PrintTemplateResponse(
            template.Id,
            template.Name,
            template.DocumentType,
            template.PageSize,
            template.JsonContent,
            template.IsDefault,
            template.CreatedAt,
            template.UpdatedAt);
    }
}
