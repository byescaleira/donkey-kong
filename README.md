# Scrap Spire

An original arcade climber built for **Apple TV** first, and running unchanged on iOS, iPadOS and
macOS: **SwiftUI** shell, **SpriteKit** scene graph, **Metal** render pipeline with **MetalFX**
upscaling to 4K, locked to a **60 Hz** simulation.

Climb the tower as Pip, a repair drone, while a malfunctioning cargo crane drops canisters down
the girders. Grab the overclock chip to smash them. Reach the power core before the bonus runs out.

Characters, art and theme are original and authored in this repository as pixel grids in code —
there are no third-party assets and no ROM is required.

## Running it

```bash
scripts/build.sh          # package + macOS + tvOS + iOS Simulator
scripts/test.sh           # 63 tests
scripts/run-mac.sh        # build and launch the Mac app
scripts/shots.sh          # headless renders into docs/shots/
```

Open `ScrapSpire/ScrapSpire.xcodeproj` to run on a device. Regenerate the project with
`cd ScrapSpire && xcodegen generate` after changing `project.yml`.

Controls:

| Platform | Move | Jump / start |
| --- | --- | --- |
| tvOS | Siri Remote touch surface or d-pad ring; any game controller | Click, or any face/shoulder button |
| iOS | On-screen stick, or a paired controller | On-screen button, or any controller button |
| macOS | Arrows or WASD, or a paired controller | Space; P or Esc pauses |

Any controller button also inserts a credit on the title screen, so the Apple TV never needs a
focused button to start a game.

## Apple TV

tvOS is the primary target and shapes three decisions:

- **Input is GameController, not touch.** `GamepadInput` polls `GCController` every frame and feeds
  the same `InputBuffer` the keyboard and the on-screen stick use, so the simulation never learns
  where input came from. The Siri Remote arrives as a `microGamepad`, configured with absolute
  d-pad values so touching a side of the surface means that direction. The decision logic — dead
  zone, clamping, one jump per press rather than one per frame — lives in `GamepadMapping` in
  `ArcadeCore` and is covered by tests, because a controller cannot be attached to a simulator.
- **The focus engine must not fight the game.** On tvOS a focusable SwiftUI control steals the
  remote's d-pad, so the settings button is hidden while a game is in progress and the only
  focusable controls are the title and game-over menus.
- **Overscan is just safe area.** `VirtualViewport` already fits the play area inside the safe
  area, and tvOS reports overscan margins through exactly that, so a TV that crops the edges never
  crops gameplay. `Slider` does not exist on tvOS, so the CRT controls fall back to a focusable
  four-step picker.

Verified on the Apple TV 4K simulator: the app renders at a native **3840×2160** with
`missingDrawable=0` across 720 consecutive presented frames at 60 fps. MetalFX is absent from the
tvOS *simulator* SDK (as it is from the iOS one) but present on the device SDK, so the simulator
exercises the native-resolution fallback and real hardware takes the MetalFX path.

## How the three requirements are met

### Responsive on any screen, without letterboxing

Old arcade games assume a fixed screen. `VirtualViewport` replaces that assumption with two rects:

- a **core play area** of 224×256 virtual units that is guaranteed to be fully visible and is the
  only thing gameplay depends on, so the game stays fair at every aspect ratio;
- a **visible area** that always matches the real screen's aspect ratio exactly.

The scale is `min(safeWidth / coreWidth, safeHeight / coreHeight)`, computed against the *safe
area* rather than the raw screen, so the notch and home indicator never cover the playfield. Any
space beyond the core is filled with parallax backdrop and dimmed scaffolding that ties the tower
to the screen edges — never black bars. A phone in portrait gains vertical backdrop; the same
phone rotated gains horizontal backdrop; the gameplay is identical in both.

Because the visible area and the screen share an aspect ratio, the SpriteKit scene uses
`scaleMode = .fill` and the mapping is exact with no distortion.

### 4K with native upscaling

SpriteKit cannot draw to the screen through a custom Metal pipeline on its own, so the game does
not use `SKView`. `FrameComposer` drives the frame explicitly:

1. `SKRenderer` renders the scene into an **offscreen `MTLTexture`** at the internal render
   resolution.
2. **`MTLFXSpatialScaler`** reconstructs that texture up to the output resolution.
3. A Metal fragment shader applies the CRT pass — scanlines locked to the virtual pixel grid,
   bloom, vignette, curvature, chromatic aberration, sharp-bilinear sampling.
4. The result is drawn into the `MTKView` drawable.

Output is capped at 3840×2160 while preserving aspect ratio, so a 5K or 6K display renders at 4K
and scales out rather than paying for pixels nobody can see. The upscaling factor is a setting:

| Mode | Internal render at 4K output | MetalFX |
| --- | --- | --- |
| Native | 3840×2160 | bypassed |
| Quality | 2560×1440 | active |
| Balanced | 2259×1271 | active |
| Performance | 1920×1080 | active |

MetalFX does not exist in the iOS Simulator SDK, so the import is guarded by `canImport` and the
pipeline falls back to native-resolution rendering there. The same fallback covers any device
where `MTLFXSpatialScalerDescriptor.supportsDevice` is false.

### Locked 60 fps

Two independent locks:

- **Presentation**: `MTKView.preferredFramesPerSecond = 60`, so a 120 Hz ProMotion display
  presents at 60.
- **Simulation**: `GameClock` is a fixed-timestep accumulator at exactly 1/60 s. Frame rate and
  simulation rate are decoupled, so physics is identical on a 60 Hz Mac and a 120 Hz iPhone, and a
  stall is clamped to 5 steps instead of spiralling. The simulation is deterministic — same seed
  and same inputs give the same frame, which is what the determinism test asserts.

## Layout

```
ArcadeKit/                    Swift package, all the code
  Sources/
    ArcadeCore/               pure simulation: no SpriteKit, no Metal, fully testable
    ArcadeScene/              SpriteKit node graph built from core state
    ArcadeRender/             Metal: composer, MetalFX, CRT shader, headless grabber
    ArcadeUI/                 SwiftUI shell, HUD, controls, settings
    ArcadeShot/               headless renderer: writes a PNG without a window
  Tests/
ScrapSpire/                   thin Xcode app target (iOS + macOS), generated by xcodegen
scripts/                      build, test, shots, run
docs/                         architecture notes and rendered verification frames
```

`ArcadeCore` has no dependency on SpriteKit, Metal or SwiftUI. Every gameplay rule lives there and
is covered by tests that run in under a hundredth of a second.

## Verification

`ArcadeShot` renders a real frame through the real pipeline — scene, MetalFX and CRT — straight to
a PNG, with no window and no screen capture. It reports what actually happened:

```
$ ArcadeShot --size 5120x2880
  drawable  5120×2880
  scene     2560×1440
  output    3840×2160
  metalfx   active
  pixels    max=255 mean=34.20 lit=18.37%
```

That makes the pipeline checkable in CI and catches a black or blank frame without a human looking
at a screen.
