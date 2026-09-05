#import "_template.typ": *
#show: post.with(
  title: "qproj - general introduction",
  date: datetime(year: 2025, month: 4, day: 30),
  tags: ("devlog", "qproj", "concept"),
  aliases: none,
  draft: false,
  cover: "/media/field-sketch-4-26-25.jpg",
)

#callout(
  kind: "note",
)[links in this article may not yet be filled in. I hope to add more details as I continue development.]

Hi. 🙋‍♀️ I'm #link("https://github.com/ada-x64/qproj")[making a game.]

#media(
  "/media/field-sketch-4-26-25.jpg",
  caption: [Sketch of a field with flowers and grass out to seed. Enframed in the center is the skyline of a small city beset by lightly forested mountains. Looming ominously over the city is a giant eye, fixed in the sky and looking down at the settlement. The palette is lilac and indigo over plain white paper.],
  linked: true,
)

== #box[#image("../assets/lilguy/lilguy-neutral.gif")] what's the concept bub??
<whats-the-concept-bub>
Quell (title tbd) is a roguelike set in a procedurally generated open world. In this game, you play as #link("Basil")[Basil], an intrepid young academic who is sent out of #link("the city")[the city] on an expedition to gather artefacts from before #link("the fall")[the fall].

As of writing (27 April 2025), the exact details of the story and the gameplay are still up in the air. The only solid things so far are the open-world exploration, artefact gathering, and magic system.

=== #box[#image("../assets/lilguy/lilguy-question.gif")] wait there's magic?
<wait-theres-magic>
Yeah. Basil is a scholar of "logical magicism," or something with a similarly pretentious name. This field studies the foundations of magical energy in the psyche. It can be seen as a parallel to the #link("https://plato.stanford.edu/entries/logical-empiricism/")[early 20th century's focus on the logical syntax of language] as the driving force behind rationality. In the game world, magic has been around for millennia: it's a driving force of society, but before the fall it was mostly seen as a cheap trick to goad schoolchildren into pursuing academia. No serious technologies had managed to make their way to the fore - until #link("spirit stones")[spirit stones] were invented. These devices allowed instantaneous communication across immense distances and were essential to focusing enough magical power to create practical magical technologies.

Now, magic in Quell doesn't work like your typical adventure game. In Quell, magic is based on real philosophy.

=== #box[#image("../assets/lilguy/lilguy-whatever.gif")] philosophy?
<philosophy>
Stick with me. Video games present a unique opportunity to explore philosophical concepts. As part of the game, the player will go around collecting fragments of real philosophical manuscripts (preferably ones that are not copyrighted, or that are paraphrased if not otherwise available). I'm not yet certain how to tie the manuscripts into the world of the game mechanically. I figure I will have an in-built note-taking system to keep track of ideas and track the interconnections. The primary usage of the manuscripts is to teach the _player_ about various ideas, which will inform how they interact with NPCs and progress the story. All of this is to play into the ongoing narrative, which explores personal trauma and revolution.

=== #box[#image("../assets/lilguy/lilguy-wow.gif")] … and revolution? like marx and shit?
<and-revolution-like-marx-and-shit>
yes, like marx and shit. The main philosophical bent of this game is critical-theoretical, straddling the line between philosophy as abstract and philosophy as active.

#quote(block: true, attribution: [#cite(
  <ThesesFeuerbachKarl>,
)])[Philosophers have hitherto only~_interpreted_~the world in various ways; the point is to~_change_~it.]

My focus in college was on early 20th century philosophy, when thinkers like Adorno and Horkheimer were creating the field. Of course, they have been dead for a while, so I'm pulling from contemporary queer theory, feminist thought, critical race theory, and the digital humanities.

