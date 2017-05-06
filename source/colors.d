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
/*
struct AnsiColor {
  int value;
  string color;
}

immutable AnsiColor[] ansiColors = [
  AnsiColor(30, "black"),
  AnsiColor(31, "red"),
  AnsiColor(32, "green"),
  AnsiColor(33, "yellow"),
  AnsiColor(34, "blue"),
  AnsiColor(35, "magenta"),
  AnsiColor(36, "cyan"),
  AnsiColor(37, "white"),
];

string asMixin() {
  string res = "";
  foreach (c; ansiColors) {
    res ~= "string " ~ c.color ~ "(string s) { return \"\\033[" ~ c.value.to!string ~ "m\" ~ s ~ \"\\033[0m\";}\n";
    res ~= "string bg" ~ c.color[0..1].toUpper ~ c.color[1..$] ~ "(string s) { return \"\\033[" ~ (c.value+10).to!string ~ "m\" ~ s ~ \"\\033[0m\";}\n";
  }
  return res;
}
*/
string asMixin() {
  string res = "";
  foreach (immutable ansiColor; [EnumMembers!AnsiColors]) {
    {
      immutable name = ansiColor.to!string;
      immutable value = ansiColor.to!int.to!string;
      res ~= "string " ~ name ~ "(string s) { return \"\\033[" ~ value ~ "m\" ~ s ~ \"\\033[0m\";}\n";
    }
    {
      immutable n = ansiColor.to!string;
      immutable name = "bg" ~ n[0..1].toUpper ~ n[1..$];
      immutable value = (ansiColor.to!int + 10).to!string;
      res ~= "string " ~ name ~ "(string s) { return \"\\033[" ~ value ~ "m\" ~ s ~ \"\\033[0m\";}\n";
    }
  }
  return res;
}
mixin(asMixin());
