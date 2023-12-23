/++
 + Print human readable units (e.g. time in days, hours, minutes or distance in km, m, cm, mm).
 +/
module unit;

import std.algorithm : cumulativeFold, find, min, map;
import std.array : array, appender, join;
import std.ascii : isAlpha, isDigit;
import std.conv : to;
import std.exception : enforce;
import std.range : empty, front, popFront, retro;
import std.typecons : tuple;

version (unittest)
{
    import unit_threaded;
}

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
        void toString(Sink, Format)(Sink sink, Format format) const
        {
            sink(value.to!string);
            sink(name);
        }
    }

    /// name of the unit
    private string name;
    /// resolutions of the unit
    private Scale[] scales;

    public this(string name, Scale[] scales)
    {
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

    private static auto parseNumberAndUnit(string s)
    {
        string value;
        while (!s.empty)
        {
            auto n = s.front;
            if (n == ' ')
            {
                s.popFront;
                continue;
            }
            if (isDigit(n))
            {
                value ~= n;
                s.popFront;
            }
            else
            {
                break;
            }
        }
        string name;
        while (!s.empty)
        {
            auto n = s.front;
            if (n == ' ')
            {
                s.popFront;
                continue;
            }
            if (isAlpha(n))
            {
                name ~= n;
                s.popFront;
            }
            else
            {
                break;
            }
        }

        auto rest = s;
        if ((name.length > 0) && (value.length > 0))
        {
            return tuple!("found", "name", "value", "rest")(true, name, value, rest);
        }
        else
        {
            return tuple!("found", "name", "value", "rest")(false, "", "", "");
        }
    }

    long parse(string s) immutable
    {
        long res = 0;
        auto next = parseNumberAndUnit(s);
        while (next.found)
        {
            auto scale = scales.find!(i => i.name == next.name);
            if (scale.empty)
            {
                throw new Exception("unknown unit " ~ next.name);
            }
            res += next.value.to!long * scale.front.factor;
            next = parseNumberAndUnit(next.rest);
        }
        return res;
    }
}

@("parse") unittest
{
    TIME.parse("1s 2ms").should == 1002;
    TIME.parse(" 1s 2ms").should == 1002;
    TIME.parse("1s2ms").should == 1002;
    TIME.parse("1blub2ms").shouldThrow;
}

@("creatingScales") unittest
{
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
    return parts[0 .. min(parts.length, nr)];
}

/++
 + example for a time unit definition
 +/
@("basicUsage") unittest
{
    auto res = TIME.transform(1 + 2 * 1000 + 3 * 1000 * 60 + 4 * 1000 * 60 * 60
            + 5 * 1000 * 60 * 60 * 24);
    res.length.should == 5;
    res[0].name.should == "d";
    res[0].value.should == 5;
    res[1].name.should == "h";
    res[1].value.should == 4;
    res[2].name.should == "m";
    res[2].value.should == 3;
    res[3].name.should == "s";
    res[3].value.should == 2;
    res[4].name.should == "ms";
    res[4].value.should == 1;

    res.map!("a.to!string").array.join(" ").should == "5d 4h 3m 2s 1ms";

    res = TIME.transform(2001).onlyRelevant;
    res.length.should == 2;
    res[0].name.should == "s";
    res[0].value.should == 2;
    res[1].name.should == "ms";
    res[1].value.should == 1;

    res = TIME.transform(2001).onlyRelevant.mostSignificant(1);
    res.length.should == 1;
    res[0].name.should == "s";
    res[0].value.should == 2;
}

// dfmt off
static immutable TIME =
    Unit("time",
         [Unit.Scale("ms", 1),
          Unit.Scale("s", 1000),
          Unit.Scale("m", 60),
          Unit.Scale("h", 60),
          Unit.Scale("d", 24)]);
// dfmt on
