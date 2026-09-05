#import "_template.typ": *
#show: post.with(
  title: "architecture 2 - q_service",
  description: "why i wrote q_service",
  date: datetime(year: 2025, month: 8, day: 12),
  tags: ("architecture", "qproj", "devlog"),
  aliases: ("posts/q_service",),
  draft: false,
  cover: "/media/architecture-2/example-architecture.png",
)

#media("/media/architecture-2/github-dark.png")

Check out the crate! #link("https://crates.io/crates/q_service")[crates.io]| #link("https://github.com/ada-x64/q_service")[github]

I recently released a crate (my first! 🎉) which aims to bring the service model to Bevy. I understand that this may seem like a strange choice, so I wanted to go over my motivations for doing so and give a general overview of the crate and how I plan on using it.

I started writing this when I had just released version 0.1, but as I'm writing I'm going over the final checks to push version 0.2. Since the crate has received a pretty major overhaul, I can't go over every decision that I made, but I'd like to share the general direction the designs have gone.

Let's start with the _why_ before we get to the _what._ We'll also talk about _when_ to use services as opposed to other abstractions.

== #box[#image("../assets/lilguy/lilguy-thinking.gif")] Why bring the service model to Bevy?
<why-bring-the-service-model-to-bevy>
Long story short: Separation of concerns for systems at runtime.

Video games are large, complicated projects. If you don't go into them with an architecture in mind, you're going to end up with spaghetti code and a terrible time. (Ask me how I know.)

For #link("/blog/bevy-jam-6.html")[Markoff] (my Bevy Jam 6 entry) I needed to #link("/blog/bevy-jam-6.html#system-sets")[gate off a bunch of systems behind SystemSets.] That was a pain! Services obviate this - just add your systems to the service and they're automatically gated.

While working on #link("https://github.com/ada-x64/qproj")[qproj] (which you can read about #link("/blog/general-introduction.html")[here on my blog]), I created a simple "boolish state" resource that I used _everywhere._ It occurred to me that I was basically gating off behavior based on whether or not certain conditions had been met or after certain actions had been performed. And while manually updating this works for simple projects, it's not nearly enough to sustain something like an editor - what I'm currently building. So I set out to automate all of that, and q\_service was born.

== #box[#image("../assets/lilguy/lilguy-question.gif")] What's a service?
<whats-a-service>
#media("/media/architecture-2/state-flow.png", caption: [A simple service state model. Nodes represent states. Red lines represent commands. Dotted lines are automatic state transitions based on hook results.])

A service, in broad terms, is a simple state machine which encapsulates some data and functionality. They're designed to be modular, reproducible, and flexible. Of course, the term "service" is a bit broad. When I refer to services, I'm talking about OS services, specifically #link("https://systemd.io")[systemd's] #link("https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html")[service model.] In systemd, a service is essentially a managed daemon, or background process. These form the core of modern Linux, and I think it could be the core of high level Bevy, too. To draw an analogy, what systems are to processes, entities and components are to files and data, and q\_service is to systemd.

=== Service-oriented architecture in systems programming
<service-oriented-architecture-in-systems-programming>
When developing systems on which other software will run - like game engines, operating systems, or SaaS environments - it's important to be able to bring together disparate systems into a single product. For example, it might we wise for an operating system to have separate services for audio and video, since they run on separate hardware devices. Similarly, you'd need services for human interface devices like keyboards and mice and services for network hardware like ethernet, wifi, and bluetooth.#footnote[Of course there's a difference between the drivers which live in the kernel and interface directly with the hardware and the userland services which _manage_ these drivers. We're talking about userland here.] Placing all of this within a monolithic structure would quickly become infeasible. In the end, this boils down to separation of concerns. In the world of Linux, systemd came into existence in order to manage these system dependencies and to allow new services to easily be spun or down.

The same model holds for SaaS - message queues, databases, load balancers, firewalls, and front-end servers are all separate systems with separate needs in terms of throughput, hardware requirements, and software implementation. In order to make these portable, scalable, and reusable, first Docker and then Kubernetes came along to containerize and manage these programs.

What I'm proposing is that we do the same thing for ECS-driven simulations.

