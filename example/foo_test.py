from foo_pb2 import Foo

foo = Foo(a=1, b=1)
print(foo)
print(foo.SerializeToString())


foo = Foo(a=-1)
print(foo)
print(foo.SerializeToString())

foo = Foo(b=-1)
print(foo)
print(foo.SerializeToString())


foo = Foo(a=-2147483648)
print(foo)
print(foo.SerializeToString())

foo = Foo(b=-2147483648)
print(foo)
print(foo.SerializeToString())


foo = Foo(f={'aa': 1, 'bb': 2})
print(foo)
print(foo.SerializeToString())
