echo "Checking node.js installation"
if command -v node &>/dev/null; then
  echo "node.js installation found"
else
  echo "node.js installation not found. Please install node.js."
  exit 1
fi
