/// Code generation module.
module pbd.codegen;

import std.meta : AliasSeq;

import pegged.grammar : ParseTree;


/// string dict converts Proto types to D types
/// See also: https://developers.google.com/protocol-buffers/docs/proto#scalar
enum Proto2DTypes = [
    "double": "double",
    "float": "float",
    "int32": "int",
    "int64": "long",
    "uint32": "uint",
    "uint64": "ulong",
    "sint32": "@ZigZag int",
    "sint64": "@ZigZag long",
    "fixed32": "uint",
    "fixed64": "ulong",
    "sfixed32": "int",
    "sfixed64": "long",
    "bool": "bool",
    "string": "ProtoArray!char",
    "bytes": "ProtoArray!byte",
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
struct Unpacked {};

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
version (pbd_test)
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
string toD(ParseTree p, int numIndent = 0, string indent = "  ")
{
  import std.range : repeat, join;

  auto spaces = indent.repeat(numIndent).join;
  switch (p.name)
  {
    case "Proto":
      assert(p.children.length == 1, "Proto should have only one child.");
      return "import pbd.codegen;\n" ~ toD(p.children[0], numIndent, indent);
    case "Proto.Root":
      string code;
      foreach (child; p.children)
      {
        code ~= toD(child, numIndent, indent);
      }
      return code;
    case "Proto.Syntax":
      assert(p.matches[0] == "proto3", `only syntax = "proto3" is supported.`);
      return "";
    case "Proto.Package":
      // TODO(karita): support package?
      return "";
    case "Proto.Option":
      // TODO(karita): support option?
      return "";
    case "Proto.Message":
      string code = spaces ~ "struct " ~ p.matches[0] ~ " {\n";
      foreach (child; p.children)
      {
        code ~= toD(child, numIndent + 1, indent);
      }
      code ~= spaces ~ "}\n";
      return code;
    case "Proto.SingleField":
      // e.g., int32 a = 1;
      auto type = Proto2DTypes[p.matches[0]];
      auto name = p.matches[1];
      auto tag = "@ProtoTag(" ~ p.matches[2] ~ ") ";
      // [packed = true];
      auto packed = p.matches.length == 3 ||
                    (p.matches[3] == "packed" && p.matches[4] == "true")
                    ? "" : "@Unpacked ";
      return spaces ~ packed ~ tag ~ type ~ " " ~ name ~ ";\n";
    default:
      assert(false, p.name ~ " unsupported");
  }
}

///
version (pbd_test)
@nogc nothrow pure @safe
unittest
{
  import std.stdio;
  import pbd.parse : Proto;

  enum exampleProto = `
syntax = "proto3";

package tensorflow;

message Foo {
  int32 aa = 1;
  sint32 bb = 2;
}
`;

  // example of generated code
  import pbd.codegen;
  struct ExpectedFoo {
    @ProtoTag(1) int aa;
    @ZigZag @ProtoTag(2) int bb;
  }

  enum tree = Proto(exampleProto);
  enum code = tree.toD(0, "  ");
  mixin(code);

  static assert(is(typeof(Foo.aa) == int));
  static assert(protoTagOf!(Foo, "aa") == 1);
  static assert(!isZigZag!(Foo, "aa"));

  static assert(is(typeof(Foo.bb) == int));
  static assert(protoTagOf!(Foo, "bb") == 2);
  static assert(isZigZag!(Foo, "bb"));
  // writeln("generated:\n", code);
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

version (pbd_test)
@nogc nothrow pure
unittest
{
    pstring cs = "abc";
    assert(cs == "abc");
}

auto ProtoToD(string path)()
{
  import pbd.parse : Proto;
  return Proto(import(path)).toD;
}
