watch:
    #!/usr/bin/env bash
    find src/ -type f | entr "just build" &
    $(cd public/ && python -m http.server &)
