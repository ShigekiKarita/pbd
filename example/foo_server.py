from multiprocessing.connection import Listener

from foo_pb2 import Foo

address = ('localhost', 6000)
with Listener(address) as listener:
  print('server is listening %s:%d' % address)
  with listener.accept() as conn:
    print('connection accepted from', listener.last_accepted)
    conn.send_bytes(Foo(a=1, b=-1).SerializeToString())
