# ✈️ AeroNexis Flight Simulator

<p align="center">
  <strong>Experience the freedom of flight.</strong><br>
  A next-generation flight simulation project built with Godot Engine.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Engine-Godot%204-478CBF?logo=godot-engine&logoColor=white" alt="Godot 4">
  <img src="https://img.shields.io/badge/Language-GDScript-478CBF" alt="GDScript">
  <img src="https://img.shields.io/badge/Status-Early%20Development-orange" alt="Early Development">
  <img src="https://img.shields.io/badge/Platform-Mobile-lightgrey" alt="Planned platforms">
</p>

---

## 🌍 About the Project

**AeroNexis Flight Simulator** is an ambitious flight simulation project focused on bringing an immersive aviation experience to players through realistic aircraft behavior, detailed cockpits, beautiful environments, and interactive flight systems.

Built with **Godot Engine 4**, our goal is to develop a simulator where every flight feels meaningful — from starting the engines and taxiing to the runway to climbing through the clouds and performing a smooth landing.

We're starting small, building a solid foundation, and working toward a richer flight simulation experience with every update.

> 🛫 **Our vision:** Make the skies accessible to everyone, from aspiring pilots to aviation enthusiasts.

## ✨ Planned Features

The following features represent our development goals. They are not all implemented yet.

- 🛩️ **Aircraft Simulation** — Aircraft with distinct handling characteristics and performance.
- 🎮 **Realistic Flight Physics** — Lift, drag, thrust, gravity, stalls, and aerodynamic control.
- 🖥️ **Interactive Cockpit** — Flight instruments, switches, engine controls, and navigation displays.
- 🛫 **Airport Environments** — Runways, taxiways, terminals, and ground operations.
- 🌦️ **Dynamic Weather** — Clouds, wind, turbulence, fog, and changing weather conditions.
- 🌄 **Immersive Scenery** — Mountains, landscapes, water, and atmospheric lighting.
- 🧭 **Navigation Systems** — Heading, altitude, flight planning, and navigation aids.
- 🛬 **Complete Flight Experience** — Engine startup, taxiing, takeoff, cruising, approach, and landing.
- 📱 **Flexible Controls** — Keyboard, mouse, gamepad, joystick, and touchscreen support where supported.
- 🚀 **Performance Optimization** — Efficient rendering and scalable graphics settings.

## 🖼️ Screenshots

Screenshots will be added as playable features become available.

<p align="center">
  <em>More cockpit, aircraft, and scenery previews coming soon.</em>
</p>

## 🛠️ Built With

| Technology | Purpose |
|---|---|
| [Godot Engine 4](https://godotengine.org/) | Game engine and rendering |
| [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html) | Gameplay and simulation logic |
| [Blender](https://www.blender.org/) | 3D aircraft and environment modeling |
| [Git](https://git-scm.com/) | Version control |
| [GitHub](https://github.com/) | Source code and collaboration |

## 🚧 Development Roadmap

Our development will progress through several milestones.

- [ ] **Phase 1 — Foundation**
  - [ ] Set up the Godot project architecture.
  - [ ] Create the initial aircraft model and flight scene.
  - [ ] Implement basic flight physics.
  - [ ] Add a runway and a chase camera.

- [ ] **Phase 2 — Flight Experience**
  - [ ] Implement pitch, roll, yaw, and throttle controls.
  - [ ] Add takeoff, landing, braking, and landing gear.
  - [ ] Create a basic cockpit and flight instruments.
  - [ ] Add keyboard and touchscreen controls as appropriate.

- [ ] **Phase 3 — World and Airports**
  - [ ] Create detailed airport environments.
  - [ ] Add terrain, sky, clouds, and atmospheric lighting.
  - [ ] Improve aircraft models and exterior visuals.
  - [ ] Add additional camera views.

- [ ] **Phase 4 — Advanced Simulation**
  - [ ] Improve aerodynamic modeling and stall behavior.
  - [ ] Introduce navigation and flight planning.
  - [ ] Add autopilot and more advanced cockpit systems.
  - [ ] Explore dynamic weather and additional aircraft.

- [ ] **Phase 5 — Optimization and Release**
  - [ ] Optimize performance for target platforms.
  - [ ] Test flight handling and gameplay.
  - [ ] Improve menus, settings, and accessibility.
  - [ ] Prepare public builds and documentation.

*The roadmap is subject to change as development progresses.*

## 🚀 Getting Started

The project is under active development. Setup instructions will be expanded as the first playable version becomes available.

### Prerequisites

- [Godot Engine 4](https://godotengine.org/download/)
- Git
- A computer capable of running Godot's 3D editor

### Clone the Repository

```bash
git clone https://github.com/AeroNexis-Labs/flight-simulator.git
cd flight-simulator
```

Open Godot, select **Import**, and choose the project's `project.godot` file once it has been added to the repository.

> **Note:** Replace the repository URL above if your actual GitHub organization or repository name differs.

## 🤝 Contributing

We welcome developers, aviation enthusiasts, 3D artists, and simulation enthusiasts who want to help improve the project.

Potential areas of contribution include:

- Aircraft physics and flight dynamics
- Godot gameplay systems and GDScript
- Aircraft and cockpit modeling
- Airport and terrain design
- UI, instruments, and user experience
- Performance optimization and testing
- Documentation and bug reports

### How to Contribute

1. Fork the repository.
2. Create a feature branch.
3. Make your changes and test them.
4. Commit your work with a descriptive message.
5. Open a pull request explaining your contribution.

Please discuss large changes through an issue before starting substantial work.

## 🎯 Project Goals

Our long-term goal is to create a flight simulator that combines:

- Convincing flight dynamics
- Immersive aircraft and cockpit design
- Beautiful 3D environments
- Accessible controls
- A modular, maintainable codebase

We believe a great simulator is built one system at a time, with attention to both technical accuracy and the experience of flying.

## 📜 License

The project's license has not yet been finalized. A license will be added before code is distributed under an open-source license.

Third-party assets, aircraft models, textures, and other resources will remain subject to their respective licenses.

## ✈️ Join the Journey

AeroNexis Flight Simulator is a work in progress, and this is only the beginning.

Follow the repository to track development, explore upcoming features, report issues, and help shape the future of the project.

**Build. Fly. Explore.**

<p align="center">
  <strong>AeroNexis Labs</strong><br>
  <em>Engineering a world without boundaries.</em>
</p>

## Local player database

See [PLAYER_DATA_SETUP.md](PLAYER_DATA_SETUP.md) for the SQLite GDExtension dependency, guest profile behavior, database schema, and Android setup instructions. Dashboard UI remains scene-based; profile and flight statistics are loaded from `PlayerData`, not hardcoded sample values.


## Mobile tilt controls (prototype)

See `MOBILE_GYROSCOPE_CONTROLS.md` for the gyroscope calibration, touch fallback, throttle slider, and isolated physics test scene. The loading scene remains the project entry point; this is not yet a production flight gameplay scene.