===== #box[#image("../assets/lilguy/lilguy-neutral.gif")] ok that sounds pretty relevant to our times
<ok-that-sounds-pretty-relevant-to-our-times>
=== #box[#image("../assets/lilguy/lilguy-thinking.gif")] but why a video game? isn't a book a better format for a philosophy project?
<but-why-a-video-game-isnt-a-book-a-better-format-for-a-philosophy-project>
Sure, books are the more traditional way of going about it, but video games offer a unique perspective. Buddhist thinkers have always considered right action a part of thought; the Stoics were known practical philosophers. Right living has been the focus of philosophy for the entirety our existence. Only since the Enlightenment, particularly the dawn of the age of secular rationality, did we lose track of that. Video games, as simulations and as interactive media, have a unique potential to bridge the gap between the static (the game assets, including the writing) and the dynamic (the interactive element). I'm sure I'll have #link("more to say on that later.")[more to say on that later.]

== #box[#image("../assets/lilguy/lilguy-question.gif")] sure but how are you making it
<sure-but-how-are-you-making-it>
I'm using #link("https://bevyengine.org")[bevy], an ECS-based game engine written in Rust with a strong and active community.

=== #box[#image("../assets/lilguy/lilguy-whatever.gif")] an experimental game engine? c'mon.
<an-experimental-game-engine-cmon.>
Although Bevy is in early development it's showing really great promise. Honestly, I mostly chose it because it is an ECS-based engine written in Rust. Most game engines are written in C++, and although I _can_ write C++, I am sane and therefore do not enjoy it.

=== #box[#image("../assets/lilguy/lilguy-question.gif")] why not use a normal game engine like unity, godot, or unreal?
<why-not-use-a-normal-game-engine-like-unity-godot-or-unreal>
I have tried working in Unity and Unreal. Neither spoke to me. They're bloated as hell, and although I would probably get a job if I just switched, I can't do that and be creative at the same time. When I was a kid I used #link("https://gamemaker.io/en")[GameMaker] (#link("/media/gm8.jpg")[8!]). The simple, file-tree-based editor never stopped appealing to me. I prefer to work mostly in an IDE, and that's what Bevy offers me.

When they say Bevy is "refreshingly simple" they really mean it. Bevy does not come with "batteries included" -- it has a renderer, an ECS, an increasingly robust asset system… and that's about it. No graphical editor included, no prefabs ready to take and play with. It's a game engine for people who love game engines, and as somebody who has #link("https://github.com/ada_x64/sundile_rs")[written one in the past], it is everything I wanted and more.

Naturally, this has its risks. Every three months or so Bevy releases a breaking change. However, they publish good migration guides and the crate is well-documented. And, if I find a bug, I can contribute back to the community!

=== #box[#image("../assets/lilguy/lilguy-smug.gif")] that sounds hard. i bet you haven't even started lol
<that-sounds-hard.-i-bet-you-havent-even-started-lol>
#media(
  "/media/screenshot-4-25-25.png",
  caption: [A screenshot of a Windows application with three docked windows. In the center there is a window with a tab entitled "GameView" from which we can see a procedurally generated environment and a rainbow-colored sphere floating.],
  linked: true,
)

No, #link("https://github.com/ada-x64/qproj")[I've been working on it for a while now.] In fact, this is attempt number… 3? or so to make this game. The past few attempts have been with my own engines. Just like #link("building this website")[building this website], I found that using #link("https://quartz.jzhao.xyz")[a flexible, pre-existing framework] allows me to focus on my creativity while giving me the room to customize.

It seems like every few years I come back to this project. This time, 5 years into my life as a #link("/blog/draft-software-artisan.html")[draft -- software artisan], I'm hoping to really make sure the development process is solid, so that when I inevitably get sidetracked by life or work I am still able to pick it up in short order.

As development proceeds, I intend to upload builds that you can interact with. (Note that I don't intend to ship to WASM, you will have to download the builds.) It will be a good while until I have anything really playable, but that's part of the process - and part of the fun! I hope to keep this blog updated every month or so with a development log. They'll probably mostly be technical. In addition, I post frequent updates #link("https://bsky.app/cubething.dev")[on my bluesky], so be sure to follow me there if you want to keep up 🙂

\*

Thanks for reading. *See you next time.*

#bibliography
