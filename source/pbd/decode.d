/// Protobuf ZigZag decoding.
module pbd.decode;

import std.typecons;

import pbd.codegen : ProtoTag, ProtoArray, pstring, protoTagOf, protoMemberOf, isZigZag, ZigZag;

struct VarintElem
{
  import std.bitmanip : bitfields;

  mixin(bitfields!(
      byte, "i", 7,
      bool, "cont", 1));
}

/// Decodes varint and consumes given bytes.
T fromVarint(T)(scope ref ubyte[] encoded)
{
  import std.bitmanip : BitArray;

  T val = 0;
  T shift = 0;
  foreach (adv, b; encoded)
  {
    // This pointer should be valid.
    const ba = BitArray((&b)[0 .. 1], 8);
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
      // two's complement = ones' complement + 1
      if (val < 0) val += 1;
      return val;
    }
  }
  assert(false, "no sentinel found");
}

/// Reverts a given zigzag-encoded ((n << 1) ^ (n >> (T.sizeof * 8 - 1)))
/// unsigned value to signed.
T fromZigzag(T)(T n)
{
  return (n >> 1) ^ (-(n & 1));
}

/// Varint examples.
version (pbd_test)
pure nothrow
unittest
{
  ubyte[] b1 = [0b0000_0001];
  assert(fromVarint!int(b1) == 1);

  ubyte[] b128 = [0b1000_0000, 0b0000_0001];
  assert(fromVarint!int(b128) == 128);

  ubyte[] b300 = [0b1010_1100, 0b0000_0010];
  assert(fromVarint!int(b300) == 300);

  ubyte[] bneg1 = [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01];
  assert(-1 == fromVarint!int(bneg1));

  ubyte[] bneg1_sint = [0x01];
  assert(-1 == fromVarint!int(bneg1_sint).fromZigzag);

  ubyte[] b1_sint = [0x02];
  assert(1 == fromVarint!int(b1_sint).fromZigzag);
}


T decode(T)(ubyte[] encoded)
{
  import std.range.primitives : ElementType;
  import std.traits : isScalarType, hasUDA;

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
      static if (hasUDA!(__traits(getMember, ret, name), ProtoTag))
        if(protoTagOf!(T, name) == tag)
      {
        // writeln(name);
        alias member = __traits(getMember, ret, name);
        alias Member = typeof(member);
        switch (k % 8)
        {
          case 0:
            // varint
            // https://developers.google.com/protocol-buffers/docs/encoding#varints
            static if (isScalarType!Member)
            {
              static if (isZigZag!(T, name))
              {
                __traits(getMember, ret, name) = fromVarint!Member(encoded).fromZigzag;
              }
              else
              {
                __traits(getMember, ret, name) = fromVarint!Member(encoded);
              }
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
            // length deliminated i.e., packed
            // https://developers.google.com/protocol-buffers/docs/encoding#packed
            static if (is(Member : ProtoArray!T, T))
            {
              alias E = ElementType!Member;
              auto numBytes = fromVarint!size_t(encoded);
              auto len = numBytes / E.sizeof;
              auto ptr = cast(E*) encoded.ptr;
              // TODO(karita): make this nogc?
              // __traits(getMember, ret, name) ~= ptr[0 .. len].dup;
              foreach (i; 0 .. len)
              {
                __traits(getMember, ret, name).insertBack(ptr[i]);
              }

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
version (pbd_test)
pure nothrow
unittest
{
  struct Foo
  {
    @ProtoTag(1) int a;
    @ZigZag @ProtoTag(2) int b;
    @ProtoTag(3) pstring c;
  }

  ubyte[] encoded = [
      /* tag(1), varint(0) */ 0x08, /* 1 */ 0x01,
      /* tag(2), varint(0) */ 0x10, /* 1 but -1 in zigzag */ 0x01,
      /* tag(3), length-delim */ 0x1a, /* len(3)*/ 03, /* abc */ 0x61, 0x62, 0x63];
  auto foo = decode!Foo(encoded);
  assert(foo == Foo(1, -1, pstring("abc")));
}

