int main(string[] args)
{
    import asciitable : AsciiTable;
    import colored : black, bold, green, lightGray, onRed, white;
    import packageinfo : packages;
    import std.algorithm : fold, map, sort;
    import std.array : join;
    import std.conv : to;
    import std.datetime.stopwatch : AutoStart, StopWatch;
    import std.getopt : defaultGetoptPrinter, getopt;
    import std.process : escapeShellCommand, spawnShell, wait;
    import std.stdio : stderr;
    import std.string : format;
    import unit : onlyRelevant, TIME;

    auto help = getopt(args);
    if (help.helpWanted)
    {
        defaultGetoptPrinter("D(t)ime your programs.", help.options);

        // dfmt off
        auto table = packages
            .sort!("a.name < b.name")
            .fold!((table, p) => table.row.add(p.name.white).add(p.semVer.lightGray).add(p.license.lightGray).table)
            (new AsciiTable(3).header.add("Package".bold).add("Version".bold).add("License".bold).table);
        // dfmt on
        stderr.writeln("Packageinfo:\n", table.format.prefix("  | ")
                .headerSeparator(true).columnSeparator(true).to!string);
        return 0;
    }

    auto childCommand = args[1 .. $];
    auto cmd = escapeShellCommand(childCommand);
    auto sw = StopWatch(AutoStart.yes);
    auto pid = spawnShell(cmd);
    auto exitCode = pid.wait();
    auto duration = sw.peek();
    auto d = duration.total!("msecs");
    auto s = childCommand.to!string;
    // dfmt off
    stderr.writeln("%s took %s".format(
                     exitCode == 0 ? s.green.to!string : s.black.onRed.to!string,
                     TIME
                         .transform(d)
                         .onlyRelevant.map!((part) =>
                                            ("%0" ~ part.digits.to!string ~ "d %s").format(part.value, part.name))
                     .join(" ")));
    // dfmt on
    return exitCode;
}
