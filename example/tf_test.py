from tensorflow.core.framework import attr_value_pb2

av = attr_value_pb2.AttrValue(i=1)
print(type(av))
print(av)
print(av.SerializeToString())

nal = attr_value_pb2.NameAttrList(name="nal", attr={"av": av})

print(type(nal))
print(nal)
print(nal.SerializeToString())
