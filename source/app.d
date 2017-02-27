version(unittest) { import unit_threaded; }

public struct Unit {
  import std.algorithm.iteration;
  import std.range;

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
    import std.array;

    auto res = appender!(Part[]);
    auto tmp = v;
    foreach (Scale scale; scales) {
      auto h = tmp / scale.factor;
      tmp = v % scale.factor;
      res.put(Part(scale.name, h));
    }
    return res.data;
  }
}

Unit.Part[] onlyRelevant(Unit.Part[] parts) {
  import std.array;
  auto res = appender!(Unit.Part[]);
  bool needed = false;
  foreach (part; parts) {
    if (needed || (part.v > 0)) {
      needed = true;
    }
    if (needed) {
      res.put(part);
    }
  }
  return res.data;
}

Unit.Part[] mostSignificant(Unit.Part[] parts, long nr) {
  import std.algorithm.comparison;
  auto max = min(parts.length, nr);
  return parts[0..max];
}

unittest {
  static immutable time = Unit("time", [Unit.Scale("ms", 1), Unit.Scale("s", 1000), Unit.Scale("m", 60), Unit.Scale("h", 60), Unit.Scale("d", 24)]);

  auto res = time.transform(1 + 2*1000 + 3*1000*60 + 4*1000*60*60 + 5 * 1000*60*60*24);
  res.length.shouldEqual(5);
  res[0].name.shouldEqual("d");
  res[0].v.shouldEqual(5);
  res[1].name.shouldEqual("h");
  res[1].v.shouldEqual(4);
  res[2].name.shouldEqual("m");
  res[2].v.shouldEqual(3);
  res[3].name.shouldEqual("s");
  res[3].v.shouldEqual(2);
  res[4].name.shouldEqual("ms");
  res[4].v.shouldEqual(1);

  res = time.transform(2001).onlyRelevant;
  res.length.shouldEqual(2);
  res[0].name.shouldEqual("s");
  res[0].v.shouldEqual(2);
  res[1].name.shouldEqual("ms");
  res[1].v.shouldEqual(1);

  res = time.transform(2001).onlyRelevant.mostSignificant(1);
  res.length.shouldEqual(1);
  res[0].name.shouldEqual("s");
  res[0].v.shouldEqual(2);
}

version (unittest) {
} else {
  int main(string[] args) {
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
}