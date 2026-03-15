**Translations** a modding field that involves translating the game or a mod to a different language. This can be done by creating translation files for the game or mod, which are then read by the game which automatically retrieves the text via keys associated to translation values. It is also possible to create a new translation language for the game.

## Translation types

Different translation types exist, used for different purposes. A translation type is associated to a specific file which needs to hold the translations for that type, sometimes requiring a prefix for the keys.

As of [Build 42.15.0](https://pzwiki.net/wiki/Build_42.15.0 "Build 42.15.0"), the translation files are `.json` files and should no longer have the language code in their name.

<table><caption>List of translation types</caption><tbody><tr><th>Translation type</th><th>Filename</th><th>Key prefix</th><th>Function</th><th>Notes</th></tr><tr><td>Attributes</td><td><code>Attributes</code></td><td></td><td><code>getText</code></td><td></td></tr><tr><td>BodyParts</td><td><code>BodyParts</code></td><td></td><td><code>getText</code></td><td></td></tr><tr><td>Challenge</td><td><code>Challenge</code></td><td><code>Challenge_</code></td><td><code>getText</code></td><td></td></tr><tr><td>ContextMenu</td><td><code>ContextMenu</code></td><td><code>ContextMenu_</code></td><td><code>getText</code></td><td><p>Translations used in the context menus of the game.</p></td></tr><tr><td>DynamicRadio</td><td><code>DynamicRadio</code></td><td><code>AEBS_</code></td><td><code>getRadioText</code></td><td><p>Dynamic radio translations.</p></td></tr><tr><td>Entity</td><td><code>Entity</code></td><td><code>EC_</code></td><td><code>getText</code></td><td><p>Translations for entity scripts.</p></td></tr><tr><td>EvolvedRecipeName</td><td><code>EvolvedRecipeName</code></td><td></td><td><code>Translator.getItemEvolvedRecipeName</code></td><td><p>Translations for evolved recipe scripts.</p></td></tr><tr><td>Farming</td><td><code>Farming</code></td><td><code>Farming_</code></td><td><code>getText</code></td><td><p>Translations for farming menus.</p></td></tr><tr><td>Fluids</td><td><code>Fluids</code></td><td><code>Fluid_Name_</code></td><td><code>getText</code></td><td><p>Translations for fluid related UI elements and fluid containers.</p></td></tr><tr><td>GameSound</td><td><code>GameSound</code></td><td><code>GameSound_</code></td><td><code>getText</code></td><td><p>Game sounds and categories translations.</p></td></tr><tr><td>IGUI</td><td><code>IG_UI</code></td><td><code>IGUI_</code></td><td><code>getText</code></td><td><p>Translations for in-game user interface elements.</p></td></tr><tr><td>ItemName</td><td><code>ItemName</code></td><td></td><td><code>getItemNameFromFullType</code></td><td><p>Translations for item scripts. The key needs to be the full type of the item.</p></td></tr><tr><td>Location_Generic</td><td></td><td></td><td></td><td><p>A translation file for the map. The filename needs to refer the file "map.info" in the mod's media folder.</p></td></tr><tr><td>MakeUp</td><td><code>MakeUp</code></td><td></td><td><code>getText</code></td><td><p>Translations for make up.</p></td></tr><tr><td>MapLabel</td><td><code>MapLabel</code></td><td><code>MapLabel_</code></td><td><code>getText</code></td><td></td></tr><tr><td>Mod</td><td><code>Mod</code></td><td></td><td></td><td><p>Translations for the mod.info file. Possible keys are "name" and "description".</p></td></tr><tr><td>Moodles</td><td><code>Moodles</code></td><td><code>Moodles_</code></td><td><code>getText</code></td><td><p>Moodles status and descriptions translations</p></td></tr><tr><td>Moveables</td><td><code>Moveables</code></td><td></td><td><code>Translator.getMoveableDisplayName</code></td><td><p>Moveable tiles as items translations.</p></td></tr><tr><td>MultiStageBuild</td><td><code>MultiStageBuild</code></td><td><code>MultiStageBuild_</code></td><td><code>Translator.getMultiStageBuild</code></td><td><p>Translations for multi stage build.</p></td></tr><tr><td>Print_Media</td><td><code>Print_Media</code></td><td><code>Print_Media_</code></td><td><code>getText</code></td><td><p>Text content for media items such as newspapers, describing their content.</p></td></tr><tr><td>Print_Text</td><td><code>Print_Text</code></td><td><code>Print_Text_</code></td><td><code>getText</code></td><td><p>Raw text content for media items such as newspapers, describing their content.</p></td></tr><tr><td>RadioData</td><td><code>RadioData</code></td><td><code>RD_</code></td><td><code>getText</code></td><td><p>Radio translations with the key being a GUID of the radio text.</p></td></tr><tr><td>RecipeGroups</td><td><code>RecipeGroups</code></td><td><code>RecipeGroup_</code></td><td><code>Translator.getRecipeGroupName</code></td><td></td></tr><tr><td>Recipes</td><td><code>Recipes</code></td><td></td><td><code>getRecipeDisplayName</code></td><td><p>Translations for the craftRecipe scripts. The key needs to be the ID of the craftRecipe block.</p></td></tr><tr><td>Recorded_Media</td><td><code>Recorded_Media</code></td><td><code>RM_</code></td><td><code>getText</code></td><td><p>Recorded media translations with the key being a GUID of the media text.</p></td></tr><tr><td>Sandbox</td><td><code>Sandbox</code></td><td><code>Sandbox_</code></td><td><code>getText</code></td><td><p>Sandbox options translations.</p></td></tr><tr><td>Stash</td><td><code>Stash</code></td><td><code>Stash_</code></td><td><code>getText</code></td><td><p>Survivor maps translations.</p></td></tr><tr><td>SurvivalGuide</td><td><code>SurvivalGuide</code></td><td><code>SurvivalGuide_</code></td><td><code>getText</code></td><td><p>Survival guide translations.</p></td></tr><tr><td>SurvivorNames</td><td><code>SurvivorNames</code></td><td></td><td><code>getText</code></td><td><p>All possible automatic character names. Used for random name generation of the player character or for zombies.</p></td></tr><tr><td>Tooltip</td><td><code>Tooltip</code></td><td><code>Tooltip_</code></td><td><code>getText</code></td><td><p>Tooltips used for UIs.</p></td></tr><tr><td>UI</td><td><code>UI</code></td><td><code>UI_</code></td><td><code>getText</code></td><td><p>Translation file for user interface elements.</p></td></tr></tbody></table>

### Map information

Map translations use the following files:

```
media/
├── maps/
│   └── <map folder>/
│       ├── map.info
│       └── ...
└── lua/
    └── shared/
        └── Translate/
            └── <language code>/
                └── <map>.json

```

The file needs to have the following format:

```
{
    "title": "Your map name",
    "description": "Your map description"
}

```

Example Riverside description: **Source:** `Translate\EN\Riverside, KY.json`

_**Retrieved**: [Build 42.15.0](https://pzwiki.net/wiki/Build_42 "Build 42")_

```
{
    "title": "Riverside, KY",
    "description": "<CENTRE> <SIZE:medium> RIVERSIDE <LINE> <LINE><LEFT> <SIZE:small> A colorful town tightly hugging the banks of the mighty Ohio: exploring Riverside is a rich and diverse experience! To the west you'll find the older parts of town, while out east is where wealthier residents work, rest, and play. <LINE> <LINE>If you're considering a stay with us, why not check out the nearby West Maple Country Club? The ultimate in comfort and relaxation, members have access to an 18-hole golf course, tennis courts, swimming pool, and fantastic bars and lounges. Come join today!"
}

```

### JSON Schemas

JSON schemas are used to validate the format of JSON files, ensuring they meet the required structure. For translations, those were made to validate the key prefixes and required fields for each translation type.

To use those schemas, you have different methods, the one described in this guide bases itself on the widely used [Visual Studio Code](https://pzwiki.net/wiki/Visual_Studio_Code "Visual Studio Code") in the modding community.

The schemas are provided in the [PZ Translation Data](https://pzwiki.net/wiki/PZ_Translation_Data "PZ Translation Data") repository for download or direct cloning. Once downloaded, you can directly refer to them with a custom key `$schema` as follows:

```
{
    "$schema": "link/to/schema.json",
    ...
}

```

The `link/to/schema.json` needs to link to the schema for the specific translation type schema which follows the link format `https://raw.githubusercontent.com/SirDoggyJvla/pz-translation-data/refs/heads/main/PZ_Translation_Schemas/<translationType>.schema.json`. You need to replace `<translationType>` with the translation type listed in the table above, for example `Moveables` will be `https://raw.githubusercontent.com/SirDoggyJvla/pz-translation-data/refs/heads/main/PZ_Translation_Schemas/Moveables.schema.json`.

To use online schemas, you need to add a new trusted domain to your Visual Studio Code setting `json.schemaDownload.trustedDomains`, either in your global settings or workspace settings:

**Source:** `.vscode\settings.json`

```
{
    "json.schemaDownload.trustedDomains": {
        "https://raw.githubusercontent.com/SirDoggyJvla/pz-translation-data": true
    }
}

```

For example, the setup for a schema will be as follows: **Source:** `media\lua\shared\Translate\EN\UI.json`

```
{
    "$schema": "https://raw.githubusercontent.com/SirDoggyJvla/pz-translation-data/refs/heads/main/PZ_Translation_Schemas/UI.schema.json",
    ...
}

```

[![](https://pzwiki.net/w/images/3/3a/LightBulbBlue.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

Alternatively, you can use local schemas by downloading them, then using the path to the schema instead of the online link.

## Languages

The game uses languages added to the `media/lua/shared/Translate` folder, information about the language is stored in the `language.txt` file of each language directory.

For [Build 41](https://pzwiki.net/wiki/Build_41 "Build 41"), most language use different encodings. Since [Build 42.15.0](https://pzwiki.net/wiki/Build_42.15.0 "Build 42.15.0"), all languages use UTF-8 encoding.

Languages in game
| Code | Language | Build 41 encoding | Pre Build 42.15.0 encoding | Post Build 42.15.0 encoding |
| --- | --- | --- | --- | --- |
| AR | Espanol (AR) - Argentina Spanish | Cp1252 | Cp1252 | UTF-8 |
| CA | Catalan | ISO-8859-15 | ISO-8859-15 | UTF-8 |
| CH | Traditional Chinese | UTF-8 | UTF-8 | UTF-8 |
| CN | Simplified Chinese | UTF-8 | UTF-8 | UTF-8 |
| CS | Czech | Cp1250 | Cp1250 | UTF-8 |
| DA | Danish | Cp1252 | UTF-8 | UTF-8 |
| DE | Deutsch - German | Cp1252 | UTF-8 | UTF-8 |
| EN | English | UTF-8 | UTF-8 | UTF-8 |
| ES | Espanol (ES) - Spanish | Cp1252 | UTF-8 | UTF-8 |
| FI | Finnish | Cp1252 | UTF-8 | UTF-8 |
| FR | Francais - French | Cp1252 | UTF-8 | UTF-8 |
| HU | Hungarian | Cp1250 | UTF-8 | UTF-8 |
| ID | Indonesia | UTF-8 | UTF-8 | UTF-8 |
| IT | Italiano | Cp1252 | UTF-8 | UTF-8 |
| JP | Japanese | UTF-8 | UTF-8 | UTF-8 |
| KO | Korean | UTF-16 | UTF-8 | UTF-8 |
| NL | Nederlands - Dutch | Cp1252 | UTF-8 | UTF-8 |
| NO | Norsk - Norwegian | Cp1252 | UTF-8 | UTF-8 |
| PH | Tagalog - Filipino | UTF-8 | UTF-8 | UTF-8 |
| PL | Polish | Cp1250 | UTF-8 | UTF-8 |
| PT | Portuguese | Cp1252 | UTF-8 | UTF-8 |
| PTBR | Brazilian Portuguese | Cp1252 | UTF-8 | UTF-8 |
| RO | Romanian | UTF-8 | UTF-8 | UTF-8 |
| RU | Russian | Cp1251 | UTF-8 | UTF-8 |
| TH | Thai | UTF-8 | UTF-8 | UTF-8 |
| TR | Turkish | Cp1254 | UTF-8 | UTF-8 |
| UA | Ukrainian | Cp1251 | UTF-8 | UTF-8 |

### Adding new languages

[![](https://pzwiki.net/w/images/9/95/Notebook.png)](https://pzwiki.net/wiki/Template:Stub "Template:Stub")

This section may need more content.

Editors are encouraged to add new material to the page while expanding upon current topics. [Edit](https://pzwiki.net/w/index.php?title=Translation&veaction=edit) ([Create account](https://pzwiki.net/w/index.php?title=Special:CreateAccount&returnto=Translation))

-   Create a new folder with the id of the language
-   Add the [language.txt](https://pzwiki.net/wiki/Language.txt "Language.txt") file
-   Add fonts if neccessary
-   Add translations

## Example

Examples were provided in the [official documentation](https://pzwiki.net/wiki/TIS_Modding_Guides#Build_42.15.0 "TIS Modding Guides").

**Source:** `media/lua/shared/Translate/EN\UI.json`

```
{
    "UI_mainscreen_continue": "CONTINUE (Duck ¼)",
    "UI_mainscreen_tutorial": "TUTORIAL (Duck ½)",
    "UI_mainscreen_solo": "SOLO (Duck ¾)",
    "UI_mainscreen_mods": "MODS (Duck ¿)"
}
```