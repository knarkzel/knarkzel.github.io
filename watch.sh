#!/usr/bin/env bash

find src/ -type f | entr ./build.sh &
$(cd public/ && python -m http.server &)
