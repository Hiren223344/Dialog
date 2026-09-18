# Star Studio — Design Document

_A 3D film-production management game inside Dialogbaaz (target vision)._
_Last updated: 2026-09-18_

> **Note on status:** This document describes the **3D target vision**. The
> currently shipping implementation is 2D and remains the live experience until a
> 3D build is funded and validated. A prior Unity spike proved 3D-in-Flutter is
> technically feasible on device; the blocker to reaching this vision is **3D art
> production** (budget/assets), not engine feasibility. See §6/§7.

---

## 1. What Star Studio Is

Star Studio is a **3D film-city management game** where the player runs a movie
studio and rises from a **regular newcomer to a top producer**. It lives inside
the Dialogbaaz app as a dedicated Studio tab (feature-flagged via
`kStarStudioEnabled`), rendered by an embedded **Unity** 3D runtime hosted
full-screen inside the Flutter app.

The core fantasy: _"Build your own Bollywood studio."_ You construct and upgrade
production buildings, hire staff, and take on creative **gigs** — writing
taglines, jingles, scripts, and pitches. Your writing is scored by **likes**,
which drive your rewards. Better writing and bigger studios unlock bigger,
more lucrative productions.

### What makes it different (the defensible hook)

Unlike a generic farm/city builder, Star Studio's core action is **creative
writing** — the exact activity Dialogbaaz is built around (Hindi quotes,
shayari, dialogue, punchlines). The gig content the player writes is real text
that can be surfaced to **real users** for real likes. This turns a solitaire
idle game into a living, social, competitive one, and marries the game to the
parent app in a way no off-the-shelf game can copy.

### Current status (what already exists)

- Full economy backbone: XP→level curve, four resources (₹ box office, fans,
  reputation, XP), 8 buildings with unlock/upgrade/cost rules, staff tiers.
- Server-authoritative state (NestJS/GraphQL) with offline SharedPreferences
  fallback and v1→v2 save migration.
- Creative-writing gig loop with a like-based quality multiplier (up to 3×).
- 2D isometric studio world, building interiors, gig board, writer, HUD.

### The gap this document addresses

The systems are **mechanically complete but experientially flat** — it plays
like a well-styled spreadsheet, not a living studio. The improvements below are
about **feedback, direction, and real social stakes**, not more systems.

---

## 2. Design Inspirations (reference games)

Researched references and the specific lessons to borrow from each. None are
templates to copy wholesale — each contributes one or two proven mechanics.

### Hay Day (Supercell) — the benchmark

- **Genre:** farming simulation. **Platform:** iOS/Android. Grossed >$1.2B by
  end of 2013.
- **What to borrow:**
  - **The steady drip of goals.** Hay Day always dangles the next small task, so
    players never wonder "what now?" This is the single biggest thing Star Studio
    lacks.
  - **Two-currency economy** (soft coins + premium diamonds; diamonds speed up
    timers). Star Studio's ₹ maps to coins; a premium currency is a later option.
  - **Real-time production timers** as return hooks — you start something, leave,
    come back to collect. Star Studio already has this for construction; extend
    the payoff feel.
  - **A curated, "postcard" presentation** — the premium feel is _art + a fixed,
    composed camera_. In 3D this is the key lesson: use a **curated, near-fixed
    camera** (composed 3/4 angle with limited orbit), not free-orbit — every angle
    must stay "postcard" composed. Invest budget in art + lighting, not camera freedom.
- **What NOT to copy:** Hay Day has no walk-around and no walk-in interiors; keep
  buildings as tappable 3D objects that open panels. Do not build free-roam 3D
  interiors (validated as out-of-scope in the Unity spike).

### Township (Playrix) — city + production blend

- **What to borrow:** blends city-building with production chains and regional
  expansion. Its **zone/region unlocking** as a long-term goal maps directly to
  Star Studio's Studio Core → Backlot → Talent Village → Premiere District zones.
  Use region unlocks as major mid/late-game milestones with a celebration moment.

### Kim Kardashian: Hollywood (Glu Mobile) — the career-fame ladder

- **Genre:** casual free-to-play RPG. Goal: rise from **E-list to A-list** by
  gaining fans through jobs (modeling, acting, appearances). Ran 2014–2024.
