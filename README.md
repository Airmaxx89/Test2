# Fantasy RPG (Godot 4.x)

Offline singleplayer fantasy RPG, 3D isometric, mobile-first (Android primary,
desktop for iteration). Built as a vertical slice, step by step.

## Requirements
- **Godot 4.3+** (Mobile renderer)

## Run
1. Open Godot, import this folder as a project (select `project.godot`).
2. Press **F5** (Play). The main scene is `scenes/world/test_world.tscn`.

## Controls
- **Desktop:** WASD or arrow keys to move. You can also drag the on-screen
  joystick (bottom-left) with the mouse.
- **Touch/Mobile:** virtual joystick in the bottom-left corner.

## Project structure
```
scenes/
  player/           player.tscn         – CharacterBody3D + placeholder capsule
  world/            test_world.tscn      – main scene (ground, obstacles, wiring)
  ui/               virtual_joystick.tscn – touch joystick
scripts/
  player/player.gd          – camera-relative movement + facing
  camera/iso_camera.gd       – follow rig with fixed orthographic iso camera
  ui/virtual_joystick.gd     – emits normalized direction via signal
  world/test_world.gd        – connects joystick -> player, camera -> player
```

## Status — vertical slice
- [x] **Step 1:** movement in a test world, isometric camera, touch controls
- [ ] Step 2: basic stats (HP, damage, level)
- [ ] Step 3: simple combat (one attack, one enemy type)
- [ ] Step 4: save / load

> Graphics are placeholder primitives (capsule/boxes). Art style comes later.
