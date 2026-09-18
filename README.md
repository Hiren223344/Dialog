# Star Studio

A standalone Flutter scaffold for **Star Studio**, the film-production
management mini-game described in
[`docs/STAR_STUDIO_DESIGN.md`](docs/STAR_STUDIO_DESIGN.md).

## What's here

This repo had no existing app in it, so this is a from-scratch minimal
scaffold: just enough of the economy/building/gig loop (§4 of the design
doc) to host and demo the **Tier 1 "juice" feedback layer** (§6) on top of
it —

- Rolling HUD counters and an XP/rank progress bar (§5.3)
- Reward icons that fly from where they were earned into the HUD (§5.4)
- Likes floating up in real time while a gig is live, with a confetti +
  flash + haptic "viral burst" when a gig crosses its like target (§5.4)
- Full-screen level-up and building-complete celebrations (§5.4)
- Haptic/system-sound feedback on every meaningful tap (§5.4)

It is **not** the real Dialogbaaz app — `game_registry.dart`,
`hud_bar.dart`, etc. referenced by the design doc as already-shipping code
didn't exist in this repository, so this scaffold reimplements the pieces
needed to demonstrate Tier 1 in isolation. Gig "likes" are simulated
locally on a timer as a stand-in for the real social feed described in
the doc's Tier 3, which needs a server and moderation this repo doesn't
have yet.

## Running it

This code hasn't been run against a Flutter SDK (none was available in
the environment that wrote it), so it hasn't been build-verified end to
end. To try it:

```sh
flutter create . --project-name star_studio --platforms=android,ios,web
flutter pub get
flutter run
```

The `flutter create .` step backfills the platform folders (`android/`,
`ios/`, `web/`, etc.) that a real Flutter project needs but this scaffold
doesn't include — it won't overwrite `lib/` or `pubspec.yaml`.

## Layout

```
lib/
  models/       Resources, rank ladder, buildings, gigs, active-gig session
  data/         game_registry.dart -- static building/gig definitions
  state/        GameState (economy + gig loop) and its GameEvent stream
  services/     studio_sfx.dart -- haptic/sound feedback cues
  widgets/      HUD, building tiles, gig sheets, and the juice effects
                (rolling counters, flying rewards, floating hearts,
                confetti, celebrations)
  screens/      StudioHomeScreen -- wires state to the juice overlay
  theme/        The cinematic dark palette from design doc §5.1
```
