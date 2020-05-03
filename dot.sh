#!bash

outfile="tf.dot"

echo "digraph tf {"
for proto in example/tensorflow/core/framework/*.proto; do
    for import in $(grep import $proto); do
        if [ $import != "import" ]; then
            echo "  \""$(basename $proto)"\" -> \""$(basename ${import:1:-2})"\";"
        fi
    done
done
echo "}"
