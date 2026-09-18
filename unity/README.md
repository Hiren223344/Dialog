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
   the origin area, a third-person camera behind it, 8 colored cube
   "buildings" laid out in a grid, and two UI panels (top-left
   "Customize" swatches; a hidden building menu that appears on
   interact).

## Controls (desktop, for testing in the Editor)

- **WASD / arrow keys** -- move (camera-relative).
- **Left/right mouse drag** -- nudge the camera within its clamped
  3/4-angle band (design doc §5.1: no free-orbit, it springs back).
- **Mouse wheel** -- zoom, also clamped.
- **Top-left panel** -- click a skin-tone or outfit swatch to recolor
  the capsule live; "Cycle Accessory" adds/removes a small placeholder
  shape at its head.
- Walk up to a building until a **"Press E to enter ..."** prompt
  appears, then press **E** -- opens a menu with Gigs / Hire Staff /
  Shop / Leave. Without the Flutter bridge wired up (below), the first
  three just show a status line; Leave closes the menu.

## What's here

| Script | Role |
| --- | --- |
| `StudioSceneBootstrapper.cs` | Builds the whole placeholder scene at runtime. |
| `ThirdPersonController.cs` | Camera-relative movement on the capsule via `CharacterController`. |
| `StudioCameraRig.cs` | The curated, clamped 3/4-angle follow camera. |
| `BuildingInteractable.cs` | Per-building trigger zone; fires enter/exit/interact events. |
| `BuildingVisualState.cs` | Applies a building's real status (locked/buildable/...) to its cube -- dims it and disables its trigger when locked. |
| `CharacterCustomization.cs` | Placeholder skin/outfit/accessory hooks on the capsule. |
| `StudioBuildingData.cs` | The 8 buildings' placeholder layout -- mirrors `lib/data/game_registry.dart`'s ids so both sides agree on what a building *is*, even though this data isn't shared code (no Dart/C# interop). |
| `StudioUIBootstrapper.cs` | Builds the on-screen UI at runtime: interaction prompt, building menu, customization panel. |
| `FlutterBridge.cs` | The Unity side of the Flutter bridge (see below). Gated behind `STAR_STUDIO_FLUTTER_BRIDGE` so its own missing dependency can't break the rest of the project. |

## Wiring the Flutter bridge

The Dart side is `lib/services/unity_bridge.dart` (message protocol) and
`lib/widgets/unity_studio_view.dart` (the widget that hosts the Unity
view), used from `lib/screens/studio_home_screen.dart` behind
`kUnity3DStudioEnabled` in `lib/config/feature_flags.dart` (**false** by
default -- flip it once you've actually gotten this running). This
whole path is unverified: `flutter_unity_widget_2` needs a Unity-built
native module (an exported Android library / iOS framework) that only
Unity's Editor can produce, so none of it has been exercised end to
end.

To wire it up:

1. `flutter pub get` (already added to `pubspec.yaml` -- switch the
   version line to `^2022.3.0` instead of `^6000.1.0` if your Unity
   project targets 2019.4-2022.3 rather than Unity 6).
2. Follow `flutter_unity_widget_2`'s own setup docs to import its Unity
   package into this project (it provides `UnityMessageManager`,
   referenced by `FlutterBridge.cs`) and export it as the native module
   Flutter embeds.
3. In Unity, add `STAR_STUDIO_FLUTTER_BRIDGE` under **Project Settings >
   Player > Scripting Define Symbols** -- this compiles `FlutterBridge.cs`
   in and makes `StudioSceneBootstrapper` attach it, and makes the
   Gigs/Hire/Shop buttons call it instead of only showing a status line.
4. The message shapes are documented on each method in `FlutterBridge.cs`
   and mirrored on each method in `UnityBridge` (Dart) -- keep both
   sides in sync if you change one.

What it does today: Flutter calls `SyncBuildings`/`SetSkinTone`/
`SetOutfitColor`/`SetAccessory` on Unity; Unity sends
`buildingInteracted`/`menuAction` events back. "Hire" and "shop" land on
`ScaffoldMessenger` placeholders in Flutter, since there's no real
hiring/shop system in `lib/state/game_state.dart` yet -- only gigs and
buildings exist there so far.

## What's intentionally not here yet

- **Real character/building assets.** `CharacterCustomization`'s method
  *signatures* (`SetSkinTone`, `SetOutfitColor`, `SetAccessory`) are
  meant to be the lasting API -- swap their bodies to change materials
  on a real rig / equip real clothing meshes instead of tinting
  primitives, without changing anything that calls them (including the
  UI buttons in `StudioUIBootstrapper`).
- **Touch input** for the camera drag/zoom and UI (only mouse is
  handled right now) and any animation (the capsule doesn't have a walk
  cycle -- it just translates).
