# Aperiodic Hat Tiling

Generate and render aperiodic **Einstein "hat" tile** patterns — both as
interactive 2-D canvases and fully-rotatable 3-D extruded panels — with a
single command.

---

## What is an aperiodic tiling?

An aperiodic tiling covers the plane with one or more tile shapes such that
the pattern never repeats by translation.  The **hat tile** (formally
*Tile(1,1)*), discovered in 2023, is the first single shape — an "Einstein"
tile — that tiles the plane aperiodically and only aperiodically.

---

## Features

- **Aperiodic layout** — hat tiles are placed using a hex-grid / kite-assembly
  algorithm with a Z3 SAT solver to guarantee a non-overlapping, gap-free tiling
- **2-D render** — interactive Plotly HTML canvas or a Matplotlib PNG/SVG
- **3-D render** — fully interactive Plotly 3-D panel with per-tile extruded
  heights and tilted top faces; rotate, zoom and pan freely in any browser
- **Self-contained HTML output** — Plotly is bundled inline; no web server needed
- **Reproducible** — a `--seed` flag controls all random height/tilt assignments
- **Single-command workflow** — `tile.sh` runs the entire pipeline in one shot

---

## Project layout

```
AperiodicTiles/
├── tile.sh                        # Single-command pipeline (recommended entry point)
├── main.py                        # Python entry point with CLI flags
├── pyproject.toml                 # Project metadata and dependencies
├── requirements.txt               # Original natural-language specification
├── aperiodic_tiles/
│   ├── __init__.py                # Public API exports
│   ├── hat_tiling.py              # Hat-tile geometry + Z3 SAT placement
│   ├── fill_canvas.py             # fill_canvas() — 2-D layout generator
│   ├── assign_tile_heights.py     # assign_tile_heights() — adds 3-D heights
│   ├── render_canvas.py           # render_canvas() — 2-D Matplotlib/Plotly render
│   └── render_panel.py            # render_panel() — 3-D Plotly render
└── documentation/
    └── windows-msys2-setup.md     # Windows / MSYS2 setup guide
```

---

## Requirements

- Python ≥ 3.13
- [`uv`](https://github.com/astral-sh/uv) (virtual environment / package manager)

Python dependencies (managed automatically by `uv`):

| Package | Purpose |
|---|---|
| `numpy` | Array maths, polygon geometry |
| `matplotlib` | 2-D figure rendering, PNG/SVG output |
| `plotly` | Interactive 2-D and 3-D HTML output |
| `z3-solver` | SAT solver for non-overlapping tile selection |
| `svgpathtools` | SVG path utilities |

---

## Installation

```bash
# 1. Create the virtual environment
uv venv

# 2. Install the project and all dependencies
uv pip install -e .
```

---

## Quick start — `tile.sh`

```bash
# Show usage / help
./tile.sh

# Generate a tiling named "mywork" with default settings
./tile.sh mywork

# Custom canvas, tile size, and seed
./tile.sh mywork --width 1200 --height 900 --tile 35

# Fine-tune the 3-D panel heights
./tile.sh mywork --min-height 10 --max-height 80 --max-tilt 15 --seed 7
```

Four files are produced in the current directory:

| File | Description |
|---|---|
| `exec.<name>.canvas.json` | 2-D tiling layout (tile vertices in pixel coords) |
| `exec.<name>.canvas.html` | Interactive 2-D render — open in any browser |
| `exec.<name>.panel.json`  | 3-D panel layout (vertices + heights + slants) |
| `exec.<name>.panel.html`  | Interactive 3-D render — open in any browser |

### `tile.sh` options

| Option | Default | Description |
|---|---|---|
| `--width FLOAT` | 800 | Canvas width in pixels |
| `--height FLOAT` | 600 | Canvas height in pixels |
| `--tile FLOAT` | 40 | Tile size (hex-lattice unit) in pixels |
| `--min-height FLOAT` | 20 | Minimum tile extrusion height |
| `--max-height FLOAT` | 120 | Maximum tile extrusion height |
| `--max-tilt FLOAT` | 25 | Maximum top-face tilt in degrees |
| `--gap FLOAT` | 2 | Gap between adjacent tiles in pixels |
| `--seed INT` | 42 | Random seed for reproducible height assignments |

---

## Alternative — `main.py`

```bash
# Show/hide interactive windows directly
uv run python main.py
uv run python main.py --width 1200 --height 900 --tile 30

# Save outputs without opening windows
uv run python main.py --no-2d --no-3d --save-2d tiling.png --save-3d panel.html

# Dump the canvas layout to JSON for inspection
uv run python main.py --no-2d --no-3d --dump-json canvas.json
```

### `main.py` options

| Option | Default | Description |
|---|---|---|
| `--width FLOAT` | 800 | Canvas width in pixels |
| `--height FLOAT` | 600 | Canvas height in pixels |
| `--tile FLOAT` | 40 | Tile size in pixels |
| `--min-h FLOAT` | 20 | Min extrusion height |
| `--max-h FLOAT` | 120 | Max extrusion height |
| `--seed INT` | 42 | Random seed |
| `--no-2d` | — | Skip the 2-D Matplotlib window |
| `--no-3d` | — | Skip the 3-D Plotly window |
| `--save-2d PATH` | — | Save 2-D figure to PNG or SVG |
| `--save-3d PATH` | — | Save 3-D panel to HTML |
| `--dump-json PATH` | — | Dump canvas JSON to file |

---

## How it works

### 1. Tile generation — `hat_tiling.py`

1. A hex grid of hexagon centres is constructed.
2. Each hexagon is divided into 6 **kite** shapes.
3. **Hat tiles** are assembled from 8 kites each, in 12 orientations
   (6 rotations × 2 chiralities).
4. A **Z3 SAT solver** selects a non-overlapping, gap-free subset:
   - *At most one* hat tile may occupy any shared kite centre.
   - *At least one* hat tile must occupy every fully-contested kite centre.
5. The boundary polygon of each chosen tile is traced and converted to pixel
   coordinates, scaled and centred on the requested canvas.

### 2. Canvas layout — `fill_canvas.py`

Wraps `generate_hat_tiling()`, filters tiles to a generous canvas margin, and
optionally shrinks each tile polygon toward its centroid to produce a pixel
gap between neighbours.  Returns a **canvas dict** describing every tile's
vertex coordinates.

### 3. Height assignment — `assign_tile_heights.py`

Takes the canvas dict and adds a random extrusion **height** and a **slant
vector** (unit normal of the top face) to each tile.  Heights are drawn
uniformly from `[min_height, max_height]`; the top-face tilt is a random
rotation of the vertical by up to `max_tilt_deg` degrees.

### 4. 2-D render — `render_canvas.py`

Draws all tile polygons using Matplotlib (`PatchCollection`) with alternating
blue / orange colour palettes.  Can display an interactive window or save to
PNG, SVG, or a Plotly interactive HTML file.

### 5. 3-D render — `render_panel.py`

Extrudes each tile into a prism using `go.Mesh3d`:
- **Bottom face** — hat polygon at z = 0
- **Top face** — same polygon lifted by `height` and tilted by `slant`
- **Side walls** — quad strips connecting bottom and top edges

Colour is height-proportional within the blue/orange palette.  The Plotly
figure opens in the default browser and supports free rotation, zoom, and pan.

---

## Windows / MSYS2

See **[documentation/windows-msys2-setup.md](documentation/windows-msys2-setup.md)**
for a step-by-step guide.  The Python code is fully cross-platform; only a
one-line fix to `tile.sh` is needed to handle the Windows virtual environment
path layout.

---

## License

See repository for license details.
