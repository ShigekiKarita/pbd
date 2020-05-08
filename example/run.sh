#!bash

base=$(dirname $0)
cd $base

echo "testing foo.proto"
protoc --python_out=. foo.proto
python3 foo_test.py

echo "testing tensorflow/core/framework"
protoc --python_out=. tensorflow/core/framework/*.proto
python3 tf_test.py

echo "testing server/client using protobuf."
python3 foo_server.py &
./foo_client.d

