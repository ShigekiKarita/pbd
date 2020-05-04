/// Protobuf ZigZag decoding.
module dpb.decode;

import std.typecons;

import dpb.codegen : ProtoTag, protoTagOf, protoMemberOf;


/// Decodes varint and consumes given bytes.
@trusted
T fromVarint(T)(scope ref byte[] encoded)
{
  import std.bitmanip : BitArray;

  T val = 0;
  T shift = 0;
  foreach (adv, b; encoded)
  {
    // This pointer should be valid.
    immutable ba = BitArray((&b)[0 .. 1], 8);
    static foreach (i; 0 .. 7)
    {
      // Decodes bit to integer.
      val += ba[i] << shift;
      ++shift;
    }

    // MSB is used as sentinel.
    if (ba[7] == 0)
    {
      // Consumes bytes.
      encoded = encoded[adv + 1 .. $];
      return val;
    }
  }
  assert(false, "no sentinel found");
}

/// Varint examples.
pure nothrow @safe
unittest
{
  byte[] b1 = [cast(byte) 0b0000_0001];
  assert(fromVarint!int(b1) == 1);

  byte[] b128 = [cast(byte) 0b1000_0000, 0b0000_0001];
  assert(fromVarint!int(b128) == 128);

  byte[] b300 = [cast(byte) 0b1010_1100, 0b0000_0010];
  assert(fromVarint!int(b300) == 300);
}


T decode(T)(byte[] encoded)
{
  import std.traits : isArray;

  T ret;
  while (encoded.length > 0)
  {
    // TODO(karita): support sint32/64
    // https://developers.google.com/protocol-buffers/docs/encoding#signed-integers
    auto k = encoded[0];
    auto tag = k / 8;
    auto mode = k % 8;
    // writeln("tag: ", tag, ", mode:", mode);

    encoded = encoded[1 .. $];
    static foreach (name; __traits(allMembers, T))
    {
      if (protoTagOf!(T, name) == tag)
      {
        // writeln(name);
        alias member = __traits(getMember, ret, name);
        alias Member = typeof(member);
        switch (k % 8)
        {
          case 0:
            // varint
            static if (!isArray!Member)
            {
              __traits(getMember, ret, name) = fromVarint!Member(encoded);
              break;
            }
            else
            {
              assert(false, "varint was encoded for array type.");
            }
          case 1:
            // 64 bit
            break;
          case 2:
            // length deliminated
            static if (isArray!Member)
            {
              auto numBytes = fromVarint!size_t(encoded);
              auto len = numBytes / typeof(member[0]).sizeof;
              auto ptr = cast(typeof(member.ptr)) encoded.ptr;
              // TODO(karita): make this nogc?
              __traits(getMember, ret, name) = ptr[0 .. len].dup;
              encoded = encoded[numBytes .. $];
              break;
            }
            else
            {
              assert(false, "length-delimited value was encoded for non-array type.");
            }
          case 5:
            // 32 bit
            break;
          default:
            assert(false, "unknown type in key.");
        }
      }
    }
  }
  return ret;
}

///
unittest
{
  struct Foo
  {
    @ProtoTag(1) int a;
    @ProtoTag(2) int b;
    @ProtoTag(3) string c;
  }

  byte[] encoded = [
      /* tag(1), varint(0) */ 0x08, /* 1 */ 0x01,
      /* tag(2), varint(0) */ 0x10, /* 2 */ 0x02,
      /* tag(3), length-delim */ 0x1a, /* len(3)*/ 03, /* abc */ 0x61, 0x62, 0x63];
  auto foo = decode!Foo(encoded);
  import std;
  writeln(foo);
  assert(foo == Foo(1, 2, "abc"));
}
