"""
Aperiodic Tiles Package
=======================
Functions for generating and rendering aperiodic tilings using the
Einstein "hat" tile (Tile(1,1)).
"""

from .fill_canvas import fill_canvas
from .assign_tile_heights import assign_tile_heights
from .render_canvas import render_canvas
from .render_panel import render_panel

__all__ = ["fill_canvas", "assign_tile_heights", "render_canvas", "render_panel"]
