using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Zayed.Infrastructure.Persistence;

#nullable disable

namespace Zayed.SqlServerMigrations.Migrations
{
    [DbContext(typeof(ZayedDbContext))]
    [Migration("20260610210001_AddHotelReservationsSqlServer")]
    public partial class AddHotelReservationsSqlServer : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "hotel_reservations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ReservationNumber = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: false),
                    ContractId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    HotelId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AgentId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    RoomTypeId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MealPlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    GuestName = table.Column<string>(type: "nvarchar(180)", maxLength: 180, nullable: false),
                    GuestPhone = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: true),
                    CheckIn = table.Column<DateOnly>(type: "date", nullable: false),
                    CheckOut = table.Column<DateOnly>(type: "date", nullable: false),
                    Rooms = table.Column<int>(type: "int", nullable: false),
                    Adults = table.Column<int>(type: "int", nullable: false),
                    Children = table.Column<int>(type: "int", nullable: false),
                    NightlyRate = table.Column<decimal>(type: "decimal(18,4)", precision: 18, scale: 4, nullable: false),
                    TotalAmount = table.Column<decimal>(type: "decimal(18,4)", precision: 18, scale: 4, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_reservations", x => x.Id));

            migrationBuilder.CreateIndex(name: "IX_hotel_reservations_CompanyId", table: "hotel_reservations", column: "CompanyId");
            migrationBuilder.CreateIndex(name: "IX_hotel_reservations_CompanyId_CheckIn_CheckOut", table: "hotel_reservations", columns: new[] { "CompanyId", "CheckIn", "CheckOut" });
            migrationBuilder.CreateIndex(name: "IX_hotel_reservations_CompanyId_ContractId", table: "hotel_reservations", columns: new[] { "CompanyId", "ContractId" });
            migrationBuilder.CreateIndex(name: "IX_hotel_reservations_CompanyId_ReservationNumber", table: "hotel_reservations", columns: new[] { "CompanyId", "ReservationNumber" }, unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "hotel_reservations");
        }
    }
}
