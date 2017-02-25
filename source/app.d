import consoled;
import std.algorithm.iteration;
import std.datetime;
import std.array;
import std.process;
import std.range;
import std.stdio;

public struct Unit {

  public struct Scale {
    string name;
    long factor;
  }

  public struct Part {
    string name;
    long v;
    string toString() {
      import std.conv;
      return v.to!(string) ~ name;
    }
  }

  private string name;
  private Scale[] scales;

  public this(string name, Scale[] scales) {
    this.name = name;
    this.scales = cumulativeFold!((result,x) => Scale(x.name, result.factor * x.factor))(scales).array.retro.array;
  }

  public Part[] transform(long v) immutable {
    auto res = appender!(Part[]);
    auto tmp = v;
    foreach (Scale scale; scales) {
      auto h = tmp / scale.factor;
      tmp = v % scale.factor;
      if (h != 0) {
        res.put(Part(scale.name, h));
      }
    }
    return res.data;
  }
}

unittest {
  static immutable time = Unit("time", [Unit.Scale("ms", 1), Unit.Scale("s", 1000), Unit.Scale("m", 60), Unit.Scale("h", 60), Unit.Scale("d", 24)]);

  auto res = time.transform(1 + 2*1000 + 3*1000*60 + 4*1000*60*60 + 5 * 1000*60*60*24);
  assert(res.length == 5);

  assert(res[0].name == "d");
  assert(res[0].v == 5);

  assert(res[1].name == "h");
  assert(res[1].v == 4);

  assert(res[2].name == "m");
  assert(res[2].v == 3);

  assert(res[3].name == "s");
  assert(res[3].v == 2);

  assert(res[4].name == "ms");
  assert(res[4].v == 1);


  res = time.transform(2001);
  assert(res.length == 2);

  assert(res[0].name == "s");
  assert(res[0].v == 2);

  assert(res[1].name == "ms");
  assert(res[1].v == 1);
}


int main(string[] args) {
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

  writecln(exitCode == 0 ? Fg.green : Fg.red, childCommand, Fg.initial, " took ", time.transform(d).map!((a) => a.toString).join(" "));
  return exitCode;
}
