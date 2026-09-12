# HC Challenger 0.1.1

HC Challenger er en manuel route-builder og guide-afspiller til WoW 1.12.1. Spillere kan bygge egne leveling-ruter trin for trin, gemme dem, afspille dem i et kompakt guidevindue og frivilligt dele dem via suitens skjulte `HCSafety`-kanal.

## Installation

Kopier mappen `HC-Challenger` til `World of Warcraft\Interface\AddOns\HC-Challenger`. Addon'et bruger kun `HCChallengerDB` og kræver ingen af de andre HC-addons.

Et flytbart route-note-ikon ved minimappet åbner/lukker Challenger. Træk ikonet for at flytte det; `/hcc minimap` skjuler eller viser det.

## Route-builder

1. Aabn `/hcc` og vælg New route, eller vælg en profil under Challenges.
2. Gem navn, challenge, faction, klasse, levelinterval og beskrivelse.
3. Tilfoej op til 80 manuelle trin: Travel, Quest, Turn in, Kill, Grind, Train, Craft, Hearth, Flight, Safety eller Note.
4. `Add` gemmer zone-only. `Add + position` optager nuværende koordinater én gang efter brugerklikket.
5. Flyt trin med Up/Down, fjern dem eller start guiden. Sletning kræver to klik inden seks sekunder.

Guiden avancerer kun med Previous, Skip eller Complete + next. Den accepterer ingen quests, targeter intet og spiller ikke karakteren.

## Community

Network er OFF som standard. `/hcc network on` tilmelder den skjulte kanal. Publish annoncerer kun route-metadata. En anden spiller skal vælge routen og klikke Download; først da sendes route-trinene til netop den spiller. Den downloadede route kan afspilles direkte eller kopieres til My Routes.

Netværksformatet er `HCS1|CHL|TYPE|MESSAGE_ID|PAYLOAD`, maks. 240 bytes pr. message, med escaping, validering, deduplikering, rate limiting, on-demand transfer og limits. Ingen modtaget kode evalueres. Cross-faction-kommunikation antages ikke.

## Trial of Heroism

Profilen beskriver reglen fra det vedhæftede serverbillede: under level 58 giver kills kun XP mod fjender mindst tre levels over spilleren; quest-XP er tilladt. Guidevinduet viser en grøn/rød vurdering af det target, spilleren selv har valgt. Det targeter eller angriber aldrig automatisk.

## Kommandoer

- `/hcc` eller `/hcchallenger` — vindue.
- `/hcc community` — community-listen.
- `/hcc challenges` — challenge-profiler.
- `/hcc guide` — aktiv guide.
- `/hcc new navn` — ny standardroute.
- `/hcc network on|off` — community-netværk.
- `/hcc minimap` — minimap-knap.

Challenge-reglerne er en statisk, forsigtig gengivelse af det leverede screenshot. Serverens aktuelle regler er altid autoritative.
