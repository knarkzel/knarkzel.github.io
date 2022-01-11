#!/bin/sh
emacs -Q --script build-site.el
cp content/styles.css public/styles.css
cp content/favicon.ico public/favicon.ico
