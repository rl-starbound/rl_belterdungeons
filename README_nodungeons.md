# Starbound mod: No Belter Dungeons

The **No Belter Dungeons** mod adds the framework necessary to spawn major dungeons into [asteroid belts](https://starbounder.org/Asteroid_Field), but disables the generation of the dungeons. It is intended as an alternative to the [Belter Dungeons](https://community.playstarbound.com/resources/belter-dungeons.6357/) mod, to handle a couple of use cases:

1. Users who want to protect existing asteroid belt bases before installing Belter Dungeons.
1. Users who don't want to spawn new asteroid belt dungeons into asteroid belts, but who also don't want to lose the custom objects that have already spawned into existing asteroid belt dungeons.

**Outside of those two use cases, most users will not want this mod, but may want Belter Dungeons.**

As always, making a backup of your game's `storage` folder is strongly recommended before installing this (or any other) mod.

## Use Case 1: Protecting Existing Asteroid Belt Bases from Dungeon Generation

After the Belter Dungeons mod has been installed, the first time (and only the first time) that the first player deploys into each asteroid belt, a set of dungeons will spawn into that belt at pseudo-random locations. This means that any bases you've already built in asteroid belts could be overwritten the first time you visit them after installing Belter Dungeons. This mod can protect your existing asteroid belt bases from the dungeon generation provided by Belter Dungeons.

1. Make a list of all asteroid belt bases you've built.
1. Install this mod, and do not install Belter Dungeons.
1. Start the game and visit each asteroid belt base. You only need to visit each base for a moment. SAIL will pop up a radio message saying, "Scans have found nothing interesting in this asteroid belt." Once you see this message, this asteroid belt has been protected from dungeon generation forever, so you can leave this base and repeat this step for each base remaining on your list.

Once you've visited all of your asteroid belt bases with this mod installed, you may uninstall this mod and install Belter Dungeons.

## Use Case 2: Disabling New Dungeon Generation

Let's say that you installed Belter Dungeons and visited some asteroid belts. Then you decide for some reason that you don't want any new asteroid belt dungeons to be generated, but you also don't want to lose the custom objects provided by this mod in the dungeons that have already generated. In that case, you can remove Belter Dungeons and install this mod. All of the existing custom objects will remain, but no new dungeons will be generated.

## Compatibility Notes

This mod has few touch-points into the base game code, and uses Starbound modding best practices in naming and patching, so it should be broadly compatible with most mods. If you believe you've discovered a mod incompatibility, please notify me using the links in the Collaboration section, and be prepared to provide a full `starbound.log` file demonstrating the incompatibility.

## Uninstallation

**Because the Belter Dungeons mod adds a biome and quest locations, removing it will break asteroid belts that generated while it was installed. If you no longer wish to use Belter Dungeons, it is strongly recommended to replace it with this mod**, which provides the definitions for the assets in the Belter Dungeons mod, but will not spawn them into newly-visited asteroid belts.

If you insist on removing Belter Dungeons and not replacing it with this mod, or if you later wish to remove this mod too, then you must delete the `universe.chunks` file from your `universe` folder after removing the mod, and allow it to regenerate. Any asteroid belts that generated while Belter Dungeons was installed may crash after it is removed, and the only way to correct this would be to delete the corresponding `.world` files and allow them to regenerate.

## Frequently Asked Questions

**Question:** I visited an asteroid belt base with this mod installed, but SAIL never popped up the indicated radio message. What happened?

**Answer:** The radio message only pops up the first time the first player visits an asteroid field with this mod, or the Belter Dungeons mod, installed. The message usually pops up within one or two seconds of deploying into the asteroid belt. If you're sure it was your first visit and you didn't miss the message, then something may have gone wrong. Check your `starbound.log` for error messages related to this mod. Any such messages would likely begin with the letters `rl_`.

## Collaboration

If you have any questions, bug reports, or ideas for improvement, please contact me via [Chucklefish Forums](https://community.playstarbound.com/members/rl-starbound.885402/), [Github](https://github.com/rl-starbound), or [Reddit](https://www.reddit.com/user/rl-starbound/). Also please let me know if you plan to republish this mod elsewhere, so we can maintain open lines of communication to ensure timely updates.

## License

Permission to include this mod or parts thereof in derived works, to distribute copies of this mod verbatim, or to distribute modified copies of this mod, is granted unconditionally to Chucklefish LTD. Such permissions are also granted to other parties automatically, provided the following conditions are met:

* Credit is given to the author(s) specified in this mod's `_metadata` file;
* A link is provided to [this page](https://community.playstarbound.com/resources/no-belter-dungeons.6358/) and/or the [source repository](https://github.com/rl-starbound/rl_belterdungeons) in the accompanying files or documentation of any derived work;
* The name "rl_belterdungeons" is not used as the metadata name of any derived mod without explicit consent of the author(s); however, the name may be used in verbatim distribution of this mod. For the purposes of this clause, minimal changes to metadata files to allow distribution on Steam shall be considered a verbatim distribution so long as authorship attribution remains.
