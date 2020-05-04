/// Code generation module.
module dpb.codegen;

import std.meta : AliasSeq;

import pegged.grammar : ParseTree;


/// string dict converts Proto types to D types
/// See also: https://developers.google.com/protocol-buffers/docs/proto#scalar
enum Proto2D = [
    "double": "double",
    "float": "float",
    "int32": "int",
    "int64": "long",
    "uint32": "uint",
    "uint64": "ulong",
    "sint32": "int",
    "sint64": "long",
    "fixed32": "uint",
    "fixed64": "ulong",
    "sfixed32": "int",
    "sfixed64": "long",
    "bool": "bool",
    "string": "string",
    "bytes": "byte[]",
];

struct ProtoTag
{
  /// Tag number for encoding/decoding
  int tag;
}

/// Returns tag of a given member or 0 if not found.
int protoTagOf(T, string member)()
{
  alias m = __traits(getMember, T, member);
  foreach (attr; __traits(getAttributes, m))
  {
    static if (is(typeof(attr) == ProtoTag))
    {
      return attr.tag;
    }
  }
  assert(false, "@ProtoTag not found: " ~ T.stringof ~ "." ~ member);
}

/// Returns a tagged member name corresponding to a given tag.
string protoMemberOf(T)(int tag)
{
  foreach (name; __traits(allMembers, T))
  {
    alias m = __traits(getMember, T, name);
    foreach (attr; __traits(getAttributes, m))
    {
      static if (is(typeof(attr) == ProtoTag))
      {
        if (attr.tag == tag)
        {
          return name;
        }
      }
    }
  }
  assert(false, "@ProtoTag not found.");
}

///
unittest
{
  struct Test
  {
    @ProtoTag(2)
    int i;
    @ProtoTag(1)
    int j;
  }

  static assert(protoTagOf!(Test, "i") == 2);
  static assert(protoMemberOf!Test(2) == "i");
}
/// Generates D code from Protobuf IDL ParseTree (Proto result).
string toD(ParseTree p)
{
  return "";
}

///
unittest
{
  import dpb.parse : Proto;

  enum exampleProto = `
syntax = "proto3";

package tensorflow;

message Foo {
  int32 aa = 1;
  int32 bb = 2;
}
`;

  struct ExpectedFoo {
    int aa;
  }

  enum code = Proto(exampleProto).toD;

  import std.stdio;
  writeln("generated:\n", code);
}
