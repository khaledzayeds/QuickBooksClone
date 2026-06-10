using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Zayed.Infrastructure.Persistence.Migrations
{
    [DbContext(typeof(ZayedDbContext))]
    [Migration("20260610210000_AddHotelReservations")]
    public partial class AddHotelReservations : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "hotel_reservations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    ReservationNumber = table.Column<string>(type: "TEXT", maxLength: 60, nullable: false),
                    ContractId = table.Column<Guid>(type: "TEXT", nullable: false),
                    HotelId = table.Column<Guid>(type: "TEXT", nullable: false),
                    AgentId = table.Column<Guid>(type: "TEXT", nullable: true),
                    RoomTypeId = table.Column<Guid>(type: "TEXT", nullable: false),
                    MealPlanId = table.Column<Guid>(type: "TEXT", nullable: false),
                    GuestName = table.Column<string>(type: "TEXT", maxLength: 180, nullable: false),
                    GuestPhone = table.Column<string>(type: "TEXT", maxLength: 60, nullable: true),
                    CheckIn = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    CheckOut = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    Rooms = table.Column<int>(type: "INTEGER", nullable: false),
                    Adults = table.Column<int>(type: "INTEGER", nullable: false),
                    Children = table.Column<int>(type: "INTEGER", nullable: false),
                    NightlyRate = table.Column<decimal>(type: "TEXT", precision: 18, scale: 4, nullable: false),
                    TotalAmount = table.Column<decimal>(type: "TEXT", precision: 18, scale: 4, nullable: false),
                    Status = table.Column<string>(type: "TEXT", maxLength: 30, nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
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
