---
name: pz-rich-text-markup
description: >
  Use this skill when building or editing Project Zomboid rich-text UI strings — tooltips, ISRichTextPanel content,
  or any text passed through processCommand markup (tags in angle brackets like <RGB>, <LINE>, <IMAGE>, <SETX>).
  Activates when working on PZ tooltip text, formatting tooltip output, debugging markup that renders wrong, or
  laying out icons/colors/columns in a foraging or inventory tooltip. Especially relevant in this mod, whose core
  feature is the foraging vision tooltip (FTE_CoreTooltip / FTE_Utils build their strings with these tags).
---

# ISRichTextPanel Rich Text Markup

ISRichTextPanel renders formatted text with embedded images and styling. Text runs through `processCommand()`, which interprets markup tags in angle brackets `<TAG>`. ISToolTip (and the foraging `ISZoneDisplay` tooltips this mod patches) support the same markup.

Reference source (in the context repo): `C:\games\pz-modding-llm-context\game\media\lua\client\ISUI\ISRichTextPanel.lua` — `processCommand()`, `paginate()`, `render()`.

## Critical rules (read first)

1. **Tags must be surrounded by spaces** or they will not parse. `" <RGB:1,0,0> Red <LINE> "` works; `"<RGB:1,0,0>Red<LINE>"` does not.
2. **RGB values are 0.0–1.0, never 0–255.** `<RGB:1,0.5,0>` is orange.
3. **British spelling:** `<CENTRE>`, not `<CENTER>`.
4. **State persists** until changed — color, font, alignment, and indentation all carry forward to later lines.

## Text formatting

- `<LINE>` — single line break. `<BR>` — double break (extra spacing).
- `<LEFT>` / `<CENTRE>` / `<RIGHT>` — alignment (persists).
- `<INDENT:px>` — left indent in pixels (`<INDENT:0>` resets). `<SETX:px>` — absolute X position (used for column-aligning values).
- `<SPACE>` — single space with 2px padding (only adds space if not at line start).

## Color

- `<RGB:r,g,b>` — set color (0.0–1.0).
- `<PUSHRGB:r,g,b>` / `<POPRGB>` — color stack for nested colors; match every push with a pop.
- Named: `<RED>` `<GREEN>` `<ORANGE>`, plus `<GHC>` (good highlight, game core) and `<BHC>` (bad highlight). This mod derives its `Colors.good`/`Colors.bad` from the same `getGoodHighlitedColor()`/`getBadHighlitedColor()`.

## Font size

- Headings (also set alignment + color): `<H1>` large centered white, `<H2>` medium left light-gray, `<TEXT>` normal default.
- Direct: `<SIZE:small>` / `<SIZE:medium>` / `<SIZE:large>`.

## Images

- `<IMAGE:path>` or `<IMAGE:path,width,height>` — inline image. Wraps to next line if it exceeds line width; adds `IMAGE_PAD` (5px) each side; line height grows to fit. Paths resolve via `getTexture()`.
- `<IMAGECENTRE:path[,w,h]>` — centered on its own line.
- `<JOYPAD:button[,w,h]>` — controller button icon (via `Joypad.Texture`).

## Other

- `<KEY:bindingName>` — replaced with the player's current keybind, rendered blue; uses `&nbsp;` for spaces in binding names; triggers `textDirty` on rebind.
- `<VIDEOCENTRE:path,vidW,vidH[,dispW,dispH]>` — centered video; falls back to `media/videos/{path}.png` if video effects are off.
- HTML entities: `&lt;` `&gt;` for literal angle brackets, `&nbsp;` for non-breaking space.

## Panel layout (ISRichTextPanel)

`panel:setMargins(l,t,r,b)` or `marginLeft/Top/Right/Bottom`; `maxLineWidth` overrides auto width; `autosetheight` (default true); `clip` for scrolling content; `maxLines` (0 = unlimited); `defaultFont` (default `UIFont.NewSmall`); `setContentTransparency(0–1)`.

## Examples

Column-aligned label/value (the pattern this mod uses for tooltip rows):
```lua
local text = " <RGB:1,1,1> Search Radius <SETX:120> <GHC> 25.0 <LINE> "
```

Icon + colored value:
```lua
local text = " <IMAGE:Item_Safety_Goggles.png,24,24> <SPACE> <RGB:1,1,1> Safety Goggles: <ORANGE> 0.975x <LINE> "
```

Patching the foraging vision tooltip:
```lua
---@param self ISZoneDisplay
local function getVisionTooltipText_Override(self)
    local text = " <RGB:1,1,1> Vision: <GHC> Excellent <LINE> "
    text = text .. " <IMAGE:media/ui/foraging/eyeconOn.png,16,16> <SPACE> Search Radius: <RGB:0.9,0.9,0.5> 25.0 tiles <LINE> "
    return text
end
```

## Debugging

When text renders wrong: check tag spacing first, then RGB range (0–1), then verify textures exist via `getTexture(path)`. `ISRichTextPanel.drawMargins = true` shows margin boundaries; set `panel.textDirty = true` and call `panel:paginate()` to force re-layout.
