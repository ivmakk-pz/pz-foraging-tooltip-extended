---
---

# ISRichTextPanel Rich Text Markup Language Specification

## Overview

ISRichTextPanel is a UI component in Project Zomboid that renders formatted text with embedded images, videos, and styling. Text is processed through `processCommand()` which interprets markup tags enclosed in angle brackets `<TAG>`. This specification documents all supported markup commands for creating rich, formatted UI displays.

## Text Formatting Commands

### Line Breaks
- `<LINE>` - Single line break (moves to next line)
- `<BR>` - Double line break (adds extra spacing, equivalent to two line breaks)

**Example:**
```lua
local text = " First line <LINE> Second line <BR> Third line with extra space above <LINE> "
```

### Text Alignment
- `<LEFT>` - Align text to the left (default)
- `<CENTRE>` - Center align text (use British spelling)
- `<RIGHT>` - Right align text

**Note:** Alignment applies to the current line and persists until changed.

**Example:**
```lua
local text = " <CENTRE> Centered Title <LINE> "
text = text .. " <LEFT> Left-aligned paragraph text <LINE> "
text = text .. " <RIGHT> Right-aligned footer <LINE> "
```

### Text Indentation and Positioning
- `<INDENT:pixels>` - Set left indent in pixels (e.g., `<INDENT:20>`)
- `<SETX:pixels>` - Set absolute X position for text (e.g., `<SETX:100>`)

**Example:**
```lua
local text = " <INDENT:10> Indented paragraph <LINE> "
text = text .. " <INDENT:20> More indented <LINE> "
text = text .. " <INDENT:0> Back to no indent <LINE> "
```

### Spacing
- `<SPACE>` - Add a single space with 2px padding

**Note:** Only adds space if `x > 0` (not at start of line).

**Example:**
```lua
local text = " <IMAGE:icon.png> <SPACE> Icon with text <LINE> "
```

## Color Commands

### Direct RGB Colors
- `<RGB:r,g,b>` - Set color using RGB values 0-1 (e.g., `<RGB:1,0.5,0>` for orange)
- `<PUSHRGB:r,g,b>` - Push current color to stack and set new color
- `<POPRGB>` - Pop color from stack and restore previous color

**RGB Value Range:** 0.0 to 1.0 (NOT 0-255)

**Example:**
```lua
local text = " <RGB:1,0,0> Red text <RGB:0,1,0> Green text <RGB:1,1,1> White text <LINE> "

-- Using color stack for nested colors
text = text .. " <RGB:1,1,1> White <PUSHRGB:1,0,0> Red <PUSHRGB:0,1,0> Green "
text = text .. " <POPRGB> Back to red <POPRGB> Back to white <LINE> "
```

### Named Colors
- `<RED>` - Pure red (1, 0, 0)
- `<GREEN>` - Pure green (0, 1, 0)
- `<ORANGE>` - Orange (0.9, 0.3, 0)
- `<GHC>` - Good highlight color (from game core, typically green)
- `<BHC>` - Bad highlight color (from game core, typically red)

**Example:**
```lua
local text = " <GHC> Positive effect <LINE> "
text = text .. " <BHC> Negative effect <LINE> "
text = text .. " <ORANGE> Warning message <LINE> "
```

## Font Size Commands

### Heading Styles
- `<H1>` - Large centered white text (UIFont.Large, RGB: 1, 1, 1)
- `<H2>` - Medium left-aligned light gray text (UIFont.Medium, RGB: 0.8, 0.8, 0.8)
- `<TEXT>` - Normal text style (default font, RGB: 0.7, 0.7, 0.7)

**Note:** Heading commands also set alignment and color automatically.

**Example:**
```lua
local text = " <H1> Main Title <LINE> "
text = text .. " <H2> Subtitle <LINE> "
text = text .. " <TEXT> Body paragraph text <LINE> "
```

### Direct Size Control
- `<SIZE:small>` - Small font (UIFont.NewSmall)
- `<SIZE:medium>` - Medium font (UIFont.Medium)
- `<SIZE:large>` - Large font (UIFont.Large)

**Example:**
```lua
local text = " <SIZE:large> Large text <SIZE:small> small text <SIZE:medium> medium text <LINE> "
```

## Image Commands

### Inline Images
- `<IMAGE:texturePath>` - Embed image inline with text at original size
- `<IMAGE:texturePath,width,height>` - Embed image with custom dimensions

**Texture Paths:** Can be texture names (looked up via `getTexture()`) or full paths.

**Example:**
```lua
local text = " <IMAGE:media/ui/foraging/eyeconOn.png> Vision Icon <LINE> "
text = text .. " <IMAGE:Item_Safety_Goggles.png,24,24> Goggles (24x24) <LINE> "
```

