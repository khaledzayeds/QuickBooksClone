using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Zayed.Infrastructure.Persistence.Migrations
{
    [DbContext(typeof(ZayedDbContext))]
    [Migration("20260610170000_AddHotelMasterData")]
    public partial class AddHotelMasterData : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "hotel_properties",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 180, nullable: false),
                    Country = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    City = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    Address = table.Column<string>(type: "TEXT", maxLength: 250, nullable: true),
                    Phone = table.Column<string>(type: "TEXT", maxLength: 60, nullable: true),
                    Email = table.Column<string>(type: "TEXT", maxLength: 150, nullable: true),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_properties", x => x.Id));

            migrationBuilder.CreateTable(
                name: "hotel_room_types",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Code = table.Column<string>(type: "TEXT", maxLength: 30, nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 120, nullable: false),
                    Capacity = table.Column<int>(type: "INTEGER", nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 300, nullable: true),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_room_types", x => x.Id));

            migrationBuilder.CreateTable(
                name: "hotel_meal_plans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Code = table.Column<string>(type: "TEXT", maxLength: 30, nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 120, nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 300, nullable: true),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_meal_plans", x => x.Id));

            migrationBuilder.CreateTable(
                name: "hotel_agents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 180, nullable: false),
                    ContactName = table.Column<string>(type: "TEXT", maxLength: 120, nullable: true),
                    Email = table.Column<string>(type: "TEXT", maxLength: 150, nullable: true),
                    Phone = table.Column<string>(type: "TEXT", maxLength: 60, nullable: true),
                    Currency = table.Column<string>(type: "TEXT", maxLength: 3, nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_agents", x => x.Id));

            migrationBuilder.CreateIndex(name: "IX_hotel_properties_CompanyId", table: "hotel_properties", column: "CompanyId");
            migrationBuilder.CreateIndex(name: "IX_hotel_properties_CompanyId_Name", table: "hotel_properties", columns: new[] { "CompanyId", "Name" }, unique: true);
            migrationBuilder.CreateIndex(name: "IX_hotel_room_types_CompanyId", table: "hotel_room_types", column: "CompanyId");
            migrationBuilder.CreateIndex(name: "IX_hotel_room_types_CompanyId_Code", table: "hotel_room_types", columns: new[] { "CompanyId", "Code" }, unique: true);
            migrationBuilder.CreateIndex(name: "IX_hotel_meal_plans_CompanyId", table: "hotel_meal_plans", column: "CompanyId");
            migrationBuilder.CreateIndex(name: "IX_hotel_meal_plans_CompanyId_Code", table: "hotel_meal_plans", columns: new[] { "CompanyId", "Code" }, unique: true);
            migrationBuilder.CreateIndex(name: "IX_hotel_agents_CompanyId", table: "hotel_agents", column: "CompanyId");
            migrationBuilder.CreateIndex(name: "IX_hotel_agents_CompanyId_Name", table: "hotel_agents", columns: new[] { "CompanyId", "Name" }, unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "hotel_agents");
            migrationBuilder.DropTable(name: "hotel_meal_plans");
            migrationBuilder.DropTable(name: "hotel_room_types");
            migrationBuilder.DropTable(name: "hotel_properties");
        }
    }
}
