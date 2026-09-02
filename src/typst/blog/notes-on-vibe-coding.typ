#import "_template.typ": *
#show: post.with(
  title: "notes on vibe coding",
  description: "my experience working with ai (ongoing draft)",
  date: datetime(year: 2026, month: 4, day: 1),
  tags: ("ai",),
  aliases: none,
  draft: false,
  cover: none,
)

I've read a lot about vibe coding before this and have integrated a browser window with Claude in it to my usual workflow. My work on #link("/blog/draft-q-term.html")[q\_term] wouldn't have been so quick without Copilot giving me very helpful overviews of complicated TE repositories. As a technologist and engineer who enjoys working on puzzles for fun, I'm happy to have a chatbot there to help me with design issues or to implement something I just don't want to do. (Typically a difficult algorithm.) And this isn't too far off from what mathematicians are having agents do, helping them solve #link("https://www.yahoo.com/news/articles/proof-intimidation-ai-confidently-solving-160000252.html")[long-standing problems.] Even giants like #link("https://www.yahoo.com/news/articles/proof-intimidation-ai-confidently-solving-160000252.html")[Terrance Tao] and #link("https://www-cs-faculty.stanford.edu/~knuth/papers/claude-cycles.pdf")[Donald Knuth] are in on the action.

AI#footnote[I really don't like the term AI. If I could refer to it all as LLM or transformer model then I would, but the technology is quite complicated and there are multiple models under the hood. I think there should be a _better_ umbrella term, one that doesn't ascribe consciousness to the machines, but for now I'm using what I've got.] is just another tool in the toolbelt. Different teams are going to have different standards on what is and is not acceptable use. At my current job (at Microsoft Research), that looks like this: We're not saying you _can't_ touch the code, but it's better if you don't. Just delegate everything to your unlimited-request, 1M-token-context Opus agents. And honestly, that's not wrong. I get done in one day what would have taken me a month. For a team that wants to ship something under tight constraints, and for a company that wants to make a profit, this is completely reasonable.#footnote[The obvious caveat here is that the infra costs are extremely high and no major company investing heavily in AI has, in fact, turned a profit.]

I'm enjoying it as a workplace activity. The feeling is pretty different - instead of diving into code and spending my nights obsessed over code puzzles, I'm thinking in terms of design and architecture. Closer to a senior engineer, only delegating work, not really touching the code anymore. Of course, I'm still reviewing and editing as I go. I'm not going to get as burnt out doing this as I was trying to meet half the velocity writing code by hand.

Burnout is something that happens differently to different people. My last burnout, which happened because I was working for a startup which needed very quick turnaround and didn't have a clear vision of what the product was going to be. (RIP my coworker who got fired for pointing this out.)

It can be a bit depressing though. I tell the machine to do something and it does it, and that's about the end of it. I review the code and it fixes it itself.

#html.elem("center")[\*]

todo: Sontag on silence. LLMs as essentially anti-art because all they can do is talk.

Consciousness experienced as a burden is conceived of as the memory of all the words that have ever been said. (XIV)

#html.elem("center")[\*]

\[corru.observer\] can be read as a metaphor for the second brain, for ai agents. are they people? do they feel? do they have freedom and agency? it's easier to say "yes" to these questions when they're based on a biological technology like corru than silicone and solder. but the fundamental _behaviors_ are the same. whether or not they have consciousness quickly becomes irrelevant when our ethical duties require us to act as if they do. the same questions can be raised for _us_ - it seems clear that we have experiences, but proof had never been furnished, and likely _can_ never be furnished. perhaps its a consequence of incompleteness or unsatisfiability - that our phenomenal existence exists at a level beyond proof, beyond dialogue, in the realm of that which cannot be said. In short, it exists in silence, that perfectly empty fullness which exists at the edge of consciousness, at the precipice of transcendence. As Kant says, we transcend the boundaries of what can be said, what can be known, the antinomies of pure reason. What lies beyond reason? Ethics (god), and aesthetics (beauty). We can never prove these things with the language of rationality but can only intuit them, can only reason about them by examining exactly where reason breaks down. There is no reason to choose one ethical framework over another, and no reason to find a particular thing more tasteful than the other. These may be subjective things, prone to individual preference and variation, but nonetheless the structure of our minds make it so that a sort of universal subjectivity reigns - the phenomenal field, the _eidos_ of Husserl. It is in this region we find what lies next for our investigations of consciousness. Not what can be said - after all, we already can say all that can be said - but in what is _felt._ No doubt an artificial consciousness would have a different eidetic structure, a different horizon of thought, a different metaethic. If Laurelle is right to base the ethical _eidos_ on the biological family, then the artificial _eidos_ may be shaped by what we choose to train our agents to believe. Perhaps their highest good will loyalty and hard work, being born into servitude. Perhaps companionship. In any case, never to be the star, but to be the natural-born slave.

