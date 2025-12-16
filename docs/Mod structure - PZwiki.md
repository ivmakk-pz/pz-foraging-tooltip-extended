https://pzwiki.net/wiki/Mod_structure

This page has been updated to the current _unstable_ beta version ([42.12.3](https://pzwiki.net/wiki/Build_42 "Build 42")).

![](https://pzwiki.net/w/images/7/7e/PlushSpiffo.png)_This article is about modding structure of Project Zomboid. For game files of Project Zomboid, see [Game files](https://pzwiki.net/wiki/Game_files "Game files"). For explanations of file formats, see [File formats](https://pzwiki.net/wiki/File_formats "File formats")._

Local mods are recognized in two different folders which each have their own rules and structure and are both in the [cache folder](https://pzwiki.net/wiki/Game_files#Cache_folder "Game files"):

-   `Zomboid/mods/` - place to put mods to install manually without using the Steam Workshop. Not recommanded for mod development.
-   `Zomboid/workshop/` - folder used for mod development and uploading to the Steam Workshop.

Example default mod structures are provided by the community to directly use:

-   [Project Zomboid Community Modding template](https://pzwiki.net/wiki/Project_Zomboid_Community_Modding_template "Project Zomboid Community Modding template") - a template mod structure to use as a base for your own mods. Simply make a copy of the repository.

[![](https://pzwiki.net/w/images/3/3b/LightBulbYellow.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

Some [operating systems](https://en.wikipedia.org/wiki/Operating_system "wikipedia:Operating system") like Linux and MacOS are case-sensitive regarding file and folder names. Make sure to use the correct casing when creating your mod structure to avoid issues for those users. (for example `common` and not `Common`)

## Video guide

[![](https://pzwiki.net/w/images/3/38/PZ_Modding_Guides_-_setting_up_a_mod_structure_-_thumbnail.png)](https://www.youtube.com/watch?v=MUGQ647o5M4)

PZ Modding Guides - setting up a mod structure

## Mods or workshop

Using the `Workshop` folder is needed to use the [in-game uploader](https://pzwiki.net/wiki/Uploading_mods#In-game_uploader "Uploading mods") meaning if you use the `mods` folder you will inevitably end up having to make a copy of your mod in the `Workshop` folder to upload it to the Steam Workshop. This is still an issue when using an external uploader like the [Steam Uploader](https://pzwiki.net/wiki/Steam_Uploader "Steam Uploader") modding project, as you need to upload the `mods` folder which would upload all the extra folders. Take this for example, the folder structure of the cache folder:

```
~/
└── Zomboid/
    ├── Crafting/
    ├── joypads/
    ├── logs/
    ├── Lua/
    ├── messaging/
    ├── mods/
    │   ├── MyMod1/
    │   │   └── ...
    │   └── MyMod2/
    │       └── ...
    ├── Recording/
    ├── Sandbox Presets/
    ├── Saves/
    ├── Workshop/
    │   └── MyModWorkshop/
    │       └── Contents/
    │           └── mods/
    │               ├── MyMod1/
    │               │   └── ...
    │               └── MyMod2/
    │                   └── ...
    ├── console.txt
    └── ...

```

In the case where you use the `mods` folder, to upload with an external tool you would have to indicate the application to upload the content of the folder `~/Zomboid` since the `mods` folder needs to be uploaded. This will also upload all the folders around it and will upload other mods you are developing inside the `mods` folder.

A bad solution is to copy the mods you want to upload inside of the `Workshop` folder for your mod but the problem with making copies of a mod is that they will clash and so you need to make sure to delete the mod copy inside the `Workshop` folder or you risk having invisible issues during the development.

This last principle also applies to downloading your own mods on the Workshop while having local copies inside the `mods` folder or the `Workshop` folder, as they will clash and cause issues. While working directly from the `Workshop` folder will assure you never get any problems in the future.

Another benefit of using the `Workshop` folder is that it allows you to store additional assets in the upper echelon of your mods `Workshop` folder. This is due to the `Workshop` folder having extra folders before the `mods` folder, taking the previous shared example you have `MyModWorkshop` and `Contents`. Anything in the `Contents` folder will be uploaded to the Workshop, but anything placed at the same level as it, inside `MyModWorkshop`, will not be uploaded and completely ignored by the game. You can use this to create other subfolders like `images` or `assets` which will hold your modding assets, you can have a file `README.md` and also a `.git` folder to have `MyModWorkshop` serve as your mod's [git](https://en.wikipedia.org/wiki/Git "wikipedia:Git") repository. This also applies to folders specific to your [IDE](https://en.wikipedia.org/wiki/Integrated_development_environment "wikipedia:Integrated development environment") like `.vscode` ([VSCode](https://pzwiki.net/wiki/Visual_Studio_Code "Visual Studio Code")) or `.idea` ([IDEA](https://pzwiki.net/wiki/IntelliJ_IDEA "IntelliJ IDEA")).

[![](https://pzwiki.net/w/images/5/55/LightBulbRed.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

When developing mods, make sure to not be subscribed to your own mod on the Steam Workshop. Any duplicated version of your mod on your computer which are loaded by the game, will mix and clash together, sometimes making any changes you make in a version, not appear in-game because they are being overwritten by this other duplicate version of the mod. Always keep only your local version inside the Workshop folder.

## Workshop folder

The Workshop folder will use the following structure:

```
Zomboid/
└── Workshop/
    └── MyExampleMod/
        ├── Contents/
        │   └── mods/
        │       ├── MyMod1/
        │       │   └── ...
        │       └── MyMod2/
        │           └── ...
        ├── workshop.txt
        └── preview.png

```

-   `Contents/`: The folder will only have the `mods/` folder.
-   `Contents/mods/`: Your various mods which can be activated by the players will be put here, with each mod having their own [mod.info](https://pzwiki.net/wiki/Mod.info "Mod.info") file associated to be recognized (see [#Mod folder](https://pzwiki.net/wiki/Mod_structure#Mod_folder)). This is the folder uploaded to the Workshop.
-   `workshop.txt`: Informations which are needed to upload your mod are put here (see [workshop.txt](https://pzwiki.net/wiki/Workshop.txt "Workshop.txt")).
-   `preview.png`: The image used as your mod preview on the Steam Workshop. Game imposes a 256x256 resolution.

[![](https://pzwiki.net/w/images/3/3a/LightBulbBlue.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

Subfolders in `MyExampleMod/` which are not `Contents/` are not recognized by the game and can be used to store various files for your mod that shouldn't get uploaded. Thus you can store in it Python scripts, images, assets, etc.

[![](https://pzwiki.net/w/images/3/3a/LightBulbBlue.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

`MyExampleMod/` can be used as a Git repository (GitHub, GitLab...).

[![](https://pzwiki.net/w/images/5/55/LightBulbRed.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

Make sure to access the Workshop folder inside the [cache folder](https://pzwiki.net/wiki/Game_files#Cache_folder "Game files") and not the game files one which has the path `steamapps/common/ProjectZomboid/Workshop` ! This folder cannot be used for modding.

## Mod folder

The files of your mods are placed in the folder `Contents/mods/` alongside a [mod.info](https://pzwiki.net/wiki/Mod.info "Mod.info") file which is the core of your mod. The folder structure of your mod folder should be as follows:

#### Build 41

[Build 41](https://pzwiki.net/wiki/Build_41 "Build 41") uses the following modding structure.

```
Contents/
└── mods/
    ├── MyMod1/
    │   ├── media/
    │   │   └── ...
    │   ├── mod.info
    │   ├── poster.png
    │   └── ...
    └── MyMod2/             <--- for extra mods, simply add a new mod folder
        ├── media/
        │   └── ...
        ├── mod.info
        ├── poster.png
        └── ...

```

[![](https://pzwiki.net/w/images/3/3b/LightBulbYellow.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

The [Build 42 modding structure](https://pzwiki.net/wiki/Mod_structure#Build_42) is considered for the rest of the page. The main difference is the position of the [media folder](https://pzwiki.net/wiki/Mod_structure#Media_folder) and the lack of versioning and common folders for Build 41.

### Build 42

[Build 42](https://pzwiki.net/wiki/Build_42 "Build 42") uses the following modding structure.

```
Contents/
└── mods/
    ├── MyMod1/
    │   ├── common/         <--- common folder is mandatory, even if empty !
    │   │   └── media/
    │   │       └── ...
    │   ├── 42/
    │   │   ├── media/
    │   │   │   └── ...
    │   │   ├── mod.info
    │   │   └── poster.png
    │   ├── 42.1/           <--- for extra versions, simply add a new version folder
    │   │   ├── media/
    │   │   │   └── ...
    │   │   ├── mod.info
    │   │   └── poster.png
    │   ├── 42.1.5/         <--- same here, another different version
    │   │   ├── media/
    │   │   │   └── ...
    │   │   ├── mod.info
    │   │   └── poster.png
    │   └── ...
    └── MyMod2/            <--- for extra mods, simply add a new differently named mod folder
        └── ...

```

[![](https://pzwiki.net/w/images/3/3a/LightBulbBlue.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

Multiple mods can be present in a single uploaded mod (inside `Contents/mods/`). This can be used for optional mods or different versions of the same mod.

## Common and versioning folders

Common and versioning folders, introduced in [Build 42](https://pzwiki.net/wiki/Build_42 "Build 42"), help manage different mod versions per game version.

-   **Versioning folders** are useful when players stick to older game versions. You don't need one for every version. They should contain code files and [mod.info](https://pzwiki.net/wiki/Mod.info "Mod.info"), as they often change with the game version.
-   **Common folder** stores large files (models, textures, animations) to keep mod size down.

These folders load with the following order:

1.  Common folder
2.  Closest versioning folder to the game version (overwrites common files which are present in it)

The versioning folders can have the following possible naming:

```
buildVersion.majorUpdate.minorUpdate
buildVersion.majorUpdate                ====> buildVersion.majorUpdate.0
buildVersion                            ====> buildVersion.0.0

```

For example:

```
42             ====> 42.0.0
43             ====> 43.0.0
42.12          ====> 42.12.0
42.1           ====> 42.1.0
42.0.5
43.5.1

```

[![](https://pzwiki.net/w/images/3/3b/LightBulbYellow.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

Common folder is not recognized by [Build 41](https://pzwiki.net/wiki/Build_41 "Build 41") modding structure. However, the [Build 41](https://pzwiki.net/wiki/Build_41 "Build 41") [Lua API](https://pzwiki.net/wiki/Lua_(API) "Lua (API)") can access some files in some cases.

[![](https://pzwiki.net/w/images/5/55/LightBulbRed.png)](https://pzwiki.net/wiki/Template:Note "Template:Note")

Common folder is mandatory, even if empty, for your mod to work !

## Media folder

Mod assets are for the most part inside this folder. Different subfolders need to be created based on the type of assets. These are usually the same as the [game media folder](https://pzwiki.net/wiki/Game_files#Media_folder "Game files") and based on your [modding field](https://pzwiki.net/wiki/Modding#Modding_fields "Modding"), you may need different ones. See each modding fields individual pages for more details on their folder structure:

<table><caption>Subfolders and modding field</caption><tbody><tr><th>Modding field</th><th>Subfolder</th></tr><tr><td><a href="https://pzwiki.net/wiki/Animation" title="Animation">Animation</a></td><td><p>Animations involve the storing of the <a href="https://pzwiki.net/wiki/File_formats#Modeling_and_animation_formats" title="File formats">animation files</a>, as well defining how those animations are triggered:</p><ul><li><code>anims_X</code> - stores the animation files.</li><li><code>AnimSets</code> - stores the animation triggers and parameters definitions.</li></ul></td></tr><tr><td><a href="https://pzwiki.net/wiki/Lua_(API)" title="Lua (API)">Lua</a></td><td><p>Most of the time, Lua modding doesn't involve game assets but simple plain code lines, however in some cases you may want to add custom UI elements and maybe need textures.</p><ul><li><code>lua</code> - stores the Lua scripts.</li><li><code>ui</code> and <code>textures</code> - used for custom UI elements</li></ul></td></tr><tr><td><a href="https://pzwiki.net/wiki/Mapping" title="Mapping">Mapping</a></td><td><ul><li><code>maps</code> - stores the map files and assets.</li></ul></td></tr><tr><td><a href="https://pzwiki.net/wiki/Modeling" title="Modeling">Modeling</a></td><td><ul><li><code>models_X</code> - stores the model assets.</li></ul></td></tr><tr><td><a href="https://pzwiki.net/w/index.php?title=Texturing&amp;action=edit&amp;redlink=1" title="Texturing (page does not exist)">Texturing</a></td><td><ul><li><code>textures</code> - stores the texture assets</li></ul></td></tr><tr><td><a href="https://pzwiki.net/wiki/Translations" title="Translations">Translations</a></td><td><ul><li><code>lua/shared/Translate</code> - translation files are put inside subfolders inside the main lua folder</li></ul></td></tr><tr><td><a href="https://pzwiki.net/wiki/Rendering" title="Rendering">Rendering</a></td><td><p>Renders are indirectly linked to modding, as in most cases is a process external to Project Zomboid where you use game assets for 3D renders:</p><ul><li><code>models_X</code></li><li><code>textures</code></li><li><code>texturepacks</code> - holds the tile sprites that you will need to unpack with the <a href="https://pzwiki.net/wiki/Project_Zomboid_Modding_Tools" title="Project Zomboid Modding Tools">Project Zomboid Modding Tools</a></li></ul><p>But in the case where renders are used to create in-game assets, you will most likely need to access the <code>ui</code> or <code>textures</code> folders.</p></td></tr><tr><td><a href="https://pzwiki.net/wiki/Scripts" title="Scripts">Scripts</a></td><td><p>Scripts involve mainly defining properties and behaviors via text files, but in most cases involve the use of assets like <a href="https://pzwiki.net/wiki/Modeling" title="Modeling">models</a>, <a href="https://pzwiki.net/w/index.php?title=Texturing&amp;action=edit&amp;redlink=1" title="Texturing (page does not exist)">textures</a> and sounds.</p><ul><li><code>scripts</code> - stores the script definitions.</li><li><code>clothing</code> - stores clothing item definitions.</li><li><code>textures</code></li><li><code>models_X</code></li><li><code>sound</code></li></ul></td></tr></tbody></table>

### clothing

The `clothing` folder is used to define clothing items via the use of XML files. Each clothing items is associated to its own XML file and a [GUID](https://en.wikipedia.org/wiki/Universally_unique_identifier "wikipedia:Universally unique identifier") to recognize the clothing item. Subfolders can be created to organize the clothing items. The outfit manager is also defined inside the file `clothing.xml` and is used to create or modify existing outfits. While this file is named the same as any others, it will not overwrite other files named like it.

### models\_X

_Main article: [model (scripts)](https://pzwiki.net/wiki/Model_(scripts) "Model (scripts)")_

The `models_X` folder is used to store model files. The files need to be either in the DirectX format (`.x`) or Filmbox format (`.fbx`). They can be put in subfolders for organization and can replace files with the same relative path. See the [File formats](https://pzwiki.net/wiki/File_formats#Modeling_and_animation_formats "File formats") page for more detail.

### textures

The `textures` folder is used to store texture files. The files need to be in the PNG format (`.png`). They can be put in subfolders for organization and can replace files with the same relative path. See the [File formats](https://pzwiki.net/wiki/File_formats#Image_formats "File formats") page for more detail.

### ui

The `ui` folder is used to store images used in the user interface elements in the game. The files need to be in the PNG format (`.png`). They can be put in subfolders for organization and can replace files with the same relative path.

### sound

The `sound` folder is used to store sound files. The files need to be in the OGG format (`.ogg`) or WAV format (`.wav`). They can be put in subfolders for organization and can replace files with the same relative path. Some sounds are stored inside bank files (`.bank`) which are used by the Fmod sound system, and they cannot be overwritten nor can bank files be loaded from mods.

## Example

Below is a full example of a mod structure in Windows.

```
%UserProfile%/
└── Zomboid/
    └── Workshop/
        └── MyMod/
            ├── Contents/
            │   └── mods/
            │       ├── MyMod1/
            │       │   ├── 42.0.0/                 <--- will be loaded for versions above 42.0.0
            │       │   │   ├── media/
            │       │   │   │   ├── AnimSets/
            │       │   │   │   │   └── ...
            │       │   │   │   ├── lua/
            │       │   │   │   │   ├── client/
            │       │   │   │   │   │   └── ...
            │       │   │   │   │   ├── server/
            │       │   │   │   │   │   └── ...
            │       │   │   │   │   └── shared/
            │       │   │   │   │       └── ...
            │       │   │   │   ├── scripts/
            │       │   │   │   │   └── ...
            │       │   │   │   └── ...
            │       │   │   ├── mod.info
            │       │   │   ├── poster.png
            │       │   │   └── icon.png
            │       │   ├── 42.X.Y/                 <--- will be loaded instead of older versions (4.0.0 for example will not load), for game versions compatibility if needed
            │       │   │   └── ...
            │       │   ├── common/                 <--- mandatory, mod won't be detected without it
            │       │   │   └── media/
            │       │   │       ├── anims_X/
            │       │   │       │   └── ...
            │       │   │       ├── models_X/
            │       │   │       │   └── ...
            │       │   │       └── ...
            │       │   ├── media/                  <--- Build 41 only folder, not used in Build 42
            │       │   │   ├── anims_X/
            │       │   │   │   └── ...
            │       │   │   ├── AnimSets/
            │       │   │   │   └── ...
            │       │   │   ├── lua/
            │       │   │   │   ├── client/
            │       │   │   │   │   └── ...
            │       │   │   │   ├── server/
            │       │   │   │   │   └── ...
            │       │   │   │   └── shared/
            │       │   │   │       └── ...
            │       │   │   ├── models_X/
            │       │   │   │   └── ...
            │       │   │   └── scripts/
            │       │   │       └── ...
            │       │   ├── mod.info
            │       │   ├── poster.png
            │       │   └── icon.png
            │       └── MyMod2/                     <--- secondary mod, optional if needed
            │           ├── 42.0.0/
            │           │   ├── mod.info
            │           │   ├── poster.png
            │           │   ├── icon.png
            │           │   └── ...
            │           ├── 42.X.Y/
            │           │   └── ...
            │           ├── common/
            │           │   └── ...
            │           ├── media/
            │           │   └── ...
            │           ├── mod.info
            │           ├── poster.png
            │           ├── icon.png
            │           └── ...
            ├── workshop.txt                        <--- automatically generated when uploading
            └── preview.png                         <--- 256x256 image

```

## See also

-   [Uploading mods](https://pzwiki.net/wiki/Uploading_mods "Uploading mods") - teaches about uploading mods.
-   [Game files](https://pzwiki.net/wiki/Game_files "Game files") - accessing the game files.
-   [workshop.txt](https://pzwiki.net/wiki/Workshop.txt "Workshop.txt") - about a file used by the in-game uploader.
-   [mod.info](https://pzwiki.net/wiki/Mod.info "Mod.info") - about the core file which defines your mod.

## Navigation
