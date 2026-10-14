# The Quiet Trench

A free, single-player 2D underwater survival and mystery game made with Godot 4. Explore a colorful alien ocean, sample strange life, research technologies, and follow an old signal into the trench.

## Run

1. Install the free Godot 4 editor from [godotengine.org](https://godotengine.org/download/).
2. Import this folder by opening `project.godot`.
3. Press **F6** to run the main scene or **F5** to run the project.

The world combines original layered SVG illustrations with the CC0 Kenney Fish Pack for its creatures and reef details. It uses no paid assets, add-ons, or online services. Asset credit and licensing are recorded beside the textures in `assets/kenney_fish_pack/`.

In VS Code, open **Terminal → Run Task...** and select **Godot: Launch game** or **Godot: Open editor**. For logic and save validation without opening a game window, choose **Godot: Run gameplay tests**. These tasks expect Godot at `%LOCALAPPDATA%\Programs\Godot`; update `.vscode/tasks.json` if your Godot executable is elsewhere.

## VS Code MCP

`.vscode/mcp.json` configures the MIT-licensed Godot MCP server, pinned to version `0.1.1`. It requires Node.js 18+ and Godot 4 available on `PATH` (or through `GODOT_PATH`). VS Code downloads the server through `npx` on first use; no paid service or game backend is involved.

## Controls

- **WASD** or **arrow keys** — swim (editable in Settings → Key Bindings)
- **Shift** — boost while wearing Current-rider fins
- **E** — collect salvage or sample nearby alien life
- **F** — open or close the field technology bench
- **Esc** — pause and open the game menu
- **Mouse** — aim the analyzer beam
- **Hold left mouse button** — scan an unstudied creature or plant within the analyzer's 30° cone (780-unit reach)
- **Right mouse button** — fire the Dreamspore dart at a hostile target in range
- **Radio** — open the latest radio message; story messages stay hidden until requested

Return to the escape pod near the surface to refill oxygen and restore health. Begin by collecting three Driftmetal and one Lumen kelp to fabricate the known Pressure-weave suit. Scan each alien species to reveal its linked technology; sampled fauna and flora provide the recipe materials. The bench lists all technologies and shows which are unknown, short on materials, ready, or already built.

Progression includes pressure protection, a larger scrubber tank, speed fins, a lamp, a visible pocket submersible, a tranquilizer, and consumable repair gel. Each upgrade opens up more of the trench and the story behind the signal.

Undiscovered technologies do not reveal their names, scan targets, or recipes. Finding a recipe ingredient reveals only that known component; scanning the associated lifeform identifies the full technology. Unknown items are shown in grey and known recipes missing materials are highlighted red.

The pause menu includes **Continue**, **Save Game**, **Load Game**, **Settings**, and **Save and Exit** (with a confirmation). Settings include 1024×576, 1280×720, 1600×900, and 1920×1080 resolutions, master volume, configurable autosave intervals (off, 30 seconds, 1, 5, 10, 15, or 30 minutes), and remappable keyboard actions. Autosave is enabled by default at one-minute intervals. Game progress and settings are stored separately under Godot's `user://` directory.

## Saves

Inventory, diver position, health, oxygen, scans, sampled specimens, crafted technologies, and story progress are saved locally in Godot's `user://` data directory as `quiet_trench_save.json`. Existing version 1 and version 2 saves are migrated automatically. User preferences are stored separately in `quiet_trench_settings.json`. Save files are not part of the project folder.

## Headless checks

With the Godot executable on PATH:

```powershell
godot --headless --path . --script res://tests/prototype_smoke_test.gd
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 120
```

GitHub Actions runs project import validation and the gameplay/save smoke test on pushes, pull requests, and manual workflow runs.
