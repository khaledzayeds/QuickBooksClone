using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Zayed.Infrastructure.Persistence;

#nullable disable

namespace Zayed.SqlServerMigrations.Migrations
{
    [DbContext(typeof(ZayedDbContext))]
    [Migration("20260610170001_AddHotelMasterDataSqlServer")]
    public partial class AddHotelMasterDataSqlServer : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "hotel_properties",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(180)", maxLength: 180, nullable: false),
                    Country = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    City = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    Address = table.Column<string>(type: "nvarchar(250)", maxLength: 250, nullable: true),
                    Phone = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: true),
                    Email = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_properties", x => x.Id));

            migrationBuilder.CreateTable(
                name: "hotel_room_types",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Code = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    Capacity = table.Column<int>(type: "int", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_room_types", x => x.Id));

            migrationBuilder.CreateTable(
                name: "hotel_meal_plans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Code = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_hotel_meal_plans", x => x.Id));

            migrationBuilder.CreateTable(
                name: "hotel_agents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(180)", maxLength: 180, nullable: false),
                    ContactName = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: true),
                    Email = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: true),
                    Phone = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: true),
                    Currency = table.Column<string>(type: "nvarchar(3)", maxLength: 3, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
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
