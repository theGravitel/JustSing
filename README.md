# MECCHA CHAMELEON — Scripted Base

A Roblox game where you paint your blank R6 "brick" character to blend
into the environment. This repo is the **scripted base**: just the
painting mechanic — input, coloring, and posing. No round/match structure,
no art/assets, no level design.

## Project layout (Rojo)

This is a source-only [Rojo](https://rojo.space/) project — there's no
`.rbxl` place file checked in. Open it in Studio with the Rojo plugin:

```
default.project.json
src/
  ReplicatedStorage/Shared/       -- shared config + helpers (server & client)
    PaintConfig.lua               -- keybinds, brush/palette tuning, paintable part list
    PaintState.lua                -- mutable client-side held color / brush size
    CharacterRigUtil.lua          -- which parts a brush stroke touches
  ServerScriptService/
    CharacterSetup.server.lua     -- forces R6 avatars, strips clothes, preps paintable parts
    PaintService.server.lua       -- validates & applies paint (RemoteEvents)
    PaletteService.server.lua     -- saves/loads palettes via DataStore
  StarterPlayer/StarterPlayerScripts/
    PaintController.client.lua    -- spacebar eyedropper, F paint mode, brush resize, apply paint
    ColorWheelUI.client.lua       -- hue strip + SV square color picker, palette swatches
    PoseController.client.lua     -- crouch / lie down / stretch poses
    CameraPreview.client.lua      -- "hunter's perspective" orbit camera check
```

`Remotes` (RemoteEvents/RemoteFunctions) are declared directly in
`default.project.json` under `ReplicatedStorage.Remotes` — Rojo creates
those instances for you, no manual setup needed in Studio.

### Running it

1. Install the [Rojo Studio plugin](https://rojo.space/docs/v7/getting-started/installation/) and the `rojo` CLI (via [Aftman](https://github.com/LPGhatguy/aftman) or standalone).
2. From this folder: `rojo serve`
3. In Studio: open the Rojo plugin panel and click **Connect**.
4. Play-test with 2+ local server instances (Studio's "Start" with multiple
   clients) to see painting/poses replicate between players.

## Why R6

Every player is forced into the classic **R6** avatar
(`Players.AvatarType = Enum.AvatarType.R6`) instead of R15/Rthro. R6 bodies
are exactly six single `BasePart`s — `Head`, `Torso`, `Left Arm`,
`Right Arm`, `Left Leg`, `Right Leg` — so each limb *is* a paintable brick
with no custom rig-building required. Clothing/accessories are stripped on
spawn so the brick colors are always visible.

## Controls

| Input | Action |
|---|---|
| **Space** | Eyedropper — aim at any object and copy its color onto your *whole* body (quick base coat) |
| **F** | Toggle Paint Mode |
| **Right-click + drag** (Paint Mode) | Resize brush |
| **Left-click** (Paint Mode) | Paint the limb you're aiming at with the held color — large brush recolors the whole limb (and links to neighboring limbs at max size), small brush drops fine color "flecks" for matching busy textures |
| **C** | Toggle Crouch |
| **Z** | Toggle Lie Down |
| **X** | Toggle Stretch |
| **V** | Stand |
| **P** | Toggle hunter's-perspective orbit camera (check your camouflage from a distance) |
| **"Colors" button** (bottom-right) | Open the color picker: drag the hue strip and saturation/value square to choose any color, click a palette swatch to select a saved color, Shift+Click a swatch to save the current color into it |

## How painting works under the hood

- **Base coat / large brush** — `PaintPartRemote:FireServer(partName, color, brushSize)`.
  The server (`PaintService`) validates the part name, clamps the color and
  brush size, and recolors the `BasePart.Color` directly. Recoloring
  replicates to everyone automatically since it's just a property change on
  a networked part.
- **Fine detail / small brush** — `PaintFleckRemote:FireServer(partName, color, hitPosition)`.
  The server spawns a small colored ball `Part`, welds it to the limb at
  the hit position, and caps the count per limb (`MaxFlecksPerPart`) to
  avoid runaway part growth. This is what makes "quick random swipes"
  create dot-like texture instead of a flat color change.
- **Palettes** — saved per-player via `SavePaletteRemote`/`GetPaletteRemote`
  (RemoteFunctions) to a DataStore, keyed by `UserId`.
- **Poses** — done client-side by tweening R6 `Motor6D` joint `C0` offsets
  directly (no animation assets needed for this base), with
  `Humanoid.PlatformStand` toggled so physics doesn't fight the pose.

## What's *not* included (out of scope for this base)

- Any round/match structure (hiding phase, seeking phase, tagging, timers)
- Level/map geometry and hiding spots
- Scoring, matchmaking, lobby UI
- Anti-exploit hardening beyond basic server-side validation/clamping/debounce
- True pixel/UV texture painting (the small-brush "fleck" system approximates
  fine detail without needing `EditableImage`/UV mapping)

These are natural next steps once the base is verified in Studio.
