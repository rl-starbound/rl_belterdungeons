# Belter Dungeons Modding Guide

This guide provides documentation for creating new dungeons to be spawned into [asteroid belts](https://starbounder.org/Asteroid_Field) by the **Belter Dungeons** mod. It assumes familiarity with Starbound dungeon creation and the [Tiled](https://www.mapeditor.org/) dungeon editor. Given that asteroid belt dungeon creation is an advanced topic, those not already familiar with Starbound dungeon creation should look for a tutorial on the basics before delving into this guide.

As always, the best way to learn Starbound modding is to unpack the source and read it. Feel free to unpack the Belter Dungeons source and examine the assets, scripts, etc.

*Note: All discussion of editing text files in this document assumes the use of a programmer's editor. Windows Notepad or word processors are not appropriate editors.*

*Note: It is strongly advised to disable any options in your operating system that hide file name extensions. If you're making a mod, that means you're a programmer, and computers should not hide technical details from programmers.*

## How to View Belter Dungeons Using Tiled

This section describes how the author organizes dungeon files and tilesets. You can skip this section if you already have a strong understanding of these concepts.

*Note: The last version of Tiled used with published Starbound base game assets appears to be version 1.2.2. I use that version when editing my mods, for safety. Newer versions may also work, but some new versions may not be fully compatible with the (relatively old) Starbound dungeon files.*

The Tiled dungeon editor does not know anything about how Starbound organizes its files, and in particular, it does not know about how the Starbound modding system uses overlay file systems. As such, before you can view Tiled dungeon parts, you'll need to organize things in a way that Tiled can understand.

First, before unpacking the base game or Belter Dungeons assets, I would strongly recommend creating a folder structure like this under your home folder:

```
starbound-src/
    assets/
        packed/
    rl_belterdungeons/
        rl_belterdungeons/
```

The remainder of this tutorial will assume you've used this structure. In this folder structure, unpack the base game assets into `starbound-src/assets/packed`. Unpack Belter Dungeons assets into `starbound-src/rl_belterdungeons/rl_belterdungeons`. The reason for this somewhat awkward structure will become obvious later.

Now, we must use an operating system feature known as "symbolic linking" or "symlinking" to link Starbound assets into points in this folder structure where Tiled expects them. If you are not familiar with basic command line navigation and symbolic linking in your operating system, you need to learn that before continuing this tutorial. Symlinking works more or less identically on Linux and Mac OS, so the examples here will use that. Windows has a different form of symlinking, but I won't go into it here.

First, create a symlink under `starbound-src` to the game's `tiled` folder. Where this folder is located depends both on your operating system and on how you obtained Starbound, e.g., Steam, GOG, etc. I use Linux and obtained Starbound from GOG Games, so this works for me (but it probably will not work verbatim for you):

```
cd -- "${HOME}/starbound-src"
ln -fs -- "${HOME}/GOG Games/Starbound/game/tiled"
```

This symlink will allow Tiled to find the images needed to show various materials and objects in the editor.

Next, we need to add a symlink from Belter Dungeons to the unpacked base game assets, so that Tiled can find tileset definitions. These commands will work on Linux and Mac OS:

```
cd -- "${HOME}/starbound-src/rl_belterdungeons/rl_belterdungeons/tilesets"
ln -fs -- "${HOME}/starbound-src/assets/packed/tilesets/packed"
```

This symlink effectively adds all of the tileset definitions from the base game into Belter Dungeons, without actually copying them. Now, when you open a Belter Dungeons Tiled dungeon part in the Tiled editor, the editor should show no errors and should show the file correctly.

## Make Your Own Mod!

Unpacking and examining source is good, but when it's time to make changes, you must not edit my assets (or the base game assets) and re-pack them. That will work *for you* in the short term, but if you distribute it to others, you will cause trouble and mod conflicts. Instead, you must make your own mod, and have it require Belter Dungeons.

To do this, we will update the folder structure used in the previous section:

```
starbound-src/
    assets/
        packed/
    rl_belterdungeons/
        rl_belterdungeons/
    your_mod1/
        your_mod1/
```

In this updated folder structure, a new mod of your own should go under `starbound-src/your_mod1/your_mod1`, where it is expected that you replace each instance of `your_mod1` with the name of your mod. It is **strongly recommended** to use only letters, numbers, and underscores in your mod's name, that is, the name used in the `name` field of the `_metadata` file and in the folder structure of your mod. The `friendlyName` can contain spaces and special characters, but using anything other than letters, numbers, and underscores in the `name` is asking for trouble.

So the first thing to do, after creating that folder structure, is to add a new text file under `starbound-src/your_mod1/your_mod1` and call it `_metadata`. A minimal metadata file will contain a JSON table like this:

```
{
    "author" : "your_name",
    "description" : "This mod does blah blah and bleh bleh.",
    "friendlyName" : "Your Mod's Friendly Name",
    "name" : "your_mod1",
    "version" : "1.0.0"
}
```

To add a strict dependency from your mod to Belter Dungeons, you would add the following field to that JSON table:

```
    "requires" : [ "rl_belterdungeons" ]
```

Or, if the `requires` field already exists in your mod, append `rl_belterdungeons` to its list. This will tell your mod to first load `rl_belterdungeons`, and to stop the game if `rl_belterdungeons` does not exist. (Note that if Belter Dungeons is merely a "nice to have" rather than a strict requirement for your mod, you should use the `includes` field instead of the `requires` field. Its semantics are the same, but it does not stop the game if the pre-requisites are missing.)

### Configuring Your Mod for Tiled

If you're building your own asteroid belt dungeons in your mod, then you'll need to complete a few more steps before Tiled will work correctly. First, you'll need to create two folders under your mod root, if they don't already exist: `_tiled` and `tilesets`.

Next, you'll need to symlink the Belter Dungeons tiled image files into your mod's `_tiled` folder. These commands will work on Linux and Mac OS (assuming you substitute `your_mod1` with your mod's name):

```
cd -- "${HOME}/starbound-src/your_mod1/your_mod1/_tiled"
ln -fs "${HOME}/starbound-src/rl_belterdungeons/rl_belterdungeons/_tiled/rl_belterdungeons"
```

Finally, you'll need to symlink both the base game tilesets and the Belter Dungeons tilesets into your mod's `tilesets` folder. These commands work for Linux and Mac OS (assuming you substitute `your_mod1` with your mod's name):

```
cd -- "${HOME}/starbound-src/your_mod1/your_mod1/tilesets"
ln -fs -- "${HOME}/starbound-src/assets/packed/tilesets/packed"
ln -fs -- "${HOME}/starbound-src/rl_belterdungeons/rl_belterdungeons/tilesets/rl_belterdungeons"
```

Now, your mod folder structure will contain links to both the base assets and the Belter Dungeons assets, and you should be ready to edit your own Tiled dungeon parts.

As a side note, if you create custom objects of your own and want to create tileset definitions to allow them to be used in the Tiled editor, you should use the following structure to ensure that your tilesets and tiled image assets can be symlinked into other people's mods:

```
starbound-src/
    your_mod1/
        your_mod1/
            ... your mod's assets ...
            _tiled/
                rl_belterdungeons  <-- symlink to rl_belterdungeons images
                your_mod1/         <-- images for your mod's tilesets
                    objects/
                        foo.png
                        bar.png
                        ...
            tilesets/
                packed             <-- symlink to base game tilesets
                rl_belterdungeons  <-- symlink to rl_belterdungeons tilesets
                your_mod1/         <-- tileset definitions for your mod
                    objects.json
```

### An Important Note About Asset Packing

The asset packer provided by Starbound will follow symlinks and copy their contents in the `.pak` file. This will bloat your mod with many megabytes of unnecessary files and could cause mod conflicts. **You must remove the symlinks under the `_tiled` and `tilesets` folders before you pack your assets.** To automate this, I keep an executable script in `starbound-src/rl_belterdungeons` with the name `make-starbound-pak`. This script assumes the folder structure I have described and works on Linux with the GOG Games distribution of Starbound, but you will need to change it if you use another operating system or if you obtained Starbound from another distributor:

```
#!/bin/sh

set -eu

STARBOUND_BIN="${HOME}/GOG Games/Starbound/game/linux"
MOD_NAME=$(basename "$(pwd)")

# Fail if we're not at a top-level mod directory.
if [ ! -f _metadata ]; then
  echo 'ERROR: not in mod root. Aborting.' >&2
  exit 1
fi

if [ -d _tiled ]; then
  find _tiled -type l -exec unlink {} \;
fi
if [ -d tilesets ]; then
  find tilesets -type l -exec unlink {} \;
fi

"${STARBOUND_BIN}/asset_packer" . "../${MOD_NAME}.pak"
```

From within the `starbound-src/rl_belterdungeons/rl_belterdungeons` folder, I run the command `../make-starbound-pak` instead of directly running the asset packer and it ensures that any symlinks are removed from the `_tiled` and `tilesets` folders before packing the assets.

Of course, after packing assets, I need to re-add the symlinks before I can use continue working on the mod using Tiled. This can be done by re-executing the commands from the [Configuring Your Mod for Tiled](#Configuring_Your_Mod_for_Tiled) section, although you may want to write another script to automate that.

### A Note About Name Prefixing

As a Starbound modding best practice, I prefix most of the names in my mods with my initials, `rl_`, to reduce the likelihood of naming clashes with other mods. For some names that might clash with the names in my other mods, I prefix the name with the full name of the mod, in this case `rl_belterdungeons_`.

When developing your own mods and creating your own custom dungeons, objects, stagehands, Lua functions, etc, please do not copy my prefixing verbatim. Entities that are newly created in your own mods should use your own prefixing, e.g., your own initials.

As an exception to this rule, if you are merely referencing an entity that I created in one of my mods in one of your mods, then of course you would use my naming for that reference.

## Dungeon Metadata

Just like base game dungeons, Belter Dungeons expects its dungeons to be defined under the `dungeons` folder of the assets using JSON files with the `.dungeon` extension. This file format is identical to that used by the base game, with one exception. The `metadata` table within this file may contain an optional additional field `extraDungeonIds` that, if present, must contain a list of tables. Each table in the list must be either an empty JSON object or a JSON object of the form:

```
{
    breathable : boolean
    gravity : integer in the range [0..100]
    protected : boolean
}
```

If the object is empty, a new dungeon ID will be created with world default values. If the object is nonempty, the given values will be used.

It may be helpful to include a comment inside of each extra dungeon ID table indicating to what portion of the dungeon that table corresponds.

When an asteroid belt dungeon is spawned into the world, Belter Dungeons will assign it a new [dungeon ID](https://starbounder.org/Dungeon_IDs). This dungeon ID corresponds to the `breathable`, `gravity`, and `protected` fields that are directly attached to the dungeon's `metadata` table. This is the base, or 0th, dungeon ID for the dungeon. If the `extraDungeonIds` field is provided, then Belter Dungeons allocates an additional dungeon ID for each table specified in the list, in the order specified in the list.

Using the following partial `.dungeon` file as an example:

```
{
  "metadata" : {
    "name" : "my_asteroidbelt_dungeon",

    ...snip...

    "gravity" : 40,
    "breathable" : true,
    "protected" : true,
    "extraDungeonIds" : [{
      // main exterior
      "breathable" : false,
      "gravity" : 0,
      "protected" : true
    }, {
      // interior of the ship, if any
      "breathable" : true,
      "gravity" : 80,
      "protected" : true
    }, {
      // exterior of the ship, if any
      "breathable" : false,
      "gravity" : 0,
      "protected" : true
    }]
  },

  ...snip...
```

In this example, the name of your new dungeon is `my_asteroidbelt_dungeon`. Dungeon names must be unique in Starbound, so it's always a good idea to prefix them with your initials and/or mod name.

When `my_asteroidbelt_dungeon` is spawned by Belter Dungeons, four new dungeon IDs will be created. Let's say the base dungeon ID happens to be assigned the value 104. In the world, the dungeon ID 104 will be assigned 40 gravity, air, and shielding. The dungeon ID 105 will be assigned 0 gravity, no air, and shielding. The dungeon ID 106 will be assigned 80 gravity, air, and shielding. The dungeon ID 107 will be assigned 0 gravity, no air, and shielding. Note that dungeon IDs 105 and 107 have the same configuration, but importantly, because they are separate dungeon IDs, their shielding can be raised or lowered independently of one another.

When creating a new dungeon, you must identify how many zones you want, i.e., how many different combinations of air, gravity, and independent shielding you want. You must then choose one of those zones as your "base", or 0th zone, and configure it directly in the `metadata` table, and each additional zone will need to be an entry in the `extraDungeonIds` list. If you only require one zone for the entire dungeon, you can feel free to not include the `extraDungeonIds` field at all.

Once you have allocated dungeon IDs in the `.dungeon` file, you will need to specify them in dungeon parts using the [rl_dynamic_dungeonid](#rl_dynamic_dungeonid) stagehand.

## Dungeon Formats

Asteroid belt dungeon parts may use either the PNG or Tiled formats. The Tiled format is strongly recommended for all new dungeon creation, and all of the dungeons provided in Belter Dungeons are implemented in it.

## Dungeon Boundaries

When players deploy into an asteroid belt in a mech, the deployment always occurs at approximately the 3500th block in the world's Y-axis. Asteroids in asteroid belts are randomly generated between the 2000th and 5000th blocks on the Y-axis. Belter Dungeons will choose a random position at which to begin generation of each dungeon, with the Y-axis coordinate between either the 2500th-3000th block or the 4000th-4500th block. This position will represent the top-left corner of the anchor part of the dungeon.

Care should be taken when designing dungeons to ensure that, no matter the combination of dungeon parts, the complete dungeon cannot extend more than 400 blocks above or below the top-left corner of the anchor part. This will ensure that, regardless of the randomly chosen Y-axis starting coordinate, the dungeon will neither overlap the player's mech deployment point, nor will it extend above or below the asteroid belt's outer limits. For the X-axis, dungeon designs should not extend more than 2500 blocks to the left or the right of the top-left corner of the anchor part. (Note that for a dungeon to extend above or to the left of its starting position, connectors must be used to add additional dungeon parts in those directions.)

These requirements therefore give maximum theoretical dungeon dimensions of 5000 blocks wide by 800 blocks tall, or 4900 by 700 if accounting for fringe as described in the next section. This is more than four times the area of the Dantalion mission. In practice, you will probably not approach these limits.

## Dungeon Fringe

Terrestrial world major dungeon generation uses C++ functions, not exposed to modders, that can flatten terrain before generating the dungeon. Mods like Belter Dungeons cannot call these functions, so asteroid belt dungeon designers must simulate terrain "flattening" manually in their designs. First, asteroid belt dungeon parts along the outer edges of the dungeon must be sized significantly larger than the actual dungeon. A rule of thumb is that approximately fifty blocks of empty space should surround the dungeon on every side.

The outer edges of each dungeon part (i.e., the edges that do not intersect another dungeon part) should consist of a wavy fringe of the "magic pink brush" tile material. This is a special meta-material that instructs the game to retain whatever was generated under it using normal terrain generation. It is important to use a wavy, jagged fringe along the outer edges of dungeons, so that any naturally spawning asteroids adjacent to the dungeon don't look unnaturally cut-off. Avoid straight lines and curves that are too smooth, as these will look very awkward if an asteroid happens to spawn naturally adjacent to them.

Designing fringes that look natural among a variety of random asteroid configurations is very difficult. Feel free to study the dungeon parts provided with Belter Dungeons and copy any fringe templates you find useful.

## World Properties

The scripts and stagehands that enable asteroid belt dungeons add several properties to all world files visited by players. These properties may be used by other scripts that can call the `world.getProperty` function. Note, however, that none of these properties can be guaranteed to exist on a given world, so any such scripts must provide appropriate default values and/or null-value detection.

* `rl_worldId` - A string containing the celestial coordinates of the world.
* `rl_worldSeed` - A string containing a hash of the celestial coordinates of the world. (This is a convenience so that hundreds of scripts don't have to recalculate this from `rl_worldId`.)
* `rl_starSystemThreatLevel` - An integer representing the threat level of the star system in which this world is located.

Additionally, a gang configuration is created and stored in the world's properties using the key `rl_gangConfig`. This property, if it exists, will consist of a JSON object in the following format:

```
{
    name : string containing the gang's name,
    hat : string containing a headwear identifier,
    majorColor : integer in the range [1..11],
    capstoneColor : integer in the range [1..11],
    species : string or list of string containing species names
}
```

Of the generated gang configurations, currently only `name`, `hat`, and `species` are used by Belter Dungeons scripts, but the colors are provided for compatibility with the base game's bounty gang configurations.

## Belter Dungeons Objects

Belter Dungeons defines several new objects. A tileset has been provided so that all Belter Dungeons objects can be used within the Tiled editor.

Currently, most of these objects are very similar to base game objects, but with script changes that make them suited for use in player-controlled environments. They have been added as new objects in this mod, rather than patching the original objects, to avoid potential mod conflicts.

### Belter Landing Beacon

The **Belter Landing Beacon** (`rl_beltermechbeacon`) is very similar to the base game [Landing Beacon](https://starbounder.org/Landing_Beacon). However, the base game Landing Beacon uses a hard-coded string as its unique ID, and will permanently corrupt a world if more than one exists in the same world. The Belter Landing Beacon uses a randomly-generated unique ID, so many can coexist in a world. Furthermore, when a player turns off a Belter Landing Beacon by interacting with it, that actually disables the beacon, hiding its signal from other players.

An important note is that a Belter Landing Beacon forces the world chunk in which it exists to remain loaded as long as the world is loaded. Consequently, if many of these exist in a world, they could cause that world to lag. A few beacons won't noticeably impact a world, but if you have dozens of them, lag might become noticeable, so it's recommended to minimize the number of beacons used.

### rl_beltershieldgenerator

This object is very similar to the base game [Shield Generator switch](https://starbounder.org/Shield_Generator_(Switch)). Its scripting has been modded to fix a race condition present in the base game switch, in which the object might associate itself with the wrong dungeon ID. Also, an output node has been provided to output the current switch state, allowing multiple switches, controlling multiple dungeon IDs, to be switched on or off together.

Like the base game Shield Generator switch, it is not intended to be in the possession of players, and does not have an associated item drop.

### rl_invisibleshieldgenerator

This object is very similar to `rl_beltershieldgenerator`, except that it is a completely invisible 1x1 block object, is non-interactive, and does not have an output node. Its intended use is to control shielded regions of dungeons that are supposed to be kept in sync with other shielded regions.

Examples of its intended use can be found in shielded asteroid belt dungeons, which often feature two dungeon IDs. One dungeon ID controls the interior of the dungeon, which features air, gravity, and shielding, and its shielding is usually controlled by an `rl_beltershieldgenerator`. Another dungeon ID controls the exterior of the dungeon, which features vacuum and zero-gravity, but whose shielding must be kept in sync with the interior shielding, so an `rl_invisibleshieldgenerator` is used, and the output node of the interior's switch is wired to the input node of the exterior's switch.

### rl_belterspacecapsule

This object is very similar to the base game [Surface-Mounted Capsule](https://starbounder.org/Surface-Mounted_Capsule). Its scripting has been modified to use the star system threat level instead of the world threat level, and to use treasure pools defined in Belter Dungeons.

### Colony Deed (patched)

The base game's [Colony Deed](https://starbounder.org/Colony_Deed) has been patched to include additional functionality for Belter Dungeons. As patched, a colony deed reads the configuration file found at `/objects/spawner/colonydeed/rl_belter_tenants.config` during its initialization. If the colony deed exists on a world type specified in the `worldTypes` list of the configuration file (currently containing only the `asteroids` world type), then it will:

1. Automatically replace any NPC types given in the `npcTypeReplacements` dictionary with the specified replacement types. In most cases, the only difference between the original and replacement types is a different set of quest pools, to optimize NPCs for asteroid belt quest generation.
1. Generate the NPC at the threat level of the star system in which the world resides, rather than the world's threat level.

*If a mod provides custom colony deeds, its author(s) (or someone else) may wish to provide a compatibility patch that appends the `/objects/spawner/colonydeed/rl_belterdungeons_colonydeed.lua` script to their custom colony deed's `/scripts` property.*

*If a mod provides custom NPC types that generate quests, then its author(s) (or someone else) may wish to provide a compatibility patch that adds belter variants of these NPCs that generate space-oriented quests.*

## Quest Location Objects

Certain randomly generated NPC quests require "quest locations". In the base game, quest locations are defined using `questlocation` stagehands. These stagehands have a couple of deficiencies: they must be pre-configured by developers within dungeon pieces, and they deactivate themselves if players modify the world within their effective region. This means that they are virtually nonexistent in places that users have modified heavily, which means that the range of randomly generated NPC quests is highly restricted in those places.

While the dungeons in Belter Dungeons do define some `questlocation` stagehands, we wish to allow players more control over their own builds. As such, certain objects from the base game and this mod have been enhanced with additional scripting to turn them into "quest location objects". These objects can be placed by the player, and register themselves as quest locations for purposes of quest generation.

The following objects have been enhanced:

* Belter Landing Beacon (from this mod)
* All placeable teleporters from the base game
* All racial flags from the base game
* Mech Platform
* Large Shipping Container
* Shipping Container
* Shelter Shelf
* Metal Store Shelf
* Rusty Metal Store Shelf
* Wooden Store Shelf
* Basic Metal Locker
* Lunar Base Locker

To make an object into a quest location object, two things must be patched into the object's definition. First, the script `/scripts/rl_questlocationobject.lua` must be appended to the object's scripts. Second, a JSON object `rl_questLocation` must be added to the object's parameters, containing at the minimum:

```
{
  "locationType" : "a_location.descriptor"
}
```

The given location descriptor must either exist in or be added to the `/quests/generated/locations.config` file.

The `rl_questLocation` object accepts a couple of additional optional parameters. If `disabled` is set to `true` then the object is disabled as a quest location by default. If `expandable` is set to `true` then the object's bounding box will be automatically expanded until it is large enough to be a quest location. Note that expandable objects use significantly more CPU, so should only be used by relatively rare objects.

Some considerations before making an object a quest location object:

* Quest location objects use more CPU than normal objects, so they shouldn't be the sort of objects that are added hundreds of times to a world.
* Quest location objects are primarily locations for NPCs to beam into a world, so they should be related to beaming in somehow.
* Quests frequently involve hostile NPCs raiding a location, so potential targets of raids are another good category of quest location objects.
* Quest locations need to be large enough for groups of NPCs or monsters to beam into, so for the most part, only larger objects were chosen. The minimum size is 5 blocks high by 4 blocks wide.
* Two smaller objects (flags and landing beacons) were highly related to beaming in, but were too small. These objects feature `expandable` quest location areas. Due to the extra CPU required to implement expansion, such objects should be relatively rare in the world, as these two generally are.

Out of an overabundance of caution, quest location objects are only enabled for use in asteroid belt worlds by default. Additional patches can be provided to allow-list them into additional world types. Once the performance overhead is better understood, I may enable them into base game worlds by default.

## Belter Dungeons Stagehands

Stagehands are virtual objects that can run scripts. Belter Dungeons uses stagehands extensively to replace static Starbound dungeon assets with more dynamic versions appropriate for asteroid fields.

### rl_dynamic_dungeonid

In the base game, dungeon ID can be set in dungeon parts using a rectangular region with the parameter `dungeonid`, which will contain the number of the dungeon ID. Furthermore, two meta-material tiles exist corresponding to the special dungeon IDs 65524 and 65525. Both of these techniques work only if the number of the dungoen ID is known at design time. With Belter Dungeons, we cannot know the number of the dungeon ID until run time, so another mechanism is required.

The `rl_dynamic_dungeonid` stagehand is created by defining a rectangular region with two parameters. The first parameter is named `stagehand` and its value is `rl_dynamic_dungeonid`. The second parameter is named `parameters` and its value is a JSON blob of the form:

```
{ "dungeonIdOffset" : 1 }
```

Going back to the [Dungeon Metadata](#Dungeon_Metadata) section of this guide, the `dungeonIdOffset` value will be the position in the `extraDungeonIds` list corresponding to the rectangular region. In the example defined in that section, the configuration shown above would correspond to the "main exterior" zone and at run time would have a dungeon ID of 105, featuring 0 gravity, no air, and shielding.

A tricky implementation detail of `rl_dynamic_dungeonid` to keep in mind is that a dungeon must define, in the metadata in its `.dungeon` file, extra dungeon IDs for every offset up to the maximum offset that can generate in the dungeon. For example, if the maximum offset that exists in any dungeon part that can generate into your dungeon is 6, then your dungeon metadata must include six extra dungeon ID entries, even if the first five are never used.

Many `rl_dynamic_dungeonid` stagehand rectangular regions may correspond to the same offset. Importantly, `rl_dynamic_dungeonid` stagehand rectangles must never overlap one another, and they must never overlap `dungeonid` rectangles or the meta-material tiles that correspond to the special dungeon IDs 65524 and 65525.

Note that at this time, `rl_dynamic_dungeonid` should only be used in asteroid belt dungeons because only Belter Dungeons generation understands and uses the `extraDungeonIds` parameter of the dungeon metadata, and therefore the extra dungeon IDs will only be allocated properly in asteroid belts.

### rl_systemthreat_monster

In the base game, monsters can be added in dungeon parts using a rectangular region with the parameter `monster` set to the monster type. Because all asteroid belts are tier 1 in the base game, this results in only tier 1 monsters, which is boring.

Instead we use the `rl_systemthreat_monster` stagehand to spawn a monster that has a threat level equal to the star system's threat level. The `parameters` property of the rectangular region defining the stagehand must be defined and must contain a JSON object. The JSON object must contain one field: `monster` must be the name of the monster type to be spawned.

The JSON object may optionally contain a `parameters` field containing a JSON object of arbitrary parameters to pass into the monster. Setting the `parameters` field is highly recommended, and it should contain, at the minimum, the parameter `aggressive`, a boolean indicating whether the monster should initially be aggressive (`true`) or passive (`false`) toward the player. (Special note for asteroid belt dungeons: while most space monsters should be aggressive toward the player, all `rustick` monsters must be defined as passive, otherwise their beam attack will not work.)

### rl_systemthreat_monstergroup

Starbound `.dungeon` definitions allow specific dungeon parts to declare minimum and maximum threat levels under which to spawn. In space hazards, this is used to choose monster groups of the appropriate tiering. This system will not work with asteroid belt dungeons, because all asteroid belts are tier 1 in the base game.

Instead of relying on dungeon part definitions, we will use a `rl_systemthreat_monstergroup` stagehand to choose an appropriate monster group and spawn it into the dungeon. The `parameters` property of the rectangular region defining the stagehand must be defined and must contain a JSON object. The JSON object must contain one field: `monsterGroup` must be the name of the monster group to be spawned. Available names are:

* `rl_belterdungeons_spacegroup_large`
* `rl_belterdungeons_spacegroup_small`

### rl_systemthreat_npc

In the base game, NPCs can be added in dungeon parts using a rectangular region with the parameter `species` set to the NPC's species and `typeName` set to the NPC's type. Because all asteroid belts are tier 1 in the base game, this results in only tier 1 NPCs, which is boring.

Instead we use the `rl_systemthreat_npc` stagehand to spawn an NPC that has a threat level equal to the star system's threat level. The `parameters` property of the rectangular region defining the stagehand must be defined and must contain a JSON object. The JSON object must contain two fields: `species` must either be the name of a species or a list of species names; and `typeName` must be the name of the NPC type to be spawned. The JSON object may optionally contain a `seed` field containing a seed for the NPC, and a `parameters` field containing a JSON object of arbitrary parameters to pass into the NPC.

Unless an NPC seed is provided explicitly, the seed is drawn from the world seed and the NPC's starting position, so multiple players should be able to observe the same NPCs at the same positions within a specific asteroid belt, assuming they have the same game version and mod lists.

### rl_systemthreat_gangmember

In the base game, bounty gang members are spawned using a stagehand that hooks into the bounty system. While Belter Dungeons does not interface with the bounty system at all, in some asteroid belt dungeons we do want to spawn gang member NPCs, and we want them to have a threat level equal to the star system's threat level. This is accomplished using the `rl_systemthreat_gangmember` stagehand.

The `rl_systemthreat_gangmember` stagehand uses the `rl_gangConfig` world property to ensure that all gang members (spawned by this stagehand) on a single world belong to the same gang. By default, there is an 80% chance that a gang will consist of a single species, with the species chosen randomly based on the world seed. If the gang is a multi-species gang, the species of each NPC will be chosen at random.

Like `rl_systemthreat_npc`, gang members are seeded by the world seed and their starting position within the world, so multiple players should be able to observe the same gang members at the same positions within a specific asteroid belt, assuming they have the same game version and mod lists.

### rl_systemthreat_treasure

In the base game, treasure pools are defined as a parameter of container objects within dungeon parts and generated randomly using the world's threat level. Because all asteroid belts are tier 1 in the base game, this results in very lame treasure pools, and in particular no mech blueprints or space weapons.

Instead of defining treasure pools attached to container objects, we use the `rl_systemthreat_treasure` stagehand. The rectangular region defining the stagehand must be drawn to exactly overlap the rectangular bounding box of the target container object. The `parameters` property of the rectangular region must be defined and must contain a JSON object. The JSON object must contain a field `treasurePools`, which must contain a list of treasure pool names. The stagehand will spawn the specified treasure at the star system's threat level, and place it in the indicated container.

Treasure pools are seeded by the world seed and the stagehand's position within the world, so multiple players should be able to observe the same treasure at the same positions within a specific asteroid belt, assuming they have the same game version and mod lists.

## Miscellaneous Dungeon Design Tips

This section details some generic tips for building good asteroid belt dungeons.

### Dungeon ID Trickiness

Dungeon ID assignment is still a tricky point of asteroid belt dungeon design. With the base game, dungeon IDs had to be assigned at design time. With `rl_dynamic_dungeonid` and the `extraDungeonIds` metadata parameter, asteroid belt dungeons can have multiple dungeon IDs that are assigned at runtime. However, the dungeon ID offsets must still be assigned at design time when implementing dungeon parts. This means that certain designs still aren't feasible.

For example, a common asteroid belt dungeon design has a shielded base and a shielded ship in the same dungeon, and the ship's shielding is controlled independently of the base's shielding. However, if you wanted to design a dungeon in which two of the same type of ship could appear together, then those ships' shields could not be independent of one another, because both ships use the same set of Tiled dungeon parts, and therefore have the same offsets for their interior and exterior regions.

### Mech Beacons

**Never use the base game Landing Beacon (mechbeacon) in an asteroid belt dungeon, or any other dungeon that is not exclusively used in an instance world.** If two or more of these beacons exist in a world, that world will become permanently corrupted and will crash instantly upon loading.

In almost all of my dungeons, a belter landing beacon exists in the anchor piece(s) of the dungeons. This ensures that a landing beacon is always present in the dungeon. While you don't have to place the belter landing beacon in an anchor piece, in most cases you will want to design your dungeon layout in such a way that a landing beacon is guaranteed to appear in the dungeon (and also design so that a single dungeon cannot generate more than one or perhaps two beacons). There is one rare dungeon combination in this mod that does not generate an *active* belter landing beacon, but that's been included deliberately as an easter egg for the most devoted belters to find.

### Shielding Trickiness

In many cases, it makes sense to shield a dungeon. However, recall that unlike instance worlds, asteroid belt dungeons exist permanently in the universe and should generally allow the player to colonize and expand on them. As such, if you shield a dungeon, there should generally be a way for the player to unshield it.

Another important aspect of shielded dungeons to remember is to avoid scenarios in which the player may become trapped in the dungeon. In the base game, nearly all shielded dungeons are instance dungeons. If the player quits the game while in an instance dungeon, upon restarting they are returned to their ship, and returning to the instance dungeon puts them back at the beginning of it, so instance dungeon designers generally don't have to worry about the player becoming stuck. When adapting the space encounters into asteroid belt dungeons, I discovered (and fixed) multiple places in which the player could become stuck if the game were stopped and restarted while the player was inside the dungeon. Becoming stuck in a dungeon is an inconvenience for players with admin access, but for players without admin access, it can mean the death of their character.

### Teleporters and Mech Platforms

Players who find an asteroid belt dungeon will probably want to be able to access it conveniently in the future. This typically means planting a flag or a placing a teleporter. Likewise, a player teleporting into an asteroid belt dungeon may want to leave the dungeon to explore the asteroid belt, which can only be achieved if a mech platform has been placed into the dungeon.

Given that teleporters are expensive, and mech platforms are considered to be endgame content, it may not make sense to include them in many asteroid belt dungeons. However, your dungeons should provide room for the player to add them later without too much remodeling. All of the adapted space encounters and NPC ships used in Belter Dungeons have included modifications to make room for teleporters and mech platforms, and a few dungeons include them.

## Adding Your Dungeon to Belter Dungeons

Once you have completed an asteroid belt dungeon, adding it to the Belter Dungeons generation system is easy. The available dungeons are registered in the `stagehands/rl_asteroidbeltmanager.stagehand` file. Use a JSON patch to add your dungeons to this file.

Create a file named `rl_asteroidbeltmanager.stagehand.patch` in the `stagehands` folder of your mod:

```
[
  {
    "op" : "add",
    "path" : "/dungeons/your_dungeons_unique_name",
    "value" : {}
  }
]
```

This is the minimum necessary to add your dungeon to the Belter Dungeons generation system. It creates a new key-value pair in the `dungeons` table with your dungeon's unique name as the key, and an empty table as the value. This table does not have to be empty. Several optional values are respected by Belter Dungeons generation:

* `maximumThreatLevel` specifies the maximum threat level of the star system into which this dungeon may spawn. The default is no maximum.
* `minimumThreatLevel` specifies the minimum threat level of the star system required for this dungeon to spawn. The default is no minimum.
* `weight` takes a non-negative numeric value indicating the relative probability to be assigned to the dungeon, compared with other dungeons. The default value is 1. Higher values make the dungeon more likely to be chosen to spawn, while lower values make it rarer.

If your mod adds more than one dungeon, you must add a separate table for each dungeon, each keyed by its unique dungeon name:

```
[
  {
    "op" : "add",
    "path" : "/dungeons/your_dungeons_unique_name1",
    "value" : {}
  },
  {
    "op" : "add",
    "path" : "/dungeons/your_dungeons_unique_name2",
    "value" : {}
  },
  ...
]
```

### Debugging Your Dungeon

While debugging, it can be very useful to guarantee that only that one dungeon can spawn. You can do this in your mod by using a slightly different variant of the `rl_asteroidbeltmanager.stagehand.patch` patch file:

```
[
  {
    "op" : "replace",
    "path" : "/dungeons",
    "value" : { "your_dungeons_unique_name" : {} }
  }
]
```

This patch will replace the entire Belter Dungeons list with one containing only your dungeon, and as a result, your dungeon will be the only one that can spawn. **You must never use this variation in a mod that you publish.** It is for debugging purposes only!

### Adding Custom NPCs to Belter Dungeons

Unlike terrestrial planets, which contain uniform gravity and on which (in general) NPCs can follow players, space is dominated by vast regions of airless zero-gravity void. NPCs cannot cross [docking fields](https://starbounder.org/Docking_Field), nor can they move properly in zero-gravity environments. As such, the base game quests involving NPCs being escorted to specific locations won't work properly in asteroid belts. Likewise, most terrestrial monsters cannot move correctly in zero-gravity, so quests involving finding terrestrial monsters won't work properly either.

Belter Dungeons provides new quest pools that remove quests that won't work in space and replace them with new space-oriented quests. These new quest pools are:

* `rl_belterdungeons_common` replacing the `common` quest pool
* `rl_belterdungeons_guard` replacing the `guard` quest pool
* `rl_belterdungeons_merchant` replacing the `merchant` quest pool
* `rl_belterdungeons_tenant` replacing the `tenant` quest pool

When designing NPC types for use in asteroid belts, you should use only the above `rl_belterdungeons_` prefixed quest pools (or custom quest pools of your own making). Additionally, two of the base game quest pools, `hats` and `shady`, contain no quests that break in space, so they may be used with asteroid belt NPC types.

Likewise, when designing NPC types for use on terrestrial worlds, you should not use the `rl_belterdungeons_` prefixed quest pools, because these contain quests that work only in space.

If you want an NPC type to be usable in both terrestrial and asteroid belt dungeons, then you should design the NPC type to work in terrestrial dungeons, that is, to use the base game quest pools. Then make a second variant of that NPC type, identical to the first, but using the space-oriented quest pools. This can be done easily because NPCs use an inheritance model. Let's assume your initials are `abc`, and then let's assume your NPC is called `abc_supercoolnpc`. You'd design this NPC for use on terrestrial worlds using the base game `common` quest pool. Then, you'd create a second NPC type, called something like `abc_beltersupercoolnpc`, and it's definition could be as simple as:

```
{
  "type" : "abc_beltersupercoolnpc",
  "baseType" : "abc_supercoolnpc",

  "scriptConfig" : {
    "questGenerator" : {
      "pools" : ["rl_belterdungeons_common"]
    }
  }
}
```

Given this definition, `abc_beltersupercoolnpc` would be identical to `abc_supercoolnpc` except that it would use the `rl_belterdungeons_common` quest pool instead of the `common` quest pool. You'd use `abc_supercoolnpc` in your terrestrial dungeons, and `abc_beltersupercoolnpc` in your asteroid belt dungeons.

As an additional complication, what if `abc_supercoolnpc` is a tenant NPC, which can be spawned by a colony deed? In this case, in addition to the definitions given above, you'll need to make one extra patch. Create the patch file `/objects/spawner/colonydeed/rl_belter_tenants.config.patch` and add this:

```
[
  {
    "op" : "add",
    "path" : "/npcTypeReplacements/abc_supercoolnpc",
    "value" : "abc_beltersupercoolnpc"
  }
]
```

This patch will instruct colony deeds to automatically replace `abc_supercoolnpc` tenants with `abc_beltersupercoolnpc` tenants when on asteroid belt worlds.

## Advanced Technical Discussion

*This section describes how Belter Dungeons adds major dungeons to a type of world that, in the base game, is devoid of the constructs necessary to generate major dungeons. Those interested only in designing dungeons for use by Belter Dungeons can ignore this section.*

In the Starbound base game, asteroid belts are significantly different from terrestrial worlds. The game allows the creation of new types of terrestrial worlds, whereas it's hard-coded to contain only a single type of asteroid belt. Furthermore, asteroid belts do not contain certain game constructs, such as layers, which are used by the game's built-in major dungeon generation. As such, spawning major dungeons into asteroid belts was considered to be impossible.

Then I noticed the `world.placeDungeon` function, which was used to place new pieces of the player space stations. This function enabled the creation of this mod. But I wasn't content with simply dumping major dungeons into asteroid belts. I wanted them to function as close to terrestrial major dungeons as possible.

Two main challenges remained:

1. Dungeons should spawn pseudo-randomly into asteroid belts and should behave as similarly as possible to terrestrial dungeons.
1. Asteroid belt dungeons should be appropriately challenging for players.

### Dungeon Spawning

Terrestrial dungeon generation obeys certain properties:

1. Major dungeons spawn only once.
1. Upon approaching a world for the first time, a specific number of major dungeons will spawn.
1. The major dungeons that may spawn are specified using a weighted list.
1. Dungeon generation is pseudo-random and seed-based, so that multiple players should observe the same set of dungeons on a specific world, assuming that their game versions and mod lists are the same.

The `world.placeDungeon` function can be called only from the server scripting context. This implies either an object or stagehand, and a stagehand was most appropriate. The function `world.spawnStagehand` can be called from the player's scripting context. The most appropriate time to call it was during deployment, so a new script was appended to the player's `deploymentConfig` scripts to add this functionality. Thus began the `rl_asteroidbeltmanager` stagehand.

The `rl_asteroidbeltmanager` stagehand uses a singleton pattern to ensure that only one instance can exist per world. To ensure that dungeon generation happens only once, the stagehand script writes its state into a world property named `rl_asteroidbeltmanager_state`. Each time the world is loaded, the stagehand will initialize and read any existing state from the world property store, but once it determines that it has already generated dungeons, it will shut down.

To ensure that dungeon generation is pseudo-random, the stagehand script seeds the random number generator with a hash of the world's celestial address. This presented a small problem, because the world's celestial address cannot be obtained from within the world's scripting context itself. However, the player's scripting context can obtain this information and pass it into the constructor for the stagehand.

### Challenging Gameplay

The `rl_asteroidbeltmanager` stagehand accomplished the first goal of this mod, to pseudo-randomly generate major dungeons into asteroid belts similarly to terrestrial worlds. However, game play was boring, because in the base game, all asteroid belts have a threat level of 1, with the consequence that all NPCs, monsters, and treasure were limited to tier 1.

An initial suggestion was to elevate asteroid belts to tier 6, or to configure them to use a random threat level. However, because only one type of asteroid belt can be defined in the game, this would mean that some players would experience a tier 6 asteroid belt in their starter system, which would likely result in death and disillusionment.

A better solution would be to somehow adjust the threat level based on the tiering of the star system in which the asteroid belt exists. This would ensure that players experience a level of difficulty commensurate with their existing progression. The problem was, there was no way to obtain information about the star system from within the world scripting context.

Once again, the information needed was obtained from the player context. While players cannot directly query star parameters, they can obtain the celestial coordinates of the world to which they are deploying. The star system coordinates are simply the world coordinates without the appended world identifier at the end.

The properties of a celestial body, be it planet or star, are available only from within a scripted window pane's scripting context. To obtain the star's parameters, a new scripted window pane was created, `rl_systemthreatscanner`. This is an invisible window pane that does nothing but obtain the parameters of the star that the world is orbiting and write them to the world's property store. Once that has happened, the pane automatically closes itself.

The `rl_systemthreatscanner` window pane is "opened" by the extended player deployment script immediately upon the player deploying to any world. The pane obtains the information and closes itself in only a few Lua update ticks (i.e., less than 1/10th of a second), so it is usually finished in the time taken to run a mech deployment or player beam-in animation.

On asteroid belt worlds, the deployment script waits for the `rl_systemthreatscanner` to finish before attempting to spawn `rl_asteroidbeltmanager`, to ensure that the appropriate world properties exist before any dungeon spawning begins. The properties provided to worlds by the `rl_systemthreatscanner` enable the `rl_asteroidbeltmanager` to use the star system's threat level as input to decide which dungeons to spawn. These properties also enable the Belter Dungeons stagehands to use system threat level to spawn tier-appropriate NPCs, monsters, and treasure within dungeons.

The `rl_systemthreatscanner` is run when the player first visits any asteroid belt or terrestrial world (i.e., planets and moons), but not on instance worlds such as anomalies, ships, space stations, or vaults. The properties it generates (`rl_worldId`, `rl_worldSeed`, and `rl_starSystemThreatLevel`) are available on any such world that has been visited at least once by a player after this mod has been installed.
