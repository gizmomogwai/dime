import std.stdio;
import std.process;
import std.datetime;
import consoled;

int main(string[] args) {
  if (args.length < 2) {
    return 1;
  }
  auto childCommand = args[1..$];
  auto cmd = escapeShellCommand(childCommand);
  auto sw = StopWatch(AutoStart.yes);
  auto pid = spawnShell(cmd);
  auto exitCode = pid.wait();
  TickDuration duration = sw.peek();
  writecln(exitCode == 0 ? Fg.green : Fg.red, args[1], Fg.initial, " took ", duration.to!("msecs", long), "ms");
  return exitCode;
}
