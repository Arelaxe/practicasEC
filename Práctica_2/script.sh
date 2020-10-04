#!/bin/bash

for i in $(seq 1 19); do
rm media
gcc -x assembler-with-cpp -D TEST=$i -no-pie media.s -o media
echo -n "T#$i "; ./media
done
