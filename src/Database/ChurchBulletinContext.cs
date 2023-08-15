using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace ProgrammingWithPalermo.ChurchBulletin.Database;

public partial class ChurchBulletinContext : DbContext
{
    public ChurchBulletinContext()
    {
    }

    public ChurchBulletinContext(DbContextOptions<ChurchBulletinContext> options)
        : base(options)
    {
    }

    public virtual DbSet<ChurchBulletinItem> ChurchBulletinItems { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see http://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=(localdb)\\MSSQLLocalDB;Database=ChurchBulletin;Trusted_Connection=True");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ChurchBulletinItem>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__ChurchBu__3214EC07EC8F1F16");

            entity.ToTable("ChurchBulletinItem");

            entity.Property(e => e.Id).ValueGeneratedNever();
            entity.Property(e => e.Name).HasMaxLength(50);
            entity.Property(e => e.Place).HasMaxLength(50);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
