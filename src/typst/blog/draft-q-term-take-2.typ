#import "_template.typ": *
#show: post.with(
  title: "qterm (2)",
  tags: (),
  draft: true,
)

\(This is a re-write of #link("/blog/draft-q-term.html")[draft - q\_term] since the design has shifted quite a bit.)

== Why use an OS metaphor?
<why-use-an-os-metaphor>
An ECS is essentially a way to manage state and perform actions on that state. It is so low-level that it doesn't have a concept of a 'class'. It's hard to think in this way. There are several existing patterns which bridge the gap between data and verbs, but I chose the operating system model because I believe it is generalizable and intuitive enough to most programmers to be useful. Frankly, I did it because I wanted to, it felt right, and I think I can work with it.

So in an ECS you have state (components, entities) and you have actions (systems). So you have _nouns_ (objects and their properties -- components and entites) and you have _verbs._ (actions -- systems). But the issue with thinking in Bevy is that everything happens _passively._ Systems are global state, like laws of a physical system. They describe action in the most general sense. This is wonderful if you're building a simulation, but it forces you into describing your action in the passive voice. Movement is applied _to_ entities with the `Dynamic` component; cameras are selected _by_ this system; etc. I find this difficult to work with. I want a way to describe my systems using the active voice.

Instead of saying "entities with xyz components have this happen _to_ them," I want a way to say "this command _does_ this." The flip from passive to active comes from _commands._ And there is some movement (albeit subterranean) towards command-prompt interfaces in Bevy, but nothing that generalizes to the degree I would like.

Truthfully, this all began when I decided to make a 'terminal emulator' which faithfully recreated ANSI escape codes, implemented in bevy\_ui. I didn't realize that, if I wanted to implement a proper shell with piping, job control, and blocking input, that I would need an entire _process_ abstraction. But that is what I landed on. And truth be told, #link("/static/media/logos/q_service.png")[I was always heading that way anyways.]

== A terminal emulator?
<a-terminal-emulator>
== The process model
<the-process-model>
