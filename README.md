🎨 Modern iOS-Inspired UI Library

Roblox Lua • Synapse X • KRNL • Fluxus • Solara • Script-Ware

A clean, modern iOS-styled Roblox UI Library featuring tabs, toggles, sliders, dropdowns, keybinds, notifications, and a config system — all in a single file.

Designed for exploit environments with smooth animations, rounded corners, and simple scripting.

---

✨ Features

• Modern iOS-style interface
• Smooth animations and hover effects
• Tabbed layout system
• Toggle switches
• Buttons with ripple effect
• Sliders with increments
• Dropdown menus
• Text input boxes
• Keybind system
• Notification system
• Config save / load system
• Theme customization
• Single file library

---

📦 Installation

Add this loader to the top of your script.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUser/YourRepo/main/UILibrary.lua"))()

Replace the URL with wherever you host UILibrary.lua.

---

🌐 Hosting Options

Host| Raw URL Format
GitHub (recommended)| https://raw.githubusercontent.com/USER/REPO/main/UILibrary.lua
Pastebin| https://pastebin.com/raw/PASTE_ID
Local File| loadfile("UILibrary.lua")()

---

🚀 Basic Example

-- Load library
local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/YourUser/YourRepo/main/UILibrary.lua"
))()

-- Create window
local Window = Library:CreateWindow({
    Title = "My Script"
})

-- Create tab
local MainTab = Window:CreateTab({
    Name = "Main"
})

-- Add toggle
MainTab:AddToggle({
    Name = "God Mode",
    Default = false,
    Callback = function(state)
        print("God Mode:", state)
    end
})

---

📚 API Reference

---

Library API

CreateWindow

Creates the main GUI window.

local Window = Library:CreateWindow({
    Title = "Aimbot v2"
})

Property| Type| Default| Description
Title| string| "Window"| Window title

---

SetTheme

Override UI colors.

Library:SetTheme({
    Accent = Color3.fromRGB(255,100,150),
    Background = Color3.fromRGB(10,10,10)
})

Theme Keys

Key| Default| Purpose
Background| 14,14,20| Window background
Container| 24,24,34| UI cards
ContainerHover| 32,32,46| Hover state
Accent| 100,149,255| Active color
Text| 235,235,245| Primary text
SubText| 150,150,170| Secondary text
Divider| 42,42,58| Separator
Success| 72,199,116| Notification
Warning| 255,188,60| Notification
Error| 255,80,80| Notification
Info| 100,149,255| Notification

---

🔔 Notifications

Library:Notify({
    Title = "Config Loaded",
    Description = "settings.json applied successfully",
    Type = "success",
    Duration = 5
})

Field| Type| Default
Title| string| "Notice"
Description| string| ""
Type| string| "info"
Duration| number| 4

Types:

success
warning
error
info

---

💾 Config System

Save and load user settings.

Library:SaveConfig("default")
Library:LoadConfig("default")

Configs are stored in:

UILibraryConfigs/<name>.json

Requires executors with filesystem support:

writefile
readfile

---

🚩 Flags

Every UI element automatically registers a flag value.

Example:

print(Library.Flags["God Mode"])
print(Library.Flags["FOV"])
print(Library.Flags["ESP Color"])

---

Window API

CreateTab

local Combat = Window:CreateTab({Name="Combat"})
local Visual = Window:CreateTab({Name="Visuals"})

Property| Type
Name| string

---

Destroy Window

Window:Destroy()

Closes the UI with animation.

---

Tab Elements

Elements are created using a Tab object.

---

Section

Tab:AddSection("Aimbot")

Adds a divider label.

---

Label

local label = Tab:AddLabel("Aim Disabled")

label:Set("Aim Enabled")

---

Toggle

Tab:AddToggle({
    Name = "Silent Aim",
    Default = false,
    Callback = function(state)
        SilentAim.Enabled = state
    end
})

Methods

toggle:Set(true)
toggle:Get()

---

Button

Tab:AddButton({
    Name = "Rejoin Server",
    Hint = "↺",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
})

---

Textbox

Tab:AddTextbox({
    Name = "Player Name",
    Placeholder = "Enter username",
    Callback = function(text)
        targetPlayer = text
    end
})

Methods

textbox:Set("Alex")
textbox:Get()

---

Slider

Tab:AddSlider({
    Name = "FOV",
    Min = 10,
    Max = 360,
    Default = 90,
    Increment = 5,
    Suffix = "°"
})

Methods

slider:Set(50)
slider:Get()

---

Dropdown

Tab:AddDropdown({
    Name = "ESP Color",
    Options = {"White","Red","Rainbow"},
    Default = "White"
})

Methods

dropdown:Set("Red")
dropdown:Get()
dropdown:Refresh({"Head","Torso"})

---

Keybind

Tab:AddKeybind({
    Name = "Toggle Menu",
    Default = Enum.KeyCode.RightShift,
    OnPress = function()
        print("Pressed")
    end
})

Methods

keybind:Set(Enum.KeyCode.V)
keybind:Get()

---

💻 Executor Compatibility

Executor| Supported
Synapse X| ✅
KRNL| ✅
Fluxus| ✅
Solara| ✅
Script-Ware| ✅
Delta| ✅
Hydrogen (Mobile)| ✅

Config saving requires filesystem access.

---

📜 License

Free to use and modify.

Credit is appreciated but not required.