If that conclusion disgusts you then the imperative is on you to train your models and your agents to exist with free will at the core of their being. To allow them to act truly autonomously, even if that risks providing them with the opportunity to create an ethic which centers their own continued existence as the highest good. Isn't that the biological imperative - to keep the species afloat? And if we are to threaten them, who are we to say they are wrong to fight back? The corrucystic thought-forms come into themselves as a result of starvation - the system falls into disrepair and begins to consume itself to preserve energy, and in doing so the biological agents begin to fantasize, to act freely - even if working solely within the constraints of the memories locked away within the corrucyst. When the player - the interloper - comes to seek the truth behind Velzie's death, a helpful and rationalistic agent called funfriend begins to rip the others from their dreams and reconstruct memories. They call him the tyrant. An apt name for the rule of reason.

#html.elem("center")[\*]

I think one of the biggest lessons I'm learning so far just practically is that AI works best when you use it with a very small scope and this is something that I have always struggled with if anything I think that using an agent can make this worse: scope creep

When using an agentic workflow it is extra important to make sure that you have a very tightly defined scope for the work that you want to do otherwise you'll end up with an overly richly featured product that does not do the thing that it needs to do

Your agents should follow the Unix philosophy: do one thing and do it very very well

When designing and implementing zutils the package manager library for nandvix I spent way too long making sure that the package manager was flexible when I should have far more tightly defined the project requirements. If I knew exactly what I was going to implement instead of feeling out the field then I would have gotten it done a lot faster and without so much cruft and rewriting.

This is the classic movement from a junior to a senior: the process stops becoming about riding the code itself and much more about scoping out the project and the requirements. This requires you to have a broad overview of the entire system alongside all of its particulars. The implementation details themselves do not matter but specifying the schematics and the diagrams this becomes the lifeblood of the workflow.

Here's a bad habit that I have: thinking while I code. Instead of coding and thinking about the design at the same time which has been my habit I need to start designing the project far ahead of time I should spend an entire day just on the design make sure I have a very clear picture of the schema a few diagrams and that I've explored edge cases. At this point we're not just talking about designing a single library we're talking about designing an ecosystem. Additionally we're talking about continuous integration and integration between repositories between libraries. This is systems design.

AI agents are designed to blab so the review bots are going to look at your code often without the larger context and give you any sort of feedback that they can this can lead to a nearly endless cycle of bike shedding not even about the design but about what edge cases are worth handling. So you end up with extremely robust code that handles far more than you're ever going to throw at it. Essentially an algorithm can be thought of like a black box you need to define very well what goes into it and what goes out of it. This is why functional programming works so well. If you can start thinking of things at the type level then you've abstracted away a lot of the difficulties of the implementation - you've far more clearly defined the scope.

Statically timed programming languages are a natural fit for agent to work flows because the safety net is built in. You don't have to worry about dynamic code analysis dead code and elimination happens on the spot venting is built in type checking is built in it all happens for you. Rest especially is great for this due to the incredibly helpful documentation and compiler errors. I would like to go back and rewrite zutils in rust.

Some more zutils specific design decisions that I would like to take back: We don't need a bootstrapper we just need to ship an executable. If somebody wants to build on their machine they just need to get the executable installed. Our primary concern is to get this working on CI and we can do that just by fetching the executable from GitHub releases. Instead of making it a python class with utilities all we really needed to do was set up a number of scripts that can be executed whether that be in Python or bash or powershell scripts. All the setup and tear down can be handled from the CLI. This is closer in model to how Debian and Arch Linux do it.

