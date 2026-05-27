# ESP Library

A modular ESP (Extra Sensory Perception) library for Roblox. Supports players, entities, and custom instances with a clean API for highlights, boxes, tracers, health bars, name labels, distance labels, state labels, and tool display.

---

## Table of Contents

- [Loading](#loading)
- [Creating ESP Objects](#creating-esp-objects)
- [Targets](#targets)
- [Removing Objects](#removing-objects)
- [ESP Types](#esp-types)
  - [Highlight](#highlight)
  - [Tracer](#tracer)
  - [Box](#box)
  - [Bar](#bar)
  - [Name](#name)
  - [Distance](#distance)
  - [State](#state)
  - [Tool](#tool)
- [Shared Systems](#shared-systems)
  - [Stroke](#stroke)
  - [Gradient](#gradient)
  - [AutoRotation](#autorotation)
  - [AutoOffset](#autooffset)
  - [Dynamic Sizing](#dynamic-sizing)
- [Types Reference](#types-reference)
- [Examples](#examples)

---

## Loading

```lua
local ESP = loadstring(game:HttpGet("YOUR_RAW_URL"))()
```

---

## Creating ESP Objects

All ESP objects are created with `ESP.new(Type)` where `Type` is a string matching one of the supported types.

```lua
local Box = ESP.new("Box")
local Bar = ESP.new("Bar")
local Name = ESP.new("Name")
```

Supported types: `"Highlight"`, `"Tracer"`, `"Box"`, `"Bar"`, `"Name"`, `"Distance"`, `"State"`, `"Tool"`

---

## Targets

Every ESP object has a `Target` property that controls what it renders on. You must set this for anything to appear.

| Value | Description |
|-------|-------------|
| `"players"` | All players in the server |
| `"entities"` | All humanoid NPCs/entities in the workspace |
| `Instance` | A specific `BasePart` or `Model` instance |
| `nil` | Nothing (disabled) |

```lua
Box.Target = "players"
Box.Target = "entities"
Box.Target = workspace.SomeModel
```

Most objects also have `IncludeLocalPlayer` (default `false`) which controls whether the local player's own character is included when targeting `"players"` or `"entities"`.

```lua
Box.IncludeLocalPlayer = true
```

---

## Removing Objects

Call `:Remove()` or `:Destroy()` on any ESP object to clean it up and free memory.

```lua
local Box = ESP.new("Box")
Box.Target = "players"

-- Later:
Box:Remove()
```

---

## ESP Types

### Highlight

Renders a Roblox `Highlight` instance over the target. Works in 3D space and is always visible through walls when `AlwaysOnTop` is true.

```lua
local Highlight = ESP.new("Highlight")
Highlight.Target = "players"
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Enabled` | `boolean` | `true` | Whether the highlight is visible |
| `FillColor` | `Color3` | `Color3.new(1,1,1)` | Fill color of the highlight |
| `FillTransparency` | `number` | `0.75` | Transparency of the fill (0 = opaque, 1 = invisible) |
| `OutlineColor` | `Color3` | `Color3.new(0,0,0)` | Outline color |
| `OutlineTransparency` | `number` | `1` | Transparency of the outline |
| `AlwaysOnTop` | `boolean` | `true` | If true, renders through walls |
| `IncludeLocalPlayer` | `boolean` | `false` | Include your own character |

---

### Tracer

Draws a line from a screen origin point to the target character.

```lua
local Tracer = ESP.new("Tracer")
Tracer.Target = "players"
Tracer.Thickness = 1.5
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Enabled` | `boolean` | `true` | Whether tracers are visible |
| `Color` | `Color3` | `Color3.new(1,1,1)` | Line color |
| `Transparency` | `number` | `1` | Line opacity (1 = fully visible, 0 = invisible) |
| `Thickness` | `number` | `1` | Line thickness in pixels |
| `ZIndex` | `number` | `0` | Render order (higher = drawn on top) |
| `AnchorPoint` | `Vector2` | `Vector2.new(0.5, 0.5)` | The point on the target the line connects to |
| `Origin` | `UDim2` or `Vector2` | `UDim2.new(0.5,0,1,0)` | Screen origin of the tracer (default: bottom center) |
| `IncludeLocalPlayer` | `boolean` | `false` | Include your own character |

Supports [Stroke](#stroke) and [Gradient](#gradient).

---

### Box

Draws a 2D bounding box around the target on screen.

```lua
local Box = ESP.new("Box")
Box.Target = "players"
Box.Dynamic = true
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Enabled` | `boolean` | `true` | Whether boxes are visible |
| `Filled` | `boolean` | `true` | If true, fills the box with `Color`; if false, outline only |
| `Color` | `Color3` | `Color3.new(1,1,1)` | Fill color |
| `Transparency` | `number` | `0.5` | Fill transparency |
| `ZIndex` | `number` | `0` | Render order |
| `Dynamic` | `boolean` | `true` | If true, calculates tight bounds from all parts; if false, uses a static character estimate |
| `AutoThickness` | `boolean` | `true` | Scales stroke thickness based on distance |
| `IncludeDescendants` | `boolean` | `false` | If true, includes all nested parts (accessories, tools, etc.) when calculating bounds; if false, only direct children |
| `IncludeLocalPlayer` | `boolean` | `false` | Include your own character |

Supports [Stroke](#stroke) and [Gradient](#gradient).

> **Note:** `Dynamic = true` is more accurate but slightly more expensive. `Dynamic = false` uses a fast estimate based on torso position.

> **Note:** `IncludeDescendants` — when off, bounds are computed from direct child parts only. When on, every nested descendant is included, giving tighter accuracy for characters with many accessories or held tools.

---

### Bar

Draws a fill bar (e.g. a health bar) beside the target's bounding box. You can create multiple bars and they will auto-space themselves on the same side.

```lua
local HealthBar = ESP.new("Bar")
HealthBar.Target = "players"
HealthBar.Side = "Left"

local ArmorBar = ESP.new("Bar")
ArmorBar.Target = "players"
ArmorBar.Side = "Left"
ArmorBar.Color = Color3.new(0.5, 0.5, 1)
ArmorBar.Value = function(Target)
    -- return a number between 0 and 1
    return 0.75
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Enabled` | `boolean` | `true` | Whether the bar is visible |
| `Color` | `Color3` | `Color3.new(0,1,0)` | Fallback fill color (used when `ColorStages` is empty) |
| `BackColor` | `Color3` | `Color3.new(0,0,0)` | Background bar color |
| `Transparency` | `number` | `1` | Fill opacity |
| `BackTransparency` | `number` | `0.5` | Background opacity |
| `Thickness` | `number` | `2` | Bar width/height in pixels |
| `Padding` | `number` | `0` | Gap between the bar and the box edge |
| `Side` | `string` | `"Left"` | Which side to place the bar: `"Left"`, `"Right"`, `"Top"`, `"Bottom"` |
| `AutoOffset` | `boolean` | `true` | Automatically space this bar away from other bars on the same side |
| `Value` | `function` or `number` | health function | A function `(Target) -> number` returning 0–1, or a static number |
| `ColorStages` | `table` | green/yellow/red | A list of `{Value, Color}` stages for gradient-style color interpolation |
| `IncludeLocalPlayer` | `boolean` | `false` | Include your own character |

Supports [Stroke](#stroke) and [Gradient](#gradient).

**ColorStages example:**
```lua
Bar.ColorStages = {
    { Value = 1.0, Color = Color3.new(0, 1, 0) }, -- full = green
    { Value = 0.5, Color = Color3.new(1, 1, 0) }, -- half = yellow
    { Value = 0.0, Color = Color3.new(1, 0, 0) }, -- empty = red
}
```
The color is interpolated between the two nearest stages based on the current value.

---

### Name

Renders the player's name or NPC model name above (or beside) the target.

```lua
local Name = ESP.new("Name")
Name.Target = "players"
Name.UseDisplayName = true
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Enabled` | `boolean` | `true` | Whether names are visible |
| `Color` | `Color3` | `Color3.new(1,1,1)` | Text color |
| `Size` | `number` | `15` | Font size in pixels |
| `Transparency` | `number` | `1` | Text opacity |
| `ZIndex` | `number` | `1` | Render order |
| `Side` | `string` | `"Top"` | Which side of the box to anchor to |
| `Offset` | `Vector2` | `Vector2.new(0,0)` | Manual pixel offset from the anchor point |
| `Font` | `Enum.Font` | `Enum.Font.Roboto` | Text font |
| `UseDisplayName` | `boolean` | `true` | If true, uses the player's display name; if false, uses their username |
| `Dynamic` | `boolean` | `false` | Scale text size based on distance |
| `AutoOffset` | `boolean` | `true` | Auto-space away from other labels on the same side |
| `IncludeLocalPlayer` | `boolean` | `false` | Include your own character |

---

### Distance

Renders the distance in studs from you to the target.

```lua
local Distance = ESP.new("Distance")
Distance.Target = "players"
Distance.Suffix = "m"
Distance.Side = "Bottom"
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Enabled` | `boolean` | `true` | Whether distance labels are visible |
| `Color` | `Color3` | `Color3.new(1,1,1)` | Text color |
| `Size` | `number` | `15` | Font size |
| `Transparency` | `number` | `1` | Text opacity |
| `ZIndex` | `number` | `1` | Render order |
| `Side` | `string` | `"Bottom"` | Which side of the box to anchor to |
| `Offset` | `Vector2` | `Vector2.new(0,0)` | Manual pixel offset |
| `Suffix` | `string` | `"m"` | Text appended after the number (e.g. `"m"`, `"studs"`, `""`) |
| `Font` | `Enum.Font` | `Enum.Font.Roboto` | Text font |
| `Dynamic` | `boolean` | `false` | Scale text size based on distance |
| `AutoOffset` | `boolean` | `true` | Auto-space away from other labels on the same side |
| `IncludeLocalPlayer` | `boolean` | `false` | Include your own character |

---

### State

Renders the target's current humanoid state (e.g. Running, Jumping, Idle).

```lua
local State = ESP.new("State")
State.Target = "players"
State.Side = "Right"
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Enabled` | `boolean` | `true` | Whether state labels are visible |
| `Color` | `Color3` | `Color3.new(1,1,1)` | Text color |
| `Size` | `number` | `15` | Font size |
| `Transparency` | `number` | `1` | Text opacity |
| `ZIndex` | `number` | `1` | Render order |
| `Side` | `string` | `"Right"` | Which side of the box to anchor to |
| `Offset` | `Vector2` | `Vector2.new(0,0)` | Manual pixel offset |
| `Font` | `Enum.Font` | `Enum.Font.Roboto` | Text font |
| `Dynamic` | `boolean` | `false` | Scale text size based on distance |
| `AutoOffset` | `boolean` | `true` | Auto-space away from other labels on the same side |
| `IncludeLocalPlayer` | `boolean` | `false` | Include your own character |

**Possible state values:** `Idle`, `Running`, `Jumping`, `Falling`, `Swimming`, `Climbing`, `Seated`, `Dead`, `Getting Up`, `Standing`, `Strafing`

---

### Tool

Renders the currently equipped tool's name and/or icon beside the target.

```lua
local Tool = ESP.new("Tool")
Tool.Target = "players"
Tool.ShowIcon = true
Tool.ShowName = true
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Enabled` | `boolean` | `true` | Whether tool display is visible |
| `Color` | `Color3` | `Color3.new(1,1,1)` | Text color |
| `Size` | `number` | `15` | Font size |
| `IconSize` | `number` | `30` | Icon size in pixels |
| `Transparency` | `number` | `1` | Opacity for both text and icon |
| `ZIndex` | `number` | `1` | Render order |
| `Side` | `string` | `"Bottom"` | Which side of the box to anchor to |
| `Offset` | `Vector2` | `Vector2.new(0,0)` | Manual pixel offset |
| `ShowIcon` | `boolean` | `true` | Show the tool's texture icon |
| `ShowName` | `boolean` | `true` | Show the tool's name as text |
| `LabelPosition` | `string` | `"Below"` | When both icon and name are shown: `"Below"` puts text under icon, `"Above"` puts text above |
| `Font` | `Enum.Font` | `Enum.Font.Roboto` | Text font |
| `Dynamic` | `boolean` | `false` | Scale sizes based on distance |
| `AutoOffset` | `boolean` | `true` | Auto-space away from other labels on the same side |
| `IncludeLocalPlayer` | `boolean` | `false` | Include your own character |

---

## Shared Systems

### Stroke

All drawing objects (Tracer, Box, Bar) expose a `Stroke` sub-object that draws an outline.

```lua
Box.Stroke.Enabled = true
Box.Stroke.Color = Color3.new(0, 0, 0)
Box.Stroke.Thickness = 2
Box.Stroke.Transparency = 1
Box.Stroke.LineJoinMode = Enum.LineJoinMode.Miter
```

| Property | Type | Description |
|----------|------|-------------|
| `Enabled` | `boolean` | Whether the stroke is drawn |
| `Color` | `Color3` | Stroke color |
| `Transparency` | `number` | Stroke opacity |
| `Thickness` | `number` | Stroke width in pixels |
| `LineJoinMode` | `Enum.LineJoinMode` | Corner style: `Miter`, `Round`, or `Bevel` |

Stroke also has its own [Gradient](#gradient) via `Stroke.Gradient`.

---

### Gradient

Every drawing object and stroke exposes a `Gradient` sub-object for color/transparency gradients.

```lua
Box.Gradient.Enabled = true
Box.Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.new(0, 0, 1)),
})
Box.Gradient.Rotation = 90
Box.Gradient.Transparency = NumberSequence.new(0)
Box.Gradient.Offset = Vector2.new(0, 0)
```

| Property | Type | Description |
|----------|------|-------------|
| `Enabled` | `boolean` | Whether the gradient is active |
| `Color` | `ColorSequence` | Color gradient across the shape |
| `Rotation` | `number` | Gradient angle in degrees (overridden when AutoRotation is on) |
| `Transparency` | `NumberSequence` | Transparency gradient across the shape |
| `Offset` | `Vector2` | Scroll offset of the gradient |

> **Note:** When `Gradient.Enabled = true`, the base `Color` property of the object is automatically forced to white internally so gradient keypoint colors render accurately. Your original color value is untouched and restores as soon as you disable the gradient.

---

### AutoRotation

Each gradient has an `AutoRotation` sub-object that animates the rotation continuously.

```lua
Box.Gradient.AutoRotation.Enabled = true
Box.Gradient.AutoRotation.Speed = 2     -- rotations per second
Box.Gradient.AutoRotation.Amount = 360  -- degrees per cycle
Box.Gradient.AutoRotation.Start = 0     -- starting angle
Box.Gradient.AutoRotation.End = 360     -- ending angle
```

| Property | Type | Description |
|----------|------|-------------|
| `Enabled` | `boolean` | Whether auto rotation is active |
| `Speed` | `number` | How fast the rotation animates |
| `Amount` | `number` | Total degrees per rotation cycle |
| `Start` | `number` | Starting rotation angle |
| `End` | `number` | Ending rotation angle |

---

### AutoOffset

When multiple label-type objects (`Name`, `Distance`, `State`, `Tool`, `Bar`) are placed on the same side of the same target, `AutoOffset` automatically stacks them so they don't overlap.

```lua
Name.Side = "Bottom"
Name.AutoOffset = true

Distance.Side = "Bottom"
Distance.AutoOffset = true
-- Distance will automatically appear below Name
```

Set `AutoOffset = false` on any element to opt it out and position it manually using `Offset`.

---

### Dynamic Sizing

When `Dynamic = true` on label or tool objects, text and icon sizes are scaled based on the target's distance from the camera. Closer targets get larger text, farther targets get smaller text. When `Dynamic = false`, sizes are fixed at whatever value you set.

```lua
Name.Dynamic = true   -- size scales with distance
Name.Dynamic = false  -- size is always Name.Size pixels
```

For `Box`, `Dynamic` controls whether the bounding box is computed from actual part geometry (tight, accurate) or estimated from torso position (fast, approximate).

---

## Types Reference

| Type name | Lua type | Example |
|-----------|----------|---------|
| `boolean` | `true` / `false` | `Box.Enabled = true` |
| `number` | Any number | `Box.Stroke.Thickness = 2` |
| `string` | Text | `Distance.Suffix = "m"` |
| `Color3` | RGB color | `Color3.new(1, 0, 0)` |
| `Vector2` | 2D vector | `Vector2.new(0, -5)` |
| `UDim2` | Scaled + offset 2D | `UDim2.new(0.5, 0, 1, 0)` |
| `ColorSequence` | Color gradient | `ColorSequence.new({...})` |
| `NumberSequence` | Number gradient | `NumberSequence.new(0)` |
| `Enum.Font` | Roblox font | `Enum.Font.Roboto` |
| `Enum.LineJoinMode` | Corner style | `Enum.LineJoinMode.Miter` |
| `function` | Callback | `function(Target) return 1 end` |
| `Instance` | Roblox object | `workspace.SomePart` |

---

## Examples

### Basic player ESP

```lua
local ESP = loadstring(game:HttpGet("YOUR_RAW_URL"))()

local Box = ESP.new("Box")
Box.Target = "players"
Box.Dynamic = true
Box.Stroke.Enabled = true
Box.Stroke.Color = Color3.new(0, 0, 0)
Box.Stroke.Thickness = 1.5

local Name = ESP.new("Name")
Name.Target = "players"

local Distance = ESP.new("Distance")
Distance.Target = "players"
Distance.Side = "Bottom"

local Health = ESP.new("Bar")
Health.Target = "players"
Health.Side = "Left"
```

### Two bars on the same side

```lua
local HealthBar = ESP.new("Bar")
HealthBar.Target = "players"
HealthBar.Side = "Left"

local StaminaBar = ESP.new("Bar")
StaminaBar.Target = "players"
StaminaBar.Side = "Left"
StaminaBar.Color = Color3.new(0.2, 0.4, 1)
StaminaBar.ColorStages = {}
StaminaBar.Value = function(Target)
    return 0.6 -- replace with your stamina logic
end
-- StaminaBar auto-spaces below HealthBar thanks to AutoOffset
```

### Animated gradient box

```lua
local Box = ESP.new("Box")
Box.Target = "players"
Box.Gradient.Enabled = true
Box.Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.new(1, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.new(0, 1, 0)),
    ColorSequenceKeypoint.new(1,   Color3.new(0, 0, 1)),
})
Box.Gradient.AutoRotation.Enabled = true
Box.Gradient.AutoRotation.Speed = 1.5
```

### Custom value bar

```lua
local Bar = ESP.new("Bar")
Bar.Target = "entities"
Bar.Side = "Right"
Bar.Value = function(Target)
    local Humanoid = Target:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return 0 end
    return Humanoid.WalkSpeed / 16 -- normalize to default walkspeed
end
Bar.ColorStages = {
    { Value = 1.0, Color = Color3.new(0, 0.5, 1) },
    { Value = 0.0, Color = Color3.new(1, 1, 1) },
}
```

### Cleaning up

```lua
local Box = ESP.new("Box")
Box.Target = "players"

-- Remove when done
Box:Remove()
```
