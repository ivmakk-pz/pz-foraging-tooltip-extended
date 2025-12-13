# Migration Guide

## Registries

In version **42.13**, the way to add some identifiers has been changed. The IDs are used in **scripts** and **recipes**.

### Identifiers

- CharacterTrait
- CharacterProfession
- ItemTag
- Brochure
- Flier
- ItemBodyLocation
- ItemType
- MoodleType
- WeaponCategory
- Newspaper
- AmmoType

### How to add identifiers

To add these identifiers and use them in scripts, you need to add them using **Lua** in the `registries.lua` file.

Requirements:

- The file must be stored in the `media` folder.
- It **must have the exact name** `registries.lua`.
- It is loaded **before scripts** and **before any other Lua files**.

### Example of adding IDs

```lua
CharacterTrait.register("testmod:nimblefingers")
CharacterProfession.register("testmod:thief")
ItemTag.register("testmod:bobbypin")
Brochure.register("testmod:Village")
Flier.register("testmod:BirdMilk")
ItemBodyLocation.register("testmod:MiddleFinger")
ItemType.register("testmod:gamedev")
MoodleType.register("testmod:Happy")
WeaponCategory.register("testmod:birb")
Newspaper.register("testmod:BirdNews", List.of("BirdKnews_July30",
"BirdKnews_July2"))

local item_key = ItemKey.new("bullets_666", ItemType.NORMAL)
AmmoType.register("testmod:duck_bullets", item_key)
```

### Example of usage in scripts

```text
character_trait_definition testmod:nimblefingers
{
    IsProfessionTrait = false,
    DisabledInMultiplayer = false,
    CharacterTrait = testmod:nimblefingers,
    Cost = 3,
    UIName = UI_trait_nimblefingers,
    UIDescription = UI_trait_nimblefingersDesc,
    XPBoosts = Lockpicking=2,
    GrantedRecipes =
    Lockpicking;AlarmCheck;CreateBobbyPin;CreateBobbyPin2,
}
```

```text
craftRecipe CreateBobbyPin
{
    timedAction = Making,
    Time = 40,
    Tags = InHandCraft;CanBeDoneInDark,
    needTobeLearn = true,
    inputs
    {
        item 1 tags[base:screwdriver] mode:keep
        flags[MayDegradeLight;Prop1],
        item 1 [Base.Paperclip],
    }
    outputs
    {
        item 1 TestMod.HandmadeBobbyPin,
    }
}
```

```text
character_profession_definition testmod:thief
{
    CharacterProfession = testmod:thief,
    Cost = 2,
    UIName = UI_prof_Thief,
    IconPathName = profession_burglar2,
    XPBoosts = Nimble=3;Sneak=2;Lightfoot=1;Lockpicking=2,
    GrantedTraits = testmod:nimblefingers,
}
```

```text
item HandmadeBobbyPin
{
    Weight = 0.01,
    ItemType = base:normal,
    Icon = HandmadeBobbyPin,
    Tags = testmod:bobbypin,
    Tooltip = Tooltip_TestMod_BobbyPin,
    WorldStaticModel = Paperclip,
}
```

## Lua

- Some Lua API has been modified. If something has stopped working for you, check the decompiled Java code.
- There will be more API changes in upcoming unstable patches

### Script changes

- **Item Script:** `DisplayName` has been removed. Now translation is taken only from `Module.ItemId`.
- **Item Script:** `Type` has been renamed to `ItemType` and requires the `ItemType` registry.
- Tags now require the `ItemTag` registry.
- It will also be useful to study script examples from the base game. They are now generated from Java code and are read by game as before.

## P.S.

- Future content patches will include modding changes based on your reports and requests, and new API documentation will gradually become available.
- More details check in mod example.
- Some Lua API has been modified. If something has stopped working for you, check the decompiled Java code.
- There will be more API changes in upcoming unstable patches.

