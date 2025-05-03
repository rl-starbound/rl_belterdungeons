# Starbound mod: Belter Dungeons

The **Belter Dungeons** mod adds the framework necessary to spawn major dungeons into [asteroid belts](https://starbounder.org/Asteroid_Field). Care was taken to ensure that these asteroid belt dungeons work as similarly as possible to the major dungeons that spawn on terrestrial planets, including:

* multi-part dungeon generation;
* deterministic pseudo-random generation, allowing folks with the same mod sets to share coordinates;
* difficulty that scales with the star system in which the asteroid belt resides;
* randomly generated space quests with quest locations in the new dungeons;
* quest location objects to allow players to enable quest generation in their own bases.

For the initial release of this mod, the dungeons included will be enhanced variations of most of the space encounters in the base game. I plan to extend this mod by adding packs of original asteroid belt dungeons over time, but also hope that other mod authors will be inspired to do likewise.

## IMPORTANT: Read This Before Installing

As always, making a backup of your game's `storage` folder is strongly recommended before installing this (or any other) mod.

After this mod has been installed, the first time (and only the first time) that the first player deploys into each asteroid belt, a set of dungeons will spawn into that belt at pseudo-random locations. This means that any bases you've already built in asteroid belts could be overwritten the first time you visit them after installing this mod. If you have already built bases in one or more asteroid belts, it is **strongly recommended** that before you install this mod, first install the [No Belter Dungeons](https://community.playstarbound.com/resources/no-belter-dungeons.6358/) mod and visit each of your asteroid belt bases briefly, which will protect those bases from the dungeon generation in this mod. After doing this, you must uninstall the No Belter Dungeons mod and install this mod.

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

Future versions of this mod will include additional original asteroid belt dungeons as they are developed. My intention is to build out a set of species-specific (as well as some inter-species) friendly and hostile dungeons, of similar scope to the set found on terrestrial worlds. Other mod authors may also add their own asteroid belt dungeons using the **modding guide**.

### Space Encounters?

Veterans of Starbound will recognize that the list of asteroid belt dungeons consists of the NPC ships and most of the anomalous space encounters from the base game (including two that were in the base game but not enabled). These are not exact replicas, but have been edited and enhanced to work well in player-controlled environments. I was intrigued by the space encounters in the base game, but annoyed that they were all ephemeral and could not be colonized or expanded by players. This deficiency is now corrected by this mod.

Eagle-eyed players may also note that among the enhancements built into the Belter Dungeons versions of the space encounters are many objects and items that exist in the game assets but are not enabled in the game. These dungeons present players with the opportunity to scan and collect these objects without resorting to admin commands.

Note that although this mod provides dungeons that are enhanced variations of base game NPC ships and anomalies, it is not intended to replace them entirely. Not all anomalies have been replicated as asteroid belt dungeons, and certain items, such as space weapons and mech blueprints, are far more likely to spawn into space encounters than in asteroid belt dungeons, so players progressing through the game still have reason to explore those encounters.

### How to Find Asteroid Belt Dungeons

Each asteroid belt randomly generates 0, 1, or 2 dungeons. Clever players will learn to pay attention to SAIL's radio message upon first deploying to an asteroid belt to determine whether that belt is worth searching.

As to search strategies, asteroid belts are huge expanses of mostly empty space and rock, devoid of identifying features and notoriously difficult to search. The simplest strategy is to stay near the Y-axis midpoint of the belt (which is roughly where the mech initially deploys) and circumnavigate the belt. If an asteroid belt dungeon with an active mech beacon exists within 3000 blocks of the mech, a small amber arrow on the mech's HUD will point in its direction. Exploring belts in this way will take a lot of time.

(Hint: Read about [navigating asteroid belts](https://starbounder.org/Asteroid_Field#Navigation_Console) on the wiki. Belts are 16000 blocks wide, and any landing beacons spawned by this mod should be not much more than 1500 blocks from the Y-axis midpoint of the asteroid belt. You can use geometry to figure out the smallest number of deployments you'll need to make around a belt to find all possible landing beacons in it.)

Because asteroid belts are huge, it is strongly recommended that players bring certain supplies to help them return to any discovered dungeons. Among these supplies are flags or teleporters, which allow return directly to dungeons, and mech platforms, which allow a player to summon a mech to navigate the expanse outside the dungeon. Many asteroid belt dungeons are shielded, so the player may have to search a dungeon and find a shield switch before these objects can be placed.

### Threat Level

All asteroid belts in the Starbound base game have a threat level of 1. To ensure a challenging and fair experience, asteroid belt dungeons (and the monsters, NPCs, treasure, and quest rewards within them) spawn using the threat level of the star system in which they exist, using the same mapping as [space encounters](https://starbounder.org/Space_Encounter). As such, asteroid belt dungeons in gentle or temperate star systems will have tier 3, those in radioactive star systems will have tier 4, in frozen star systems tier 5, and in fiery star systems tier 6. Some dungeons have a minimum threat level, and will only spawn in star systems that have a tier at least that high.

## Recommended Mods

While the following mods are not required by this mod, they are **strongly recommended**:

* [Field Control Technology](https://community.playstarbound.com/resources/field-control-technology.6028/) - Adding or removing blocks will reset the [dungeon ID](https://starbounder.org/Dungeon_IDs) of those blocks to hard-coded defaults. This is how the Starbound core engine was coded, and cannot be changed by modders. Due to the fact that dungeon ID controls environmental properties such as air and gravity, neither of which exist by default in asteroid belts, adding or removing blocks from asteroid belt dungeons will cause loss of air and gravity in them. The tools in Field Control Technology allow players to manipulate dungeon IDs in worlds, allowing players to repair asteroid belt dungeons as they build and expand on them. This mod is a must for anyone looking to colonize asteroid belts.
* [Mech Overhaul](https://community.playstarbound.com/resources/mech-overhaul.5654/) - This mod overhauls how mechs work, most importantly adding mech fuel and in-flight refueling, which allows for longer mech deployments. This makes exploring asteroid belts, which are much larger than planets or space encounters, easier. (The Mech Overhaul mod has been absorbed into Frackin Universe, so it is already present if you use FU.)
* [Emergency Teleporter](https://community.playstarbound.com/resources/emergency-teleporter.5745/) - I'm 99.9% sure that I've eliminated all places where a player could get trapped in a shielded dungeon, but if you're playing on normal or hardcore mode and you don't have admin access, you may want to bring one of these with you, just in case. (And if you find such a trap in one of my dungeons, please screenshot it and report it to me.)

## Compatibility Notes

This mod has few touch-points into the base game code, and uses Starbound modding best practices in naming and patching, so it should be broadly compatible with most mods. If you believe you've discovered a mod incompatibility, please notify me using the links in the Collaboration section, and be prepared to provide a full `starbound.log` file demonstrating the incompatibility.

## Uninstallation

**Because this mod adds a biome and quest locations, removing it will break asteroid belts that generated while it was installed. If you no longer wish to use this mod, it is strongly recommended to replace it with the [No Belter Dungeons](https://community.playstarbound.com/resources/no-belter-dungeons.6358/) mod**, which provides the definitions for the assets in this mod, but will not spawn them into newly-visited asteroid belts.

If you insist on removing this mod and not replacing it with No Belter Dungeons, then you must delete the `universe.chunks` file from your `universe` folder after removing the mod, and allow it to regenerate. Any asteroid belts that generated while this mod was installed may crash after it is removed, and the only way to correct this would be to delete the corresponding `.world` files and allow them to regenerate.

## Frequently Asked Questions

**Question:** Is this compatible with Frackin Universe?

**Answer:** Probably. I don't use FU, so I haven't tested it, but I did give their code a quick look and I think my code should be compatible with theirs. If you find incompatibilities, please report them and I'll see if I can address them either in this mod or with a compatibility patch.

**Question:** Tenants spawned using a third-party colony deed never offer belt-exclusive quests. Why not?

**Answer:** Belt-exclusive quests can only be generated by NPCs spawned using colony deeds that have been patched with Belter Dungeons code. Only the base game's colony deed is patched in this mod. I won't be adding support for third-party content directly into this mod, but compatibility patches can be made easily.

**Question:** If I remove this mod, and later reinstall it, will additional dungeons spawn into asteroid belt worlds that already have dungeons in them?

**Answer:** No, once a set of asteroid belt dungeons (and that set may be 0 dungeons) have spawned into a world, metadata is written into the world to prevent any additional dungeon generation from this mod. These metadata are not removed when the mod is removed. Just like a terrestrial world, if you want to force dungeon regeneration, you'll have to delete the corresponding `.world` file from your `universe` folder.

**Question:** Can I share coordinates of asteroid belt dungeons?

**Answer:** That depends. Dungeon generation is pseudo-random and is seeded by the asteroid belt's celestial coordinates, so multiple players should observe the same dungeon(s) in the same location(s) of a specific asteroid belt, provided they have identical game versions and mod lists. However, if the game versions or mod lists are different, there's a chance that they'll observe different results.

**Question:** I followed an amber arrow in my mech but there was no landing beacon at the position to which it led. What happened?

**Answer:** Each belter landing beacon works efficiently by writing its location into the world's property store when it is activated, and removing its location when it is deactivated or broken. I've ensured that they always clean up after themselves when removed normally, but in extreme circumstances, e.g., crashes or mod removal, a beacon can be destroyed without getting a chance to clean up after itself. This will leave a phantom in the world's property store. If you believe you've encountered one of these, then as an admin, spawn the item `rl_beltermechbeaconvalidator` and place it anywhere in the world. The light will change from red to blue in a few seconds. Once that happens, all of the beacons in the world have been validated and any phantoms have been removed. You may then break the validator, which will drop nothing.

## Collaboration

If you have any questions, bug reports, or ideas for improvement, please contact me via [Chucklefish Forums](https://community.playstarbound.com/members/rl-starbound.885402/), [Github](https://github.com/rl-starbound), or [Reddit](https://www.reddit.com/user/rl-starbound/). Also please let me know if you plan to republish this mod elsewhere, so we can maintain open lines of communication to ensure timely updates.

## License

Permission to include this mod or parts thereof in derived works, to distribute copies of this mod verbatim, or to distribute modified copies of this mod, is granted unconditionally to Chucklefish LTD. Such permissions are also granted to other parties automatically, provided the following conditions are met:

* Credit is given to the author(s) specified in this mod's `_metadata` file;
* A link is provided to [this page](https://community.playstarbound.com/resources/belter-dungeons.6357/) and/or the [source repository](https://github.com/rl-starbound/rl_belterdungeons) in the accompanying files or documentation of any derived work;
* The name "rl_belterdungeons" is not used as the metadata name of any derived mod without explicit consent of the author(s); however, the name may be used in verbatim distribution of this mod. For the purposes of this clause, minimal changes to metadata files to allow distribution on Steam shall be considered a verbatim distribution so long as authorship attribution remains.
