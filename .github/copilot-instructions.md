# Copilot instructions

## Project

This is a single-player 2D underwater survival and mystery game built with Godot 4 and GDScript. Keep the first release self-contained and desktop-friendly, with local saves and no required online service. There is no backend, React app, or GitHub Pages deployment target.

The game loop centers on exploring an alien ocean, managing dive oxygen and pressure, gathering resources, crafting upgrades, and uncovering what happened on the planet. Keep gameplay systems data-driven where that makes balancing easier, and keep scene responsibilities focused: the main scene coordinates a run, the diver owns movement, world content owns its presentation and interactions, and the HUD communicates current state and objectives.

## Build and test

The project uses Godot's native project format; no external packages or test framework are currently configured.

- Open `project.godot` in Godot 4 and run the main scene (F6) or project (F5).
- Gameplay/save smoke test: `godot --headless --path . --script res://tests/prototype_smoke_test.gd`
- Headless project/editor check: `godot --headless --path . --editor --quit`
- Headless main-scene startup smoke test: `godot --headless --path . --quit-after 120`
- Run the project with a locally installed Godot executable; if the command is not on PATH, substitute its full path.

Tests use a lightweight built-in `SceneTree` script, with no external test framework.

## Controls and gameplay conventions

- WASD or arrow keys move; E interacts with nearby salvage or story objects; F crafts at the surface station.
- Keep oxygen, pressure depth, resource counts, and upgrade state visible in the HUD and make interaction prompts contextual.
- The player can recharge oxygen at the surface station. Pressure upgrades should open new exploration depth and connect progression to newly discovered story clues.
- This is a non-monetary single-player game. Do not add wagering, cash-out, payment, accounts, or online dependencies.
- Preserve the bright, illustrated marine palette: sunlit cyan shallows, saturated reef colors, and gradual indigo depth. Prefer project-owned art and documented CC0 assets; record asset source and license next to imported packs.
- Keep project data and scenes in Godot-native formats. Avoid introducing a web stack or server unless the product direction is explicitly changed.

## Tooling and distribution

The editor, engine, and local build/test workflow should remain free. `.github/workflows/godot-ci.yml` downloads the pinned Godot release and runs headless project validation plus the gameplay/save smoke test on pushes, pull requests, and manual dispatches. Desktop builds can be exported from Godot for local play and later distribution. Steam is optional and has a per-app Steam Direct fee; do not make Steamworks a development dependency.
