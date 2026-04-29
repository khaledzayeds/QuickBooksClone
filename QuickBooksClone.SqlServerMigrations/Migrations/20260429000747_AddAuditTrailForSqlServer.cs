using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.SqlServerMigrations.Migrations
{
    /// <inheritdoc />
    public partial class AddAuditTrailForSqlServer : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "audit_log_entries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    UserName = table.Column<string>(type: "nvarchar(160)", maxLength: 160, nullable: false),
                    Action = table.Column<string>(type: "nvarchar(160)", maxLength: 160, nullable: false),
                    HttpMethod = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Path = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    StatusCode = table.Column<int>(type: "int", nullable: false),
                    Controller = table.Column<string>(type: "nvarchar(160)", maxLength: 160, nullable: true),
                    EndpointAction = table.Column<string>(type: "nvarchar(160)", maxLength: 160, nullable: true),
                    RequiredPermissions = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    IpAddress = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: true),
                    UserAgent = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    OccurredAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_audit_log_entries", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_audit_log_entries_Action",
                table: "audit_log_entries",
                column: "Action");

            migrationBuilder.CreateIndex(
                name: "IX_audit_log_entries_CompanyId",
                table: "audit_log_entries",
                column: "CompanyId");

            migrationBuilder.CreateIndex(
                name: "IX_audit_log_entries_Controller",
                table: "audit_log_entries",
                column: "Controller");

            migrationBuilder.CreateIndex(
                name: "IX_audit_log_entries_OccurredAt",
                table: "audit_log_entries",
                column: "OccurredAt");

            migrationBuilder.CreateIndex(
                name: "IX_audit_log_entries_UserId",
                table: "audit_log_entries",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "audit_log_entries");
        }
    }
}
