build:
    #!/usr/bin/env bash
    emacs -Q --script build.el

    # copy static data and make directories
    for FILE in $(git ls-files src/ | grep -v .org); do
        mkdir -p `dirname public/${FILE:4}`
        cp "src/${FILE:4}" "public/${FILE:4}"
    done    

watch:
    #!/usr/bin/env bash 
    find src/ -type f | entr just build &
    cd public/ && python -m http.server
