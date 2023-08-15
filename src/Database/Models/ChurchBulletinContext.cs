using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace ProgrammingWithPalermo.ChurchBulletin.Database.Models;

public partial class ChurchBulletinContext : DbContext
{
    public ChurchBulletinContext()
    {
    }

    public ChurchBulletinContext(DbContextOptions<ChurchBulletinContext> options)
        : base(options)
    {
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseSqlServer("Server=(localdb)\\MSSQLLocalDB;Database=ChurchBulletin;Trusted_Connection=True;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
