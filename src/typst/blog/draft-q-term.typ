#import "_template.typ": *
#show: post.with(
  title: "Building a command prompt in bevy",
  description: "How I made q_term",
  date: none,
  tags: ("bevy", "devlog", "inspector"),
  aliases: none,
  draft: true,
  cover: none,
)

I'm making a command prompt for bevy. That's a lot harder than it sounds.

== The vision
<the-vision>
Game design is all about iteration. The faster you can iterate, the faster you can make something fun. I would like to be able to edit my game _in_ my game, while it's running, in a manner similar to Gary's Mod, or creative mode in Minecraft. But, the current state of bevy\_ui (0.18) is… not ready for that. It's getting there! But without a proper inspector, the user is left to do all the work manually - to compile and recompile with Rust's infamously slow compilation times. (#link("https://docs.rs/bevy/latest/bevy/app/hotpatch/index.html")[Hotpatching systems] is available but it only gets you so far, and I honestly haven't found it super helpful yet.)

Personally, I really enjoy working in a terminal. It's magical to tell a computer what to do, and have it _do_ it. So, why not build an in-game command prompt to help speed along development? This would allow me to execute arbitrary commands on the fly. Possibly, I could integrate scripting (with #link("https://github.com/makspll/bevy_mod_scripting")[rhai] or #link("https://github.com/jarkonik/bevy_scriptum")[ruby] -- if these crates get updated). But I would definitely want to be able to execute queries, modify the world, and save changes to a scene in real time. The best part is that this is possible without the headache of building up a full-featured editor interface - so why wait?

Several other crates exist for this purpose. #link("https://github.com/markspll/bevy-console")[markspll/bevy-console] has done something similar with egui, and #link("https://github.com/shanecelis/bevy_minibuffer")[shanecells/bevy\_minibuffer] is already on top of bevy\_ui. These are excellent crates and I've used them both! But, I would like to have something more closely resembling a full terminal written entirely with bevy-native components. So its time to roll my own.

== Prior Art - Diving into TE Implementations
<prior-art---diving-into-te-implementations>
=== What is a terminal, anyways?
<what-is-a-terminal-anyways>
A terminal is a program which interacts with an operating system, usually through text (though #link("https://en.wikipedia.org/wiki/Sixel")[not always]). Most of the time, users will be interacting with a terminal _emulator_, which operates within the GUI (or through a TUI, like termux). The terminal emulator replicates the behavior of a true terminal, or a TTY ("teletype"). The TTY takes in keystrokes and spits out text. That's it! The vast majority of a command line's functionality happens through a separate program called the _shell._

The shell lives a layer closer to the operating system, taking in user input from the terminal and executing commands - mostly through spawning processes. When you enter in a command, the shell hands execution over to the spawned process. Eventually the process exits, returning control to the shell, which then awaits the next command.

At a fundamental level, this is all that computer interaction _is_. At boot, a few system TTYs are opened, and shells are spawned. Graphical shells exist as well, such as the #link("https://en.wikipedia.org/wiki/GNOME_Shell")[GNOME shell] and #link("https://en.wikipedia.org/wiki/KDE_Plasma")[KDE Plasma.] These are what you typically associate with the desktop experience.

Most Linux distributions will serve around 6 TTYs at launch. (Modern distributions often have more. You can check how many you have by listing `/dev/tty[N]` - mine has 64.) But, if we have so few TTYs, and the TTY interface is the one way user input is interpreted, how can we launch more than 6 terminals at the same time? This happens through a PTY, or a _pseudo_ terminal. PTYs allow the system's dedicated TTY ports to be multiplexed, enabling terminal emulators to instantiate as many views as they need. The _vast_ majority of the time, when you're interacting with a terminal, it will be going through a PTY. You'll only ever see a real TTY if you have to switch over to text mode. You can do this by pressing `Ctrl+Alt+F[N]` in your graphical shell, or by directly connecting to a 'headless' device such as a raspberry pi.

It is important to note that just because the PTY is a _file descriptor_, that doesn't mean it's a _file._ File descriptors in Unix are the universal IO standard. The PTY is much closer to a pipe, with what is called a 'master' and 'slave' component. (Sorry, I didn't make the names.) The master file descriptor is held by the terminal emulator, while the shell holds the slave. Input (keystrokes) and forwarded from the TE to the shell, and output is forwarded from the shell to the TE. All the TE does is display the data, while the shell takes care of interpreting the keystrokes and doing all the programmatic stuff.

And finally, there's something called the _line discipline_ which describes how input is handled. There are two main modes, canonical mode and raw mode. The typical terminal experience is the canonical mode, where input is sent from the TE to the shell only after a submit event. In raw mode, useful for TUIs like vim and htop, the input is sent directly to the shell without any buffering.

==== Further reading
<further-reading>
There's a lot more to be said about terminals.

- For an awesome overview with interactive demonstrations and rusty code snippets, see #link("https://poor.dev/blog/terminal-anatomy/")[terminal anatomy] from Aram Drevekenin, creator of #link("https://zellij.dev")[zellij].
- For more on TTYs, PTYs, and multiplexing, see #link("https://biriukov.dev/docs/fd-pipe-session-terminal/4-terminals-and-pseudoterminals/")[this article by Viacheslav Biriukov.]

=== Storing the data
<storing-the-data>
In order to take in text and store it in an indefinitely-growing console, we need a buffer. The buffer should hold a statically allocated amount of memory and should truncate lines when the buffer overflows. This is a good fit for a ring buffer, so that's what everybody does. But what goes in the buffer?

Most modern terminal emulators (such as #link("https://github.com/ghostty-org/ghostty")[ghostty], #link("https://github.com/kovidgoyal/kitty")[kitty], and #link("https://github.com/alacritty/alacritty")[Alacritty]) use a grid of cells to store their data. For our purposes, Alacritty makes a good case study. What follows is a close reading of the code.

The base value for the Alacritty terminal is a `Cell`. Each #link("https://github.com/alacritty/alacritty/blob/master/alacritty_terminal/src/term/cell.rs")[`Cell`] corresponds to a character in the terminal alongside associated metadata such as styling information. `Cells` are stored in #link("https://github.com/alacritty/alacritty/blob/master/alacritty_terminal/src/grid/row.rs")[`Rows`,] which correlate to logical lines of characters. Rows are then stored in a #link("https://github.com/alacritty/alacritty/blob/master/alacritty_terminal/src/grid/storage.rs")[custom ring buffer,] which itself is stored in a #link("https://github.com/alacritty/alacritty/blob/master/alacritty_terminal/src/grid/mod.rs")[`Grid`.] The `Grid` implements virtual scrolling by storing references to visible lines in the buffer, alongside an offset for wrapping. Finally, there is the #link("https://github.com/alacritty/alacritty/blob/master/alacritty_terminal/src/term/mod.rs")[`Term`,] the high-level terminal interface, which handles most actions.

In Alacritty, there are two grids, one for scrollback mode (the default) and one for fullscreen mode (in TUIs such as vim). The `Term` also stores information about the current viewport and a bunch of extra TE stuff that we're not going to need.

Interaction is handled through a separate #link("https://github.com/alacritty/alacritty/blob/master/alacritty_terminal/src/event_loop.rs")[event loop,] which iterates over #link("https://github.com/alacritty/alacritty/blob/master/alacritty_terminal/src/event.rs")[buffered events.] The events range from user interactions like writing text to the PTY, to toggling the cursor blink, to exiting the terminal. Actual keyboard interaction parsing happens outside of the alacritty\_terminal library, in the #link("https://github.com/alacritty/alacritty/blob/master/alacritty/src/event.rs")[main application.] (Alacritty uses OpenGL through #link("https://github.com/rust-windowing/glutin")[Glutin,] which at a glance seems similar to #link("https://libsdl.org/")[SDL.])

=== Rendering the buffer
<rendering-the-buffer>
Bevy #strike[uses] _used to_ use #link("https://github.com/pop-os/cosmic-text")[cosmic-text] to handle text formatting.#footnote[Bevy's UI working group #link("https://github.com/bevyengine/bevy/pull/22879/")[recently switched] to #link("https://github.com/bevyengine/bevy/pull/22879/")[Parley.]The rationale for the change can be found #link("https://github.com/bevyengine/bevy/issues/21765#issuecomment-3856953775")[here,]with which I completely agree. Alice notes that cosmic-text lacks a public API for editing the underlying text buffer, something I found deeply frustrating. I also ran into some performance concerns while prototyping the console, so I think we're headed in the right direction with this change.] Since we're using cosmic-text for our text buffer, it only makes sense to take a look at how #link("https://github.com/pop-os/cosmic-term/")[cosmic-term] works. It just so happens to be a thin wrapper around alacritty\_terminal 😉 While alacritty\_terminal handles the inner workings of the terminal emulation, cosmic-term handles the input processing and rendering.

Most of our text pipeline implementation will mimic how cosmic-term #link("https://github.com/pop-os/cosmic-term/blob/108ba0dfe35c80e5fa0842f9ca0415fc8dcd5f27/src/terminal_box.rs#L265-L297")[lays out] and #link("https://github.com/pop-os/cosmic-term/blob/108ba0dfe35c80e5fa0842f9ca0415fc8dcd5f27/src/terminal_box.rs#L354-L800")[draws] its text. Thankfully, bevy already handles the majority of this through its #link("https://github.com/bevyengine/bevy/blob/main/crates/bevy_text/src/pipeline.rs")[text pipelines,] so we'll build on top of that.

That being said, we'll need to manually keep track of resizing and reflowing the buffer. This takes place at the grid level. Wrapping could be handled by cosmic-text, but the buffers #link("https://github.com/pop-os/cosmic-term/blob/108ba0dfe35c80e5fa0842f9ca0415fc8dcd5f27/src/terminal.rs#L306")[should _not_ wrap lines automatically] since we'll be handling that ourselves. Wrapping in terminals is a simple hard wrap, irrespective of the last character, but our underlying virtual scrolling container should allow other wrapping methods so that it can be used elsewhere, for instance in rendering long passages of text.

== Designing a Command Prompt for Bevy
<designing-a-command-prompt-for-bevy>
=== What does a command prompt need?
<what-does-a-command-prompt-need>
At its core, a command prompt is a program that takes in some text, executes a command, and spits out the results. A proper terminal emulator that interfaces with the operating system certainly meets these requirements, but adds a whole lot more. File descriptors, pipes, ANSI escapes, program execution and forking, etc.#footnote[Technically, most of this is stuff handled by the shell or the OS itself via the scheduler, with the terminal layer interacting only with the PTY. But I digress.] Most of these are things we won't need. For our purposes it's enough to have an input buffer, an output buffer, and a way to execute commands. Then, we'll need a way to render all of that to the screen.

The console is split into three main parts. There's the UI representation, which consists of the `Console` component and its corresponding functions. Then there are _actions_ and _commands_. Console _actions_ are events that affect the console. Examples include moving the buffer view, moving the input cursor, clearing the buffer, etc. Console _commands_ are user-defined commands which execute bevy systems to update the world. Essentially, the actions act as a shell, while the commands act as programs. The UI ties it all together, acting as the terminal emulator. #media("/media/q_term/comparison-dark.png", caption: [A comparison of a true terminal emulator and our command prompt. The TE corresponds to the console UI, the shell corresponds to the action handler, and programs in the OS correspond to events in the world.])

=== What does Bevy already do?
<what-does-bevy-already-do>
Before we figure out what needs to be done, we should asses what's already in place. So let's take a quick look at how Bevy handles text rendering.

As with everything, text rendering is handled through the ECS pattern. A `Text` component (or a `Text2d` component, though we'll be focusing on UI here) contains the raw text. The `Text` component is transformed into a `ComputedTextBlock` through a text rendering pipeline.

Rich text, i.e.~styling, is designed to work by adding child text spans to the primary `Text` component's entity. At render time, the `TextSpan` child entity's raw text is appended to the top-level `Text`'s inner value. So if you have "foo" in the top-level text, and "bar" in the child, you'd end up with "foobar." Each stylizable text element requires an accompanying `TextFont`, `TextColor`, and `LineHeight`, though these can be omitted as they'll automatically spawn through the `#[require]` marco. Finally, the top-level `Text` node requires a `TextLayout` component to tell the `ComputedTextNode` how to handle justification and wrapping. So, the requirement hierarchy looks like this (excluding some internal details):

#mermaid("flowchart LR\n\tText[\"Text[2d]\"]\n    Text --> TextLayout --> ComputedTextBlock & TextLayoutInfo\n\t\n\tj1(( ))\n    Text --- j1\n    TextSpan --- j1\n    j1 --> TextFont & TextColor & LineHeight")

A fully expanded entity hierarchy might look like this (simplified):

```rust
(
    Node {..},
    Text("first"),
    TextFont,
    TextColor(css::BLUE),
    TextLayout,
    TextLayoutInfo,
    ComputedTextBlock,
    children![
        (
            TextSpan("second"),
            TextFont,
            TextColor(css::RED)
            LineHeight,
        ),
        (
            TextSpan("third"),
            TextFont,
            TextColor(css::GREEN),
            LineHeight,
        )
    )]
)
```

…which would output "firstsecondthird".

The transformation from this tree to the `ComputedTextBlock` takes place in `bevy_ui::text_system` (#link("https://github.com/bevyengine/bevy/blob/628f6d477423d5240db4f05d760d8b6d45247906/crates/bevy_ui/src/widget/text.rs#L320-L386")[widget/text.rs:320-386]). Note that the same process occurs for `Text2d` (#link("https://github.com/bevyengine/bevy/blob/7a436e3aa18362eb8abee3c540f912d8a7b4ed2c/crates/bevy_sprite/src/text2d.rs#L163-L308")[text2d.rs:163-308]) - both use the same underlying text rendering pipeline.

== Designing the terminal layer
<designing-the-terminal-layer>
That's a pretty good start! If we can reuse the existing text pipeline then that would be great, so let's explore the possibilities for an ECS-based virtual scrolling buffer. At what level do we start building components?

=== Core Components
<core-components>
I'm going to rule out the possibility of each cell being its own component right away. It gives me a bad vibe. I imagine bevy could handle it, but it's still a lot of stress on the ECS for no good reason. I'm not entirely certain that cells should even have their own type, since styling information is handled through spans and not on a per-character basis.

Looking from the top of the abstraction ladder, we could encapsulate the entire terminal grid into a single component. But if we were to store the rows within that component, then we would have to start managing our own storage and lose out on the benefits of preexisting implementations. Instead, let's have a simple terminal grid with a vec of lines, each with a reference to the entity which contains its value and an offset into that value if the line has wrapped. Then, operations on this terminal component would provide actions like scrolling the buffer and writing text.

Perhaps each logical line could be a component, with a text span hierarchy quite similar to (if not identical with) what's already used for `Text`. Of course, the logical lines would need to be stored in order. There's precedent for this: the #link("https://github.com/bevyengine/bevy/blob/main/crates/bevy_ecs/src/hierarchy.rs#L151")[Child component] is just a newtype around `Vec<Entity>`. This is how `TextSpan`s get stored in order. So, we should define our own relationships (docs below) to store the line data and the buffer rows, with simple vecs of entity ids to keep track.

We could have the line references as individual components as well, following the hierarchy pattern above. Since this is order-preserving, resizing the terminal would simply result in replacing the terminal width and adding or removing rows as appropriate.

Great! So as a start, let's write some types. I've removed some extraneous details to make this easier to read at a glance, so the code in the repository will be different. Also, reading this code requires an understanding of bevy's component hooks and relationships, so take a look at the documentation (#link("https://docs.rs/bevy/latest/bevy/ecs/lifecycle/index.html")[hooks], #link("https://docs.rs/bevy/latest/bevy/ecs/relationship/trait.Relationship.html")[relationships]) if you need a refresher.

```rust
    /// A simple marker component for the command prompt.
    #[derive(Component)]
    #[require(
        TerminalCols,
        TerminalRows,
        TerminalLines,
        TerminalLayout,
        TerminalScrollPos
    )]
    pub struct Terminal;

    /// The number of columns in the terminal.
    #[derive(Component)]
    #[component(immutable, on_insert=Self::on_insert)]
    pub struct TermWidth(pub usize);
    impl TermWidth {
        fn on_insert(...) {
            // reflow
        }
    }

    /// The number of rows in the terminal.
    #[derive(Component)]
    #[component(immutable, on_insert=Self::on_insert)]
    pub struct TermHeight(pub usize);
    impl TermHeight {
        fn on_insert(...) {
            // reflow
        }
    }

    /// Relationship target for [`TerminalLine`]s.
    #[derive(Component)]
    #[relationship_target(relationship=TerminalLine, linked_spawn)]
    pub struct TerminalLines(Vec<Entity>);

    /// A single, newline-delimited logical line.
    #[derive(Component)]
    #[component(immutable)]
    #[relationship(relationship_target=TerminalLines)]
    pub struct TerminalLine {
        #[deref]
        pub value: String,
        #[relationship]
        target: Entity,
    }

    /// Relationship target for [`LineRef`]s.
    #[derive(Component, Default, Deref, Debug)]
    #[relationship_target(relationship=TerminalRow, linked_spawn)]
    pub struct TerminalLayout(Vec<Entity>);

    /// A reference to a logical line with a character offset into its full text value.
    #[derive(Component)]
    #[relationship(relationship_target=TerminalLayout)]
    #[component(immutable)]
    pub struct TerminalRow {
        /// Reference to an entity containing a [`TerminalLine`].
        /// If the line is empty, this will be None.
        pub line: Option<Entity>,
        /// Character offset into the line at which to begin this span.
        pub offset: usize,
        /// Relationship target
        #[relationship]
        parent: Entity,
    }
```

… and an example hierarchy:

```rust
(
    Terminal,
    TermHeight(3),
    TermWidth(15),
    TerminaLines(...),
    related!(TerminalLine[
            // entity 1
            TerminalLine("foo"),
            // entity 2
            TerminalLine("pretend this one is really long"),
    ]),
    TerminalLayout(...),
    related!(TerminalRow[
            TerminalRow {entity: 1, offset: 0}, // foo
            TerminalRow {entity: 2, offset: 0}, // pretend this on
            TerminalRow {entity: 2, offset: 15},// e is really lon
            TerminalRow {entity: 2, offset: 30},// g
    ])
    ]
)
```

It's important to note that the `TerminalRows` are the _full buffer_. I was stuck for a while trying to figure out how to flow only part of the text, but that makes no sense. Reflows only happen on user-initiated changes, and they need to be cached in order to scroll. So, it's okay (and necessary) to reflow the entire underlying buffer when terminfo (width/height) changes. However, when appending a new line, it's a waste to reflow the entire buffer, so we only flow the newly appended lines.

And lastly, just for fun, have a little diagram :)

#mermaid("flowchart TB\n\nsubgraph Terminal[Terminal Entity]\n\ttc[Terminal]\n\ttrows[TermHeight]\n\ttcols[TermWidth]\n\tlayout[TerminalLayout]\t\n\tlines[TerminalLines]\n\t\n\ttc --- j([requires])\n\tj ---> trows & tcols & layout & lines\nend\n\nsubgraph Rows\n\tdirection TB\n\tr1[TerminalRow]\n\tr2[TerminalRow]\nend\nsubgraph Lines\n\tt1[TerminalLine]\n\tt2[TerminalLine]\nend\n\nstyle Rows fill:none;\nstyle Lines fill:none;\n\nlayout --- j1([related])\nj1 --> r1 & r2\nlines --- j2([related])\nj2 --> t1 & t2")

=== Mutations
<mutations>
Any sort of terminal modification should occur through a `TerminalMsg` buffered event, including writing, resizing, and scrolling. This will prevent out-of-order execution of mutations, and allows us to sort messages by priority, for instance always appending before reflowing, and reflowing before updating the display.

The `TerminalRows` and `TerminalCols` components use a replace-to-update pattern, where inserting the component will execute a world mutation. In this case, changing the size of the terminal will result in a reflow.

It could be argued that having separate components for the terminal data points is overly cumbersome. Using an insert-to-update pattern introduces a possibly unnecessary layer of indirection within a buffered event flow. Since bevy is asynchronous by default, each component would, on insertion, need to write the relevant message to a buffer to avoid out-of-order errors, simply moving the buffer write a step up the call chain. However, having all the terminal data points on a single component means that mutable access to those data points would require unique access to the `Terminal` component. Additionally, we want to avoid users erroneously calling a mutable query on the terminal and its data points, since mutating these data points could have potentially serious consequences. So, if we make all the data points immutable with the insert-to-update pattern, we still get the buffered events while relying on type-level guarantees to avoid erroneous mutation and component locking.

== Displaying the results
<displaying-the-results>
=== Plain text
<plain-text>
In order of any of this to be useful, we'll need to put in on screen! The idea here is to utilize the already existing text implementations. Bevy UI starts with a `Node` component, which has a calculated width and height. From there, it would be simple to update the `TermWidth` and `TermHeight` components, relative to the line height and character width. But, we still need to add our UI hierarchy.

In order to do this, we could add a `TerminalWindow` component which contains a reference to a single `Terminal` component. The `TerminalWindow` will spawn a `Node` and automatically spawn `Text` and `TextSpan` child hierarchies as appropriate. So, something like this:

```rust
    /// A terminal display. Will spawn a new [`Node`] sized to the parent
    /// container and populate the hierarchy with [`TextSpan`] components according
    /// to the target entity's properties.
    #[derive(Component, Reflect)]
    #[require(
        Node
        Text,
        // ...
    )]
    #[component(immutable)]
    pub struct TerminalWindow(pub Entity);
```

In addition, each terminal could have multiple windows displaying its contents. So, let's add a relationship, which we'll require on the Terminal.

```rust
    /// Tracks which [`TerminalWindow`] entities are displayed by this node's terminal.
    #[derive(Component, Default, Reflect, Deref, Debug)]
    #[relationship_target(relationship = TerminalWindow)]
    pub struct TerminalWindowList(Vec<Entity>);
```

… resulting in a diagram like this:

#mermaid("flowchart TB\n\nj1([relationship vec]) --> tw1 & tw2(...)\n\nsubgraph t1[Terminal entity]\n\tTerminal ~~~ TerminalWindowList\n\tTerminalWindowList --> j1\nend\n\nsubgraph tw1[Terminal Window entity]\n\tTerminalWindow ~~~ Children\n\tChildren --> j2\nend\n\nj2([childof vec]) --> child1 & child2\n\nsubgraph child1[Child entity]\n\tTextSpan\t\nend\t\nchild2(...)")

But we've revealed an issue here. Each window should have its own representation, which means _they all must wrap the same buffer._ Was thinking maybe it would be better to have a single entity which stores all the rows? But that's not very bevyish (ecs maximalism). ECS paradigm means we can have parallel iteration over the TerminalRow entities whenever we need to update them.

Anyways. Key point: Must move terminal width, height, scroll position, line wrapping behavior et al to the TerminalWindow. The terminal itself is just the _underlying buffer._

Since we're now storing the `TerminalRow`s per window, we're going to have an additional $n =\|upright("TerminalLines")\|$ entities attached to the `TerminalWindow`. These entities are very lightweight, though, containing only an entity reference and an offset. (Rich text information will be stored on the underlying buffer lines.) So the underlying buffer's size scales with the size of the stored strings (a jagged, nonlinear growth, $O\(f\(s\)\)gt.eq O\(n\)$), but the memory footprint of the `TerminalRow`s grows linearly ($O\(n\)$). Additionally, these pointers can be replaced by iterating in parallel, speeding up reflow execution. So overall, it's more performant to utilize bevy's native array-of-struct framework than to switch to a manual struct-of-arrays approach.

Another way of putting this: Let the sets $R$, $L$, and $S$ be the domains of the row, line, and textspan entities, respectively. Then $\|L\|lt.eq\|R\|$ and $\|S\|lt.eq\|R\|$. We can think of line wrapping as a transformation, $upright("wrap")\(l\): L arrow.r R$ . Similarly, textspan layout could be $upright("layout")\(r\): R arrow.r S$. Note that $\|R\|prop upright("TermWidth")$ and $\|S\|prop upright("TermHeight")$.

#media("/media/q_term/layout-sets-dark.png", caption: [From lines to rows to the view. Click to expand.], linked: true)

Currently, the text spans have a 1:1 correspondence with the TerminalRows. This is fine for now, but the picture gets more complicated when we introduce rich text.

I'll leave the details of how the TextSpans are spawned and updated to the reader. Suffice it to say, we spawn and replace all children whenever the terminal width, height, or layout are updated. This happens whenever a new line is appended to the underlying buffer, or when the user resizes the terminal. Terminal resizing changes the `ComputedNode`'s size value, so we can use that to update the width and height, and from there we can update as needed.

There are some simple additions to this, such as scroll position and the measurement of character width which I'll leave as exercises. Or you can #link("https://github.com/ada-x64/qproj")[go see the repository.] For now, let's end this subsection with a video of our progress so far!

#video("/media/q_term/2026-03-04 13-12-41 (trimmed).mp4")

The video demonstrates multiple windows for the same underlying buffer, as well as text wrapping based on window and font size, and scrolling behavior. There is some flashing when resizing the windows with white backgrounds, which I'm unhappy with, but this seems to be an issue with the bevy text renderer, which goes beyond the scope of this crate.

=== Rich Text
<rich-text>
Our terminal is now rendering plain text. Great! But common tasks require text colorization, which means we need to support rich text. Here's an idea of how I'd like the API to work:

```rust
// potential macro invocation
let spans = term_writeln!(
    "This is some ",
    ("fancy", background=red, text=green),
    " text!"
);
commands.write_message(TerminalMessage::writeln_rich(term_id, spans));
```

… which would give us: "this is some fancy text!" This is implemented as vector of `VirtualTextSpanSpawner`, which will transform the appended strings and their associated styles into a `TerminalLine` and its `VirtualTextSpan` children. They look like this:

```rust
/// A single, newline-delimited logical line. Does _not_ include the
/// trailing newline.
#[derive(Component, Deref, DerefMut, Debug, Reflect, PartialEq, Eq, Hash, Clone)]
#[component(immutable)]
#[relationship(relationship_target=TerminalLines)]
pub struct TerminalLine {
    #[deref]
    pub value: String,
    #[relationship]
    target: Entity,
}
/// Marker component for an entity which acts as a virtual [`TextSpan`] for
/// the underlying [`TerminalLine`]. This component's range will be used to create
/// [`TextSpan`] child entities for the [`TerminalRow`] container entities.
#[derive(Component, Debug, Reflect, PartialEq, Eq)]
pub struct VirtualTextSpan {
    pub start: usize,
    pub end: usize,
    pub color: Color,
    pub background: Color
}
```

All in all, this isn't too different from what was done previously. The below schema demonstrates the text flow. `VirtualTextSpan`s reference the `TerminalLine` parent entity, which then is transformed into a series of `TextSpan`s and their respective styling information. `TextFont` info is propagated down the hierarchy.

#media("/media/q_term/rich text flow-dark.png", caption: [A diagram of the rich text flow. Click to expand.], linked: true)

At the moment, I don't want to allow setting the font, as this will undoubtedly mess up the character width calculation for those spans. There is no way to assure that users will properly set up font variations, so I'm leaving that for future work, if ever.

Let's leave behind the display concerns with this final screenshot, showing off some rich text! This should set us up nicely for whenever we want to go back and add text highlighting and clipboard support.

#media("/media/q_term/Pasted image 20260304222607.png")

== Writing a simple shell
<writing-a-simple-shell>
There should be a clear distinction between the terminal layer (storing and displaying the buffer) and the shell layer (modifying the buffer). The shell's responsibilities include: displaying a command prompt, parsing any input text into a format the terminal can display (e.g.~ANSI escapes, potentially custom syntaxes), and running commands.

This is actually the easy part! A command can be dispatched by executing an #link("https://docs.rs/bevy/latest/bevy/prelude/trait.Event.html")[event.] That's all it needs to be. However, we need a way to register valid commands so that we can execute them. I've settled on a simple type-erased map between the command id and a `ConcreteConsoleCommand` type which stores the command parsing information (currently a `clap::Command`) and the SystemId to execute.

Command systems must take in the corresponding `SubmitMsg`, which corresponds to typical inputs for executables (argv, argc). Otherwise they're free to do what they please.

As for parsing command inputs, there's precedent for using #link("https://docs.rs/clap/latest/clap/")[clap,] so that's what I'm doing. It might be nice to eventually support #link("https://github.com/rosetta-rs/argparse-rosetta-rs")[different parsing backends] (or to write something bespoke), but clap is certainly expressive, popular, and fast enough for me. Eventually, command auto-completion will be triggered by pressing `tab`, and will be populated with #link("https://docs.rs/clap_complete/latest/clap_complete/")[clap-complete] if available.

But, before we get there, we need to be able to write some text!

=== Designing the Input
<designing-the-input>
There have been several bevy\_ui native input crates. The two I prefer to reference are #link("https://github.com/rparrett/bevy_simple_text_input")[rparett/bevy\_simple\_text\_input] and #link("https://github.com/ickshonpe/bevy_ui_text_input")[ickshonpe/bevy\_ui\_text\_input.] However, neither of these really capture what we need. `bevy_simple_text_input` is a bit _too_ simple - we'll need to be able to wrap the lines as they come in, and we should be able to support multi-line prompts. Additionally, we'll need to support text highlighting and cursor movements. `bevy_ui_text_input` certainly supports this (and it's written by ickshonpe, who has more or less taken the helm on `bevy_ui` implementation), but it's based on `comsic_text`'s editor abstraction. Since we're working with Parley now, that's no longer the right abstraction - plus the cosmic editor implements its own wrapping. So we're not going to be able to use any third-party implementation for this.

So how do other terminal emulators handle this? Well -- they don't! All they do is send the text inputs directly to the PTY. Then, they read the results and display them to the screen. So, we're left with double-duty here. Probably the best thing to do is to create a separate entity for the text input - a shell - which has its own state. When we focus the `TerminalWindow` and send it key events, it forwards those events to the underlying shell. Separating it like this allows users to write their own shell implementations, should they choose to do so. But of course, we'll provide a basic one.

Separating the shell layer from the terminal layer requires us to implement some more complex behavior on the underlying "buffer." In particular, we're going to need to add a cursor. Any writes to the buffer will occur at the cursor location. Right now we're on a purely line-write based implementation. That's going to have to change. This will complicate the richtext implementation, but not too terribly much. And as an added bonus, we get ANSI-style cursor editing, enabling things like user prompts and #link("https://en.wikipedia.org/wiki/Curses_(programming_library)")[curses]-style TUIs. Not that we're going to implement any of that today 🙃

#media("/media/q_term/pty-model-dark.png", caption: [The PTY model. Click to expand.], linked: true)

Everything on the `Terminal` entity relates directly to the underlying buffer. (Eventually, this may be split into its own PTY entity in order to support other backends, such as a real PTY.) `VirtualTextSpan`s are generated when the PTY is read. This requires reading the entire PTY buffer. From there, `TerminalLine`s are generated which reference 1 or more `VirtualTextSpan`, and, finally, a `TerminalRow` is generated for each `TerminalLine` currently in view. -- Note that $\|upright("VirtualTextSpans")\|gt.eq\|upright("TerminalLines")\|gt.eq\|upright("TerminalRows")\|$.

Each chain the link requires the next chain to recalculate. So, a write to the PTY requires a recalculation of the `VirtualTextSpans` (at most once per frame), which requires the `TerminalLines` to reflow, which requires the `TerminalRows` to be recalculated. Similarly, changing the terminal size requires reflowing the `TerminalLines`, which requires recalculating the `TerminalRows`. Since all of this occurs at most once per frame, the fairly expensive recalculations shouldn't add up to any significant delay.

=== Parsing ANSI
<parsing-ansi>
Our PTY implementation is pure bytes. So, we need a way to transform those bytes into colors! Thankfully (???), there's a standard for that. #link("https://en.wikipedia.org/wiki/ANSI_escape_code")[ANSI escapes] are a standard method for terminal emulators to modify the display of the underlying buffer. This allows us to do #link("https://talyian.github.io/ansicolors/")[color escaping] (e.g.~1b\[31m, 1b\[45m), cursor movement, sound a bell, and #link("https://en.wikipedia.org/wiki/ANSI_escape_code#Operating_System_Command_sequences")[other things] like hyperlink encoding through extensions. Sounds pretty useful! But hard!

It's a good thing it's a standard. I'm using #link("https://docs.rs/anstyle-parse/latest/anstyle_parse/index.html")[anstyle-parse] to parse ANSI escapes from the underlying buffer. Our current text-span style display is fine for basic colorization, but it will be a BIG PAIN to support cursor movement.

#divider()
