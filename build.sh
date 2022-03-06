#!/bin/sh

set -euf

# build site
emacs -Q --script build-site.el

# copy over static data
cp content/styles.css public/styles.css
cp content/favicon.ico public/favicon.ico
cp -r assets/ public/

# remove pre-wrap for source-code and minify
for f in $(find public/ -type f -name "*.html"); do
    sed -i "s/white-space: pre-wrap;//g" "$f"
    if [ $f = "public/projects/index.html" ]; then sed -i "s/<p>$//;s/<\/p>$//" "$f"; fi
    binaries/minify "$f" -o "$f"
done

# minify css
for f in $(find public/ -type f -name "*.css"); do
    binaries/minify "$f" -o "$f"
done
