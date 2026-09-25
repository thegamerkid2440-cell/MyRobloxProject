# MyRobloxProject

A beginner-friendly Roblox Luau project managed with [Rojo](https://rojo.space/) and Git.

## What is included?

- `src/ServerScriptService`: server-only scripts. These run securely on the Roblox server.
- `src/ReplicatedStorage/Shared`: ModuleScripts that can be required by both server and client code.
- `src/StarterPlayer/StarterPlayerScripts`: LocalScripts that run for each player.
- `src/StarterGui/MainGui`: the player's starter ScreenGui and its LocalScripts.
- `src/ReplicatedStorage/Remotes`: a replicated container reserved for RemoteEvents and RemoteFunctions.

The starter scripts only demonstrate safe, normal Roblox Studio Luau. They do not use exploit executors or exploit-only APIs.

## Prerequisites

Install these on your computer:

1. Roblox Studio.
2. Git.
3. Rojo, following the official installation instructions: <https://rojo.space/docs/getting-started/installation/>.
4. The Rojo plugin for Roblox Studio, installed from the Roblox Creator Store.

The GitHub repository stores source files. Rojo synchronizes those files into an open Roblox Studio place; it does not automatically publish the place or replace Roblox Studio's Save/Publish workflow.

## Exact project structure

```text
MyRobloxProject/
├── default.project.json
├── README.md
└── src/
    ├── ReplicatedStorage/
    │   └── Shared/
    │       └── MathUtil.luau
    ├── ServerScriptService/
    │   └── Server.server.luau
    ├── StarterGui/
    │   └── MainGui/
    │       └── MainGui.client.luau
    └── StarterPlayer/
        └── StarterPlayerScripts/
            └── Client.client.luau
```

`Remotes` is created by `default.project.json` as a `Folder` in `ReplicatedStorage`. Add RemoteEvents or RemoteFunctions to the Rojo mapping when you need them.

## First-time setup

From the repository folder, run:

```bash
git clone https://github.com/thegamerkid2440-cell/MyRobloxProject.git
cd MyRobloxProject
rojo serve default.project.json
```

Then open Roblox Studio, open the place you own, and click the Rojo plugin's **Connect** button. Select the server shown by `rojo serve` (normally `localhost:34872`).

Keep the terminal running while you work. Rojo will synchronize file changes into Studio.

## Git commands

If you already cloned this repository, do not run `git init` again. For a brand-new local folder, use:

```bash
git init
git branch -M main
git remote add origin https://github.com/thegamerkid2440-cell/MyRobloxProject.git
git add .
git commit -m "Set up Roblox Rojo project"
git push -u origin main
```

If the repository already contains the project and you cloned it, the usual update commands are:

```bash
git pull origin main
# edit or add files here
git add .
git commit -m "Describe the Roblox change"
git push origin main
```

After pulling a later change, keep or restart `rojo serve default.project.json`, then click **Connect** or **Reconnect** in the Rojo Studio plugin. Rojo synchronizes source files into Studio; use Studio's normal **File > Publish to Roblox** to publish the place.

## Important Rojo notes

- The source of truth for scripts is this repository.
- Avoid editing Rojo-managed scripts directly in Studio; make code changes in the repository and let Rojo sync them.
- Studio-only instances, terrain, parts, and place data are not automatically represented by this starter script layout. Use Rojo models or a separate place workflow for those assets.
- Never commit secrets, API keys, or private tokens.