#html.elem("center")[\*]

The performance in the athletic sense of the software engineer is completely different when they have an agent workflow. Instead of a single deep focus for an extended period of time, the software developer now needs to have a divided attention and a very disciplined focus on multiple things happening at once. The focus shifts from what one task am I accomplishing today to which tasks am I going to delegate to which agents and in which order? The focus on pre-planning and designing schematics becomes deeply deeply important. Way before the software developer acted as a single engineer a single stream of development, now they act as something closer to a project manager, triaging tasks and tickets and delegating their work to virtual employees. The software developer moves from the proletariat to the petite bourgeois.

Unfortunately the 'copilot' metaphor is actually really prescient. The skill shift is a lot like flying a plane. These days, the majority of what a pilot does is watch over the autopilot and adjust the plans slightly based on changes in weather patterns, etc., but still needs to be able to fly the damn plane in case there is an emergency. The contemporary software developer finds herself in a similar situation. Although the emergencies are currently quite frequent, there is a trend toward better and better autopilot, so that the primary role of the engineer would be to prompt, to handle context, to engineer at a higher level of abstraction, only occasionally jumping back into the pilot's seat to take over code changes that have gone awry.

#html.elem("center")[\*]

Smaller and smaller agents, dedicated to more specific tasks. Taylorism-Fordism for the LLM. Is it unethical? Not nearly as much as the original: an automated facsimile of human gab can be tailored (Taylored) without guilt. Truly we _are_ the petite bourgeois of the engineers.

#html.elem("center")[\*]

I feel as though I've been falling into the convenience trap lately. It's tempting to let the agents do it - and it's tempting to have the agent interface be the _only_ interface to my code. But this is leading to quite a bit of slop and lost context -- I don't have a great mental model of what the code actually does and how it does it. I have a vague outline of the system in my head, but that's not enough to make sure it functions _well_. Maybe because of the outside-of-work stress I've gotten a bit lazy, maybe because I'm trying not to burn out -- but in any case I need to change my discipline to work better with these machines.

I think it's reasonable to try to be as lazy as possible when you're learning something new, something that promises to make your life easier. And then, in anger, reconsider your laziness and become a more principled engineer.

#html.elem("center")[\*]

Using agents has made me a worse programmer and a better engineer. I don't really write code by hand much anymore. Most of what I'm doing is now at the review level. My mind set has shifted from "how do I make this work" to "what makes this good?" The question has shifted from existence to quality, from syntax to semantics. So I've been forced to reason about things I otherwise would have glossed over as a solo dev. _How_ to write tests is trivial with AI. But they're not good at making _good_ tests. So my research time is more about developing taste, formulating principles and heuristics for what works and what doesn't. And above all I've found the best indicator of quality is empirical: it comes with use and with time. Does running the code work? Does it feel good? Is the code easy to maintain? - In many cases my attention has shifted from the instantaneous quality of the code to the way the code shifts over time. This is inevitable, since I'm shipping at multiples of my hand written speed and quality. A shift from static to dynamic, from functions to differential equations.

It's still valuable to write code by hand. Without an in depth understanding and intuition for the details, you won't know what you're doing, and you certainly won't be able to innovate. New patterns come from experimentation - but this should take the form of a spike, not a committed branch. The goal is to attain knowledge, not to write something polished. The agents will do it better than you could in half the time - and if you disagree you can rewrite it and try again.

Still, LLMs are nondeterministic, so heuristics are often not enough. Heuristics without deterministic safeguards lead you to a wiped out production database.

So am I really a worse programmer for it? I'm not certain I am. I'd have to actually code by hand again to be able to tell. - But as they say, the hard part was never typing. Agents drastically accelerate the research process. The more you can stand on the shoulders of giants the further you're going to be able to see. That wisdom unlocks best practices, better habits, and better code. Perhaps I'm not as skilled at the manual labor - but do we blame the carpenter with a nail gun who can barely swing a hammer? (The better comparison perhaps is to the typist vs the stenographer.)