==== #box[#image("../assets/lilguy/lilguy-erm-actually.gif")] Aren't ECS engines closer to RDBMSs than OSs?
<arent-ecs-engines-closer-to-rdbmss-than-oss>
If we're to continue with the OS metaphor, we need to talk about how the OS stores data. Operating systems run on top of file systems, but the ECS is far closer in structure to a database. However, both are efficient means of storing data, just for different purposes. (And sometimes in cloud storage it makes sense to store data in a hierarchical storage system rather than an RDBMS _anyways._)

While the core of the game engine is the ECS, there is certainly a lot more going on. Networking, input, rendering - all of these are separate plugins. If the ECS is analagous to the filesystem, then built-in plugins are analagous to the kernel-level drivers and systems which come built-in to the operating system. If we were OS devs, we'd be creating user space _daemons._ Systemd acts as the glue between the kernel and user space. This is what q\_service aims to do, too.

For more consideration on plugins, see #link("#what-about-plugins")[below.]

==== Event-Driven Service-Oriented Architecture
<event-driven-service-oriented-architecture>
Services need to communicate with each other somehow. The normal way of doing this is to send events between systems. Thankfully, Bevy already implements events, both in the buffered and reactive/targeted varieties. q\_service mostly uses buffered events, though it's compatible with observers, too.

== Some implementation details
<some-implementation-details>
In order to discuss the benefits and downsides of this approach, we'll need to cover the highlights of the implementation. If you're satisfied with the theoretical argument above you can feel free to skip this section. If you're interested in using the library (or even contributing), I recommend you also #link("https://docs.rs/q_service/latest/q_service/")[read the docs.]

=== Encapsulation - States, Events, Hooks, and Scopes
<encapsulation---states-events-hooks-and-scopes>
Services are declared by implementing the #link("https://docs.rs/q_service/latest/q_service/service_trait/trait.Service.html")[Service] trait.

Services have two main states: Up and Down. These are pretty self-explanatory. If the initialization or deinitialization hooks are asynchronous, the service may be Initializing or Deinitializing on frame start, respectively. Additionally, services can fail, though in my model this automatically spins them down and is not represented as a separate state. You can determine if a service failed by checking its `DownReason`.

Services change state through #link("https://docs.rs/q_service/latest/q_service/lifecycle/commands/index.html")[commands]. They can be manually spun up or down, restarted, and failed. Services are also allowed to spin up at Startup by setting a flag when declaring the service. This is just sugar for manually spinning it up, but it's useful to have.

All of these actions will emit events which can be listened to with either #link("https://docs.rs/bevy/latest/bevy/prelude/struct.Observer.html")[Observers] or #link("https://docs.rs/bevy/latest/bevy/ecs/event/struct.Events.html")[EventReaders]. And, if you want to change the service's behavior, you can declare hooks for each of the lifecycle events: `scope.init_with`, `scope.on_up`, `scope.deinit_with`, and `scope.on_down`.

Finally, services would be pretty useless if they couldn't actually gate off some functionality. When creating your app, you can add service-scoped systems. These act like normal systems, except that they'll automatically be placed into a SystemSet which only runs when the service is up.

=== Dependencies - Resource and Asset Management
<dependencies---resource-and-asset-management>
Services can have dependencies, which can be other services, resources, or assets. A service will wait to spin up until all of its dependencies are up. This means that asset loads are automatically scoped for you. Similarly, resources declared in the service's spec will be added on initialization and removed on deinitialization.

When the service is spun down, it will clean up any automatically spun up dependencies. There is an important exception, though, which as of 0.2 I have yet to implement:#footnote[If you see any other issues like this _please_ point them out to me, I want this crate to be as robust as possible considering I plan on using it for a long time. (A benefits of writing long spec docs is that you catch easily overlooked features like this.)] any services which are manually spun up or initialized at Startup will remain active until they are manually spun down or they fail. You can opt out of that behavior by declaring the services as `owned`. In the opposite direction, if you want to keep an automatically spun up dependency around you can declare it `persistent`. You cannot mix `owned` and `persistent`.

