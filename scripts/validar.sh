#!/usr/bin/env bash
# Comprueba la integridad de la guía antes de publicarla.
# Existe porque el archivo se ha corrompido dos veces al editarlo por SSH:
# una quedó truncado con un marcador "???END", otra se redujo a las líneas
# visibles en pantalla más la barra de estado de vim. Ambos casos habrían
# llegado a producción sin estas comprobaciones.
#
# Uso: ./scripts/validar.sh [ruta-al-html]
set -uo pipefail

F="${1:-public/index.html}"
fallos=0

fallo() { echo "  ✗ $*"; fallos=$((fallos + 1)); }
ok()    { echo "  ✓ $*"; }

echo "Validando $F"

if [ ! -f "$F" ]; then
  echo "  ✗ el archivo no existe"
  exit 1
fi

# --- El archivo está completo ---
if [ "$(tail -c 20 "$F" | grep -c '</html>')" -eq 1 ]; then
  ok "cierra con </html>"
else
  fallo "no termina en </html> — archivo truncado"
fi

# --- Sin restos de la interfaz del terminal ---
if grep -qE '\?\?\?END|-- INSERT --|-- VISUAL --' "$F"; then
  fallo "contiene artefactos de terminal (volcado de pantalla en vez del archivo)"
else
  ok "sin artefactos de terminal"
fi

# --- Etiquetas balanceadas ---
for t in html head body div section figure svg ol ul li table tr td dl; do
  # grep -o | wc -l cuenta ocurrencias; grep -c contaría solo líneas,
  # y estas etiquetas aparecen varias veces en la misma línea.
  abren=$(grep -oE "<$t[ >]" "$F" | wc -l)
  cierran=$(grep -oE "</$t>" "$F" | wc -l)
  if [ "$abren" -ne "$cierran" ]; then
    fallo "<$t>: $abren abren / $cierran cierran"
  fi
done
[ "$fallos" -eq 0 ] && ok "etiquetas balanceadas"

# --- Cada enlace del menú tiene su sección ---
rotos=0
for a in $(grep -oE 'href="#[a-zA-Z0-9_-]+"' "$F" | sed 's/href="#//;s/"//' | sort -u); do
  if ! grep -q "id=\"$a\"" "$F"; then
    fallo "enlace roto: #$a no corresponde a ningún id"
    rotos=$((rotos + 1))
  fi
done
[ "$rotos" -eq 0 ] && ok "todos los enlaces internos resuelven"

# --- Los ids no se repiten ---
dups=$(grep -oE ' id="[a-zA-Z0-9_-]+"' "$F" | sort | uniq -d)
if [ -n "$dups" ]; then
  fallo "ids duplicados:$(echo " $dups" | tr '\n' ' ')"
else
  ok "ids únicos"
fi

# --- Referencias a las figuras ---
for ref in $(grep -oE 'aria-labelledby="[^"]+"' "$F" | sed 's/aria-labelledby="//;s/"//'); do
  for id in $ref; do
    grep -q "id=\"$id\"" "$F" || fallo "aria-labelledby apunta a un id inexistente: $id"
  done
done

echo
echo "  $(wc -l < "$F") líneas · $(wc -c < "$F") bytes · $(grep -c '<section id=' "$F") secciones"

if [ "$fallos" -gt 0 ]; then
  echo
  echo "FALLO: $fallos problema(s). No publicar."
  exit 1
fi

echo
echo "OK: el archivo está íntegro."
