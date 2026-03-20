"""
main.py
=======
Demo / entry-point script for the Aperiodic Hat Tiling application.

Run with:
    uv run python main.py

Or activate the virtual environment first:
    source .venv/bin/activate
    python main.py

Command-line options
--------------------
  --width    INT   Canvas width in pixels   (default: 800)
  --height   INT   Canvas height in pixels  (default: 600)
  --tile     FLOAT Tile size in pixels      (default: 40)
  --min-h    FLOAT Min extrusion height     (default: 20)
  --max-h    FLOAT Max extrusion height     (default: 120)
  --seed     INT   Random seed              (default: 42)
  --no-2d         Skip the 2-D render
  --no-3d         Skip the 3-D render
  --save-2d  PATH  Save 2-D image to file
  --save-3d  PATH  Save 3-D model to HTML file

Examples
--------
  python main.py
  python main.py --width 1200 --height 900 --tile 30
  python main.py --save-2d tiling.png --save-3d panel.html --no-2d --no-3d
"""

import argparse
import json
import sys

from aperiodic_tiles import fill_canvas, assign_tile_heights, render_canvas, render_panel


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Aperiodic Hat Tile demo",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument("--width",   type=float, default=800,  help="Canvas width (px)")
    p.add_argument("--height",  type=float, default=600,  help="Canvas height (px)")
    p.add_argument("--tile",    type=float, default=40.0, help="Tile size (px)")
    p.add_argument("--min-h",   type=float, default=20.0, help="Min tile height")
    p.add_argument("--max-h",   type=float, default=120.0,help="Max tile height")
    p.add_argument("--seed",    type=int,   default=42,   help="Random seed")
    p.add_argument("--no-2d",   action="store_true",      help="Skip 2-D render")
    p.add_argument("--no-3d",   action="store_true",      help="Skip 3-D render")
    p.add_argument("--save-2d", type=str,   default=None, help="Save 2-D PNG/SVG")
    p.add_argument("--save-3d", type=str,   default=None, help="Save 3-D HTML")
    p.add_argument("--dump-json", type=str, default=None,
                   help="Dump canvas JSON to file (for inspection)")
    return p.parse_args()


def main() -> None:
    args = parse_args()

    print("=" * 60)
    print("  Aperiodic Hat Tiling")
    print("=" * 60)
    print(f"  Canvas : {args.width} × {args.height} px")
    print(f"  Tile   : {args.tile} px")
    print(f"  Heights: {args.min_h} – {args.max_h} px  (seed={args.seed})")
    print()

    # ── 1. Generate the 2-D tiling layout ───────────────────────────────────
    print("[1/3] Generating aperiodic tiling layout …")
    canvas = fill_canvas(
        width=args.width,
        height=args.height,
        tile_size=args.tile,
    )
    n_tiles = len(canvas["tiles"])
    n_reflected = sum(1 for t in canvas["tiles"] if t["reflected"])
    print(f"      {n_tiles} tiles placed  "
          f"({n_tiles - n_reflected} normal, {n_reflected} reflected)")

    if args.dump_json:
        with open(args.dump_json, "w") as fh:
            json.dump(canvas, fh, indent=2)
        print(f"      Canvas JSON saved to {args.dump_json}")

    # ── 2. Assign heights to produce the 3-D panel ──────────────────────────
    print("[2/3] Assigning random heights and slant vectors …")
    panel = assign_tile_heights(
        canvas=canvas,
        min_height=args.min_h,
        max_height=args.max_h,
        max_tilt_deg=25.0,
        seed=args.seed,
    )
    avg_h = sum(t["height"] for t in panel["tiles"]) / max(len(panel["tiles"]), 1)
    print(f"      Average height: {avg_h:.1f} px")

    # ── 3a. 2-D render ───────────────────────────────────────────────────────
    if not args.no_2d or args.save_2d:
        print("[3/3] Rendering 2-D canvas …")
        render_canvas(
            canvas=canvas,
            show=not args.no_2d,
            save_path=args.save_2d,
        )

    # ── 3b. 3-D render ───────────────────────────────────────────────────────
    if not args.no_3d or args.save_3d:
        print("[3/3] Rendering 3-D panel (opens browser) …")
        render_panel(
            panel=panel,
            show=not args.no_3d,
            save_html=args.save_3d,
        )

    print()
    print("Done.")


if __name__ == "__main__":
    main()
