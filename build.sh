#!/bin/sh

# build site
emacs -Q --script build-site.el

# copy over static data
cp content/styles.css public/styles.css
cp content/favicon.ico public/favicon.ico

# remove pre-wrap for source-code
for f in $(find public/ -type f -name "*.html"); do
    echo "Removing pre-wrap from $f"
    sed -i "s/white-space: pre-wrap;//g" $f
done
