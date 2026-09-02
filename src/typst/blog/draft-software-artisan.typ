#import "_template.typ": *
#show: post.with(
  title: "how to be a software artisan",
  description: "an ideology, or a manifesto of sorts",
  draft: true,
)

== intro
<intro>
#quote(block: true, attribution: [#cite(<benjaminOnewayStreetOther2021>, supplement: [58])])[#block[
#set enum(numbering: "1.", start: 8)
+ Anyone who does not simply refuse to perceive decline will hasten to claim a
special justification for his own continued presence, his activity and
involvement in this chaos. As there are many insights into the general failure,
so there are many exceptions for one's own sphere of action, place of residence,
and moment of time. A blind determination to save the prestige of personal
existence, rather than, through an impartial disdain for its impotence and
entanglement, at least to detach it from the background of universal delusion,
is triumphing almost everywhere. That is why the air is so thick with life
theories and world views, and why in this country they cut so presumptuous a
figure, for almost always they finally serve to sanction some wholly trivial
private situation. For just the same reason the air is so full of phantoms,
mirages of a glorious cultural future breaking upon us overnight in spite of
all, for everyone is committed to the optical illusions of his isolated
standpoint.
]]

Consider this my justification for the fact that I like to do things the way I
do them; my apologia for not currently having a job in machine learning; the
reason I am making a game, a website, seeking attention generally. The bourgeois
liberal order has been in crisis for the past century at least, and as a
non-binary Kansan I'm experiencing the decline first hand. We're seeing it most
actively in the United States with the dual elections of Donald Trump, and
globally with the general rise in extreme politics on both sides of the
spectrum. Political breakdown incurs radical breaks with the old regime.

I want to explain to you what I mean when I say I am a software artisan. First
we, should distinguish artisanship from similar ideas. Artisanship is not
#link("https://manifesto.softwarecraftsmanship.org/#/en")[craftmanship.] It is
not
#link("https://thoughts.melonking.net/guides/introduction-to-the-web-revival-1-what-is-the-web-revival")[nostalgia.]
It is not anti-AI, Web3, or anything else, so long as that anything can be put
to good use. "Artisanship" is the process of creating something lovingly and by
hand, for practical and artistic purposes. "Software artisanship" is just that -
artisanship for software. At its core, the artisanal craft is not designed to
make money. It knows nothing of capital.

== critique of the web revival movement
<critique-of-the-web-revival-movement>
The
#link("https://thoughts.melonking.net/guides/introduction-to-the-web-revival-1-what-is-the-web-revival")[web
revival] is a counter-culture, mostly with leftist politics. It focuses on the
handmade, the crafted, the messy. It is nostalgic (as all culture in the 21st
century seems to be), pulling on oldweb aesthetics and striving to be as loud
and unsellable as possible. The ethos is anticapitalist at heart. Advertisements
are antithema to the movement. Paying for web services is generally frowned
upon, as is designing for mobile or having expertise generally. This is likely a
cope for their own frustrations and pride at having created a genuine piece of
net art - one platform is work enough! And that's fair, many of the revival
netizens are teenagers or otherwise not deeply skilled in web development, so I
can't blame them for their pride or immaturity.

Most netizens use #link("https://neocities.org")[neocities] to host their sites.
It's all static HTML/CSS/JS - no backends, no services. Most stateful things
like chatrooms are handled with a script they've copy/pasted from somebody
else's website like it's Neopets. Generally, this is great! I'm all for
individuals having creative freedom and a community to share their thoughts
without corporations profiting off of them. I love exploring the pages on
#link("webrings")[webrings] and listings, there is a genuine sense of discovery
and play which has been desperately missing from the web for a few decades
now.#footnote[I'm aware I'm coming at this a few years late - I've been
following the movement for a while now but haven't participated or said much
about it yet. Too sucked into my doomscrolling to see what's happening in front
of me.] That being said, I have concerns about the decentralization of the
smallweb.

