#import "_template.typ": *
#show: post.with(
  title: "inspector 1 - widgets, states, cameras",
  date: datetime(year: 2025, month: 5, day: 16, hour: 17, minute: 0, second: 0),
  tags: ("qproj", "inspector", "devlog"),
  aliases: none,
  draft: false,
  cover: "/static/media/inspector-1/editor.png",
)

== intro
<intro>
#media("/static/media/inspector-1/editor.png", alt: "Editor.", caption: [Screenshot of the editor. The game view is in the center, featuring a capsule and a red wireframe of a sphere with an arrow pointing toward the capsule. In the upper-right corner there is a gizmo showing the XYZ axes in worldspace. Framing the game view are three docked panels: the hierarchy with all the entities in the scene, the inspector with details of the highlighted entity (Player), and the bottom tray with tabs for Resources, Assets, and States.], linked: true)

#link("https://github.com/ada-x64/qproj/pull/2")[I _finally_ got player interactions working.]

Well, kinda.

=== #box[#image("../assets/lilguy/lilguy-uh-oh.gif")] why is that PR so big……
<why-is-that-pr-so-big>
This has been a _big_ learning process.

In order to understand what's happening in the game, I need a way to inspect the world. Thankfully, there are #link("https://github.com/rewin123/space_editor")[plenty] #link("https://github.com/jakobhellermann/bevy_editor_pls")[of] #link("https://github.com/databasedav/aalo")[crates] in this space. I decided to use the well-supported #link("https://github.com/jakobhellermann/bevy-inspector-egui")[bevy\_inspector\_egui] as the basis of my inspector because of its integrations with the general egui ecosystem. That being said, I'm keeping an eye on #link("https://github.com/databasedav/haalka")[haalka], #link("https://github.com/dekirisu/mevy")[mevy], and #link("https://github.com/Leafwing-Studios/i-cant-believe-its-not-bsn")[dairy-free BSN] as bevy-native alternatives. I have #link("/static/media/inspector-1/ari-reading.webp")[a life outside of gamedev,] otherwise I'd already be trying them out and contributing back.

#callout(kind: "note", title: [General codebase architecture])[In addition to building out a UI, I've been playing around trying to figure out the best way to organize my code. Games are big projects and I have _got_ to be clear about what I'm doing, especially given time and attention constraints. I've settled on #link("/blog/architecture-1.html")[a fairly simple architecture.] Click on that link to learn more, it's got a tl;dr and everything :)]

== a tale of two UI systems
<a-tale-of-two-ui-systems>
=== bevy\_inspector\_egui
<bevy_inspector_egui>
`bevy_inspector_egui` has been pretty much a necessary evil. It is the most robust currently existing inspector solution, if only because `egui` has a _lot_ of plugins. I've been making use of #link("https://github.com/Adanos020/egui_dock")[egui\_dock,] among others.

However, egui and bevy don't always play well together. Egui has its own render cycle completely separate from the main loop, so it's difficult to get interactions between the UI and the game world. I've settled on #link("https://bevy-cheatbook.github.io/programming/states.html")[states] as my go-to mechanism for implementing this functionality. This may seem strange - why not use an #link("https://bevy-cheatbook.github.io/programming/events.html")[event?] Simply, most of my use-cases have been stateful, e.g.~whether or not the cursor is over the gameview or whether or not the main camera is enabled. In order to implement these boolish states, I've made #link("https://github.com/ada-x64/qproj/blob/main/crates/utils/src/boolish.rs")[a simple macro.]

#figure(caption: "crates/utils/.../boolish.rs")[
  ```rust
  #[derive(
  	Default, States, Debug, Copy, Clone, PartialEq, Eq, Hash, Reflect
  )]
  #[reflect(State)]
  pub enum $name {
  	/// awaiting setup
  	/// glosses to false
  	#[default]
  	Init,
  	/// implements Into/From<bool> (true)
  	Enabled,
  	/// implements Into/From<bool> (false)
  	Disabled,
  }
  ```
]

#figure(caption: "crates/inspector/.../inspector_state.rs")[
  ```rust
  use q_utils::boolish_states;
  boolish_states!(InspectorState, GameViewState);
  //...
  impl Plugin for InspectorStatePlugin {
      fn build(&self, app: &mut App) {
          app.setup_boolish_states()
          //...
      }
  }
  ```
]

All of my states are independent. This is pretty flexible, as it allows me to query for individual states and to update them without affecting any other state. If I were to lump them all together into a big `InspectorState` struct then this wouldn't allow me to do things like conditionally run systems, which is the whole point. State changes are also tracked like events, so we can run one-shot systems whenever states change. Best of both worlds!

#figure(caption: "crates/inspector/.../inspector_state.rs")[
  ```rust
  impl Plugin for InspectorCamPlugin {
      fn build(&self, app: &mut App) {
          app.setup_boolish_states()
              .add_systems(OnExit(InspectorCamState::Init), Self::spawn_camera)
              .add_systems(
                  Update,
                  (Dolly::<InspectorCam>::update_active, Self::update_camera)
                      .run_if(in_state(InspectorCamState::Enabled)),
              )
              .add_systems(
                  OnEnter(InspectorCamState::Disabled),
                  Self::set_cam_active::<false>,
              )
              .add_systems(
                  OnEnter(InspectorCamState::Enabled),
                  Self::set_cam_active::<true>,
              );
      }
  }
  ```
]

