# Running AperiodicTiles on Windows with MSYS2

This guide walks you through installing and running the Aperiodic Hat Tiling
application on Windows using **MSYS2** (a Unix-like environment that provides
bash, GNU tools, and a pacman package manager).

---

## Prerequisites

- Windows 10 or 11 (64-bit)
- [MSYS2](https://www.msys2.org/) installed (use the **MINGW64** shell)

---

## 1 — Install MSYS2

1. Download the installer from <https://www.msys2.org/>
2. Run the installer and accept the defaults (default path: `C:\msys64`)
3. After installation, open the **MSYS2 MINGW64** terminal
   (Start → MSYS2 → MSYS2 MINGW64)
4. Update the package database:

```bash
pacman -Syu
```

Close the terminal when asked, then re-open it and run:

```bash
pacman -Su
```

---

## 2 — Install `uv`

`uv` is the package / virtual-environment manager used by this project.
Install the pre-built Windows binary from the MSYS2 shell:

```bash
# Download and run the official installer script
curl -LsSf https://astral.sh/uv/install.sh | sh
```

After the script completes, restart the terminal (or `source ~/.bashrc`) so
that `uv` is on your `PATH`.  Verify:

```bash
uv --version
```

> **Alternative:** download the `.exe` from
> <https://github.com/astral-sh/uv/releases> and place it somewhere on your
> `PATH` (e.g. `C:\msys64\usr\local\bin\`).

---

## 3 — Clone / obtain the project

```bash
# Example — adjust the URL or path to wherever your repo lives
git clone <your-repo-url> /c/projects/AperiodicTiles
cd /c/projects/AperiodicTiles
```

Or simply `cd` to the directory if you already have it:

```bash
cd /c/projects/AperiodicTiles   # adjust path as needed
```

---

## 4 — Create the virtual environment and install dependencies

```bash
uv venv
uv pip install -e .
```

`uv` on Windows places the Python interpreter at:

```
.venv/Scripts/python.exe        ← Windows layout
```

rather than the Linux layout:

```
.venv/bin/python                ← Linux layout
```

This matters for the next step.

---

## 5 — Fix `tile.sh` for the Windows venv path

Open `tile.sh` in your editor and find this block (around line 44):

```bash
PYTHON="${SCRIPT_DIR}/.venv/bin/python"
if [[ ! -x "${PYTHON}" ]]; then
    echo "ERROR: Python interpreter not found at ${PYTHON}" >&2
    ...
    exit 1
fi
```

Replace it with the following so the script finds the interpreter on both
Linux and Windows:

```bash
PYTHON="${SCRIPT_DIR}/.venv/bin/python"
if [[ ! -x "${PYTHON}" ]]; then
    PYTHON="${SCRIPT_DIR}/.venv/Scripts/python.exe"
fi
if [[ ! -x "${PYTHON}" ]]; then
    echo "ERROR: Python interpreter not found." >&2
    echo "       Run 'uv venv' and 'uv pip install -e .' in the project root first." >&2
    exit 1
fi
```

---

## 6 — Run the application

### Using `tile.sh` (recommended)

```bash
bash tile.sh mywork
bash tile.sh mywork --width 1200 --height 900 --tile 35
bash tile.sh mywork --min-height 10 --max-height 80 --seed 7
```

Output files are written to the current directory:

| File | Description |
|---|---|
| `exec.mywork.canvas.json` | 2-D tiling layout data |
| `exec.mywork.canvas.html` | Interactive 2-D render (open in browser) |
| `exec.mywork.panel.json`  | 3-D panel layout data |
| `exec.mywork.panel.html`  | Interactive 3-D render (open in browser) |

Open the `.html` files in any browser — no web server is required.

### Using `main.py` directly

```bash
.venv/Scripts/python.exe main.py
.venv/Scripts/python.exe main.py --width 1200 --height 900 --tile 30
.venv/Scripts/python.exe main.py --no-2d --save-3d panel.html
```

> `main.py` with `--no-2d` skips the Matplotlib window (which requires a
> display), making it the safest option in a headless MSYS2 session.

---

## 7 — Matplotlib display (optional)

When `main.py` is run **without** `--no-2d`, it tries to open a Matplotlib
GUI window.  Under MSYS2 this requires a native Windows backend.

**Option A — suppress the window (simplest)**

```bash
MPLBACKEND=Agg .venv/Scripts/python.exe main.py --save-2d tiling.png --no-2d
```

**Option B — use the TkAgg backend**

Install Tk support:

```bash
pacman -S mingw-w64-x86_64-python-tkinter
```

Then run normally; Matplotlib will find Tk automatically.

> `tile.sh` already sets `MPLBACKEND=Agg`, so it is never affected by
> this issue.

---

## 8 — Plotly 3-D rendering

`render_panel()` calls `fig.show()`, which uses Python's built-in
`webbrowser` module to open the generated HTML in your default browser.
This works out of the box on Windows as long as a default browser is
registered in Windows settings.

Alternatively, just open the saved `.html` file manually in any browser.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `ERROR: Python interpreter not found` | Windows venv path not found | Apply the `tile.sh` fix in §5 |
| `ModuleNotFoundError` | Dependencies not installed | Run `uv pip install -e .` |
| Matplotlib window does not open | No GUI backend | Use `MPLBACKEND=Agg` or install Tk (§7) |
| `uv: command not found` | `uv` not on PATH | Re-open terminal or add install dir to PATH |
| Garbled paths in Python heredoc | MSYS2 POSIX paths passed to Windows Python | Use `cygpath -w "${SCRIPT_DIR}"` in the heredoc if needed |

---

## Summary of changes required

Only **one code change** is needed to run on Windows under MSYS2:

- **`tile.sh`** — add a fallback to `.venv/Scripts/python.exe` (§5 above).

All Python source files (`main.py`, `aperiodic_tiles/`) and all dependencies
are fully cross-platform and require no changes.
