/// Code generation module.
module dpb.codegen;

import pegged.grammar : ParseTree;

struct ProtoTag
{
  /// Tag number for encoding/decoding
  int tag;
}


struct Test
{
  @ProtoTag(2)
  int i;
}

/// Generates D code from Protobuf IDL ParseTree (Proto result).
string toD(ParseTree p)
{
  return "";
}

