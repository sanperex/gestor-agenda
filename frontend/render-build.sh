#!/usr/bin/env bash
# Compila la app web para Render (sitio estatico). Lo ejecuta Render con: bash render-build.sh
#
# Render no trae Flutter instalado, asi que se descarga la version fija del proyecto.
# Si Flutter ya esta en el PATH (por ejemplo, al probarlo en un PC), usa ese.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.3}"

# La URL de la API se fija al compilar (String.fromEnvironment en api_constants.dart).
# Sin ella la app llamaria a http://localhost:3000 y en Render no funcionaria nada, asi
# que es mejor que el despliegue falle aqui con un mensaje claro.
if [ -z "${API_URL:-}" ]; then
  echo "ERROR: falta la variable de entorno API_URL." >&2
  echo "Ponla en Render con la URL publica de la API, por ejemplo https://gestor-agenda-api.onrender.com" >&2
  exit 1
fi
API_URL="${API_URL%/}"

if command -v flutter >/dev/null 2>&1; then
  FLUTTER="flutter"
else
  SDK_DIR="${FLUTTER_SDK_DIR:-$HOME/flutter-sdk}"
  if [ ! -x "$SDK_DIR/bin/flutter" ]; then
    echo "Descargando Flutter $FLUTTER_VERSION..."
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK_DIR"
  fi
  FLUTTER="$SDK_DIR/bin/flutter"
fi

"$FLUTTER" --version
"$FLUTTER" config --no-analytics >/dev/null
"$FLUTTER" pub get
"$FLUTTER" build web --release --dart-define=API_URL="$API_URL"

echo "Listo: build/web compilado contra $API_URL"
