#!/bin/bash

FILES=$(ls ./test/*.tape.js)

for f in $FILES; do

    echo "========================================"
    echo "testing... $f"
    echo "----------------------------------------"

    # set the VISIBLE envvar to restrict logger output, then run tests
    #
    VISIBLE= node "$f" | faucet


done