**Notes:**
- Images wrap to next line if they exceed `maxLineWidth`
- Adds `IMAGE_PAD` (5 pixels) padding on both sides of image
- Line height adjusts to accommodate image height

### Centered Images
- `<IMAGECENTRE:texturePath>` - Center image horizontally on its own line
- `<IMAGECENTRE:texturePath,width,height>` - Centered image with custom size

**Example:**
```lua
local text = " <IMAGECENTRE:media/ui/banner.png> <LINE> "
text = text .. " <IMAGECENTRE:logo.png,256,128> <LINE> "
```

### Joypad Button Icons
- `<JOYPAD:buttonName>` - Display controller button icon at original size
- `<JOYPAD:buttonName,width,height>` - Controller button with custom size

**Note:** Uses `Joypad.Texture[buttonName]` lookup table.

**Example:**
```lua
local text = " Press <JOYPAD:AButton,24,24> to confirm <LINE> "
text = text .. " Use <JOYPAD:LeftTrigger> to aim <LINE> "
```

## Video Commands

### Centered Videos
- `<VIDEOCENTRE:videoPath,videoWidth,videoHeight>` - Basic centered video
- `<VIDEOCENTRE:videoPath,videoWidth,videoHeight,displayWidth,displayHeight>` - Video with custom display size

**Behavior:**
- If video effects enabled: Plays video at display dimensions
- If video effects disabled: Shows backup image at `media/videos/{videoPath}.png`

**Example:**
```lua
local text = " <VIDEOCENTRE:intro,1920,1080,384,216> <LINE> "
text = text .. " <VIDEOCENTRE:tutorial,1280,720> <LINE> "
```

## Keybind Display

### Key Name Replacement
- `<KEY:bindingName>` - Automatically replaced with current key binding

**Behavior:**
- Displays player's current key binding for the specified action
- Rendered in blue text (RGB: 0, 0.635, 0.91)
- Uses `&nbsp;` for spaces in binding names
- Dynamically updates if keybinds change (triggers `textDirty` flag)

**Example:**
```lua
local text = " Press <KEY:Forward> to move forward <LINE> "
text = text .. " Use <KEY:Toggle Search Mode> to toggle foraging <LINE> "
text = text .. " Hold <KEY:Run> to sprint <LINE> "
```

## HTML Entity Escaping

### Special Characters
When you need to display literal angle brackets or spaces:
- Use `&lt;` for `<` (left angle bracket)
- Use `&gt;` for `>` (right angle bracket)
- Use `&nbsp;` for non-breaking space

**Example:**
```lua
local text = " Formula: A &lt; B &gt; C <LINE> "
text = text .. " Spaced&nbsp;text&nbsp;here <LINE> "
```

## Panel Configuration

### Layout Properties
```lua
-- Set content margins in pixels
panel:setMargins(left, top, right, bottom)

-- Or set individually
panel.marginLeft = 20      -- Left margin (default: 20)
panel.marginTop = 10       -- Top margin (default: 10)
panel.marginRight = 10     -- Right margin (default: 10)
panel.marginBottom = 10    -- Bottom margin (default: 10)

-- Override automatic line width calculation
panel.maxLineWidth = 300   -- Custom max line width (default: width - margins)

-- Auto-adjust panel height to content
panel.autosetheight = true -- Auto-resize height (default: true)

-- Enable content clipping at panel boundaries
panel.clip = true          -- Enable clipping (default: false)

-- Limit displayed lines (useful for scrolling logs)
panel.maxLines = 50        -- Max lines to display (0 = unlimited, default: 0)

-- Default font for text
panel.defaultFont = UIFont.NewSmall -- Default font (default: UIFont.NewSmall)

-- Content transparency
panel:setContentTransparency(0.8) -- Alpha 0.0-1.0 (default: 1.0)
```

## Complete Usage Examples

### Basic Formatted Text
```lua
local text = " <H1> Equipment Analysis <LINE> "
text = text .. " <H2> Vision-Affecting Items <LINE> <BR> "
text = text .. " <TEXT> Items currently worn that affect your vision: <LINE> "
text = text .. " <INDENT:10> <GHC> Night Vision Goggles: 1.25x <LINE> "
text = text .. " <INDENT:10> <BHC> Welding Mask: 0.50x <LINE> "
text = text .. " <INDENT:0> <BR> "
text = text .. " <CENTRE> <RGB:1,1,1> Total Modifier: 0.625x <LINE> "
```

