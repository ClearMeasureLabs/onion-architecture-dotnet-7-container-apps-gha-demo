using System;
using System.Collections.Generic;

namespace ProgrammingWithPalermo.ChurchBulletin.Database;

public partial class ChurchBulletinItem
{
    public Guid Id { get; set; }

    public string? Name { get; set; }

    public string? Place { get; set; }

    public DateTime? Date { get; set; }
}
