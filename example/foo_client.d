#!/usr/bin/env dub
/+ dub.json:
{
  "dflags": ["-J=."],
  "dependencies": {
     "pbd": {"path": ".."}
  }
}
+/

// NOTE: run `python3 foo_server.py` before this script.
import std.socket;
import std.stdio;
    
import pbd;


mixin(ProtoToD!"foo.proto");

void main()
{
  auto socket = new TcpSocket(
      new InternetAddress("localhost", 6000));
  ubyte[1024] buffer;
  auto size = socket.receive(buffer);
  Foo decoded = buffer[0 .. size].decode!Foo;

  writeln(decoded);
  assert(decoded == Foo(1, -1));
}
