/++
 + main unit of dime.
 +/
module dime;

public import dime.packageversion;

/**
 * measure the time for calling args
 * Params:
 * args = shell command
 */
int dime_(string[] args)
{
    import unit;
    import colored;
    import std.array;
    import std.datetime.stopwatch;
    import std.datetime;
    import std.process;
    import std.algorithm.iteration;
    import std.string;
    import std.conv;
    import std.stdio;
    import std.getopt;

    auto help = getopt(args);
    if (help.helpWanted)
    {
        defaultGetoptPrinter("D(t)ime your programs.", help.options);
        import packageversion;
        import std.algorithm : sort;
        import asciitable;

        // dfmt off
        auto table = packageversion
            .getPackages.sort!("a.name < b. name")
            .fold!((table, p) => table.add(p.name, p.semVer, p.license))(AsciiTable(0, 0, 0));
        // dfmt on
        writeln("Packages:\n", table.toString("   ", " "));
        return 0;
    }

    auto childCommand = args[1 .. $];
    auto cmd = escapeShellCommand(childCommand);
    auto sw = std.datetime.stopwatch.StopWatch(AutoStart.yes);
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

@("formatWithWidth") unittest
{
    import unit_threaded;
    import std.string;

    "%03d".format(1).shouldEqual("001");
    "%01d".format(1).shouldEqual("1");
}
