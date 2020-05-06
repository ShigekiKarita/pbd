module pbd.parse;

import pegged.grammar;

mixin(grammar(`
Proto:
    Root < Syntax?  :';'?
           Package? :';'?
           ((Import / Option / Enum / Message) :';'?)*

    Spacing <~ (space / endOfLine / Comment)*
    Comment <~ "//" (!endOfLine .)* endOfLine

    Syntax < :"syntax" :'=' String

    Package < :"package" identifier

    Import < :"import" String

    Option < :"option" identifier :'=' Value

    Enum < :"enum" identifier :'{'
               (EnumField :';'?)*
           :'}'

    EnumField < identifier :'=' Integer

    Message < :"message" identifier :'{'
                  ((SingleField / RepeatedField / Oneof / Map / Enum / Message) :';'?)*
              :'}'

    SingleField < identifier identifier :'=' Integer

    RepeatedField < :"repeated" identifier identifier :'=' Integer
                    (:'[' "packed" :'=' Bool :']')?

    Oneof < :"oneof" identifier :'{'
               (SingleField :';'?)*
             :'}'

    Map < :"map<" identifier :","  identifier :">" identifier :'=' Integer

    Value  <- String
            / Integer
            / Bool

    Bool   <- "true" / "false"

    String <~ :doublequote Char* :doublequote
    Char   <~ backslash doublequote
            / backslash backslash
            / backslash [bfnrt]
            / (!doublequote .)

    Integer <~ '0'
            / [1-9] Digit*?
    Digit  <- [0-9]
`));


///
version (pbd_test)
unittest
{
  enum exampleProto = `
/// test test
syntax = "proto3";

/// test
package tensorflow;

/// test
option cc_enable_arenas = true;
option java_outer_classname = "OpDefProtos";
import "tensorflow/core/framework/attr_value.proto";
import "tensorflow/core/framework/types.proto";

// Defines an operation. A NodeDef in a GraphDef specifies an Op by
// using the "op" field which should match the name of a OpDef.
// LINT.IfChange
message OpDef {
  // Op names starting with an underscore are reserved for internal use.
  // Names should be CamelCase and match the regexp "[A-Z][a-zA-Z0-9>_]*".
  string name = 1;

  // For describing inputs and outputs.
  message ArgDef {
    // Name for the input/output.  Should match the regexp "[a-z][a-z0-9_]*".
    string name = 1;

    // Human readable description.
    string description = 2;
  };

  repeated AttrDef attr = 4 [packed = true]; // test

  oneof test_oneof {
    string name = 4;
    string sub_message = 9; //test
  };

  map<string, int32> str2int = 5;

  enum Visibility {
    // Normally this is "VISIBLE" unless you are inheriting a
    // different value from another ApiDef.
    DEFAULT_VISIBILITY = 0;
    // Publicly visible in the API.
    VISIBLE = 1;
    // Do not include this op in the generated API. If visibility is
    // set to 'SKIP', other fields are ignored for this op.
    SKIP = 2;
    // Hide this op by putting it into an internal namespace (or whatever
    // is appropriate in the target language).
    HIDDEN = 3;
  }
  Visibility visibility = 2;
}
`;

  auto tree = Proto(exampleProto);
  assert(tree.successful, tree.failMsg);

  assert(tree.name == "Proto");

  auto root = tree.children[0];
  assert(root.name == "Proto.Root");

  // syntax = "proto3";
  auto syntax = root.children[0];
  assert(syntax.name == "Proto.Syntax");
  assert(syntax.matches == ["proto3"]);

  // package tensorflow;
  auto package_ = root.children[1];
  assert(package_.name == "Proto.Package");
  assert(package_.matches == ["tensorflow"]);

  // option cc_enable_arenas = true;
  auto option0 = root.children[2];
  assert(option0.name == "Proto.Option");
  assert(option0.matches == ["cc_enable_arenas", "true"]);
  assert(option0.children[0].name == "Proto.Value");
  assert(option0.children[0].children[0].name == "Proto.Bool");

  // option java_outer_classname = "OpDefProtos";
  auto option1 = root.children[3];
  assert(option1.name == "Proto.Option");
  assert(option1.matches == ["java_outer_classname", "OpDefProtos"]);

  // import "tensorflow/core/framework/attr_value.proto";
  auto import0 = root.children[4];
  assert(import0.name == "Proto.Import");
  assert(import0.matches == ["tensorflow/core/framework/attr_value.proto"]);

  // import "tensorflow/core/framework/types.proto";
  auto import1 = root.children[5];
  assert(import1.name == "Proto.Import");
  assert(import1.matches == ["tensorflow/core/framework/types.proto"]);

  // message OpDef {
  auto message = root.children[6];
  assert(message.name == "Proto.Message");
  assert(message.matches[0] == "OpDef");

  //   string name = 1;
  auto field0 = message.children[0];
  assert(field0.name == "Proto.SingleField");
  assert(field0.matches == ["string", "name", "1"]);
  assert(field0.children[0].name == "Proto.Integer");
  assert(field0.children[0].matches == ["1"]);

  //   message ArgDef {
  auto subMessage = message.children[1];
  assert(subMessage.name == "Proto.Message");
  assert(subMessage.matches[0] == "ArgDef");

  //     string name = 1;
  auto subField0 = subMessage.children[0];
  assert(subField0.name == "Proto.SingleField");
  assert(subField0.matches == ["string", "name", "1"]);

  //   repeated AttrDef attr = 4; // test
  auto repeated = message.children[2];
  assert(repeated.name == "Proto.RepeatedField");
  assert(repeated.matches == ["AttrDef", "attr", "4", "packed", "true"]);

  //   oneof test_oneof {
  auto oneof = message.children[3];
  assert(oneof.name == "Proto.Oneof");
  assert(oneof.matches[0] == "test_oneof");

  //     string name = 4;
  auto oneofField0 = oneof.children[0];
  assert(oneofField0.name == "Proto.SingleField");
  assert(oneofField0.matches == ["string", "name", "4"]);

  //     string sub_message = 9; //test
  auto oneofField1 = oneof.children[1];
  assert(oneofField1.name == "Proto.SingleField");
  assert(oneofField1.matches == ["string", "sub_message", "9"]);

  //   map<string, int32> str2int = 5;
  auto map = message.children[4];
  assert(map.name == "Proto.Map");
  assert(map.matches == ["string", "int32", "str2int", "5"]);

  //   enum Visibility
  auto enumDecl = message.children[5];
  assert(enumDecl.name == "Proto.Enum");
  assert(enumDecl.matches == [
      "Visibility",
      "DEFAULT_VISIBILITY", "0",
      "VISIBLE", "1",
      "SKIP", "2",
      "HIDDEN", "3"]);
  auto enumField0 = enumDecl.children[0];
  assert(enumField0.name == "Proto.EnumField");
  assert(enumField0.matches == ["DEFAULT_VISIBILITY", "0"]);
}
