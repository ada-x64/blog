#import "_template.typ": *
#show: post.with(
  title: "bevy architecture 1 - plugin hierarchies",
  description: "Some thoughts on ordering dependencies and organizing code in Bevy 0.15.",
  date: datetime(year: 2025, month: 5, day: 16, hour: 17, minute: 0, second: 0),
  tags: ("bevy", "qproj", "architecture"),
  aliases: ("posts/plugin-hierarchies",),
  draft: false,
  cover: "/media/architecture-1/plugin-hierarchy-bsd1-dark.png",
)

As you know, #link("/blog/general-introduction.html")[I'm making a game] using the #link("https://bevyengine.org")[bevy game engine].

== tl;dr
<tldr>
Bevy has two main ways of lumping code into units: #link("https://bevy-cheatbook.github.io/programming/plugins.html")[plugins] and #link("https://bevy-cheatbook.github.io/programming/bundle.html")[bundles]. I've been architecting my project like this: Separate crates for major features which expose a single plugin composed of various, smaller plugins. Sub-plugs are individual features which are integrated into the crate-plugs, which then get composed together into the main app. Feature flags help keep the main app flexible, allowing me to do things like build the same app with or without the inspector. Components are declared within sub-plugs; bundles and complex systems are integrated as their own files. Breaking it up like this keeps code simple and follows the single-responsibility principle.

#figure(caption: "Some of the code tree.")[
  ```bash
  $ tree crates/inspector crates/player src
  crates/inspector
  ├── Cargo.toml
  └── src
      ├── gizmos
      │   ├── mod.rs
      │   └── player_cam.rs
      ├── inspector_cam
      │   ├── bundle.rs
      │   └── mod.rs
      ├── lib.rs
      ├── state
      │   ├── inspector_state.rs
      │   ├── mod.rs
      │   └── ui_state.rs
      └── tabs
          ├── assets.rs
          ├── game_view.rs
          ├── inspector.rs
          ├── mod.rs
          └── resources.rs
  crates/player
  ├── Cargo.toml
  └── src
      ├── cam
      │   ├── bundle.rs
      │   ├── driver.rs
      │   └── mod.rs
      ├── controls
      │   └── mod.rs
      ├── lib.rs
      └── player
          ├── bundle.rs
          └── mod.rs
  src
  ├── inspector.rs
  └── main.rs

  12 directories, 24 files
  ```
]

== Crate dependencies
<crate-dependencies>
#media(
  "/media/architecture-1/crate-deps-bsd1.png",
  caption: [A schematic of the dependencies hierarchy.],
  linked: true,
)

The crate dependency structure is pretty straight-forward. The more general-purpose crates are higher on the tree, including bevy and general libraries, while the inspector (being essentially an integration library) is placed right below the main application. I had gone back and forth on this structure, sometimes adding feature flags to higher-level plugin crates for inspector features, but this is generally unnecessary and clutters up the build process.#footnote[] The plugin hierarchy is more interesting, and plays into the overall project structure.

== Plugin hierarchy
<plugin-hierarchy>
#media(
  "/media/architecture-1/plugin-hierarchy-bsd1.png",
  caption: [A schematic of the plugin hierarchy.],
  linked: true,
)

It's pretty clear that every file should hold only one "thing" in it, but with a flat hierarchy like we have with components that's a bit hard to accomplish! We need some way to understand how to group things together. That's where bundles come in. They're just collections of components. We can create a "prefab" by creating a function that returns `impl Bundle`, typically with a unique marker component for easy access. This is exactly what I did. I'm using a full struct instead of a free function for better encapsulation, in case I need to define systems that relate to the specific bundle.

#figure(caption: "crates/player/player/bundle.rs")[
  ```rust
  #[derive(Component, Default, Debug)]
  pub struct Player;
  pub struct PlayerBundle;
  impl PlayerBundle {
      #[allow(clippy::new_ret_no_self)]
      pub fn new<M: Material>(
          transform: Transform,
          mesh: Handle<Mesh>,
          material: Handle<M>,
      ) -> impl Bundle {
          (
              Name::new("Player"),
              Player,
              transform,
              Mesh3d(mesh),
              MeshMaterial3d(material),
              RigidBody::Dynamic,
              Collider::capsule(0.5, 1.),
              TnuaController::default(),
              TnuaAvian3dSensorShape(Collider::cylinder(0.49, 0.)),
              LockedAxes::ROTATION_LOCKED,
              SpawnAroundTracker,
          )
      }
  }
  ```
]

But not everything we make is prefab-ish; the power of the ECS lies in the flexibility of components. So, we need a way to organize our components and systems. This is exactly what plugins do for us. Conveniently, plugins can be nested. So, each crate contains a major feature which is relegated to its own plugin. Within the crate, each submodule contains its own plugin. In the end, the exposed plugin should be just a collection of other plugins - a plugin bundle, if you will. Similarly to my bundle structs, I define my systems within the submodule plugins for better encapsulation.

#figure(caption: "crates/player/lib.rs")[
  ```rust
  pub mod prelude {
      pub use crate::cam::*;
      pub use crate::controls::*;
      pub use crate::player::*;
  }
  use prelude::*;
  pub struct PlayerPlugin;
  impl Plugin for PlayerPlugin {
      fn build(&self, app: &mut App) {
          app.add_plugins((IntegrationPlugin, PlayerCamPlugin, ControlsPlugin));
      }
  }
  ```
]

Splitting up my dependencies in this way lets me _compose_ the main application from various pieces, rather than mucking my way through interwoven dependencies.

Of course, some amount of interdependency is going to happen. Plugin composition and exposed components, etc., allow us to cross-breed our plugins. The important part is that this happens _at the top-level._

I'm sure I'm missing a lot, and that a lot of this is fairly obvious - but hey, the fact that it feels obvious now is the sign of good design, right?