The problem is with networking - how are we meant to find each other behind the
wall of unnavigable web searches? AI slop has essentially put us back at the
dawn of the dotcom bubble, when search engines were just becoming a thing. We
have the advantage of hindsight, but webrings, forums, and listings can only do
so much. I'm a big fan of RSS and use #link("https://rssby.email")[rssby.email]
to keep up with blogs and other smallweb content, but this is still difficult
for the non-technical person to use, yet alone deploy for their own sites. This
is why I switched to bluesky and am enthusiastic about
#link("https://atproto.com")[the ATProtocol] it's built on.#footnote[The primary
problem with Mastodon as a service (at least when I last tried it a few years
ago) was in its usability and general mood of exclusivity. I could never figure
out how to make a proper account on half the damn sites; choosing a site to host
my account on - yet alone _switching_ sites - and figuring out how to curate my
feeds was a huge pain the ass. Practically speaking, if nobody _uses_ it then
there's no chance it's going to be revolutionary. But, the idea of federation is
deeply important and we are indebted to
#link("https://activitypub.rocks")[activitypub] for it. Bluesky did it right
with the invite-only beta and its general focus on polish and design. It's
intended to replace old Twitter in look and feel, and it's done a damn fine job
of it.] The project is young, but I see it solving many of these concerns.
Bluesky is likely to continue as the primary ATProto implementor, but its
open-source and fairly easy-to-use nature makes it a great candidate for future
federated web frameworks. Sites like neocities could integrate --
#link("https://itch.io/user/settings/bluesky")[itch.io already has]. And I think
it's _excellent_ that Bluesky is available as a centralized service. Most people
just do not care enough to curate their feeds, operate on multiple federated
servers, or explore webrings - and once they do, it is even more work to
maintain those links and bookmarks. This is why algorithmic feeds have become so
popular - they make the work easy. And, ironically, this is the point of
webrings and databases as well. They're curated, niche feeds - just smaller, and
hand-picked rather than automated to the point of incomprehensibility.

I don't think that the net revival is sustainable. The web they strive for was
rural, dotted with shoddily-made houses and some small communities. As the
userbase grew - and as capital interest saw the potential of the web - larger,
centralized communities began to form. People moved to the cities, servers where
they could see one another on a regular basis - but to live there for free they
had to give up their privacy and comfort. As people urbanized those cozy old
houses broke down, shuttered their blinds, and decomposed. The endpoint is
paranoia, distrust, disinformation; a nostalgic yearning for a past which never
truly was. After Musk bought The Website Formerly Known As Twitter, and as AI
continues to bilge out its nonsense, people are once again seeking refuge in the
countryside. But their online cottagecore fantasy is ultimately only a fantasy.
It's a lot of work to live in the country, and the (petty-)bourgeois now
inhabiting the outer lands are not accustomed to it. Speaking as a web
developer, somebody who does this professionally and as a hobby: there's a
reason geocities shut down. Servers cost money. Net art is famously volatile.
Nothing lasts forever.#footnote[This is why we need
#link("https://archive.org")[archives] (#link("https://annas-archive.org")[2]).]

I don't want to make light of the travails of the modern internet user. I think
the netizens have the right idea in spite of the flaws in their ethos, and I
want to make it clear that I am definitely their ally. They're the beating heart
of the movement away from slop, the undercurrent fueling projects like
#link("https://kagi.com")[kagi] and
#link("https://xeiaso.net/blog/2025/anubis/")[anubis] which hope to make the
internet usable again.

== artistry in the mundane
<artistry-in-the-mundane>
The loud and youthful aesthetic of the web revival does not appeal to everybody.
Not to be a buzzkill, but it's not _practical._ It's brittle, arrogant, brash,
sometimes annoying. This is why we love it, but as adults living in a society
with our own children and the need to make money and live comfortably, the web
revival is not enough.#footnote[Some would call this tendency of the reactionary
left an
#link("https://www.marxists.org/archive/lenin/works/1920/lwc/index.htm")["Infantile
Disorder."] #cite(<leninLeftWingCommunismInfantile1920>)] Expressionism alone is
not enough, artistry is not enough - we need to act as artisans.

*Artisans make practical goods. Chairs, lamps, tables, desks; they infuse their
expression into the stuff of our lives. Why should software be any different?*

In the dialectic of our collective Internet presence, AI slop represents the
thesis of the free service model: spyware
#link("/blog/edgelord-eschatology.html")[on an apocalyptic level], our lives
scraped and conglomerated,
#link("https://web.dev/learn/privacy/fingerprinting/")[fingerprinted]
(#link("https://www.amiunique.org/fingerprint")[2]) and sold phantom goods with
money we don't have. As a friend tells me, "if it's free then you are the
product." The web revival attempts a backwards step, the antithesis which has
lied dormant, hidden in plain sight. It's clear that neither are sustainable.
Software artisanship is the synthesis, the only logical next step.

There has been
#link("https://en.wikipedia.org/wiki/Arts_and_Crafts_movement")[movement in this
direction before]

This is a test edit. Another test edit. I should see it occur immediately.

#bibliography
