# Status 0.1.2

## Implementeret

- Manuel editor med op til 30 egne routes og 80 trin pr. route.
- Metadata: challenge, faction, klasse, levelinterval, beskrivelse og revision.
- 11 trintyper, engangsoptagelse af zone/koordinater, mob-levelinterval, rækkefølge og sletning.
- Kompakt guide med gemt karakterprogress, Previous, Skip og Complete + next.
- Trial of Heroism targetindikator for `target level >= player level + 3` under level 58.
- 12 statiske challenge-profiler fra det leverede serverbillede.
- Community-katalog, manuel Publish/Download, valideret todelt step-transfer og op til 25 gemte community-routes.
- Netværk OFF som standard, separat `CHL`-modul på `HCSafety`, 240-byte loft, rate limiting og deduplikering.
- Klassisk UI, X/Escape/slash, minimap og gemte vinduespositioner.

## Kendte begrænsninger

- Serverregler kan ændres; addon'et rådgiver, men håndhæver dem ikke.
- 1.12 har ingen moderne quest-/waypoint-API. Alle trin og fremskridt er bevidst manuelle.
- Koordinater udelades, hvis klienten ikke giver plausible data eller World Map er åbent.
- Store routes tager tid at sende med den sikre kanalrate; begge spillere skal være online.
- Cross-faction custom channels er serverafhængige.
- Konkret in-game og flerklienttest udestaar.
