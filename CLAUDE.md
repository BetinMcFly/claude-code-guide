# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este proyecto

Una guía práctica de Claude Code, en español, publicada en https://claude-code.albertosolano.dev

Es **una sola página estática**: `public/index.html`, con el CSS y el JavaScript en línea. No hay build, ni backend, ni dependencias empaquetadas. Las únicas peticiones externas son a Google Fonts.

La guía cubre dos escenarios de uso: arrancar un proyecto desde cero y dar seguimiento a uno existente, corrigiendo errores y añadiendo funcionalidades.

## Los cambios de contenido los hace Claude

El propietario del repositorio describe qué quiere cambiar y Claude edita el archivo. **No le sugieras que copie y pegue contenido largo desde la terminal.**

Edita por SSH, y copiar desde la pantalla de vim corrompió el archivo dos veces: una vez quedó truncado con un marcador `???END`, otra un archivo de 729 líneas se redujo a las 55 líneas visibles más una línea `-- INSERT --` de la barra de estado. Copiar desde pantalla nunca puede capturar un archivo de cientos de líneas.

Si alguna vez necesita reemplazar el archivo entero él mismo, la vía correcta es `scp` desde su máquina local, no pegar en un editor.

## Validar antes de publicar

```bash
./scripts/validar.sh
```

**Ejecútalo siempre antes de desplegar.** Comprueba que el HTML cierra, que las etiquetas balancean, que cada enlace del menú tiene su sección, que no hay ids duplicados y que no quedan artefactos de terminal. Sale con código 1 si algo falla.

Existe por los dos incidentes de corrupción descritos arriba. Está probado contra ambos casos reales. En el segundo, esta comprobación fue lo único que impidió que media guía con un `-- INSERT --` al final llegara al sitio público.

## Publicar

El despliegue está automatizado. **Basta con hacer push a `main`**: GitHub Actions valida y despliega.

```bash
git push origin main          # dispara validación + despliegue + verificación
```

Los dos workflows viven en `.github/workflows/`:

- **`publicar.yml`** — al hacer push a `main`, valida, despliega a producción y después compara byte a byte lo que sirve el dominio contra el repositorio, reintentando mientras el CDN propaga. No se fía del "Deploy complete".
- **`previsualizar.yml`** — cada PR obtiene una URL temporal de 7 días comentada en el propio PR, y al cerrarlo se borra el canal. Los PRs desde un fork solo se validan: GitHub no expone secretos a forks.

Ambos workflows filtran por rutas, así que tocar solo documentación no dispara un despliegue.

Los PRs se fusionan con **squash**: el historial de `main` es lineal y cada commit lleva su `(#N)`.

### Despliegue manual

Sigue funcionando y es útil para probar sin hacer commit. El CLI de Firebase es un binario standalone en `~/.local/bin`:

```bash
~/.local/bin/firebase deploy --only hosting                        # a producción
~/.local/bin/firebase hosting:channel:deploy pruebas --expires 7d  # a una URL temporal
```

### Marcha atrás

`firebase hosting:rollback` **no existe** en el CLI instalado (v15.26). Las vías reales son la consola de Firebase (Hosting → historial de versiones), `firebase hosting:clone <sitio>:<canal> <sitio>:live`, o revertir en git y volver a desplegar.

## Comprobar el resultado visualmente

Hay Chromium con Playwright instalado, así que **no hay excusa para verificar la maquetación calculando**. El guion vive fuera del repositorio, para no meter `node_modules` en un proyecto que no tiene build:

```bash
source ~/.local/share/capturas/entorno.sh   # PATH, LD_LIBRARY_PATH y FONTCONFIG_PATH
node ~/.local/share/capturas/capturar.js <url> <carpeta-salida>
```

Captura a 320, 360, 390, 820 y 1280px en tema claro y oscuro, y reporta el desbordamiento horizontal de cada combinación. Funciona igual con un `file://` al archivo local, sin necesidad de desplegar.

Para comprobar algo que las capturas no miden —si una tira de navegación desplaza dentro de sí misma, si un elemento desborda su contenedor— escribe un guion aparte, pero pásale `NODE_PATH=~/.local/share/capturas/node_modules`. `entorno.sh` no lo exporta, así que `require('playwright')` falla desde cualquier otra carpeta.

**La página lleva `scroll-behavior:smooth`, así que desplazarse es una animación.** Un `scrollIntoView()` a una sección del final son 12.000px animados: si capturas o mides a los pocos cientos de milisegundos, te crees cosas que no pasan. A mí me dio dos falsos positivos en la misma tanda — una captura de escritorio completamente negra y un enlace del menú que parecía dejar su sección a 202px del borde, cuando la deja a 20px. Salta de golpe con `window.scrollTo({top, behavior:'instant'})` y espera a que `window.scrollY` se estabilice antes de disparar la captura.

