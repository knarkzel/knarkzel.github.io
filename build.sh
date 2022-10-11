#!/usr/bin/env bash

# build site
emacs -Q --script build.el

# copy static data and make directories
for FILE in $(git ls-files src/ | grep -v .org); do
    mkdir -p `dirname public/${FILE:4}`
    cp "src/${FILE:4}" "public/${FILE:4}"
done

# create absolute paths for srht pages
for FILE in $(find public/ -type f -name "*.html"); do
    ABSOLUTE=`dirname ${FILE:6}`
    [[ "$ABSOLUTE" == "/" ]] && EXTRA="" || EXTRA="/"
    sed -i "/Go back/! s|\.\/|$ABSOLUTE$EXTRA|g" "$FILE"
done
