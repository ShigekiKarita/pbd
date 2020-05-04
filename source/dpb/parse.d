module dpb.parse;

import pegged.grammar;

mixin(grammar(`
Proto:
    Root < Syntax?  :';'?
           Package? :';'?
           ((Import / Option / Message) :';'?)*

    Spacing <~ (space / endOfLine / Comment)*
    Comment <~ "//" (!endOfLine .)* endOfLine

    Syntax < :"syntax" :'=' String

    Package < :"package" identifier

    Import < :"import" String

    Option < :"option" identifier :'=' Value

    Message < :"message" identifier :'{'
                  ((SingleField / RepeatedField / Oneof / Message) :';'?)*
              :'}'

    SingleField < identifier identifier :'=' Integer

    RepeatedField < :"repeated" identifier identifier :'=' Integer

    Oneof < :"oneof" identifier :'{'
               (SingleField :';'?)*
             :'}'

    Value  <- String
            / Integer
            / True
            / False

    True   <- "true"
    False  <- "false"

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

  repeated AttrDef attr = 4; // test

  oneof test_oneof {
    string name = 4;
    string sub_message = 9; //test
  };
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
  assert(option0.children[0].children[0].name == "Proto.True");

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
  assert(repeated.matches == ["AttrDef", "attr", "4"]);

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
}