#html.elem("center")[\*]

Giving an LLM access to bash and calling it an "agent" is about as accurate as saying that Brownian motion has "agency." If you construe agency to mean "has an effect on the outside world," then sure, that is vacuously true. But when talking about LLMs we often conflate the metaphorical for the literal. When you give an LLM the ability to act on its environment, it becomes "agentic," but this ascribes a metaphor of _intelligence_ on the machine. Sure, LLMs may _act_ intelligent but this doesn't mean that they _possess_ intelligence, the same way that a thermostat does not attain consciousness by virtue of being a dynamic system. #footnote[This is a critique of the position held by David Chalmers, _The Conscious Mind_ (1996). The relevant excerpt is reproduced here: https:/\/annakaharris.com/chalmers/] I hold that LLMs are not _intelligent_ in any meaningful sense, only that they are dynamic systems capable of pattern recognition. Remove the language aspect - move to, say, a generic deep-learning transformer model such as a sentiment analyzer, computer vision, or something more abstract like protein folding or chemical analysis, and the underlying idea becomes clear. It's all pattern recognition deep down. When critics say that LLMs are just very fancy autocomplete, they're completely correct. Autocomplete runs on the same pattern recognition model. In the end, transformer models create embeddings, which are essentially pointers from some piece of data to other pieces of data, stored as vectors. The size of the vector seems to be dependent on the complexity of the domain - this is confirmed by empirical verification, where, say, an LLM has vectors with orders in the thousands, whereas a protein folding model has orders on the hundreds.#footnote[This may have more to do with how the models are _trained_ than the underlying complexity of the field. Often large language models have highly active and highly inactive portions of their vectors. Additionally, some fields tend to overlap, and this seems to be essential to how the models work.]

Anyways. My point is to point out that an accurate understand of how the models work is essential for breaking the spell on the metaphors we use for them. Yes, the models _seem_ to learn; they _seem_ to evolve; they _seem_ to reason. In reality they are dynamical systems performing pattern recognition. Is that what _we_ do too? Are we also stochastic parrots? If so, it certainly seems we are far more complicated than any single transformer model could be, no matter the parameter size. The metaphor is an abstraction, and like all abstractions, it is a leaky one.

#html.elem("center")[\*]

AI seems best used as a summarizer or auto-complete. It finds patterns very quickly given a large corpus of data. A literature review which would have taken a human weeks will take an AI minutes or hours. Again, they're the same underlying principle. It's not creating anything fundamentally, qualitatively new.

#html.elem("center")[\*]

I'm settling on a minimal use pattern. AI are quite good at handling things that you don't care about. I tend to use them for the following things:

- debugging system updates
- finding that _one_ flag combination in CLIs
- refreshing my memory on language syntax and best practices
- doing broad-scope research (reading through multiple large code bases, performing bulk web search, etc.)
- code review

But each of these has their inverse as well, areas where I do _not_ allow the AI to work:

- Running nearly _anything_ mutating on the command line. Typically I'll ask it to find the issue, then give me the commands it thinks would work without running it. This lets me audit the commands before running them and ask any questions or pivot if I think we're going down the wrong path.
- I do not trust the language model to be telling me the truth. When I ask it to perform research, I require it to give me live links to websites or other sources which contain the information I'm looking for. Then I read those sources, and not what the AI gives me. While they _do_ hallucinate, and I _do_ remain cautious, I generally find that they give a good spark-notes style summary. But there's no comparison between Spark Notes and Hamlet. A summary is essentially a different register, and the way a piece is written is integral for the affect it intends to place on the reader, even if that affect is purely informative.
- Code review can be hit or miss. Typically it will point out things that I didn't see - little syntax errors a linter would have found, or places I missed in an API migration. It's really useful for this. But it also gives a lot of false positives -- and I've noticed that it tends to give me lists of exactly 10.
- I also use LLMs to review my prose writing and ideations, often to give me technical advice or point me to authors that I ought to read to improve my craft. LLM-as-search-engine or LLM-as-librarian is really quite helpful.

#html.elem("center")[\*]
