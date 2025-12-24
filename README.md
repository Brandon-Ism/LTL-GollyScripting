# LTL-GollyScripting

A collection of **Golly** Lua scripts (plus a couple helper tools) to support research and exploration of **Larger Than Life (LTL)** cellular automata: drawing/erasing geometric shapes, exporting boundaries/coordinates to CSV, generating/searching initial configurations, and visualizing/quantifying “jitter bugs”.

## Citation / Published papers

If you use this repository (or derived scripts) in academic work, please **cite the relevant paper(s)** below and/or cite this repo.

- **Published papers**:
  - B. Ismalej, K. M. Evans, “Automating Large-Scale Detection and Classification of Larger Than Life Cellular Automata Patterns”. 2025 IEEE 15th Annual Computing and Communication Workshop and Conference (CCWC), Jan 6-8, 2025, Las Vegas, NV, USA. [10.1109/CCWC62904.2025.10903710](10.1109/CCWC62904.2025.10903710)
- **Repository citation**:
  - Brandon Ismalej, *LTL-GollyScripting*, GitHub repository. 2023. [https://github.com/Brandon-Ism/LTL-GollyScripting](https://github.com/Brandon-Ism/LTL-GollyScripting)

## Table of contents

- [LTL-GollyScripting](#ltl-gollyscripting)
  - [Citation / Published papers](#citation--published-papers)
  - [Table of contents](#table-of-contents)
  - [Quick start](#quick-start)
  - [Script catalog](#script-catalog)
    - [Rectangle drawing / erasing](#rectangle-drawing--erasing)
    - [Circle / ellipse drawing / erasing](#circle--ellipse-drawing--erasing)
    - [Bug boundary capture + CSV pipeline](#bug-boundary-capture--csv-pipeline)
    - [Configuration generation / automation / search](#configuration-generation--automation--search)
    - [Visualization + image export](#visualization--image-export)
    - [Jitter bug analysis](#jitter-bug-analysis)
    - [Pattern detection](#pattern-detection)
    - [Browser tools](#browser-tools)
  - [Contributing](#contributing)
  - [License](#license)

## Quick start

- **Run in Golly**:
  - Put this repo (or selected `.lua` scripts) somewhere convenient.
  - In Golly, run a script via **File → Run Script…** (or your preferred workflow).
- **Selections matter**:
  - Several scripts require a selection created with Golly’s **Select** tool (e.g. boundary capture, overlays, PNG export).
- **Outputs**:
  - CSV exports are typically written either to a fixed filename in the script (e.g. `boundary_points.csv`) or into `g.getdir("app")` (Golly’s app directory), depending on the script.

## Script catalog

### Rectangle drawing / erasing

- **`RectangleScripts/DrawRectangle.lua`**: Draw a filled **live (1)** rectangle by clicking opposite corners (no live preview).
- **`RectangleScripts/DrawRectangleWithErase.lua`**: Draw a filled **live (1)** rectangle by clicking opposite corners with a **live preview** (preview may overwrite cells while moving).
- **`RectangleScripts/DrawRectangle-Menu.lua`**: Menu-driven filled **live (1)** rectangle tool: click-and-preview **or** enter coordinates/dimensions.
- **`RectangleScripts/DrawRectangleWithOutline-Menu.lua`**: Menu-driven rectangle tool: draw filled rectangle **or** rectangle outline using **live (1)** cells.
- **`RectangleScripts/EraseRectangleWithOutline-Menu.lua`**: Menu-driven rectangle tool that “erases” using **dead (0)** cells: draw filled rectangle **or** rectangle outline.

### Circle / ellipse drawing / erasing

- **`CircleScripts/DrawCircle-Menu.lua`**: Menu-driven circle tool using **live (1)** cells: filled circle **or** ring; click-to-define radius with live preview **or** enter center/radius.
- **`CircleScripts/EraseCircle-Menu.lua`**: Same UI as above, but draws using **dead (0)** cells (i.e., erase-filled-circle or erase-ring).
- **`CircleScripts/DrawEllipse-Menu.lua`**: Menu-driven ellipse tool using **live (1)** cells: filled ellipse **or** outline; click-to-define axes with live preview **or** enter center/axes.
- **`CircleScripts/EraseEllipse-Menu.lua`**: Same UI as above, but draws using **dead (0)** cells (i.e., erases an ellipse region/outline).

### Bug boundary capture + CSV pipeline

These scripts are commonly used together to capture the **inner/outer boundary** of an LTL “bug” and export a boundary in a useful ordering.

- **`CaptureBugBoundary/BoundaryCellCapture.lua`**: From a **selected region**, identify **boundary cells** and write them to a CSV (default: `boundary_points.csv`).
- **`CaptureBugBoundary/CSVplot.lua`**: Plot (x,y) points from a chosen CSV file onto the Golly grid as **live (1)** cells.
- **`CaptureBugBoundary/CSVcenter_plot.lua`**: Like `CSVplot.lua`, but also computes the centroid and **centers the plotted coordinates about (0,0)**.
- **`CaptureBugBoundary/CaptureLiveCellstoCSV.lua`**: Export all **live (1)** cell coordinates inside a selection to `live_cells.csv`.
- **`CaptureBugBoundary/CaptureLiveCellstoCSV_AngularSort.lua`**: Export **edge cells** from a selection and write them **sorted clockwise** by angle to the shape’s center (default output: `sorted_live_cells.csv`).

For the full step-by-step workflow (including where to edit file paths/names), see:
- **`CaptureBugBoundary/README.md`**

### Configuration generation / automation / search

These scripts generate and/or search initial “live sites” vs “dead sites” configurations (often parameterized by circles/ellipses/rectangles and setbacks), and write results to CSV for later analysis.

If you use tools from this section in your work, please cite the following paper: 
> B. Ismalej, K. M. Evans, “Automating Large-Scale Detection and Classification of Larger Than Life Cellular Automata Patterns”. 2025 IEEE 15th Annual Computing and Communication Workshop and Conference (CCWC), Jan 6-8, 2025, Las Vegas, NV, USA.

- **`Configurations/Configuration_Generator.lua`**: Interactive generator to place many initial configurations on a grid (user chooses counts, spacing, shapes, dimensions, etc.).
- **`Configurations/Configuration_Automation.lua`**: Automates generation across **ranges** of parameters and writes results to a CSV (includes spacing, live/dead shapes, setbacks, etc.).
- **`Configurations/Configuration_Search_and_Classify.lua`**: Larger search/classification pipeline:
  - Prompts for a rule/time horizon and parameter ranges.
  - Generates many configurations, simulates them for a fixed number of time steps, and records measurements to CSV.
  - Includes logic to estimate period/displacement for patterns.
- **`Configurations/CSV_Configurator_Importer.lua`**: Reads a CSV of configuration parameters and places those configurations onto the grid.

### Visualization + image export

- **`ImageScripts/Color_Step_Overlay.lua`**: Visualize cell age by applying user-defined colors over time using an overlay. Works on a selected region and supports saving the overlay as a PNG.  
  - Note: the current script includes logic to create a toroidal universe from the selection (see in-script prompts/behavior).
- **`ImageScripts/savePNG.lua`**: Save the current **selected** region as a PNG using an overlay, with user-defined RGB for live vs dead cells.
- **`ImageScripts/RGB Color Picker - WebApp/RGB Color Selector.html`**: Small browser UI to pick RGB values and save swatches (handy for building palettes for overlay scripts).

### Jitter bug analysis

- **`Jitter_Bugs/JitterFactor.lua`**: Measures a selected “jitter bug”-like pattern by:
  - Centralizing the pattern’s centroid at (0,0),
  - Estimating period + displacement,
  - Computing a **jitter factor** based on centroid distance from the line of displacement over a cycle,
  - Writing a CSV (default: `jitter_bug_data.csv` in `g.getdir("app")`) including centroid trajectory.
- **`Jitter_Bugs/plot_jitter.py`**: Python helper to plot the centroid path from a `jitter_bug_data.csv`-style export (creates PNGs and opens them using `feh`).

### Pattern detection

- **`ReplicatorDetect.lua`**: Experimental detector that advances the simulation and hashes connected clusters to flag a “possible replicator” if a cluster hash repeats within the checked window (default loop: 100 generations).

### Browser tools

- **`tools/jitter-centroid-plot-tool/`**: A lightweight, client-side plotting tool (HTML/JS + Plotly) to drag-and-drop a CSV and quickly visualize **Centroid X/Y** in the browser, with a “Download plot as PNG” button.

  - **Try it live:** https://brandon-ism.github.io/LTL-GollyScripting/jitter-centroid-plot-tool/

## Contributing

Thanks for your interest. External contributions aren’t being accepted right now while the scripts evolve alongside ongoing research. If you have ideas or issues, please open an issue.

## License

MIT, see `LICENSE`.
