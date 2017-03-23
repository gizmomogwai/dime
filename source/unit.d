public struct Unit {
  import std.algorithm.iteration;
  import std.range;

  public struct Scale {
    string name;
    long factor;
    int digits;
  }

  public struct Part {
    string name;
    long value;
    int digits;
    string toString() {
      import std.conv;
      return value.to!(string) ~ name;
    }
  }

  private string name;
  private Scale[] scales;

  public this(string name, Scale[] scales) {
    import std.exception;
    this.name = name;
    this.scales = cumulativeFold!((result,x) => Scale(x.name, result.factor * x.factor, x.digits))(scales).array.retro.array;
    enforce(__ctfe);
  }

  public Part[] transform(long v) immutable {
    import std.array;

    auto res = appender!(Part[]);
    auto tmp = v;
    foreach (Scale scale; scales) {
      auto h = tmp / scale.factor;
      tmp = v % scale.factor;
      res.put(Part(scale.name, h, scale.digits));
    }
    return res.data;
  }
}

/++
 + get only relevant parts of an part array.
 + relevant means all details starting from the first
 + non 0 part.
 +/
Unit.Part[] onlyRelevant(Unit.Part[] parts) {
  import std.array;
  auto res = appender!(Unit.Part[]);
  bool needed = false;
  foreach (part; parts) {
    if (needed || (part.value > 0)) {
      needed = true;
    }
    if (needed) {
      res.put(part);
    }
  }
  return res.data;
}

/++
 + get the first nr of parts (or less if not enough parts are available.
 +/
Unit.Part[] mostSignificant(Unit.Part[] parts, long nr) {
  import std.algorithm.comparison;
  auto max = min(parts.length, nr);
  return parts[0..max];
}

unittest {
  import unit_threaded;

  static immutable time = Unit("time", [Unit.Scale("ms", 1), Unit.Scale("s", 1000), Unit.Scale("m", 60), Unit.Scale("h", 60), Unit.Scale("d", 24)]);

  auto res = time.transform(1 + 2*1000 + 3*1000*60 + 4*1000*60*60 + 5 * 1000*60*60*24);
  res.length.shouldEqual(5);
  res[0].name.shouldEqual("d");
  res[0].value.shouldEqual(5);
  res[1].name.shouldEqual("h");
  res[1].value.shouldEqual(4);
  res[2].name.shouldEqual("m");
  res[2].value.shouldEqual(3);
  res[3].name.shouldEqual("s");
  res[3].value.shouldEqual(2);
  res[4].name.shouldEqual("ms");
  res[4].value.shouldEqual(1);

  res = time.transform(2001).onlyRelevant;
  res.length.shouldEqual(2);
  res[0].name.shouldEqual("s");
  res[0].value.shouldEqual(2);
  res[1].name.shouldEqual("ms");
  res[1].value.shouldEqual(1);

  res = time.transform(2001).onlyRelevant.mostSignificant(1);
  res.length.shouldEqual(1);
  res[0].name.shouldEqual("s");
  res[0].value.shouldEqual(2);
}
