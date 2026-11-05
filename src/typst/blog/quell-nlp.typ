#import "_template.typ": *;
#show: post.with(
  title: "On NLP and Games as
Philosophy",
  description: "Some thoughts.",
  date: datetime(year: 2026, month: 11, day: 5),
  tags: ("qproj", "ai"),
  aliases: none,
  draft: false,
)

had some thoughts today, but I need to share some background first.

So the idea with Quell is to make a philosophical game. I was inspired by
Heidegger's conception of human emotion as revealing metaphysical truths to us,
that the negation of logic needs a deeper grounding. "The idea of 'logic' itself
disintegrates in the turbulence of a more original questioning. ... [N]egation
cannot claim to be either the sole of the leading nihilative behavior in which
[our being] remains shaken by the nihilation of the nothing. Unyielding
antagnonism and stinging rebuke have a more abysmal source than the measured
negation of thought. Galling failure and merciless prohibition requires some
deeper answer. Bitter privation is more burdensome." (Heidegger, tr. Krell,
"What is Metaphysics?")

That was about a decade ago. I've been reading and writing and learning to code
since then. This is my third, and most sustained, attempt to make this game a
reality.

The following thoughts are about whether or not a 'philosophical' game is
feasible at all. I've lately been experimenting with the idea of having a player
interact directly with NPCs via a free text input. This has lead me down the
road of using natural language processing (NLP) and research techniques in
argument mining to interpret dialogue. But so far I'm not getting very good
results, and I'm beginning to question if this is even the right approach.

---

NLP might not be needed. Removing it requires player cooperation -- but all
games do. I just finished playing Soverign Tower, which is an information-lock
gmae. There are guides. Outwer Wilds has been solved for a long time. Perhaps
the act of _original_ philosophizing is a bit out of reach for now. But no
literature has ever been so flexibile as to allow the player's opinions to
influence it. There's always a _thesis._ Soverign Tower has Epicrates convicne
hte player to tear down the tower. Outer Wilds discusses the end of a
civilization and what comes next. Disco Elysium is a static story, where the
politics are explored with no 'true' ending -- a thesis to itself, a form of
political nihilism? A study of the state? The insertion of the player's opinion
(as contra or tangential or irrelevant to the main thesis) destroys the work as
a static object. So it ceases to be what it is. -- Perhaps games as philosophy
-- in the sense of the stage upon which a player _does_ philosophy, as a new,
unique synthetic stance (and not in relation to an existing thesis) is
impossible by virtue of the game as a static object. Which is not to say an
artifact cannot be philosophical in the sense of proposing and defending a
thesis. This is, after all, just what philosophy texts, as literature, _do._

What distinguishes philosophy from science? -- I raise this because a game which
relies on free text would need to lay the tracks as it runs -- the world would
need to shift accordingly. NPC behavior &c would change, thus changing the way
the story progresses. We give it a starting point and a history and it moves
from there. (Earlier drafts of the game relied on this procedural nature, a la
Dwarf Fortress or RimWorld.) But analysis of this is analysis of one, or a
series of, possible worlds. Does philosophy proper need to be _universal?_
Ideal, Platonic? Or immanent, Deleuzian? What would it mean for it to be
immanentist? -- to engage with the _infinite_ rather than the
_ideal?_#footnote[I'm referring here to Delueze and Guattari's _What is
  Philosophy?_ where they describe the roles of philosophy, art, and science as
  relations between the human and the infinite.] The _scope_ of logic, as a
discipline, is infinite -- _all_ thought. Or, _ideal_ thought. Where do the
ideal and the inifinte distinguish themselves? Ideal as transcendent, _above_
reality; infinite as immanent, _within_ and _composite of _ reality.

\*

The way the static version of Quell would work is by presenting artifacts to
NPCs. You get to know them and can contact them via your soul stone throughout
the game. ITems may have strange consequences depending on context and who you
interact with; human draam stuff. ARtefacts are tagged with concepts. No player
notes describing the artifact and interpreting them; just _my_ interpretations;
the logic is there and static, the ideas are "objective." Feels like a bit of a
consession but this is at least a good first draft, and can be automated with
NLP later if desired -- if its not fun, or doesn't meet the expected outcome
(real engagement). -- This requires some faith in the reader to engage genuinely
-- but all literature does. And it's certainly less risky than free text input.

Mechanically, texts are tagged with concepts and stances about those concepts.
Presenting them to NPCs yields new paths, like free text but far more
constrained.

--

If you're interested in Quell and it's development, check out
#link("https://qproj-wiki.netlify.app")[the wiki] and the
#link("https://github.com/cubething-qproj")[github org.]