== How does this fit in to the existing Bevy ecosystem?
<how-does-this-fit-in-to-the-existing-bevy-ecosystem>
Some alternatives exist which tackle various parts of the service model, but none of them do system encapsulation (afaik), and none of them bring it all together. I'd also love to cover what's going on in C++ land and the ECS environment altogether, but I really do not have the energy to do a thorough review of _two_ ecosystems.

=== Framework-style crates
<framework-style-crates>
#link("https://github.com/Zeenobit/moonshine_view")[moonshine\_view] is a Model-View framework for Bevy. This could offer a nice complementary crate to q\_service for layer separation as in #link("#lilguy-whatever-gif-enough-theory-egghead-give-us-an-example")[our example architecture below.] This crate does rely on the rest of the moonshine framework, though, so if you're not bought into that you might look for an alternative.

#link("https://github.com/IyesGames/iyes_progress?")[iyes\_progress] is a battle-tested crate for general-purpose asynchronous progress management. It's typically used to build load screens and things like that. It's likely that q\_service can provide _some_ of this functionality through async initialization, but its main focus is on system encapsulation. If you need general purpose state management without encapsulation, iyes\_progress is probably a better fit.

#link("https://github.com/NiklasEi/bevy_asset_loader")[bevy\_asset\_loader] is a far more full-featured asset loader. If you have a lot of assets, including dynamic assets, this is definitely the go-to crate for handling them. Again, it's a different domain and integration is possible. If you want to integrate, just add an AssetCollection as a resource dependency.

It's possible I may extend this crate in the future to enable compatibility with those mentioned above. I'm especially interested in adding bevy\_asset\_loader compatibility (which gives us iyes\_progress compat for free!)

=== Game Templates
<game-templates>
Templates like #link("https://github.com/TheBevyFlock/bevy_new_2d")[`bevy_new_2d`,] #link("https://github.com/NiklasEi/bevy_game_template")[NiklasEi/bevy\_game\_template,] #link("https://github.com/benfrankel/pyri_new_jam")[`pyri_new_jam`,] and #link("https://github.com/janhohenheim/foxtrot")[foxtrot] offer opinionated (and at this point, semi-canonical) ways to start up new projects. They offer core bindings like dev tooling, build tooling, asset management, state management, example level editing flows, and camera setup. I'm especially fond of the way `pyri_new_jam` #link("https://github.com/benfrankel/pyri_new_jam/blob/main/src%2Fcore%2Fmod.rs#L42-L78")[subdivides the Update schedule] for a more fine-grained approach to the application lifecycle.#footnote[Pyri also has the fantastic #link("https://github.com/benfrankel/pyri_state")[pyri\_state] and #link("https://github.com/benfrankel/tiny_bail")[tiny\_bail] crates to patch up some of Bevy's rougher APIs.] `bevy_game_template` offers excellent cross-platform support; and of course foxtrot is the one 3D example project here, often lauded for its cleanliness.

== Monoliths vs Service-Oriented Games
<monoliths-vs-service-oriented-games>
If I have one critique of these crates, it's that they're specifically designed for smaller projects. They all set up their game logic _globally._ These are then active for the lifetime of the application - great for a quick start but not flexible enough for a large game. I would propose replacing these global items with services, for example a service to handle physics, the main gameplay camera, player state, etc. We want to replace the monolithic design of a game jam game with the more flexible, extensible, and modular design of a service-oriented architecture.

As a small example, if you have an RPGMaker style game with a main gameplay loop, a map screen, and a battle system, you could easily gate these behind services. Without them, you'd have to manually finagle service sets, wait for asset loads, build out a load screen system, _and_ have all of these systems in memory for the entire lifespan of the game. Again, for a small example that's fine, but when you start building something like an open-world game, memory becomes a real constraint. When you spin down a service, all the memory-heavy assets and resources associated with the service are dropped#footnote[This is _mostly_ true. Assets are stored using handles, so if there is another strong handle alive somewhere in the world, the asset will not be dropped. This is a good thing!], and the compute-heavy services are disabled until the service is back online. One of the upshots of spinning down services is that you can easily spin them back up again.

Now you might argue that the whole point of ECS as an architecture is to keep everything as flat as possible. Entities, components, and systems are made to replicate the way computer hardware works, which is what makes them so efficient. I agree, and that's why I love the ECS framework. But, conceptually, we are mere humans and our minds do _not_ work with so many loose dependencies. We need to chunk behaviors into distinct concepts.

