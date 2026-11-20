# Disky Football

> **3D online multiplayer football game with disks**

[![Engine](https://img.shields.io/badge/Engine-Godot%204.7-478CBF?logo=godot-engine&logoColor=white)](#)
[![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20itch.io-blue)](#)
[![Status](https://img.shields.io/badge/Status-Released-Success)](#)


<a href="https://mexa123.itch.io/disky-football">
  <img src="https://cdn.simpleicons.org/itchdotio/FA5C5C" alt="itch.io" width="24" height="24" valign="middle" />
  Itch.io game page
</a>
<br>
<a href="https://youtu.be/eAnGfGoKED4">
  <img src="https://cdn.simpleicons.org/youtube/FA5C5C" alt="itch.io" width="24" height="24" valign="middle" />
  Youtube gameplay preview video
</a>

---

## Gameplay Preview

![Gameplay preview](./docs/Disky_Football.gif)

| Main Menu | Multiplayer Menu | Custom Lobby Menu |
| :---: | :---: | :--: |
| ![Screenshot 1](./docs/Main_Menu.png) | ![Screenshot 2](./docs/Multiplayer_Menu.png) | ![Screenshot 3](./docs/Custom_Lobby_Menu.png)

---

## Key game features
* Score 5 goals to win.
* Match duration 20 in-game minutes.
* 20 levels against BOT.
* Online multiplayer mode with custom lobby creation or random game join (implemented using Photon Fusion SDK for Godot Game Engine).
---

## Technical focus

* **Main project focus:** Implementing online multiplayer with Photon Fusion SDK in Godot Engine, using compact binary serialization instead of JSON to reduce network traffic overhead.
- **Encountered difficulties:** Since the Photon Fusion SDK for Godot is still under active development, automatic state synchronization didn't work reliably. To solve this, I implemented a turn-based synchronization model where the active player simulates the game state and transmits updated positions to the opponent.
