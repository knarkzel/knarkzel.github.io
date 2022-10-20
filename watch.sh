#!/usr/bin/env bash

./build.sh
$(cd public/ && python -m http.server &)
find src/ -type f | entr ./build.sh
