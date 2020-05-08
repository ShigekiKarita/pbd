#!/usr/bin/env dub
/+ dub.json:
{
  "dflags": ["-J=."],
  "dependencies": {
     "pbd": {"path": ".."}
  }
}
+/

import std.stdio;
    
import pbd;


mixin(ProtoToD!"foo.proto");

void main()
{
  auto foo = Foo(1, 2);
  writeln(foo);
}
