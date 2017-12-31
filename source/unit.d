/++
 + Print human readable units (e.g. time in days, hours, minutes or distance in km, m, cm, mm).
 +/
module unit;

/++
 + A unit allows to easily print mixed resolution values.
 + Typical examples include time (with hours, minutes, ...)
 + and distances (with km, m, cm, mm).
 + The unitclass simplifies definition of such things as well
 + as transforming a high resolution value, to a supposedly
 + more human readable representation.
 + e.g. 3_610_123 would convert to 1h 0m 10s 123ms.
 +/
public struct Unit
{
    import std.algorithm.iteration;
    import std.range;

    /++
     + A scale is one resolution of a unit.
     +/
    public struct Scale
    {
        /// the name of the scale (e.g. h for hour)
        string name;

        /++ factor to the next higher resolution (e.g. 60 from minutes to seconds) +/
        long factor;

        /++ normal renderwidth for the application (e.g. 2 for minutes (00-59)) +/
        int digits;
    }

    /++ factory for Scale
     + Params:
     + name = unitname
     + factor = factor to the next bigger unit
     + digits = padding digits
     +/
    static auto scale(string name, long factor, int digits = 1)
    {
        return Scale(name, factor, digits);
    }

    /++
   + One part of the transformed Unit.
   + a part of a unit is e.g. the minute resolution of a duration.
   +/
    public struct Part
    {
        /// name of the part
        string name;
        /// value of the part
        long value;
        /// number of digits
        int digits;
        /// convenient tostring function. e.g. 10min
        auto toString()
        {
            import std.conv;

            return value.to!(string) ~ name;
        }
    }

    /// name of the unit
    private string name;
    /// resolutions of the unit
    private Scale[] scales;

    public this(string name, Scale[] scales)
    {
        import std.exception;

        this.name = name;
        this.scales = cumulativeFold!((result, x) => scale(x.name,
                result.factor * x.factor, x.digits))(scales).array.retro.array;
        enforce(__ctfe);
    }

    /++
     + transforms the unit to its parts
     +/
    public auto transform(long v) immutable
    {
        import std.array;

        auto res = appender!(Part[]);
        auto tmp = v;
        foreach (Scale scale; scales)
        {
            auto h = tmp / scale.factor;
            tmp = v % scale.factor;
            res.put(Part(scale.name, h, scale.digits));
        }
        return res.data;
    }
}

@("creatingScales") unittest
{
    import unit_threaded;

    auto s = Unit.scale("ttt", 1, 2);
    s.digits.shouldEqual(2);

    s = Unit.scale("ttt2", 1);
    s.digits.shouldEqual(1);
}

/++
 + get only relevant parts of an part array.
 + relevant means all details starting from the first
 + non 0 part.
 +/
auto onlyRelevant(Unit.Part[] parts)
{
    import std.array;

    auto res = appender!(Unit.Part[]);
    bool needed = false;
    foreach (part; parts)
    {
        if (needed || (part.value > 0))
        {
            needed = true;
        }
        if (needed)
        {
            res.put(part);
        }
    }
    return res.data;
}

/++
 + get the first nr of parts (or less if not enough parts are available).
 +/
auto mostSignificant(Unit.Part[] parts, long nr)
{
    import std.algorithm.comparison;

    auto max = min(parts.length, nr);
    return parts[0 .. max];
}

/++
 + example for a time unit definition
 +/
@("basicUsage") unittest
{
    import unit_threaded;

    static immutable time = Unit("time", [Unit.Scale("ms", 1), Unit.Scale("s",
            1000), Unit.Scale("m", 60), Unit.Scale("h", 60), Unit.Scale("d", 24)]);

    auto res = time.transform(1 + 2 * 1000 + 3 * 1000 * 60 + 4 * 1000 * 60 * 60
            + 5 * 1000 * 60 * 60 * 24);
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
