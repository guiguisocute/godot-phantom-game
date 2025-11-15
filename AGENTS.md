# Repository Guidelines

## Project Structure & Module Organization
The Godot project root contains `project.godot`, shared audio routing in `default_bus_layout.tres`, and export options in `export_presets.cfg`. Gameplay lives in `src/`, grouped by feature: `character/player` and `character/phantom` hold playable actors plus their `states/`, `level/` stores the main scenes such as `level1.tscn`, `ui/` covers HUD and menus, `state_machine/` keeps reusable logic, and `special_stuff/` owns interactables (buttons, spikes, ladders, destinations). `autoload/` exposes singleton scripts like `game.gd`. Keep feature-specific assets beside their scripts; place long-form notes or mockups under `doc/`, and raw art/audio drops inside `freeasset/` or `my_game_art/` so version control stays predictable.

## Build, Test, and Development Commands
- `godot4 --editor --path .` - opens the 4.5 project, regenerates import caches, and lets you edit scenes/resources.
- `godot4 --run src/level/level1.tscn --path .` - launches the current playable level without entering the editor; change the scene path when prototyping other timelines or menu flows.
- `godot4 --headless --run src/timeline_controler/timeline_controler.tscn --path .` - verifies timeline scripts without rendering, which is useful for CI smoke checks.
- `godot4 --export-debug "Windows Desktop" build/win/goldengoat.exe` - builds a desktop package using the provided export preset; ensure the target folder exists first.

## Coding Style & Naming Conventions
Scripts use GDScript 4.5 with 4-space indentation, trailing commas on multiline arrays, and snake_case for functions, signals, and file names (`die_from_spite.gd`). Classes, nodes, and exported enums follow PascalCase to match the node tree (`Player`, `TimelineControler`). Mirror scene and script names (`player.tscn` with `player.gd`) and keep state scripts inside a `states/` child directory. Run Godot's built-in formatter (Ctrl+Shift+F in the script editor) before committing larger API changes so autocompletion data stays fresh.

## Testing Guidelines
No automated suite exists yet, so add lightweight verification scenes under `src/tests/` or alongside the feature being exercised. Name scenes `something_test.tscn` and pair them with scripts ending in `_test.gd`. Smoke-test headlessly via `godot4 --headless --run res://src/tests/<scene>.tscn --path .` and document required inputs inside the scene description. Before opening a PR, at least launch `level1.tscn` plus any modified feature scenes to catch signal or animation regressions.

## Commit & Pull Request Guidelines
Recent history mixes English and Chinese summaries with prefixes such as `feat: ...`, `add ...`, and occasional `test`. Keep the short line under 60 characters, start with a lowercase imperative verb, and add the language that best describes the change. Multi-step work should be split per feature (e.g., `feat: add phantom ladder climb`). PRs must include: a short description of behavior changes, linked course issue or task ID, reproduction steps, screenshots or GIFs for UI tweaks, and a checklist confirming the commands above were run. Request at least one teammate review and avoid force pushes once review starts.

## Configuration Tips
The `.godot/` directory contains editor cache files; avoid touching them manually. Audio routing edits belong in `default_bus_layout.tres`, and new exports must be registered in `export_presets.cfg` before automation can use them. Keep large binaries in Git LFS if they exceed 50 MB, and prefer `.ogg` or `.webp` assets to keep checkout size manageable.
