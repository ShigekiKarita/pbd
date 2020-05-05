/// Code generation module.
module pbd.codegen;

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
  int tag = 0;
}

/// Returns tag of a given member or 0 if not found.
int protoTagOf(T, string member)()
{
  import std.traits : getUDAs;
  enum udas = getUDAs!(__traits(getMember, T, member), ProtoTag);
  static assert(udas.length == 1);
  return udas[0].tag;
}

struct ZigZag {};

/// Returns true if member is zigzag encoded.
bool isZigZag(T, string member)()
{
  import std.traits : hasUDA;
  return hasUDA!(__traits(getMember, T, member), ZigZag);
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
    @ZigZag
    @ProtoTag(1)
    int j;
  }

  static assert(protoTagOf!(Test, "i") == 2);
  static assert(!isZigZag!(Test, "i"));
  static assert(protoMemberOf!Test(2) == "i");
  static assert(isZigZag!(Test, "j"));
}

/// Generates D code from Protobuf IDL ParseTree (Proto result).
string toD(ParseTree p)
{
  return "";
}

///
unittest
{
  import pbd.parse : Proto;

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


/// Custom array type for pb decoding
struct ProtoArray(T)
{
  import std.container.array : Array;

  Array!T base;
  alias base this;

  /// Converts to string for debugging
  string toString() const
  {
    import std.conv : text;
    return this.base[].text;
  }

  static if (is(T == char))
  {
    /// Constructs from string
    this(string rhs)
    {
      this.base.clear();
      this.base.reserve(rhs.length);
      foreach (x; rhs)
      {
        this.base.insertBack(x);
      }
    }

    /// Compares to non-string types
    bool opEquals(Rhs)(auto ref Rhs rhs)
    {
      return this.base == rhs;
    }

    /// Compares to string
    @nogc nothrow pure bool opEquals(Rhs : string)(Rhs rhs)
    {
      // if (this.length != rhs.length) return false;
      // foreach (i; 0 .. this.base.length)
      // {
      //   if (this.base[i] != rhs[i]) return false;
      // }
      // return true;
      return (&this[0])[0 .. this.length] == rhs;
    }
  }
}

alias pstring = ProtoArray!char;

@nogc nothrow pure
unittest
{
    pstring cs = "abc";
    assert(cs == "abc");
}