#callout(kind: "aside")[*The Service Composition Pattern* Services can be composed in a manner similar to components. You can easily declare a service which is comprised entirely of more complicated dependency services. For example:

```rust
struct MyService;
impl Service for MyService {
    fn build(scope: &mut ServiceScope) {
        scope.add_dep::\<ComplicatedServiceA>()
            .add_dep::\<ComplicatedServiceB>();
    }
}
```

Dependency is _not_ inheritance.]

=== #box[#image("../assets/lilguy/lilguy-question.gif")] Aren't lifecycles and dependencies already covered by component hooks and required components?
<arent-lifecycles-and-dependencies-already-covered-by-component-hooks-and-required-components>
While components recently got the opportunity to declare hooks and required siblings, they aren't the wide-scale singletons we want. We have a reasonable abstraction of a global data through Resources. Although #link("https://hackmd.io/_uB08OiAT4GqOXPE-X76eQ")[everything in Bevy is built on top of entities and components,] Resources as of yet #link("https://github.com/bevyengine/bevy/issues/12231")[do not support lifecycle hooks and dependencies.] (It's possible they never will.) Meanwhile, components can (#link("https://docs.rs/bevy/latest/bevy/ecs/system/struct.SystemId.html")[and do]) represent systems; they're stored as singleton entities similar to Resources. If an entity is a bundle of components, a service is a bundle of systems gated behind state flags.

If \#12231 gets implemented, this crate might be obviated, or at least need a restructure. That being said, there's a lot more going on here than just hooks.

=== What about plugins?
<what-about-plugins>
Plugins exist at the application level. They're designed to augment the application with additional functionality, so they're locked in at build time. Services are designed to live at the world level and exist specifically to add modular _runtime_ functionality. Different domains!

Once you start up your app, there's no way to load or unload a plugin. Plugin's don't offer dependency management either - if your plugin relies on a few other plugins to run, there's no built-in way to handle that.#footnote[#link("https://crates.io/crates/q_tasks")[I have a very simple crate if you're interested.]] If you need to wait for a certain asset to load, for example, there's no clear answer on how to do that unless you rely on #link("#lilguy-neutral-gif-how-does-this-fit-in-to-the-existing-bevy-ecosystem")[one of the crates discussed above.]

Again, you can think of a service as a kind of dynamic plugin. Whereas plugins encapsulate at build time, services encapsulate at run time.

==== Performance characteristics of services vs plugins?
<performance-characteristics-of-services-vs-plugins>
Services definitely have some overhead; they're not a zero-cost abstraction. But I would hope that a) the overhead is minimal and b) the benefits of cleanly grouping behaviors together would outweigh the cost of manually keeping track of all your dependencies. Consider this a note to do some benchmarking.

== #box[#image("../assets/lilguy/lilguy-whatever.gif")] Enough theory egghead!! Give us an example.
<enough-theory-egghead-give-us-an-example.>
#media("/media/architecture-2/example-architecture.png", caption: [An example game architecture. Click to expand.], linked: true)

Here's an example game architecture. It's a kind of layered architecture that you might see used in a Unity dev's MVC or MVP project, loosely based on chickensoft's #link("https://chickensoft.games/blog/game-architecture")[enjoyable Godot game architecture.]

With services, we can easily ensure that the dependencies of each one of these layers is up and running. We can mix and match services, turn them on and off. This gives us the control to have predictable behavior while still allowing us to build emergent systems.

As you can see, services are not the _whole_ of the architecture. They are a tool to allow cleaner, more consistent code. How you arrange them is up to you. You may even end up needing a service orchestrator vis a vis Kubernetes to control all your services after a while.

== Conclusion
<conclusion>
Whew! Thank you for reading all that, if you did. I've been working on this crate, and this essay alongside it, pretty much full-time for the last month. I'm always open to comments and criticism (despite there being no comment system on this website, yet). Also, I'm currently looking for work, and rent is expensive - so if you want to #link("https://ko-fi.com/cubething")[sponsor the project] I would really appreciate it :)
