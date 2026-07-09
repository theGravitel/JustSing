# MECCHA CHAMELEON — Paint System

Just the painting mechanic: paint your blank R6 "brick" character to blend
into the environment. Two scripts, both print heavily to the Output window
so you can see exactly what's happening.

## Files

```
default.project.json
src/
  ServerScriptService/
    PaintServer.server.lua       -- Script: forces R6, strips clothes, applies paint
  StarterPlayer/StarterPlayerScripts/
    PaintClient.client.lua       -- LocalScript: input, color swatches, eyedropper
```

If you're setting this up by hand in Studio instead of using Rojo:

1. `PaintServer.server.lua` → paste into a **Script** named `PaintServer` in **ServerScriptService**.
2. `PaintClient.client.lua` → paste into a **LocalScript** named `PaintClient` in **StarterPlayer > StarterPlayerScripts**.
3. That's it — **you don't need to create a Remotes folder or any RemoteEvent yourself.** `PaintServer` creates `ReplicatedStorage.Remotes.PaintPart` automatically the first time it runs if it doesn't already exist. If you already made a `Remotes` folder, that's fine too — the script reuses it and just adds `PaintPart` inside if it's missing.

Getting the script *type* right matters: a Script in the wrong service, or a LocalScript where a Script should be (or vice versa), simply won't run — with no error. Double check:
- `PaintServer` must be a **Script** (not LocalScript) inside **ServerScriptService**.
- `PaintClient` must be a **LocalScript** (not Script) inside **StarterPlayer > StarterPlayerScripts**.

## Diagnosing with the Output window

Open **View > Output** in Studio before pressing Play. Every step prints a
`[PaintServer]` or `[PaintClient]` line:

- `[PaintServer] script started` / `[PaintClient] script started` — the script is running at all. If you never see these, the script is the wrong type, in the wrong place, or disabled.
- `[PaintServer] ReplicatedStorage.Remotes was missing, created it` — confirms the server just built the remote for you.
- `[PaintClient] found Remotes.PaintPart, setting up UI and input` — the client connected successfully. If instead you see a `warn` saying it never appeared after 10s, the server script isn't running (check the two "script started" lines above).
- `[PaintServer] appearance loaded for <name> - prepping paintable parts` then `is ready to paint` — your character's limbs are set up. If you see `expected part not found on character: X`, your avatar isn't R6 yet (rejoin/reset the character — `Players.AvatarType` only affects characters spawned *after* it's set).
- `[PaintClient] eyedropper: no BasePart under the cursor` — Space was pressed but nothing valid was aimed at.
- `[PaintClient] painting <part> with <color>` and `[PaintServer] painted <part> for <name>` — a successful paint, client then server confirming it applied.

If nothing prints at all when you press Play, the scripts weren't placed correctly — re-check step 1/2 above (service + script type).

## Why R6

Every player is forced into the classic **R6** avatar
(`Players.AvatarType = Enum.AvatarType.R6`). R6 bodies are exactly six
single `BasePart`s — `Head`, `Torso`, `Left Arm`, `Right Arm`, `Left Leg`,
`Right Leg` — so each limb *is* a paintable brick with no custom rig
needed. Clothing/accessories are stripped on spawn so the brick colors are
always visible. This only takes effect for characters that spawn *after*
the setting changes, so if you're testing with an already-R15 avatar,
reset your character once.

## Controls

| Input | Action |
|---|---|
| **Space** | Eyedropper — copies the color of whatever you're aiming at onto your *whole* body |
| **Click a swatch** (bottom of screen) | Sets the held color without needing to eyedrop |
| **F** | Toggle Paint Mode |
| **Left-click** (Paint Mode on) | Paints the limb you're aiming at (on yourself) with the held color |

## How it works

- Client fires `Remotes.PaintPart:FireServer(partName, color)`.
- Server (`PaintServer`) validates the part name is one of the six R6
  limbs, clamps the color, and sets `part.Color` directly — that
  replicates to everyone automatically since it's just a normal property
  change on a networked part.

## What's not included (by design — this is just the paint system)

- Palettes/saving colors, a full hue-wheel picker, fine detail "brush" texture, brush sizing
- Poses, hunter's-perspective camera check
- Any round/match structure

These can be layered back on top once this base is confirmed working.
