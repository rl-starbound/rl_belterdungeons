# Belter Dungeons User's Guide

The [Belter Dungeons](https://community.playstarbound.com/resources/belter-dungeons.6357/) mod adds the framework necessary to spawn major dungeons into [asteroid belts](https://starbounder.org/Asteroid_Field). These asteroid belt dungeons should work similarly to the major dungeons that spawn on terrestrial planets, including the following features:

* deterministic pseudo-random multi-part dungeon generation in asteroid belts, allowing players to share coordinates;
* more diverse monsters and ores found in asteroid belts;
* difficulty tiering (including environmental hazards, monsters, NPCs, ore, treasure, etc.) that scales with the star system in which the asteroid belt resides;
* randomly generated space quests with quest locations in and around the new dungeons;
* quest location objects to allow players to enable quest generation in their own bases.

For the initial releases, the dungeons included will be enhanced versions of most of the space encounters in the base game. I plan to extend this with packs of original asteroid belt dungeons, but also hope that other modders will be inspired to do likewise. Modders wishing to build on top of Belter Dungeons should consult the [modder's guide](modders-guide.md).

## IMPORTANT: Read This Before Installing

As with any major mod, make a backup of your game's `storage` folder before installing this mod.

After this mod has been installed, the first time that the first player deploys into each asteroid belt, a set of dungeons will spawn into that belt at pseudo-random locations. This means that any bases you've already built in asteroid belts could be overwritten the first time you visit them after installing this mod. If you have already built bases in one or more asteroid belts, it is **strongly recommended** that before you install this mod, first install the [No Belter Dungeons](https://community.playstarbound.com/resources/no-belter-dungeons.6358/) mod and visit each of your asteroid belt bases briefly, which will protect those bases from the dungeon generation in this mod. After doing this, you must uninstall the No Belter Dungeons mod and install this mod.

## Belter Dungeons

After this mod has been installed, the first time (and only the first time) that the first player deploys into each asteroid belt, a set of dungeons will spawn into that belt at pseudo-random locations. The set of dungeons currently includes:

* Abandoned Peacekeeper station
* Abandoned USCM base (rare)
* Abandoned USCM flagship (rare)
* Abandoned USCM ship
* Ancient ruins
* Arcade
* Astrofae haven
* Bandit hideout
* Base ruins
* Destroyed ship wreckage (often including a pirate ship)
* Diner
* Escape pods
* Gang safe-houses (including a rare gang lair)
* Hotel
* Letheia branch office
* Merchant bases
* Miniknog base
* Mining asteroids (including refineries)
* Mining camp
* Novakid saloon
* Office tower
* Poptop farm
* Produce garden
* Space shelters and camps
* Storage depots
* Zoological ark

In addition, many of these dungeons have a chance to spawn with a friendly or hostile ship nearby, including astro and industrial merchants, penguins, researchers, pirates, and cultists.

Friendly NPCs that spawn within asteroid belt dungeons will offer some space-exclusive quests, further increasing the liveliness of the belts.

Future versions of this mod will include additional original asteroid belt dungeons as they are developed. My intention is to build out a set of species-specific (as well as some inter-species) friendly and hostile dungeons, of similar scope to the set found on terrestrial worlds. Other mod authors may also add their own asteroid belt dungeons using the [modder's guide](modders-guide.md).

### Space Encounters?

Veterans of Starbound will recognize that the list of asteroid belt dungeons consists of the NPC ships and most of the anomalous space encounters from the base game (including two that were in the base game but not enabled). These are not exact replicas, but have been edited and enhanced to work well in player-controlled environments. I was intrigued by the space encounters in the base game, but annoyed that they were all ephemeral and could not be colonized or expanded by players. This deficiency is now corrected by this mod.

Eagle-eyed players may also note that among the enhancements built into the Belter Dungeons versions of the space encounters are many objects and items that exist in the game assets but are not enabled in the game. These dungeons present players with the opportunity to scan and collect these objects without resorting to admin commands.

Note that although this mod provides dungeons that are enhanced variations of base game NPC ships and anomalies, it is not intended to replace them entirely. Not all anomalies have been replicated as asteroid belt dungeons, and certain items, such as space weapons and mech blueprints, are far more likely to spawn into space encounters than in asteroid belt dungeons, so players progressing through the game still have reason to explore those encounters.

### How to Find Asteroid Belt Dungeons

Each asteroid belt randomly generates 0, 1, or 2 dungeons. Clever players will learn to pay attention to SAIL's radio message upon first deploying to an asteroid belt to determine whether that belt is worth searching.

As to search strategies, asteroid belts are huge expanses of mostly empty space and rock, devoid of identifying features and notoriously difficult to search. The simplest strategy is to stay near the Y-axis midpoint of the belt (which is roughly where the mech initially deploys) and circumnavigate the belt. If an asteroid belt dungeon with an active mech beacon exists within 3000 blocks of the mech, a small amber arrow on the mech's HUD will point in its direction. Exploring belts in this way will take a lot of time.

(Hint: Read about [navigating asteroid belts](https://starbounder.org/Asteroid_Field#Navigation_Console) on the wiki. Belts are 16000 blocks wide, and any landing beacons spawned by this mod should not be more than 1500 blocks from the Y-axis midpoint of the asteroid belt. Using geometry you can calculate the smallest number of deployments you'll need to make around a belt to find all possible landing beacons in it.)

Because asteroid belts are huge, it is strongly recommended that players bring certain supplies to help them return to any discovered dungeons. Among these supplies are flags or teleporters, which allow return directly to dungeons, and mech platforms, which allow a player to summon a mech to navigate the expanse outside the dungeon. Many asteroid belt dungeons are shielded, so the player may have to search a dungeon and find a shield switch before these objects can be placed.

### Threat Level

All asteroid belts in the Starbound base game have a threat level of 1. To ensure a challenging and fair experience, asteroid belt dungeons (and the monsters, NPCs, ore, treasure, and quest rewards within them) spawn using the threat level of the star system in which they exist, using a similar mapping as that of [space encounters](https://starbounder.org/Space_Encounter). Asteroid belts around gentle star systems will have tier 2, those in temperate star systems will have tier 3, in radioactive star systems tier 4, in frozen star systems tier 5, and in fiery star systems tier 6. Some dungeons have a minimum threat level, and will only spawn in star systems that have a tier at least that high.

In addition to airlessness, asteroid belts around radioactive star systems will feature deadly radiation, those in frozen star systems will feature deadly chill, and those in fiery star systems will feature both deadly radiation and deadly chill. *Note that, to ensure reasonable difficulty progression, if either of [Mech Compatibility Core](https://steamcommunity.com/sharedfiles/filedetails/?id=3371002682) or [Mech Compatibility Loader](https://steamcommunity.com/sharedfiles/filedetails/?id=3371011064) is not installed, then ore generation in asteroid belts will be capped at tier 3. Both of those mods must be installed to enable higher-tier ore generation.*

## Frequently Asked Questions

**Question:** Is this compatible with Frackin Universe?

**Answer:** Probably. I don't use FU, so I haven't done more than basic testing. I did give their code a quick look and I think my code should be compatible with theirs. If you find incompatibilities, please report them and I'll see if I can address them either in this mod or with a compatibility patch.

**Question:** Tenants spawned using a third-party colony deed never offer belt-exclusive quests. Why not?

**Answer:** Belt-exclusive quests can only be generated by NPCs spawned using colony deeds that have been patched with Belter Dungeons code. Only the base game's colony deed is patched in this mod. I won't be adding support for third-party content directly into this mod, but compatibility patches can be made easily.

**Question:** If I remove this mod, and later reinstall it, will additional dungeons spawn into asteroid belt worlds that already have dungeons in them?

**Answer:** No, once a set of asteroid belt dungeons (and that set may be 0 dungeons) have spawned into a world, metadata is written into the world to prevent any additional dungeon generation from this mod. These metadata are not removed when the mod is removed. Just like a terrestrial world, if you want to force dungeon regeneration, you'll have to delete the corresponding `.world` file from your `universe` folder.

**Question:** Can I share coordinates of asteroid belt dungeons?

**Answer:** That depends. Dungeon generation is pseudo-random and is seeded by the asteroid belt's celestial coordinates, so multiple players should observe the same dungeon(s) in the same location(s) of a specific asteroid belt, provided they have identical game versions and mod lists. However, if the game versions or mod lists are different, there's a chance that they'll observe different results.

**Question:** I followed an amber arrow in my mech but there was no landing beacon at the position to which it led. What happened?

**Answer:** Each belter landing beacon works efficiently by writing its location into the world's property store when it is activated, and removing its location when it is deactivated or broken. I've ensured that they always clean up after themselves when removed normally, but in extreme circumstances, e.g., crashes or mod removal, a beacon can be destroyed without getting a chance to clean up after itself. This will leave a phantom in the world's property store. If you believe you've encountered one of these, then as an admin, spawn the item `rl_beltermechbeaconvalidator` and place it anywhere in the world. The light will change from red to blue in a few seconds. Once that happens, all of the beacons in the world will have been validated and any phantoms will have been removed. You may then break the validator, which will drop nothing.

**Question:** I was expanding one of the asteroid belt dungeons, and now I have no air or gravity! What happened?

**Answer:** A hard-coded quirk of the Starbound core engine is that it resets the dungeon ID of a position any time you add or remove a block (either foreground or background) at that position. Dungeon IDs are what provide things like air and gravity in Starbound. In an asteroid belt, the default dungeon IDs have no air or gravity, so when you add or remove a tile in an asteroid belt dungeon, that position loses its air and gravity. The tools provided in the [Field Control Technology](https://community.playstarbound.com/resources/field-control-technology.6028/) mod, specifically the Field Tuner, allow you to change the dungeon IDs of blocks, which will allow you to repair the air and gravity of asteroid belt dungeons as you expand them. Almost everyone who uses Belter Dungeons will probably want Field Control Technology, or some similar mod.

**Question:** If I expand or alter a friendly asteroid belt dungeon, will its villagers attack me?

**Answer:** No, there is no [stealing](https://starbounder.org/Stealing) game mechanic in my dungeons. I'm not opposed to some variation of this mechanic, but I don't like how it works in the base game, so I didn't include it in my dungeons.
