#import "_template.typ": conf
#show: conf

#let info(current: none, queue: none, recent: none) = [
    #if current != none [
      #html.details(open: true)[
        #html.summary[Current]
        #current
      ]
     ]
    #if recent != none [
      #html.details(open: true)[
        #html.summary[Recent]
        #recent
      ]
    ]
    #if queue != none [
      #html.details[
        #html.summary[Queue]
        #queue
      ]
    ]
 ]

= /now


== ./projects

- Essays on play, aesthetics, agency, and epistemology (#link("https://github.com/ada-x64/play")[github])
- Roach Hell (visual novel)
- game dev @ #link("https://github.com/cubething-qproj")[qproj]

#html.hr()

== ./reading

#info(
  current: [
    - C. Thi Nguyen, _The Score: How to Stop Playing Somebody Else's Game_ (2026)
  ],
  queue: [
    - Bernard Suits, _The Grasshopper: Games, Life, and Utopia_ (Third Edition, 2014)
    - Play as Symbol of the World, _Eugen Fink_ (tr. Moore, 2016)
    - Virtual Worlds as Philosophical Tools: How to Philosophize With a Digital Hammer, _Stefano Gualeni_ (2015)
    - Strange Tools: Art and Human Nature, _Alva Noë_ (2015)
  ],
  recent: [
    - Deleuze and Guatarri, _Anti-Oedipus_ (1972)
    - James S. Hans, _The Play of the World_ (1981)
    - Tim McNamara, _Rust In Action_ (2021)
    - Alva Noë, _The Entanglement_ (2023)
  ]
)

#html.hr()

== ./games

#link("https://steamcommunity.com/id/cubething/")[steam] | #link("https://cubething.itch.io")[itch] | #link("https://discord.com/users/159805063596998656")[discord]

#info(
  current: [
    - Team Cherry, _Hollow Knight: Silksong_ (2025)
  ],
  queue: [
    - Bennet Foddy, _Getting Over It with Bennett Foddy_ (2017)
    - snek et al, _#link("https://snekofspicy.itch.io/dog-days-dog-daze")[Dog Days Dog Daze]_ (2026)
    - snek et al, _#link("https://snekofspicy.itch.io/the-death-of-harsh-noise")[THE DEATH OF HARSH NOISE]_ (2026)
    - za/um, _Disco Elysium_ (2019)
    - sunset visitor 斜陽過客, _1000X RESIST_ (2024)
  ],
  recent: [
    - Black Tabby Games, _Slay the Princess_ (2023)
    - snek et al., _#link("https://snekofspice.itch.io/loner-dog")[LONER_DOG:\/\/Snuff Puppy Carnage Society]_ (2025)
  ]
)

#html.hr()

== ./movies


#info(
  queue: [
    - Curry Barker, _Obsession_ (2026)
  ],
  recent: [
    - Kane Parsons, _Backrooms_ (2026)
    - Bong Joon Ho, _Parasite_ (2019)
    - Hayao Miyazaki, _Spirited Away_ (2001)
    - Chris Sanders, _The Wild Robot_ (2024)
  ],
)

#html.hr()

== ./tv

#info(
  current: [
    - Vince Gilligan, _Breaking Bad_ (2008-2013)
    - Alex Hirsch, _Gravity Falls_ (2012-2016)
  ],
  recent: [
    - Gooseworx, _The Amazing Digital Circus_ (2023-2026)
    - Nico Tanigawa, _Watamote_ (2013)
  ],
  queue: [
    - Hwang Dong-hyuk, _Squid Game_ (2021)
  ]
)
