/++
 + main unit of dime.
 +/
module dime;

/**
 * measure the time for calling args
 * Params:
 * args = shell command
 */
int dime(string[] args)
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

    if (args.length < 2)
    {
        return 1;
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
                         .onlyRelevant.map!((part) => ("%0" ~ part.digits.to!string ~ "d %s")
                         .format(part.value, part.name))
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