**Espera siempre a `document.fonts.ready` antes de medir nada.** Esta máquina no traía ninguna fuente; se instalaron 316 en `~/.local/share/fonts`. Antes de eso, una comprobación de desbordamiento pasaba en verde y era falsa: sin fuentes el texto no ocupa ancho, así que nada desbordaba. Un chequeo que pasa por el motivo equivocado es peor que no tenerlo.

## Al editar el HTML

**Los diagramas duplican texto que también está en el HTML.** Las tres figuras SVG llevan sus rótulos escritos dentro del `<svg>`, incluido un `<desc>` que enumera los mismos elementos para lectores de pantalla. Si cambias los chips de niveles de la sección 01 sin tocar la figura 1, el error queda duplicado en vez de corregido.

**Los dos flujos de la sección 03 comparten bloques.** El bloque de «Optimización» está repetido en el Flujo A y el Flujo B con contenido idéntico; al cambiar uno decide conscientemente sobre el otro. La fase «Corregir un error» está **solo** en el Flujo A a propósito: el Flujo B arranca sin código que depurar.

**Reutiliza las clases que ya existen** en vez de añadir CSS: `.lvl`/`.chip` para niveles, `.phase`/`.steps` para flujos (variantes `.p-design`, `.p-work`, `.p-opt`), `.cmd`/`pre`/`.copy` para bloques de código, `.callout` y `.note` para avisos, `.anat` para listas de definiciones, `.signals` para la tabla, `.fig` para figuras.

**El menú lateral y los ids de sección deben coincidir.** Las trece secciones, en orden: `jerarquia`, `planmode`, `flujos`, `claudemd`, `prompts`, `contexto`, `skills`, `subagentes`, `mcp`, `senales`, `comandos`, `problemas`, `recursos`. El scroll-spy deriva su lista del propio menú, así que una sección nueva entra sola en cuanto tiene su enlace; `validar.sh` detecta los enlaces sin sección.

**Insertar una sección en medio renumera todas las de abajo, y cada número vive en dos sitios**: el `<span>NN</span>` del menú y el `<div class="sec-num">NN</div>` de la cabecera. Si cambias solo uno, el índice y el cuerpo discrepan y `validar.sh` no lo nota — comprueba que las dos listas dan la misma secuencia:

```bash
grep -oE '<span>[0-9]+</span>' public/index.html
grep -oE '<div class="sec-num">[0-9]+</div>' public/index.html
```

Renumera **en una sola pasada con un mapa completo**, nunca en cadena: sustituir `08→10` y después `10→12` vuelve a mover lo que acabas de mover. Y quedan las referencias cruzadas en la prosa, que ningún script valida: `grep -o 'sección [0-9]*'`.

