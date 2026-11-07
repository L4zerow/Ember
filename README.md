# Ember

A native macOS animated wallpaper: slow, grainy flame-like gradients rendered with Metal. The soft shapes, the charcoal/red/orange/teal palette, and the stable grain are all procedural; no image is loaded at runtime.

Ember started as a fork of [JerryI/SimplexFlame-OSX](https://github.com/JerryI/SimplexFlame-OSX). The look and the shader are unchanged; this fork renames the app, shares GPU resources between displays, and stops rendering when the desktop is hidden.

![](./img.png)

## Build and run

Requires macOS 13+ and Apple's Command Line Tools (`xcode-select --install`). No third-party dependencies or full Xcode installation required.

```sh
bash scripts/build.sh
open dist/Ember.app
```

## Turning it on and off

- **On:** open the app and click **Use as Wallpaper**, or pick **Enable Wallpaper** from the flame icon in the menu bar.
- **Off:** pick **Disable Wallpaper** from the flame menu. Your normal wallpaper is underneath and reappears at once.
- **Quit:** **Quit Ember** from the flame menu also reveals the normal wallpaper.

Ember remembers whether the wallpaper was on. If you quit with it on, the next launch goes straight to wallpaper mode with no preview window; use the flame menu to reach the controls.

## Controls

The preview window has flow speed, grain, and brightness sliders; settings are remembered. Day and night palettes follow the macOS appearance setting automatically. Click **Use as Wallpaper** to place the animation behind desktop icons on each connected screen. Use the flame menu-bar icon to reopen controls, pause, disable the wallpaper, or quit. It does not install a login item or change the system wallpaper image.

Check **Pomodoro · 20 Minutes** in the flame menu to enable repeating breaks. After 20 minutes of normal work, a fullscreen splash over the animated wallpaper on every display counts down from 30 seconds to zero, then returns to the previous mode and starts the next 20-minute interval. Double-click anywhere or press Escape to skip a break. Uncheck the menu item to stop the cycle. Sleep counts toward the interval; a break that becomes due during sleep appears on wake.

## Render a still

```sh
mkdir -p output
dist/Ember.app/Contents/MacOS/Ember --snapshot output/frame-0.png 0
dist/Ember.app/Contents/MacOS/Ember --snapshot output/frame-30.png 30
# Preview the light palette (snapshots default to dark):
dist/Ember.app/Contents/MacOS/Ember --snapshot output/daylight.png 0 --light
# Match a specific display's pixel dimensions:
dist/Ember.app/Contents/MacOS/Ember --snapshot output/display.png 30 --width 2560 --height 1600
```

The optional last argument is animation time in seconds. This uses the same Metal shader as the live app.

## Measure GPU cost

```sh
dist/Ember.app/Contents/MacOS/Ember --benchmark              # two-pass renderer (what the app uses)
dist/Ember.app/Contents/MacOS/Ember --benchmark --reference  # single full-resolution pass, for comparison
```

On an M5 Max the two-pass renderer takes about 0.23 ms of GPU time per frame at 3472×2266, versus 1.6 ms for the reference pass.

## Implementation

- Swift/AppKit app with an `MTKView` and fullscreen triangles.
- Four-octave gradient noise, slow domain warping, shaped warm folds, and a nonlinear color ramp in `Flame.metal`.
- Screen-anchored grain: it does not randomly flicker every frame.
- 30 fps with output matching each screen's full backing resolution, including Retina scaling.
- Two render passes: calculate the smooth scalar flame field at one quarter of the output width/height, then interpolate it and apply the palette and grain at full output resolution. Only the internal smooth field is approximated; the finished image is not upscaled. A padded border preserves interpolation at screen edges.
- One Metal device, command queue, and compiled shader per process (`MetalContext`), shared by the preview and every display. Toggling the wallpaper, changing displays, or starting a break never recompiles the shader.
- Each desktop window pauses rendering while it is fully covered by other windows or a full-screen app, and resumes where it left off when any part of it shows again. Rendering also pauses on display/system sleep and manual pause; hidden/occluded previews stop rendering.
- One click-through desktop-level window per display, joining desktop Spaces; windows rebuild when displays change.
- Pomodoro reuses the wallpaper views and adds an AppKit text overlay updated once per second during breaks. Work intervals use a single scheduled timer. When disabled there is no running timer or overlay.
