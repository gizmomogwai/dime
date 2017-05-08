module colors;

import std.conv;
import std.string : toUpper;
import std.traits;

enum AnsiColors {
  black = 30,
  red = 31,
  green = 32,
  yellow = 33,
  blue = 34,
  magenta = 35,
  cyan = 36,
  white = 37
}

string asMixin(T)() {
  import std.string;
  string res = "";
  foreach (immutable ansiColor; [EnumMembers!T]) {
    res ~= "string %s(string s) { return \"\\033[%dm\" ~ s ~ \"\\033[0m\";}\n".format(ansiColor, ansiColor);
    immutable n = ansiColor.to!string;
    immutable name = n[0..1].toUpper ~ n[1..$];
    res ~= "string bg%s(string s) { return \"\\033[%dm\" ~ s ~ \"\\033[0m\";}\n".format(name, ansiColor+10);
  }
  return res;
}

unittest {
  import unit_threaded;
  enum TTT {
    r = 1
  }
  asMixin!TTT.shouldEqual(
`string r(string s) { return "\033[1m" ~ s ~ "\033[0m";}
string bgR(string s) { return "\033[11m" ~ s ~ "\033[0m";}
`);
}

mixin(asMixin!AnsiColors);
