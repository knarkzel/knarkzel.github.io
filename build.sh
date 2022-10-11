#!/usr/bin/env bash

# build site
emacs -Q --script build.el

# make directories
for FILE in $(find src/ -type d); do
    mkdir -p "public/${FILE:4}"
done

# copy static data
for FILE in $(find src/ -type f -not -name "*.org"); do
    cp "src/${FILE:4}" "public/${FILE:4}"
done

# remove ./ from relative links, causes issues on srht pages
for FILE in $(find public/ -type f -name "*.html"); do
    sed -i "/Go back/! s/\.\///g" $FILE
done


