#!/usr/bin/env bash

# build site
emacs -Q --script build.el

# copy over static data
mkdir -p public/hello-world/os/src
for FILE in $(find src/ -type f -not -name "*.org"); do
    cp "src/${FILE:4}" "public/${FILE:4}"
done
