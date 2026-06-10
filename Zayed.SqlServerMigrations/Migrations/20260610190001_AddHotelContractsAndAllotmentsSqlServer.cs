using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Zayed.Infrastructure.Persistence;

#nullable disable

namespace Zayed.SqlServerMigrations.Migrations
{
    [DbContext(typeof(ZayedDbContext))]
    [Migration("20260610190001_AddHotelContractsAndAllotmentsSqlServer")]
    public partial class AddHotelContractsAndAllotmentsSqlServer : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "hotel_contracts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ContractNumber = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: false),
                    HotelId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AgentId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    StartDate = table.Column<DateOnly>(type: "date", nullable: false),
                    EndDate = table.Column<DateOnly>(type: "date", nullable: false),
                    Currency = table.Column<string>(type: "nvarchar(3)", maxLength: 3, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_contracts", x => x.Id));

            migrationBuilder.CreateTable(
                name: "hotel_contract_rates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ContractId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RoomTypeId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MealPlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Rate = table.Column<decimal>(type: "decimal(18,4)", precision: 18, scale: 4, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_hotel_contract_rates", x => x.Id);
                    table.ForeignKey("FK_hotel_contract_rates_hotel_contracts_ContractId", x => x.ContractId, "hotel_contracts", "Id", onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "hotel_allotments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ContractId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    HotelId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AgentId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    StartDate = table.Column<DateOnly>(type: "date", nullable: false),
                    EndDate = table.Column<DateOnly>(type: "date", nullable: false),
                    Rooms = table.Column<int>(type: "int", nullable: false),
                    AllotmentType = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    IsOverAllotment = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_allotments", x => x.Id));

            migrationBuilder.CreateIndex(name: "IX_hotel_contracts_CompanyId", table: "hotel_contracts", column: "CompanyId");
            migrationBuilder.CreateIndex(name: "IX_hotel_contracts_CompanyId_ContractNumber", table: "hotel_contracts", columns: new[] { "CompanyId", "ContractNumber" }, unique: true);
            migrationBuilder.CreateIndex(name: "IX_hotel_contract_rates_ContractId", table: "hotel_contract_rates", column: "ContractId");
            migrationBuilder.CreateIndex(name: "IX_hotel_contract_rates_CompanyId_ContractId", table: "hotel_contract_rates", columns: new[] { "CompanyId", "ContractId" });
            migrationBuilder.CreateIndex(name: "IX_hotel_contract_rates_ContractId_RoomTypeId_MealPlanId", table: "hotel_contract_rates", columns: new[] { "ContractId", "RoomTypeId", "MealPlanId" }, unique: true);
            migrationBuilder.CreateIndex(name: "IX_hotel_allotments_CompanyId", table: "hotel_allotments", column: "CompanyId");
            migrationBuilder.CreateIndex(name: "IX_hotel_allotments_CompanyId_ContractId", table: "hotel_allotments", columns: new[] { "CompanyId", "ContractId" });
            migrationBuilder.CreateIndex(name: "IX_hotel_allotments_CompanyId_StartDate_EndDate", table: "hotel_allotments", columns: new[] { "CompanyId", "StartDate", "EndDate" });
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "hotel_allotments");
            migrationBuilder.DropTable(name: "hotel_contract_rates");
            migrationBuilder.DropTable(name: "hotel_contracts");
        }
    }
}
