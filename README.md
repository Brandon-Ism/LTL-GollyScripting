# LTL-GollyScripting

The purpose of these scripts are to assist a professor in their research of _Larger Than Life_ cellular automata. They serve as tools to manipulate cells on the 2 dimensional grid within the _Golly_ software. These scripts were written in Lua to be tailored for use within the Golly software environment.

## Table of Contents

- [LTL-GollyScripting](#ltl-gollyscripting)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
    - [About Golly](#about-golly)
    - [Purpose of the Scripts](#purpose-of-the-scripts)
    - [Key Features](#key-features)
  - [Installation](#installation)
  - [Scripts](#scripts)
  - [Contributing](#contributing)
  - [Licensing](#licensing)

## Introduction

Welcome to the LTL-GollyScripting! This repository contains a collection of Lua scripts specially tailored for use with the Golly software. These scripts are designed to assist mathematicians, researchers, and enthusiasts in exploring and conducting research on Larger Than Life cellular automata within the Golly environment.

### About Golly

[Golly](https://golly.sourceforge.io/) is a powerful and versatile open-source software for simulating and exploring cellular automata. It provides a rich set of features and tools for experimenting with various automaton rules and patterns.

### Purpose of the Scripts

The Lua scripts included in this repository serve various purposes, from creating specific patterns to capturing elements of certain cellular automaton. They leverage the Golly software's Lua scripting capabilities to make these tasks more efficient and accessible.

### Key Features

- **Feature 1:** One of the core features of this collection of Lua scripts is the set of tools that empower users to create and manipulate shapes within the Golly environment. These tools enable users to draw and erase various geometric shapes, including squares, rectangles, circles, and rings, using live (1) and dead (0) cells.
- **Feature 2:** `<i>`Boundary Capture and Export for "Bugs"`</i>`: This feature is a powerful set of three Lua scripts that work collaboratively to capture and export the inner or outer boundary coordinates of a "bug" within the Larger Than Life cellular automata. The primary goal is to facilitate in-depth analysis, mathematical computations, and research on these complex automata patterns.

Whether you're a seasoned Golly user or just starting to explore the world of cellular automata, these scripts aim to simplify your workflow and enhance your research experience.

**Note:** These scripts are specifically designed to work within the Golly environment, utilizing Golly's Lua libraries. They may not function correctly in other Lua environments.

## Installation

To get started with these Lua scripts tailored for Golly, follow these steps:

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/Brandon-Ism/LTL-GollyScripting
   cd LTL-GollyScripting
   ```
2. Store the Scripts in the Golly Folder (Recommended):

   For the most convenient access and usability, consider storing these scripts in the same directory as your Golly software installation. This ensures that Golly can easily locate and run the scripts when you need them.
3. Launch Golly
   Start or restart Golly to make sure it recognizes the newly added scripts.
4. Use the Scripts:
   You can now use these Lua scripts within Golly to draw shapes, capture bug boundaries, or perform other tasks as needed. Refer to the [Usage](#usage) section in this README and the individual script documentation for instructions on how to use them effectively.

## Scripts

* `<b>`DrawRectangle.lua`</b>`: Allows user to draw a rectangle of live(1) cells by clicking opposite corners on grid.
* `<b>`DrawRectangle-Menu.lua`</b>`: Presents user with options to draw(1) a solid rectangle: clicking 2 opposite corners with live cell preview OR inputting vertices/dimensions of rectangle.
* `<b>`DrawRectangleWithErase.lua`</b>`: Allows user to draw(1) a rectangle, with a live cell preview, by clicking two opposite corners. The live cell preview will overwrite existing live(1) cells on the grid.
* `<b>`DrawRectangleWithOutline-Menu.lua`</b>`: Presents user with options to draw (live cells(1)) a rectangle: clicking 2 opposite corners with live cell preview OR inputting vertices/dimensions of rectangle.
* `<b>`EraseRectangleWithOutline-Menu.lua`</b>`: Presents user with options to draw (dead cells (0)) a rectangle outline: clicking 2 opposite corners with live cell preview OR inputting vertices/dimensions of rectangle.
* `<b>`DrawCircle-Menu.lua`</b>`: Presents user with options to draw (live (1)) a filled circle or unfilled circle (ring): selecting center and dragging to radius length OR inputting center coordinates (x,y), and inputting radius length.
* `<b>`EraseCircle-Menu.lua`</b>`: Presents user with options to draw (dead (0)) a filled circle or unfilled circle (ring): selecting center and dragging to radius length OR inputting center coordinates (x,y), and inputting radius length.
* `<b>`Capture_Bug_Boundary`</b>`: These three scripts, when used together, allow the user to capture and export inner and/or outer boundary cell coordinates to a csv file, of `<i>`Larger than Life "bugs"`</i>`. The .txt file contained within this directory provide a detailed guide to the use of these scripts for this desired purpose.

## Contributing

Thank you for your interest in contributing to this repository. As of now, I am not accepting external contributions. Some of these scripts are actively under development and are part of collaborative work with my professor at California State University, Northridge.

**Why?**

The decision to limit contributions at this time is to maintain the integrity and focus of the ongoing research and development efforts.

**How You Can Help**

While external contributions are not being accepted at this moment, your interest is greatly appreciated. If you have suggestions, feedback, or ideas for improvements, please feel free to open an issue in this repository. Your feedback can be valuable and may influence the direction of future development.

Additionally, if you are interested in collaborating or have specific inquiries related to the scripts or our research, you can reach out via brandonDOTismalejDOT671ATmyDOTcsunDOTedu .

Thank you for your understanding and support in our efforts to advance the study of Larger Than Life cellular automata.

## Licensing

This project is licensed under the MIT License - see the LICENSE.md file for details.
