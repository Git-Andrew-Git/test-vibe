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

Tests use a lightweight built-in `SceneTree` script, with no external test framework. Cover scanning, sampling/recipes, every craftable's effect, and save migration when changing progression systems.

## Controls and gameplay conventions

- WASD or arrow keys move; Shift boosts with fins; E samples or collects nearby objects; F toggles the field technology bench; hold left mouse to scan the lifeform in the analyzer beam; right-click to fire a tranquilizer dart.
- Keep oxygen, pressure depth, resource counts, and upgrade state visible in the HUD and make interaction prompts contextual.
- The escape pod refills oxygen. Scanning alien species reveals the technology they are associated with; sampling them yields their recipe ingredients. Keep recipe states explicit (unknown, missing resources, craftable, installed) and persist scans, materials, sampled life, upgrades, and story progress.
- Pressure equipment, scrubber tanks, fins, lamps, submersibles, weapons, and healing should have visible and testable in-game effects.
- This is a non-monetary single-player game. Do not add wagering, cash-out, payment, accounts, or online dependencies.
- Preserve the bright, illustrated marine palette: sunlit cyan shallows, saturated reef colors, and gradual indigo depth. Prefer project-owned art and documented CC0 assets; record asset source and license next to imported packs.
- Keep project data and scenes in Godot-native formats. Avoid introducing a web stack or server unless the product direction is explicitly changed.

## Tooling and distribution

The editor, engine, and local build/test workflow should remain free. `.github/workflows/godot-ci.yml` downloads the pinned Godot release and runs headless project validation plus the gameplay/save smoke test on pushes, pull requests, and manual dispatches. Desktop builds can be exported from Godot for local play and later distribution. Steam is optional and has a per-app Steam Direct fee; do not make Steamworks a development dependency.