- **What to borrow:**
  - **The fame ladder as the spine of progression** — an explicit, named rank
    ("Newcomer → Working Producer → Director → Executive → Top Producer") the
    player is always climbing. Star Studio has the levels but not the _felt_
    identity of rank.
  - **Jobs rated for quality → more fans → higher rank.** This is nearly
    identical to Star Studio's like-scored gigs; lean into the rating drama.
  - **Cosmetic identity/wardrobe progression** as a fame expression. A **rigged
    3D producer avatar** that visibly evolves with rank — same recognizable
    person, changing outfit/grooming/accessories/prestige across tiers.
  - **Energy-gated actions** (optional) as a session-pacing / monetization lever.

### Game Dev Story (Kairosoft) — the closest structural match

- **Genre:** studio-management sim. You run a startup studio, **hire staff,
  control production, and ship creative products scored 1–10 by reviewers**;
  scores drive sales; profits grow the studio and staff.
- **What to borrow:**
  - **The produce → get scored → reinvest loop** is exactly Star Studio's gig
    loop. Its addictiveness comes from the _reveal moment_ (the review score).
    Star Studio must dramatize the "likes rolling in / viral" reveal the same way.
  - **Staff with specialties and stats** that meaningfully change output quality
    — deepen Star Studio's staff beyond a flat efficiency multiplier.
  - **Witty, personality-filled copy** — reviewer comments, flavor text. Cheap to
    add, huge for charm.

### Kairosoft catalog (The Sushi Spinery, Dungeon Village, etc.) — pattern library

- **What to borrow:** the whole Kairosoft family proves a **management sim with
  deep systems and charming feedback** succeeds on _juice_, independent of
  dimension. Their combo/bonus popups, milestone jingles, and end-of-year award
  ceremonies are a masterclass in juicing a numbers game — port that feedback
  language directly into the 3D world (floating popups, celebratory VFX, SFX).

---

## 3. Design Principles (the throughline)

1. **Every action gets a reaction.** No silent state changes — coins fly, numbers
   roll, hearts float, sounds play. Juice is 80% of "feel."
2. **Always show the next goal.** The player should never wonder what to do next.
3. **Rank is identity, not a number.** The producer's climb from newcomer to
   top producer should be felt through titles, avatar, and unlocks.
4. **Real social stakes.** Writing is scored by real people, not a fake timer.
5. **3D, curated, premium.** A composed near-fixed camera + premium art +
   lighting + motion. Curated framing over camera freedom; no walk-in interiors.
6. **Respect the parent app.** Reuse Dialogbaaz auth, feed, moderation, analytics.

---

## 4. How Star Studio Should Operate

### 4.1 The core gameplay loop

```
Enter Studio → see current goal → pick a gig at a building
   → write creative content → post it
   → likes arrive (real players or simulated) → quality is scored
   → collect reward (₹ + fans + XP) with a celebration
   → reinvest: upgrade buildings, hire staff, unlock the next building/zone
   → rank up (Newcomer → … → Top Producer) → bigger gigs unlock → repeat
```

Every lap of this loop must produce a visible, satisfying payoff. The loop
already exists in code; the work is making each step _perform_.

### 4.2 Session shape

- **First session (onboarding):** a scripted, hand-held first production that
  teaches by doing — "Write your first tagline → post → collect your first ₹ →
  unlock the Editing Bay." No walls of tutorial text; learn through one guided lap.
- **Daily session (2–5 min):** collect finished productions/construction, claim
  daily reward, do 1–3 gigs, start a new build/upgrade timer, leave.
- **Long-term (weeks):** climb the 5 producer ranks, build all 8 buildings, unlock
  all 4 zones, chase milestones and leaderboards.

### 4.3 Systems

**Resources (already implemented)**
- **₹ Box Office** — primary soft currency (build, upgrade, hire).
- **Fans** — audience size; should gate content reach and multiply like potential.
- **Reputation** — studio prestige; should gate premium gigs/staff.
- **XP / Level** — drives rank and unlocks (curve: `100 × level^1.8`).
- _Give fans & reputation real teeth_ — today they are largely vanity numbers;
  make them multiply rewards or gate content so they matter.
- **Premium currency (future):** a diamond-equivalent to speed timers / buy
  cosmetics, à la Hay Day. Optional, monetization-gated.

