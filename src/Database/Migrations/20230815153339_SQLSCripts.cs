using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ProgrammingWithPalermo.ChurchBulletin.Database.Migrations
{
    /// <inheritdoc />
    public partial class SQLSCripts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            var sqlFiles = Directory.GetFiles(@"scripts\Update", "*.sql");
                foreach (var file in sqlFiles)
                {
                    var script = File.ReadAllText(file);
                    migrationBuilder.Sql(script);
                }
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
