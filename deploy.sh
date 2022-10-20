#!/usr/bin/env bash

./build.sh

# knarkzel.srht.site
git push origin master

# knarkzel.github.io
git push github master

# knarkzel.surge.sh
surge public/ knarkzel.surge.sh