### Images with Text and Colors
```lua
local text = " <H2> Equipped Items <LINE> "
text = text .. " <IMAGE:Item_Safety_Goggles.png,24,24> <SPACE> "
text = text .. " <RGB:1,1,1> Safety Goggles: <RGB:0.9,0.3,0> 0.975x <LINE> "
text = text .. " <IMAGE:WeldingMask.png,32,32> <SPACE> "
text = text .. " <RGB:1,1,1> Welder Mask: <RGB:1,0,0> 0.50x <LINE> "
```

### Complex Layout with Sections
```lua
local text = " <H1> Foraging Guide <LINE> <BR> "

-- Section 1: Vision
text = text .. " <H2> Vision System <LINE> "
text = text .. " <TEXT> <IMAGE:media/ui/foraging/eyeconOn.png> Vision affects detection range <LINE> <BR> "

-- Section 2: Controls
text = text .. " <H2> Controls <LINE> "
text = text .. " <TEXT> Press <KEY:Toggle Search Mode> to toggle search mode <LINE> "
text = text .. " Use <KEY:Interact> to pick up items <LINE> <BR> "

-- Section 3: Tips
text = text .. " <H2> Tips <LINE> "
text = text .. " <INDENT:10> <GHC> Search during daylight for better visibility <LINE> "
text = text .. " <INDENT:10> <BHC> Avoid searching while exhausted <LINE> "
text = text .. " <INDENT:0> "
```

### Dynamic Content with Color Stacks
```lua
local text = " <RGB:1,1,1> Base color "
text = text .. " <PUSHRGB:0,1,0> Nested green "
text = text .. " <PUSHRGB:1,0,0> Deeper red "
text = text .. " <POPRGB> Back to green "
text = text .. " <POPRGB> Back to white <LINE> "
```

## Important Notes and Best Practices

### Tag Spacing
**CRITICAL:** Commands must be surrounded by spaces for proper parsing.

```lua
-- CORRECT:
local text = " <RGB:1,0,0> Red text <LINE> "

-- INCORRECT (will not parse):
local text = "<RGB:1,0,0>Red text<LINE>"
```

### State Persistence
- **Color changes persist** until explicitly changed
- **Font changes persist** until explicitly changed
- **Alignment persists** until explicitly changed
- **Indentation persists** until explicitly changed

**Example:**
```lua
local text = " <RGB:1,0,0> This is red "
text = text .. " This is still red <LINE> "
text = text .. " <RGB:1,1,1> Now it's white <LINE> "
```

### Line Wrapping Behavior
- Text automatically wraps based on `maxLineWidth` or panel width minus margins
- Images wrap to next line if they exceed line width
- Line height automatically adjusts to accommodate tallest element (text or image)

### Performance Considerations
- Text is repaginated only when `textDirty` flag is set
- Keybind changes automatically trigger repagination
- Use `maxLines` to limit rendering for scrolling logs
- Enable `clip` for panels with scrolling content

### Common Pitfalls
1. **RGB values:** Use 0.0-1.0 range, NOT 0-255
2. **British spelling:** Use `<CENTRE>` not `<CENTER>`
3. **Tag spacing:** Always surround tags with spaces
4. **Image paths:** Ensure textures exist via `getTexture()`
5. **Color stack:** Match `PUSHRGB` and `POPRGB` calls to avoid stack issues

## Integration with ISToolTip

When extending ISZoneDisplay tooltips (like in Foraging Tooltip Extended), rich text markup is fully supported:

```lua
---@param self ISZoneDisplay
local function ISZoneDisplay_getVisionTooltipText_Override(self)
    local text = " <RGB:1,1,1> Vision: <GHC> Excellent <LINE> "
    text = text .. " <IMAGE:media/ui/foraging/eyeconOn.png,16,16> <SPACE> "
    text = text .. " Search Radius: <RGB:0.9,0.9,0.5> 25.0 tiles <LINE> "
    return text
end
```

## Debugging Rich Text

When text doesn't display as expected:

1. **Check spacing:** Ensure all tags are surrounded by spaces
2. **Verify RGB values:** Must be 0.0-1.0 range
3. **Test texture paths:** Use `getTexture(path)` to verify texture exists
4. **Enable margin visualization:** Set `ISRichTextPanel.drawMargins = true`
5. **Check panel dimensions:** Ensure panel is large enough for content

**Debug mode example:**
```lua
ISRichTextPanel.drawMargins = true -- Show margin boundaries
panel.textDirty = true -- Force repagination
panel:paginate() -- Manually trigger pagination
```

## Reference

**Source File:** `PZ_files/ISRichTextPanel.lua`
**Processing Function:** `ISRichTextPanel:processCommand(command, x, y, lineImageHeight, lineHeight)`
**Pagination Function:** `ISRichTextPanel:paginate()`
**Rendering Function:** `ISRichTextPanel:render()`