**Buildings (8, already defined in `game_registry.dart`)**
Producer's Office, Shoot Floor, Editing Bay, Music Room, Cast Suite, Costume
Room, Marketing Wing, Mini Theatre. Each: unlock level, build cost, real-time
build timer, upgrade levels, staff slots, and interior zones that link to gigs.
- **Improvement:** buildings should visibly reflect state — under construction,
  staff working, upgrade tier, active production.

**Gigs (creative writing — the core action)**
Tagline, print ad, jingle, short film, music video, web series, feature film,
blockbuster. Each: char limit, like target, timer, cost, ₹/fan/XP rewards,
required level + buildings. Scored by likes → quality multiplier (0.7×–3×).
- **Improvement:** dramatize the "likes arriving" and "viral" moments; make the
  quality reveal the emotional peak of the loop (see Game Dev Story's score reveal).

**Staff**
Tiers (Intern → Junior → Senior → Expert) trading salary for an efficiency
multiplier; hired per building; drain ₹/hour.
- **Improvement:** give staff light specialties/personality so hiring is a
  decision, not just a slider (Game Dev Story lesson).

**Progression / Rank (the spine)**
An explicit named ladder the player always climbs:
`Newcomer → Working Producer → Director → Executive → Top Producer`.
- **Improvement:** surface rank prominently; tie avatar, unlocks, and celebrations
  to crossing each rank (Kim Kardashian: Hollywood lesson).

**Goals & Quests (NEW — highest priority)**
A steady queue of small directed tasks with rewards ("Complete 3 gigs," "Hire
your first staff," "Reach 100 fans," "Unlock the Music Room"). This is the
scaffolding that converts disconnected systems into a journey. Reward plumbing
already exists; needs a goal model + HUD panel.

**Retention layer (NEW)**
Daily login reward + streak; daily featured gig with bonus multiplier; local
notifications when timers finish; limited-time cultural events (Diwali film
festival, awards season, trending-topic weekends).

**Social layer (NEW — the differentiator)**
Post gig content to a real Star Studio feed where other players see and like it;
real likes drive gig success. Leaderboards (top producers by fans/box office),
featured-creator spotlights. **Requires moderation** (reuse existing admin
moderation infra) since text is user-generated and public.

### 4.4 Server authority & offline

Economy stays **server-authoritative** via GraphQL; the client never invents
currency. Offline uses the SharedPreferences fallback and reconciles to the
server snapshot on reconnect. Preserve save-migration keys `star_studio_v1` /
`star_studio_v2`. Gate Studio entry behind `AuthGate.requireAuth`.

---

## 5. How Star Studio Should Look

The bar is **Hay Day's presentation** — premium and cohesive — delivered in **3D**
via Unity: detailed stylized art + a curated near-fixed camera + constant motion.
The lesson from Hay Day still holds: the "premium" feeling comes from **art +
lighting + a composed camera**, not from camera freedom. Chase art quality, not
free-roam.

### 5.1 Art direction

- **Style:** warm, premium, **detailed stylized-realistic 3D** "film city" (URP,
  PBR materials). Think golden-hour Bollywood studio lot — clean architecture,
  rich color, readable silhouettes, baked/soft lighting. Explicitly **not**
  low-poly-faceted, not flat-corporate, not cheap mobile-cartoon. (The Unity
  spike's placeholder low-poly kits are a starting point only — the target
  requires higher-quality building/character assets.)
- **Palette (already in the code's dark theme):** deep warm browns/near-black
  backgrounds (`#12100E`, `#17110F`), gold accents (`#FFC857`, `#D4A052`), teal
  highlights (`#4ECDC4`), coral for warnings (`#FF6B6B`). Keep this cohesive
  cinematic palette everywhere.
- **Camera:** a **curated near-fixed 3/4 angle** ("postcard" framing) with
  limited orbit/pitch and pinch-zoom within a pleasant band — never flat-on,
  never top-down, no free-orbit. (The Unity spike proved free-orbit makes every
  angle a liability; constrain it.)
- **Lighting (3D/URP):** warm directional key light, soft shadows, gentle
  emissive glows on interactive objects, day/evening tint for mood, and a
  post-processing pass (color grading, bloom) for the cinematic "glow." This is
  the single biggest low-cost lever for premium feel — apply it early.

### 5.2 The living world

The studio lot should feel _inhabited_, not static:

- **Ambient life:** crew NPCs walking (already have `crew_member` /
  `crew_movement`), vehicles, birds, drifting clouds, flickering set lights.
- **Buildings that breathe:** construction shows cranes/scaffolds + a progress
  bar; active production shows a glowing "on air" light; higher upgrade tiers
  look visibly grander.
- **Interactive objects glow:** anything tappable (notice board, building
  entrances, finished productions) has a subtle pulse/shimmer so the player knows
  where to act.

### 5.3 UI / HUD

- **Persistent top HUD** (`hud_bar.dart`): ₹, fans, reputation, XP bar with rank
  title. Numbers **roll/animate** on change; rewards **fly** into their counter.
- **Rank badge** front and center — the player always sees their current title
  and progress to the next rank.
- **Goals panel:** a collapsible "objectives" strip showing the current 1–3 goals
  with reward previews — the player's compass.
- **Overlays, not screens:** gig writing, staff hire, upgrade, confirmations are
  polished bottom sheets / dialogs over the world (already the pattern). No stack
  of full-screen menus.
- **Bottom-sheet gig board** (already exists) as the "contract board" — refine
  card design, add urgency/featured framing.

### 5.4 Motion & feedback (the juice — highest visual priority)

- **Likes arriving:** hearts/engagement icons float up in real time; the like
  counter ticks; a **viral burst** (confetti + flash + sound) when the target is
  crossed. This is the emotional peak — make it feel like a hit.
- **Reward payout:** coins/fans/XP visibly stream into the HUD; counters roll up.
- **Level-up & building-complete:** full-screen celebration with the new
  rank/building revealed, not a silent number change.
- **Micro-feedback:** button taps, sheet slides, haptics, and layered SFX
  (`studio_sfx.dart` needs expansion) on every meaningful action.

### 5.5 Producer avatar (3D identity)

A **rigged 3D producer avatar** — the same recognizable person from newcomer to
top producer — that visibly evolves with rank: outfit, grooming, accessories,
posture, and prestige flourish change across the 5 tiers while identity stays
constant. Walks the studio lot, appears in celebration moments, and is
customizable (face/hair/body/wardrobe via modular sockets). Requires a clean
**Humanoid** rig so animations (idle/walk) retarget correctly — the Unity spike
showed a poorly-rigged free character causes scale/animation bugs, so avatar rig
quality is a real requirement, not a nice-to-have. Kept separate from the
app-wide profile-avatar system.

---

## 6. Improvement Roadmap (priority order)

| Tier | Theme | Why | Effort |
| --- | --- | --- | --- |
| **1** | **Juice / feedback** — likes arriving, reward payout, level-up & build-complete celebrations, sound + haptics | Biggest felt improvement per hour; makes everything else satisfying | Low |
| **2** | **Goals, quests, guided onboarding** | Turns complete-but-flat systems into a journey; fixes "what do I do now?" | Medium |
| **3** | **Real social likes + leaderboards** (with moderation) | The defensible differentiator; marries the game to Dialogbaaz | Medium–High |
| **4** | **Retention** — daily reward/streak, featured gig, notifications, cultural events | Builds the return habit | Medium |
| **5** | **Depth & identity** — 3D producer avatar, staff specialties, living buildings, meaningful fans/reputation | Personalization + long-term pull | Medium |
| **6** | **Trust & polish** — moderation, funnel analytics, accessibility, performance | Shipping readiness | Ongoing |

**Recommended first build:** Tier 1 (juice), because it is the fastest visible
win and multiplies the payoff of every later tier.

---

## 7. Explicitly Out of Scope

- **Walk-inside-building 3D interiors.** Even in the 3D target, buildings are
  tappable 3D objects that open **Flutter overlay panels** for their functions
  (hire staff, start gigs, upgrade) — the Hay Day / Township model. Full walkable
  3D interiors are AAA-scope, are not what the benchmark does, and stay out of scope.
- **Free-orbit / free-roam camera.** The camera is curated and constrained (§5.1).
- **Economy authority in Unity.** Unity renders only; all currency/XP/unlock logic
  stays server-authoritative via GraphQL. Unity requests mutations through Flutter
  and re-renders from the returned snapshot.
- **A third hand-maintained copy of game rules.** Rules live in
  `game_registry.dart` (client) + the NestJS backend; a generated data contract
  feeds Unity so it never becomes a third source of truth.
- A third hand-maintained copy of game rules. Rules live in
  `game_registry.dart` (client) + the NestJS backend; keep them in sync there.
