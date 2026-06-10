using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Zayed.Infrastructure.Persistence.Migrations
{
    [DbContext(typeof(ZayedDbContext))]
    [Migration("20260610190000_AddHotelContractsAndAllotments")]
    public partial class AddHotelContractsAndAllotments : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "hotel_contracts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    ContractNumber = table.Column<string>(type: "TEXT", maxLength: 60, nullable: false),
                    HotelId = table.Column<Guid>(type: "TEXT", nullable: false),
                    AgentId = table.Column<Guid>(type: "TEXT", nullable: true),
                    StartDate = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    EndDate = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    Currency = table.Column<string>(type: "TEXT", maxLength: 3, nullable: false),
                    Notes = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_contracts", x => x.Id));

            migrationBuilder.CreateTable(
                name: "hotel_contract_rates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    ContractId = table.Column<Guid>(type: "TEXT", nullable: false),
                    RoomTypeId = table.Column<Guid>(type: "TEXT", nullable: false),
                    MealPlanId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Rate = table.Column<decimal>(type: "TEXT", precision: 18, scale: 4, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
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
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    ContractId = table.Column<Guid>(type: "TEXT", nullable: false),
                    HotelId = table.Column<Guid>(type: "TEXT", nullable: false),
                    AgentId = table.Column<Guid>(type: "TEXT", nullable: true),
                    StartDate = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    EndDate = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    Rooms = table.Column<int>(type: "INTEGER", nullable: false),
                    AllotmentType = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    IsOverAllotment = table.Column<bool>(type: "INTEGER", nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
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