**Si generas marcado con un heredoc de Python, cuidado con la barra invertida.** Dentro de una cadena normal, `\` al final de línea es una continuación y Python se la come junto al salto: una continuación de línea de shell en un bloque de código desaparece sin avisar y el ejemplo queda con un doble espacio en medio.

## Trampas del CSS, todas descubiertas rompiendo algo

**No uses `--ink` como fondo.** Se invierte con el tema, así que un fondo oscuro con texto claro construido sobre él queda claro sobre claro en modo oscuro. Para eso están `--code-bg`, `--code-fg` y `--fig-inv-bg`, que se mantienen oscuros en ambos temas. Lo mismo con `--mustard`: como texto no llega al contraste mínimo en tema claro, para eso existe `--mustard-text`.

**Dentro de los SVG, los colores van en clases, nunca en atributos.** Un `fill="#6B5B7B"` escrito en el marcado **gana a cualquier regla CSS** y no se adapta al tema. Las clases disponibles son `.t-tag-2`, `.t-tag-3`, `.t-alt`, `.box-alt`, `.box-fill`, `.zone-pine`, `.mk` y `.mk-alt`.

**Todo ítem de grid o flex necesita `min-width:0` si su contenido no puede encoger.** Por defecto un ítem no baja de su contenido mínimo. El `.rail` no lo tenía y su tira de navegación, con los enlaces en `nowrap`, forzaba 666px en un viewport de 360: la página entera se desplazaba en horizontal. Aplica igual a `.cmd-row`, que usa `minmax(0,1fr)` por el mismo motivo.

**El texto de un SVG escala con su `viewBox`.** Con 700 unidades comprimidas en un móvil, un texto de 11 unidades se renderiza a menos de 5px reales. Por eso las figuras viven en `.fig-scroll`, que en pantalla estrecha las mantiene a 640px mínimos y se navegan desplazando. Ese contenedor lleva `overflow-y:hidden` a propósito: con solo `overflow-x`, el eje vertical pasa a `auto` y el scroller de dos ejes atrapa el gesto táctil.

**Acota los selectores de descendiente.** `.cmd-row code` alcanzaba también a los `<code>` en línea de las descripciones; ahora es `.cmd-row > code`.

**`--rule` es un color de filetes; como color de texto no se lee.** Los números del menú lo usaban y daban 1.36:1 en tema claro y 1.48:1 en oscuro, con el mínimo en 4.5:1 — a 10px, invisibles. Un color pensado para una línea de 1px no sirve para texto, por muy secundario que sea. Para eso existe ahora `--rail-num`, con 4.67:1 y 5.56:1, todavía por debajo del contraste de la etiqueta para conservar la jerarquía. Si quieres un texto tenue, mide el contraste antes de dar por bueno un token que ya existe.

**Los `<code>` en línea llevan relleno lateral, y eso despega el punto que los sigue.** Se leía «en `/resume` .» con cinco píxeles de hueco. Lo corrige un `margin-right:-3px` en `.steps code` y `.cmd-row p code`. Si tocas ese relleno, comprueba de nuevo una frase que termine en `<code>`.

## Cómo está escrita la guía

Dos revisiones de redacción en octubre de 2026 encontraron que casi todo lo ilegible o lo mal escrito venía de estos hábitos. Conviene no reintroducirlos.

**Nombra el sujeto en cada frase.** El caso que lo destapó: «Plan Mode le quita las herramientas de escritura: lee archivos, busca en el código…». El sujeto cambia a mitad de frase —quien lee los archivos es Claude, no Plan Mode— y el «le» no tiene antecedente. Si la frase habla de Claude, escribe Claude.

**Nada de elipsis que obliguen a reconstruir la frase anterior.** «Plan Mode no.» exigía recomponer «Plan Mode no es una sugerencia que se pueda ignorar».

**«skill» es femenino**: la skill, las skills, una skill. Estuvo mezclado con el masculino en la mitad del sitio.

**Nada de verbos calcados del inglés.** *Scaffoldea*, *commitear*, *testear*, *lintear* y *commitea* llegaron a convivir en el texto; ninguno se dice en voz alta. Los sustantivos sí se quedan, porque un equipo los usa de verdad: commit, bug, prompt, stack, feature, skill, hook, workflow. La frontera es esa — se admite el sustantivo prestado, no el verbo inventado a partir de él.

**No uses «la salida» con el sentido de solución.** En una guía llena de salidas de terminal, choca. Lo mismo con «prerequisito», que lleva doble erre.

Y una regla de estructura: **una idea, una vez**. La sección 02 abría con una metáfora y repetía el mismo contraste tres párrafos después.

## Exactitud del contenido

La guía documenta Claude Code, que cambia rápido. **Contrasta cualquier afirmación nueva contra https://code.claude.com/docs antes de escribirla, nunca de memoria.**

Una revisión previa encontró cuatro errores factuales. Los que conviene no repetir:

- `user-invocable` **por defecto ya es `true`**. Se pone en `false` para ocultar una skill del menú `/`. El campo que impide que Claude dispare una skill sola es `disable-model-invocation: true`.
- CLAUDE.md no es el único mecanismo que persiste entre sesiones: **auto memory** también, y lo escribe Claude solo.
- Specs / SDD es una metodología, no una función del producto. La lista oficial de extensiones es CLAUDE.md, Skills, Code intelligence, MCP, Subagents, Agent teams, Hooks, Plugins y Artifacts.
- **Agent teams es experimental y viene desactivado por defecto.** Cualquier mención debe decirlo.

**Retocar la redacción de una frase no es revisar lo que afirma.** La fila de `/clear [nombre]` decía que el nombre etiqueta la sesión nueva; etiqueta la conversación que dejas atrás, para reconocerla en `/resume`. Le arreglé la gramática en una pasada de estilo sin mirar si era cierta, así que el error sobrevivió justo a la revisión que debía cazarlo. Si tocas una frase que hace una afirmación sobre el producto, contrástala, aunque la estés tocando por otro motivo.

**Y una verificación caduca.** La guía decía `Shift+Tab × 2` para entrar en Plan Mode. Era correcto cuando se escribió y dejó de serlo dos días después, cuando el modo automático pasó a ser el arranque por defecto y se colocó por delante en el ciclo: ahora son tres pulsaciones. Que algo se contrastara una vez no lo mantiene cierto — si una afirmación lleva meses escrita, vuelve a comprobarla antes de apoyarte en ella.

## Infraestructura

| | |
|---|---|
| Proyecto GCP / Firebase | `claude-projects-496723` |
| Zona de Cloud DNS | `albertosolano-dev`, en el mismo proyecto |
| Registro del subdominio | CNAME a `claude-projects-496723.web.app` (permanente) |
| Certificado | Gestionado por Firebase, renovación automática |
| Despliegue desde CI | Service account `github-actions-deploy@`, con `firebasehosting.admin` y `firebase.viewer`; su clave vive solo como secreto `FIREBASE_SERVICE_ACCOUNT` del repositorio |

El HTML se sirve con `Cache-Control: public, max-age=300`, así que **un cambio tarda hasta 5 minutos en verse**. Si el sitio no refleja el despliegue, espera y reintenta antes de sospechar un fallo.
