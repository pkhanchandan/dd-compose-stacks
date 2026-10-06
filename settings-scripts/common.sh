# Shared by set-docker-gui.sh and restore-docker-gui.sh: locates Docker Desktop's settings-store.json.
case "$(uname -s)" in
  Darwin)               DIR="$HOME/Library/Group Containers/group.com.docker" ;;
  Linux)                DIR="$HOME/.docker/desktop" ;;
  MINGW*|MSYS*|CYGWIN*) DIR="$(cygpath -u "$APPDATA")/Docker" ;;   # Git Bash on Windows
  *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

FILE="$DIR/settings-store.json"
BACKUP="$FILE.pre-v2.bak"
ABSENT_MARKER="$FILE.pre-v2.absent"
