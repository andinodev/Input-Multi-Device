## ============================================================================
## GameColors — Paleta de colores global del proyecto
## ============================================================================
##
## Contiene todas las constantes de color usadas en el proyecto.
## Al ser un script con class_name, se puede acceder desde cualquier lugar:
##
##   GameColors.PRIMARY     → Color("#2dd4bf")
##   GameColors.BG          → Color("#0f1923")
##
## ¿POR QUÉ class_name EN VEZ DE AUTOLOAD?
##   - Las constantes se resuelven en tiempo de compilación (costo cero).
##   - No necesita un nodo en el árbol de escenas.
##   - Autoload es para lógica que necesita _process(), señales, etc.
##   - class_name es para datos puros y funciones utilitarias estáticas.
##
## ¿ES EFICIENTE?
##   - Sí. Las const en GDScript son inline — el compilador las reemplaza
##     directamente donde se usan. No hay lookup en runtime.
##   - Además, cambiar un color aquí lo cambia en TODAS las escenas.
## ============================================================================
class_name GameColors
extends RefCounted


# ── Fondos ───────────────────────────────────────────────────────────────────
## Fondo principal oscuro (navy profundo)
const BG := Color("#0f1923")
## Fondo alternativo para distinguir escenas (ej: gameplay)
const BG_ALT := Color("#0d1117")
## Superficies elevadas (botones, paneles)
const SURFACE := Color("#1a2332")

# ── Acentos ──────────────────────────────────────────────────────────────────
## Color primario — teal vibrante (acciones principales)
const PRIMARY := Color("#2dd4bf")
## Color secundario — amber cálido (acciones secundarias)
const SECONDARY := Color("#f59e0b")
## Color de peligro/retroceso — coral suave (salir, volver)
const DANGER := Color("#f87171")

# ── Texto ────────────────────────────────────────────────────────────────────
## Texto principal (off-white)
const TEXT := Color("#e2e8f0")
## Texto secundario/atenuado (gray-blue)
const TEXT_DIM := Color("#94a3b8")
