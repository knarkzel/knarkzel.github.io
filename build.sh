#!/bin/sh
emacs -Q --script build-site.el
cp styles.css public/styles.css
