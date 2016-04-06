#!/bin/bash

FILES=$(ls ./test/*.spec.js)

for f in $FILES; do

    echo "========================================"
    echo "testing... $f"
    echo "----------------------------------------"

    VISIBLE=warn,error ./node_modules/.bin/mocha "$f"


done
