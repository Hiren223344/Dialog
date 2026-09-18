# Star Studio -- Unity placeholder scene

Movement/camera/interaction scripts for the 3D target vision (design doc
§5-§7): a character the player walks around the studio lot with, who
enters buildings to do gigs/hiring/shopping there. **Placeholder
geometry only** -- the character is a capsule, buildings are cubes --
until real 3D assets (rigged character + clothing, building models) are
available to swap in.

This can't be built or tested from the environment that wrote it (no
Unity Editor there), so **none of this has been opened in Unity yet**.
Treat it as a first draft to verify and iterate on, not finished work.

## Why there's no `.unity` scene file

Hand-writing Unity's YAML scene format blind, with no editor to open and
check it, is a good way to hand you a scene that silently fails to load.
Instead, `StudioSceneBootstrapper.cs` builds the entire scene from code
at runtime -- ground, capsule character, camera rig, and all 8 cube
buildings -- so there's nothing scene-specific that can be malformed.

## Setup

1. Create a new 3D (Built-in or URP, either works with these scripts)
   Unity project.
2. Copy `Assets/Scripts/` from here into that project's `Assets/`
   folder.
3. In a new, empty scene, create an empty GameObject (`GameObject >
   Create Empty`), name it e.g. `Bootstrapper`, and attach
   `StudioSceneBootstrapper`.
4. Press Play. You should get: a ground plane, a capsule character at
   the origin area, a third-person camera behind it, and 8 colored cube
   "buildings" laid out in a grid.

## Controls (desktop, for testing in the Editor)

- **WASD / arrow keys** -- move (camera-relative).
- **Left/right mouse drag** -- nudge the camera within its clamped
  3/4-angle band (design doc §5.1: no free-orbit, it springs back).
- **Mouse wheel** -- zoom, also clamped.
- **E**, when near a building -- "interact" (currently just logs to the
  Console; see below).

## What's here

| Script | Role |
| --- | --- |
| `StudioSceneBootstrapper.cs` | Builds the whole placeholder scene at runtime. |
| `ThirdPersonController.cs` | Camera-relative movement on the capsule via `CharacterController`. |
| `StudioCameraRig.cs` | The curated, clamped 3/4-angle follow camera. |
| `BuildingInteractable.cs` | Per-building trigger zone; fires enter/exit/interact events. |
| `CharacterCustomization.cs` | Placeholder skin/outfit/accessory hooks on the capsule. |
| `StudioBuildingData.cs` | The 8 buildings' placeholder layout -- mirrors `lib/data/game_registry.dart`'s ids so both sides agree on what a building *is*, even though this data isn't shared code (no Dart/C# interop). |

## What's intentionally not here yet

- **Flutter embedding.** No `flutter_unity_widget` (or similar) wiring.
  `BuildingInteractable`'s events currently just `Debug.Log`; once an
  embedding package is chosen, a bridge script subscribes to those same
  events (`BuildingEntered` / `BuildingExited` / `BuildingInteracted`)
  and forwards them to Flutter instead of (or alongside) logging, and
  `CharacterCustomization`'s public methods get called from Flutter's
  customization UI.
- **Real character/building assets.** `CharacterCustomization`'s method
  *signatures* (`SetSkinTone`, `SetOutfitColor`, `SetAccessory`) are
  meant to be the lasting API -- swap their bodies to change materials
  on a real rig / equip real clothing meshes instead of tinting
  primitives, without changing anything that calls them.
- **Touch input** for the camera drag/zoom (only mouse is handled right
  now) and any animation (the capsule doesn't have a walk cycle -- it
  just translates).
