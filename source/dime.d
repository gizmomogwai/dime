module dime;
import unit;

int dime(string[] args) {
  import consoled;
  import std.array;
  import std.datetime;
  import std.process;
  import std.algorithm.iteration;

  if (args.length < 2) {
    return 1;
  }

  static immutable time =
    Unit("time", [
           Unit.Scale("ms", 1),
           Unit.Scale("s", 1000),
           Unit.Scale("m", 60),
           Unit.Scale("h", 60)
         ]);

  auto childCommand = args[1..$];
  auto cmd = escapeShellCommand(childCommand);
  auto sw = StopWatch(AutoStart.yes);
  auto pid = spawnShell(cmd);
  auto exitCode = pid.wait();
  TickDuration duration = sw.peek();
  auto d = duration.to!("msecs", long);

  writecln(exitCode == 0 ? Fg.green : Fg.red, childCommand, Fg.initial, " took ", time
           .transform(d)
           .onlyRelevant
           .map!((a) => a.toString)
           .join(" "));
  return exitCode;
}