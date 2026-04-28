using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using QuickBooksClone.Infrastructure.Persistence;

#nullable disable

namespace QuickBooksClone.SqlServerMigrations.Migrations
{
    [DbContext(typeof(QuickBooksCloneDbContext))]
    [Migration("20260428121001_AddDocumentMetadataSqlServer")]
    public partial class AddDocumentMetadataSqlServer : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "document_metadata",
                columns: table => new
                {
                    Id = table.Column<Guid>(nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(nullable: true),
                    CompanyId = table.Column<Guid>(nullable: false),
                    DeviceId = table.Column<string>(maxLength: 20, nullable: false),
                    DocumentNo = table.Column<string>(maxLength: 80, nullable: false),
                    SyncStatus = table.Column<int>(nullable: false),
                    LastModifiedAt = table.Column<DateTimeOffset>(nullable: false),
                    SyncVersion = table.Column<long>(nullable: false),
                    LastSyncAt = table.Column<DateTimeOffset>(nullable: true),
                    SyncError = table.Column<string>(maxLength: 500, nullable: true),
                    DocumentType = table.Column<string>(maxLength: 80, nullable: false),
                    DocumentId = table.Column<Guid>(nullable: false),
                    PublicMemo = table.Column<string>(maxLength: 1000, nullable: true),
                    InternalNote = table.Column<string>(maxLength: 2000, nullable: true),
                    ExternalReference = table.Column<string>(maxLength: 120, nullable: true),
                    TemplateName = table.Column<string>(maxLength: 120, nullable: true),
                    ShipToName = table.Column<string>(maxLength: 200, nullable: true),
                    ShipToAddressLine1 = table.Column<string>(maxLength: 200, nullable: true),
                    ShipToAddressLine2 = table.Column<string>(maxLength: 200, nullable: true),
                    ShipToCity = table.Column<string>(maxLength: 120, nullable: true),
                    ShipToRegion = table.Column<string>(maxLength: 120, nullable: true),
                    ShipToPostalCode = table.Column<string>(maxLength: 40, nullable: true),
                    ShipToCountry = table.Column<string>(maxLength: 120, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_document_metadata", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "document_attachment_metadata",
                columns: table => new
                {
                    Id = table.Column<Guid>(nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(nullable: true),
                    DocumentMetadataId = table.Column<Guid>(nullable: false),
                    FileName = table.Column<string>(maxLength: 260, nullable: false),
                    ContentType = table.Column<string>(maxLength: 120, nullable: false),
                    FileSizeBytes = table.Column<long>(nullable: false),
                    StorageKey = table.Column<string>(maxLength: 500, nullable: false),
                    UploadedAt = table.Column<DateTimeOffset>(nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_document_attachment_metadata", x => x.Id);
                    table.ForeignKey(
                        name: "FK_document_attachment_metadata_document_metadata_DocumentMetadataId",
                        column: x => x.DocumentMetadataId,
                        principalTable: "document_metadata",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex("IX_document_attachment_metadata_DocumentMetadataId", "document_attachment_metadata", "DocumentMetadataId");
            migrationBuilder.CreateIndex("IX_document_metadata_CompanyId", "document_metadata", "CompanyId");
            migrationBuilder.CreateIndex("IX_document_metadata_DeviceId", "document_metadata", "DeviceId");
            migrationBuilder.CreateIndex("IX_document_metadata_DocumentNo", "document_metadata", "DocumentNo", unique: true);
            migrationBuilder.CreateIndex("IX_document_metadata_DocumentType_DocumentId", "document_metadata", new[] { "DocumentType", "DocumentId" }, unique: true);
            migrationBuilder.CreateIndex("IX_document_metadata_LastModifiedAt", "document_metadata", "LastModifiedAt");
            migrationBuilder.CreateIndex("IX_document_metadata_SyncStatus", "document_metadata", "SyncStatus");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "document_attachment_metadata");
            migrationBuilder.DropTable(name: "document_metadata");
        }
    }
}