You may also notice that I'm running initialization code when the state _exits_ `$state::Init`. This way we don't unnecessarily populate the game world with junk components, and we have finer control over when a system set is run. This has generalized really well, and I'm using it all over the codebase. The only major drawback is that because states are handled individually you have to query lots of them to get complicated information. But, this is not too different from general queries, and may even be a good thing. In general, *a system should know only what it needs to, and nothing more.* This is the single-responsibility principle in practice.

==== #box[#image("../assets/lilguy/lilguy-whatever.gif")] ok, state is cool but what about the ui?
<ok-state-is-cool-but-what-about-the-ui>
I need all this state to send interactions between the egui UI system and bevy. It's a hassle! Though I'm glad I did it, because I'm using it in the main application as well. As far as the actual UI goes, I'm pretty much just copying the #link("https://github.com/jakobhellermann/bevy-inspector-egui/blob/main/crates/bevy-inspector-egui/examples/integrations/egui_dock.rs")[egui\_dock example] from the repo. The main exception to this is the play/pause state, which simply de/activates physics, the player's controller state, and the player camera. Optionally, you can play the game while keeping the inspector camera running. I'm trying to capture a Unity-like feel here.

I've also added an `InspectorIgnore` component for filtering out entities I don't want to see, for example the inspector cam and the gizmo entities.

==== #box[#image("../assets/lilguy/lilguy-thinking.gif")] …and the noise editor?
<and-the-noise-editor>
This is not yet implemented. I intend for it to be a generalized terrain / procgen stuff editor which utilizes #link("https://github.com/attackgoat/noise_gui")[noise\_egui], though I will probably end up making this into a separate application, if not copying the expression library and implementing a bevy-native clone…

=== bevy\_ui and gizmos
<bevy_ui-and-gizmos>
The real meat of the editor is in the gizmos! Unfortunately I haven't made too many yet! The primary gizmos are those for viewing the player camera (the red sphere and arrow in the screenshot above), and the XYZ axes in the top-right corner. I'm going for a Blender-style feel for that one. The axes were achieved by #link("https://github.com/ada-x64/qproj/blob/main/crates/inspector/src/gizmos/mod.rs")[rendering to a texture,] which is #link("https://bevyengine.org/examples/3d-rendering/render-to-texture/")[a common practice,] but I still feel proud for learning it! Future work on this includes things like jump-to-entity, transform gizmos, and scene integration.

== Cameras, Physics, Controls - The actual game stuff!
<cameras-physics-controls---the-actual-game-stuff>
So far all of this is still pretty basic. For cameras, I'm using #link("https://github.com/BlackPhlox/bevy_dolly")[bevy\_dolly,] which is a wonderfully flexible and powerful camera controller. It was a bit of a struggle to get it to do what I want, which is a big part of why this PR took so long. I'm happy with it though! It turns out I had just gotten some coordinate spaces mixed up - gamedev shit. I wouldn't have figured that out without the inspector though.

As far as physics goes, I'm using #link("https://github.com/Jondolf/avian")[avian3d]. As I'm writing, I'm seeing that #link("https://github.com/Jondolf/avian/releases/tag/v0.3.0")[v0.3.0 is out!] Avian was locking me to bevy 0.15 (one version behind), so I'm very glad to hear this has been released. That being said, it looks like bevy\_dolly's 0.16 migration is #link("https://github.com/BlackPhlox/bevy_dolly/pull/77")[still WIP as of writing.]

…and for the player I'm using #link("https://github.com/idanarye/bevy-tnua")[tnua.] I might end up replacing this if I need to, though the library seems flexible enough to do all the things I need it to. Right now the player is bumping about on the uneven terrain, which looks pretty ugly. I'm sure I can tweak the settings to improve this though. I also haven't implemented proper camera controls yet! Right now the camera just follows behind the player, no zooming or rotating. I'm aiming for the feel of the player controls to be something akin to 3D Zelda games; Breath of the Wild is a big inspiration.

I'd really like to upgrade my dependencies. The #link("https://bevyengine.org/news/bevy-0-16/")[bevy 0.16 update] included a lot of API changes (such as #link("https://bevyengine.org/news/bevy-0-16/#ecs-relationships")[ECS relationships]) which aim toward a better devex. This is all headed toward the #link("https://github.com/bevyengine/bevy/discussions/14437")[next-gen scene/ui system] and the #link("https://github.com/bevyengine/bevy_editor_prototypes")[official editor] - very big and exciting stuff! Generally 0.16 has been a huge leap forward for the engine and I'm excited to see it grow. Unfortunately, I'm still stuck in 0.15 land until my dependencies migrate.

== Conclusion
<conclusion>
This was a lot of work!! Way too much for a single PR. In the future I'm going to try to split things up a bit more cleanly. This has been good though, I've learned a _lot_ about how Bevy works, and in general feel far more confident to scaffold out the project.

As far as future work goes, I need to:

- Migrate to bevy 0.16
- Implement better player camera controls
- Implement better player movement
- Do visual things like adding a skybox and textures to the world
- Implement the terrain editor / general procgen tool.

Thank you for reading!
