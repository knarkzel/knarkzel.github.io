build:
    #!/usr/bin/env bash
    emacs -Q --script build.el

    # copy static data and make directories
    for FILE in $(git ls-files src/ | grep -v .org); do
        mkdir -p `dirname public/${FILE:4}`
        cp "src/${FILE:4}" "public/${FILE:4}"
    done    

watch:
    find src/ -type f | entr just build &
    pkill python >/dev/null || cd public/ && python -m http.server

deploy:
    git push origin master
    git push github master
