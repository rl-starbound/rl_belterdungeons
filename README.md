# Starbound mod: Belter Dungeons

The **Belter Dungeons** mod allows space-themed dungeons to spawn into [asteroid belts](https://starbounder.org/Asteroid_Field) just like major dungeons spawn into terrestrial worlds. Features include:

* deterministic pseudo-random multi-part dungeon generation in asteroid belts, allowing players to share coordinates;
* more diverse monsters and ores found in asteroid belts;
* difficulty tiering (including environmental hazards, monsters, NPCs, ore, treasure, etc.) that scales with the star system in which the asteroid belt resides;
* randomly generated space quests with quest locations in and around the asteroid belt dungeons;
* quest location objects to allow players to enable quest generation in their own bases.

For the initial releases, the dungeons included will be enhanced versions of most of the space encounters in the base game. I plan to extend this with packs of original asteroid belt dungeons, but also hope that other modders will be inspired to do likewise. Modders wishing to build on top of Belter Dungeons should consult the [modder's guide](modders-guide.html).

Players should read the [user's guide](users-guide.html) for a detailed guide to the gameplay features added or enhanced by this mod, which are too numerous to list here.

## IMPORTANT: Read This Before Installing

As with any major mod, make a backup of your game's `storage` folder before installing this mod.

After this mod has been installed, the first time that the first player deploys into each asteroid belt, a set of dungeons will spawn into that belt at pseudo-random locations. This means that any bases you've already built in asteroid belts could be overwritten the first time you visit them after installing this mod. If you have already built bases in one or more asteroid belts, it is **strongly recommended** that before you install this mod, first install the [No Belter Dungeons](https://community.playstarbound.com/resources/no-belter-dungeons.6358/) mod and visit each of your asteroid belt bases briefly, which will protect those bases from the dungeon generation in this mod. After doing this, you must uninstall the No Belter Dungeons mod and install this mod.

## Optional Functionality

To take full advantage of Belter Dungeons ore generation, you must install [Mech Compatibility Core](https://steamcommunity.com/sharedfiles/filedetails/?id=3371002682) and [Mech Compatibility Loader](https://steamcommunity.com/sharedfiles/filedetails/?id=3371011064). If either of those mods is not installed, then ore generation in asteroid belts will be capped at tier 3.

## Recommended Mods

While the following mods are not required, they are **strongly recommended**:

* [Field Control Technology](https://community.playstarbound.com/resources/field-control-technology.6028/) - Adding or removing blocks will reset the [dungeon ID](https://starbounder.org/Dungeon_IDs) of those blocks to hard-coded defaults. Because dungeon ID controls environmental properties such as air and gravity, neither of which exist by default in asteroid belts, adding or removing blocks from asteroid belt dungeons will cause loss of air and gravity. Field Control Technology allows players to manipulate dungeon IDs, allowing repair of asteroid belt dungeons as players build and expand them. This mod is a must for anyone looking to colonize asteroid belts.
* [Mech Overhaul](https://community.playstarbound.com/resources/mech-overhaul.5654/) - This mod overhauls mechs, adding fuel and in-flight refueling, which allows longer mech deployments. (The Mech Overhaul mod has been absorbed into Frackin Universe, so it is already present if you use FU.)
* [Better Environment Hazards](https://community.playstarbound.com/resources/better-environment-hazards.6363/) - This mod fixes bugs in base game environmental hazards that may impact players using Belter Dungeons.
* [Emergency Teleporter](https://community.playstarbound.com/resources/emergency-teleporter.5745/) - I'm confident that I've eliminated any places where a player could get trapped in a shielded dungeon, but if you're playing on normal or hardcore mode and you don't have admin access, you may want to bring one of these with you, just in case. (If you find such a trap in one of my dungeons, please screenshot it and report it to me.)

## Compatibility Notes

This mod uses Starbound modding best practices in naming and patching, so it should be broadly compatible with most mods. If you believe you've discovered a mod incompatibility, please notify me using the links in the [Collaboration](#collaboration) section, and be prepared to provide a full `starbound.log` file demonstrating the incompatibility.

## Uninstallation

**Because this mod adds a biome and quest locations, removing it will break asteroid belts that generated while it was installed. If you no longer wish to use this mod, it is strongly recommended to replace it with the [No Belter Dungeons](https://community.playstarbound.com/resources/no-belter-dungeons.6358/) mod**, which provides the definitions for the assets in this mod, but will not spawn them into newly-visited asteroid belts.

If you insist on removing this mod and not replacing it with No Belter Dungeons, then you must delete the `universe.chunks` file from your `universe` folder after removing the mod, and allow it to regenerate. Any asteroid belts that generated while this mod was installed may crash after it is removed, and the only way to correct this would be to delete the corresponding `.world` files and allow them to regenerate.

## Collaboration

If you have any questions, bug reports, or ideas for improvement, please contact me via [Chucklefish Forums](https://community.playstarbound.com/members/rl-starbound.885402/), [Github](https://github.com/rl-starbound), [Reddit](https://www.reddit.com/user/rl-starbound/), or Discord (`rl.steam`). Also please let me know if you plan to republish this mod elsewhere, so we can maintain open lines of communication to ensure timely updates.

## License

Permission to include this mod or parts thereof in derived works, to distribute copies of this mod verbatim, or to distribute modified copies of this mod, is granted unconditionally to Chucklefish LTD. Such permissions are also granted to other parties automatically, provided the following conditions are met:

* Credit is given to the author(s) specified in this mod's `_metadata` file;
* A link is provided to the [mod page](https://community.playstarbound.com/resources/belter-dungeons.6357/) or the [source repository](https://github.com/rl-starbound/rl_belterdungeons) in the accompanying files or documentation of any derived work;
* The names "Belter Dungeons" and "rl_belterdungeons" are not used as the names of any derived mods without explicit consent of the author(s); however, the names may be used in verbatim distribution of this mod. For the purposes of this clause, minimal changes to metadata files to allow distribution on Steam shall be considered a verbatim distribution so long as authorship attribution remains.
