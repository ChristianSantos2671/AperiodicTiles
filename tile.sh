#!/usr/bin/env bash
#: ───────────────────────────────────────────────────────────────────────────────
#: tile.sh — Aperiodic Hat Tiling — single-command generator
#: ─────────────────────────────────────────────────────────
#:
#: USAGE
#:   ./tile.sh <execution_name> [options]
#:
#: Generates four files in one shot:
#:   exec.<name>.canvas.json   — 2-D tiling layout
#:   exec.<name>.canvas.html   — interactive 2-D render  (open in any browser, no server needed)
#:   exec.<name>.panel.json    — 3-D panel layout with per-tile heights
#:   exec.<name>.panel.html    — interactive 3-D render  (open in any browser, no server needed)
#:
#: OPTIONS
#:   --width      FLOAT   Canvas width  in pixels              (default: 800)
#:   --height     FLOAT   Canvas height in pixels              (default: 600)
#:   --tile       FLOAT   Tile size in pixels                  (default: 40)
#:   --min-height FLOAT   Minimum tile extrusion height        (default: 20)
#:   --max-height FLOAT   Maximum tile extrusion height        (default: 120)
#:   --max-tilt   FLOAT   Max top-face tilt in degrees         (default: 25)
#:   --gap        FLOAT   Gap between tiles in pixels          (default: 2)
#:   --seed       INT     Random seed for reproducibility      (default: 42)
#:
#: EXAMPLES
#:   ./tile.sh mywork
#:   ./tile.sh mywork --width 1200 --height 900 --tile 35
#:   ./tile.sh mywork --min-height 10 --max-height 80 --seed 7
#:
#: NOTES
#:   All output files are saved in the current working directory.
#:   The .html files are fully self-contained (Plotly bundled inline) —
#:   just open them in a browser; no web server is required.
#:   The virtual environment is expected at .venv/ inside the project root.
#: ───────────────────────────────────────────────────────────────────────────────

set -euo pipefail

## ── Locate the script's own directory (project root) ──────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

## ── Python interpreter inside the uv venv ─────────────────────────────────
PYTHON="${SCRIPT_DIR}/.venv/bin/python"
if [[ ! -x "${PYTHON}" ]]; then
    PYTHON="${SCRIPT_DIR}/.venv/Scripts/python.exe"
fi
if [[ ! -x "${PYTHON}" ]]; then
    echo "ERROR: Python interpreter not found." >&2
    echo "       Run 'uv venv' and 'uv pip install -e .' in the project root first." >&2
    exit 1
fi

## ── Display help when called with no arguments ─────────────────────────────
if [[ $# -eq 0 ]]; then
    grep '^#:' "${BASH_SOURCE[0]}" | sed 's,#:,,'
    exit 0
fi

## ── Parse execution name ───────────────────────────────────────────────────
if [[ "${1}" == --* ]]; then
    echo "ERROR: Missing required <execution_name> argument." >&2
    echo "       Run './tile.sh' with no arguments to see usage." >&2
    exit 1
fi
NAME="${1}"; shift

## ── Defaults ───────────────────────────────────────────────────────────────
WIDTH=800
HEIGHT=600
TILE=40
MIN_H=20
MAX_H=120
MAX_TILT=25
GAP=2
SEED=42

## ── Parse options ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --width)      WIDTH="${2}";    shift 2 ;;
        --height)     HEIGHT="${2}";   shift 2 ;;
        --tile)       TILE="${2}";     shift 2 ;;
        --min-height) MIN_H="${2}";    shift 2 ;;
        --max-height) MAX_H="${2}";    shift 2 ;;
        --max-tilt)   MAX_TILT="${2}"; shift 2 ;;
        --gap)        GAP="${2}";      shift 2 ;;
        --seed)       SEED="${2}";     shift 2 ;;
        *) echo "ERROR: Unknown option: $1" >&2
           echo "       Run './tile.sh' with no arguments to see usage." >&2
           exit 1 ;;
    esac
done

## ── Report settings ────────────────────────────────────────────────────────
echo "============================================================"
echo "  Aperiodic Hat Tiling  →  ${NAME}"
echo "============================================================"
echo "  Canvas : ${WIDTH} × ${HEIGHT} px  |  tile=${TILE}  gap=${GAP}"
echo "  Heights: ${MIN_H} – ${MAX_H} px  |  tilt≤${MAX_TILT}°  seed=${SEED}"
echo ""

## ── Run the full pipeline in one Python call ───────────────────────────────
MPLBACKEND=Agg "${PYTHON}" - <<PYEOF
import json, sys
sys.path.insert(0, '${SCRIPT_DIR}')
from aperiodic_tiles import fill_canvas, assign_tile_heights, render_canvas, render_panel

## 1. Generate 2-D tiling layout
print("[1/4] Generating aperiodic tiling layout …")
canvas = fill_canvas(
    width=${WIDTH}, height=${HEIGHT},
    tile_size=${TILE},
    gap=${GAP},
)
n = len(canvas['tiles'])
print(f"      {n} tiles placed")

canvas_json = 'exec.${NAME}.canvas.json'
with open(canvas_json, 'w') as f:
    json.dump(canvas, f, indent=2)
print(f"      Saved: {canvas_json}")

## 2. Render 2-D canvas to HTML
print("[2/4] Rendering 2-D canvas …")
canvas_html = 'exec.${NAME}.canvas.html'
render_canvas(canvas, show=False, save_path=canvas_html)
print(f"      Saved: {canvas_html}")

## 3. Assign random heights
print("[3/4] Assigning random heights …")
panel = assign_tile_heights(
    canvas,
    min_height=${MIN_H},
    max_height=${MAX_H},
    max_tilt_deg=${MAX_TILT},
    seed=${SEED},
)
avg_h = sum(t['height'] for t in panel['tiles']) / max(len(panel['tiles']), 1)
print(f"      Average height: {avg_h:.1f} px")

panel_json = 'exec.${NAME}.panel.json'
with open(panel_json, 'w') as f:
    json.dump(panel, f, indent=2)
print(f"      Saved: {panel_json}")

## 4. Render 3-D panel to HTML
print("[4/4] Rendering 3-D panel …")
panel_html = 'exec.${NAME}.panel.html'
render_panel(panel, show=False, save_html=panel_html)
print(f"      Saved: {panel_html}")

print()
print("Done.  Open the HTML files in any browser — no server needed.")
PYEOF
