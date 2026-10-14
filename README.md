# The Quiet Trench

A free, single-player 2D underwater survival and mystery game made with Godot 4. Explore a colorful alien ocean, salvage materials, craft a pressure upgrade, and follow an old signal into the trench.

## Run

1. Install the free Godot 4 editor from [godotengine.org](https://godotengine.org/download/).
2. Import this folder by opening `project.godot`.
3. Press **F6** to run the main scene or **F5** to run the project.

The world combines original layered SVG illustrations with the CC0 Kenney Fish Pack for its creatures and reef details. It uses no paid assets, add-ons, or online services. Asset credit and licensing are recorded beside the textures in `assets/kenney_fish_pack/`.

In VS Code, open **Terminal → Run Task...** and select **Godot: Launch game** or **Godot: Open editor**. For logic and save validation without opening a game window, choose **Godot: Run gameplay tests**. These tasks expect Godot at `%LOCALAPPDATA%\Programs\Godot`; update `.vscode/tasks.json` if your Godot executable is elsewhere.

## VS Code MCP

`.vscode/mcp.json` configures the MIT-licensed Godot MCP server, pinned to version `0.1.1`. It requires Node.js 18+ and Godot 4 available on `PATH` (or through `GODOT_PATH`). VS Code downloads the server through `npx` on first use; no paid service or game backend is involved.

## Controls

- **WASD** or **arrow keys** — move
- **E** — collect nearby salvage or the signal fragment
- **F** — craft the pressure weave at the surface pod

Return to the pod near the surface to replenish oxygen. The first dive is pressure-limited. Gather three Driftmetal and one Lumen kelp to craft the pressure weave, then descend after the signal.

## Saves

Progress is saved locally in Godot's `user://` data directory as `quiet_trench_save.json`. Save files are not part of the project folder.

## Headless checks

With the Godot executable on PATH:

```powershell
godot --headless --path . --script res://tests/prototype_smoke_test.gd
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 120
```

GitHub Actions runs project import validation and the gameplay/save smoke test on pushes, pull requests, and manual workflow runs.
