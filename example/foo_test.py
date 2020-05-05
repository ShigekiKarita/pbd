from foo_pb2 import Foo

foo = Foo(a=1, b=2)
print(foo)
print(foo.SerializeToString())


foo = Foo(f={'aa': 1, 'bb': 2})
print(foo)
print(foo.SerializeToString())
