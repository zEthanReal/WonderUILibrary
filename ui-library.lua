--[[
    WonderUI Library v2.0
    Enhanced Mobile + PC UI Library for Roblox
    
    Improvements:
    - Fixed all known bugs
    - Added 10+ new features
    - Better code organization
    - Improved mobile support
    - Theme system
    - Notification stacking
    - Better animations
    - Error handling
    - And much more...
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Library = {}
Library.__index = Library

-- Configuration
local Config = {
    Theme = "Dark",
    SoundEnabled = false,
    AnimationSpeed = 1,
    SaveFolder = "WonderUI_Configs"
}

-- Enhanced Color Themes
local Themes = {
    Dark = {
        Main = Color3.fromRGB(25, 25, 30),
        Top = Color3.fromRGB(35, 35, 45),
        Accent = Color3.fromRGB(80, 130, 255),
        Text = Color3.fromRGB(230, 230, 230),
        Secondary = Color3.fromRGB(45, 45, 55),
        Success = Color3.fromRGB(80, 255, 120),
        Error = Color3.fromRGB(255, 80, 80),
        Warning = Color3.fromRGB(255, 180, 80)
    },
    Light = {
        Main = Color3.fromRGB(240, 240, 245),
        Top = Color3.fromRGB(220, 220, 230),
        Accent = Color3.fromRGB(60, 100, 220),
        Text = Color3.fromRGB(40, 40, 50),
        Secondary = Color3.fromRGB(200, 200, 210),
        Success = Color3.fromRGB(60, 200, 100),
        Error = Color3.fromRGB(220, 60, 60),
        Warning = Color3.fromRGB(220, 150, 60)
    },
    Midnight = {
        Main = Color3.fromRGB(15, 15, 25),
        Top = Color3.fromRGB(25, 25, 40),
        Accent = Color3.fromRGB(147, 112, 219),
        Text = Color3.fromRGB(220, 220, 240),
        Secondary = Color3.fromRGB(35, 35, 50),
        Success = Color3.fromRGB(100, 255, 150),
        Error = Color3.fromRGB(255, 100, 100),
        Warning = Color3.fromRGB(255, 200, 100)
    },
    Ocean = {
        Main = Color3.fromRGB(20, 30, 40),
        Top = Color3.fromRGB(30, 45, 60),
        Accent = Color3.fromRGB(0, 200, 255),
        Text = Color3.fromRGB(230, 245, 255),
        Secondary = Color3.fromRGB(40, 55, 70),
        Success = Color3.fromRGB(0, 255, 150),
        Error = Color3.fromRGB(255, 80, 100),
        Warning = Color3.fromRGB(255, 200, 50)
    }
}

local Colors = Themes[Config.Theme]

-- Utility Functions
local Utility = {}

function Utility:Tween(obj, info, properties)
    local tween = TweenService:Create(obj, info, properties)
    tween:Play()
    return tween
end

function Utility:PlaySound(soundId)
    if not Config.SoundEnabled then return end
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = PlayerGui
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

function Utility:ValidateCallback(callback)
    return typeof(callback) == "function" and callback or function() end
end

function Utility:Round(num, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

function Utility:Clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function Utility:CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

function Utility:CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.Accent
    stroke.Thickness = thickness or 1.5
    stroke.Parent = parent
    return stroke
end

function Utility:CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://131604521931008"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

-- Notification System
local NotificationSystem = {}
NotificationSystem.ActiveNotifications = {}
NotificationSystem.MaxNotifications = 5
NotificationSystem.Spacing = 80
NotificationSystem.StartY = -20

function NotificationSystem:Notify(title, text, duration, type)
    duration = duration or 3
    type = type or "Info"
    
    local typeColors = {
        Info = Colors.Accent,
        Success = Colors.Success,
        Error = Colors.Error,
        Warning = Colors.Warning
    }
    
    local holder = Instance.new("Frame")
    holder.Name = "Notification"
    holder.Parent = PlayerGui
    holder.Size = UDim2.new(0, 280, 0, 75)
    holder.Position = UDim2.new(1, 20, 1, NotificationSystem.StartY)
    holder.BackgroundColor3 = Colors.Top
    holder.BorderSizePixel = 0
    holder.ZIndex = 100
    
    Utility:CreateCorner(holder, 10)
    Utility:CreateStroke(holder, typeColors[type], 2)
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Parent = holder
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 10, 0, 10)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = typeColors[type]
    
    local iconIds = {
        Info = "rbxassetid://140013216202448",
        Success = "rbxassetid://90853647693818",
        Error = "rbxassetid://90853647693818",
        Warning = "rbxassetid://140013216202448"
    }
    icon.Image = iconIds[type]
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Parent = holder
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = Colors.Text
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 42, 0, 8)
    titleLabel.Size = UDim2.new(1, -54, 0, 25)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextSize = 15
    
    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.Parent = holder
    desc.Text = text
    desc.Font = Enum.Font.Gotham
    desc.TextColor3 = Colors.Text
    desc.BackgroundTransparency = 1
    desc.Position = UDim2.new(0, 10, 0, 38)
    desc.Size = UDim2.new(1, -20, 0, 30)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.TextWrapped = true
    desc.TextSize = 13
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "Progress"
    progressBar.Parent = holder
    progressBar.Size = UDim2.new(1, 0, 0, 3)
    progressBar.Position = UDim2.new(0, 0, 1, -3)
    progressBar.BackgroundColor3 = typeColors[type]
    progressBar.BorderSizePixel = 0
    
    Utility:CreateCorner(progressBar, 1)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Parent = holder
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 5)
    closeBtn.Text = "×"
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextColor3 = Colors.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    
    table.insert(NotificationSystem.ActiveNotifications, 1, holder)
    
    while #NotificationSystem.ActiveNotifications > NotificationSystem.MaxNotifications do
        local old = table.remove(NotificationSystem.ActiveNotifications)
        if old then
            pcall(function()
                Utility:Tween(old, TweenInfo.new(0.3), {
                    Position = UDim2.new(1, 20, 1, old.Position.Y.Offset)
                })
                task.wait(0.3)
                old:Destroy()
            end)
        end
    end
    
    NotificationSystem:UpdatePositions()
    
    Utility:Tween(holder, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -300, 1, holder.Position.Y.Offset)
    })
    
    Utility:Tween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 3)
    })
    
    local closed = false
    local function close()
        if closed then return end
        closed = true
        
        for i, notif in ipairs(NotificationSystem.ActiveNotifications) do
            if notif == holder then
                table.remove(NotificationSystem.ActiveNotifications, i)
                break
            end
        end
        
        Utility:Tween(holder, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 20, 1, holder.Position.Y.Offset)
        })
        
        task.wait(0.3)
        holder:Destroy()
        NotificationSystem:UpdatePositions()
    end
    
    closeBtn.MouseButton1Click:Connect(close)
    task.delay(duration, close)
    
    return holder
end

function NotificationSystem:UpdatePositions()
    for i, notif in ipairs(NotificationSystem.ActiveNotifications) do
        if notif and notif.Parent then
            local targetY = NotificationSystem.StartY - ((i - 1) * NotificationSystem.Spacing)
            Utility:Tween(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Position = UDim2.new(1, -300, 1, targetY)
            })
        end
    end
end

-- Tooltip System
local TooltipSystem = {}
TooltipSystem.CurrentTooltip = nil

function TooltipSystem:Show(parent, text)
    self:Hide()
    
    if not text or text == "" then return end
    
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.Parent = PlayerGui
    tooltip.BackgroundColor3 = Colors.Secondary
    tooltip.BorderSizePixel = 0
    tooltip.ZIndex = 200
    tooltip.AutomaticSize = Enum.AutomaticSize.XY
    
    Utility:CreateCorner(tooltip, 6)
    Utility:CreateStroke(tooltip, Colors.Accent, 1)
    
    local label = Instance.new("TextLabel")
    label.Parent = tooltip
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Colors.Text
    label.BackgroundTransparency = 1
    label.TextSize = 12
    label.AutomaticSize = Enum.AutomaticSize.XY
    
    local padding = Instance.new("UIPadding")
    padding.Parent = tooltip
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    
    local absPos = parent.AbsolutePosition
    local absSize = parent.AbsoluteSize
    tooltip.Position = UDim2.new(0, absPos.X, 0, absPos.Y - 40)
    
    tooltip.BackgroundTransparency = 1
    label.TextTransparency = 1
    
    Utility:Tween(tooltip, TweenInfo.new(0.2), {BackgroundTransparency = 0})
    Utility:Tween(label, TweenInfo.new(0.2), {TextTransparency = 0})
    
    self.CurrentTooltip = tooltip
end

function TooltipSystem:Hide()
    if self.CurrentTooltip then
        local tooltip = self.CurrentTooltip
        Utility:Tween(tooltip, TweenInfo.new(0.15), {BackgroundTransparency = 1})
        
        local label = tooltip:FindFirstChildOfClass("TextLabel")
        if label then
            Utility:Tween(label, TweenInfo.new(0.15), {TextTransparency = 1})
        end
        
        task.delay(0.15, function()
            if tooltip then tooltip:Destroy() end
        end)
        
        self.CurrentTooltip = nil
    end
end

-- Config System
local ConfigSystem = {}

function ConfigSystem:Save(name, data)
    if not writefile then
        warn("writefile not available - cannot save config")
        return false
    end
    
    local success, err = pcall(function()
        local json = HttpService:JSONEncode(data)
        writefile(Config.SaveFolder .. "/" .. name .. ".json", json)
    end)
    
    if not success then
        warn("Failed to save config: " .. tostring(err))
        return false
    end
    
    return true
end

function ConfigSystem:Load(name)
    if not readfile or not isfile then
        warn("readfile/isfile not available - cannot load config")
        return nil
    end
    
    local path = Config.SaveFolder .. "/" .. name .. ".json"
    if not isfile(path) then
        return nil
    end
    
    local success, result = pcall(function()
        local json = readfile(path)
        return HttpService:JSONDecode(json)
    end)
    
    if not success then
        warn("Failed to load config: " .. tostring(result))
        return nil
    end
    
    return result
end

function ConfigSystem:ListConfigs()
    if not listfiles then return {} end
    
    local configs = {}
    local files = listfiles(Config.SaveFolder)
    
    for _, file in ipairs(files) do
        if file:match("%.json$") then
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    
    return configs
end

function ConfigSystem:Delete(name)
    if not delfile then return false end
    
    local path = Config.SaveFolder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        return true
    end
    return false
end

-- Main Library Functions
function Library:SetTheme(themeName)
    if Themes[themeName] then
        Config.Theme = themeName
        Colors = Themes[themeName]
    end
end

function Library:GetThemes()
    local themeList = {}
    for name, _ in pairs(Themes) do
        table.insert(themeList, name)
    end
    return themeList
end

function Library:Notify(title, text, duration, type)
    return NotificationSystem:Notify(title, text, duration, type)
end

function Library:CreateWindow(settings)
    settings = settings or {}
    
    local title = settings.Title or "WonderUI"
    local size = settings.Size or Vector2.new(400, 500)
    local position = settings.Position or nil
    local theme = settings.Theme or Config.Theme
    local keybind = settings.ToggleKeybind or Enum.KeyCode.RightShift
    local canResize = settings.CanResize ~= false
    local minSize = settings.MinSize or Vector2.new(300, 200)
    local maxSize = settings.MaxSize or Vector2.new(800, 600)
    
    if Themes[theme] then
        Colors = Themes[theme]
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WonderUI_" .. title:gsub(" ", "_")
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        screenGui.Parent = CoreGui
    end)
    
    if not screenGui.Parent then
        screenGui.Parent = PlayerGui
    end
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Parent = screenGui
    main.Size = UDim2.new(0, size.X, 0, size.Y)
    
    if position then
        main.Position = UDim2.new(0, position.X, 0, position.Y)
    else
        main.Position = UDim2.new(0.5, -size.X/2, 0.5, -size.Y/2)
    end
    
    main.BackgroundColor3 = Colors.Main
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.ClipsDescendants = true
    main.ZIndex = 10
    
    Utility:CreateCorner(main, 12)
    Utility:CreateStroke(main, Colors.Accent, 2)
    Utility:CreateShadow(main)
    
    -- Top Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Parent = main
    topBar.Size = UDim2.new(1, 0, 0, 45)
    topBar.BackgroundColor3 = Colors.Top
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 11
    
    Utility:CreateCorner(topBar, 12)
    
    local fixFrame = Instance.new("Frame")
    fixFrame.Parent = topBar
    fixFrame.Size = UDim2.new(1, 0, 0.5, 0)
    fixFrame.Position = UDim2.new(0, 0, 0.5, 0)
    fixFrame.BackgroundColor3 = Colors.Top
    fixFrame.BorderSizePixel = 0
    fixFrame.ZIndex = 11
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Parent = topBar
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Colors.Text
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 12
    
    if settings.Icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Parent = topBar
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 15, 0.5, -12)
        icon.BackgroundTransparency = 1
        icon.Image = settings.Icon
        icon.ImageColor3 = Colors.Accent
        icon.ZIndex = 12
        
        titleLabel.Position = UDim2.new(0, 48, 0, 0)
    end
    
    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Parent = topBar
    controls.Size = UDim2.new(0, 100, 1, 0)
    controls.Position = UDim2.new(1, -105, 0, 0)
    controls.BackgroundTransparency = 1
    controls.ZIndex = 12
    
    local controlsLayout = Instance.new("UIListLayout")
    controlsLayout.Parent = controls
    controlsLayout.FillDirection = Enum.FillDirection.Horizontal
    controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlsLayout.Padding = UDim.new(0, 8)
    controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    
    local function createControlButton(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = controls
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.Text = text
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.AutoButtonColor = false
        btn.ZIndex = 13
        
        Utility:CreateCorner(btn, 6)
        
        btn.MouseEnter:Connect(function()
            Utility:Tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)})
        end)
        
        btn.MouseLeave:Connect(function()
            Utility:Tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = color})
        end)
        
        btn.MouseButton1Click:Connect(callback)
        
        return btn
    end
    
    local minimized = false
    local originalSize = main.Size
    
    local minimizeBtn = createControlButton("—", Colors.Accent, function()
        minimized = not minimized
        
        if minimized then
            Utility:Tween(main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0, main.Size.X.Offset, 0, 45)
            })
            minimizeBtn.Text = "+"
        else
            Utility:Tween(main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = originalSize
            })
            minimizeBtn.Text = "—"
        end
    end)
    
    createControlButton("×", Colors.Error, function()
        Utility:Tween(main, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)})
        task.wait(0.3)
        screenGui:Destroy()
    end)
    
    if canResize then
        local resizeHandle = Instance.new("TextButton")
        resizeHandle.Name = "ResizeHandle"
        resizeHandle.Parent = main
        resizeHandle.Size = UDim2.new(0, 20, 0, 20)
        resizeHandle.Position = UDim2.new(1, -20, 1, -20)
        resizeHandle.BackgroundTransparency = 1
        resizeHandle.Text = ""
        resizeHandle.ZIndex = 20
        resizeHandle.AutoButtonColor = false
        
        local resizeIcon = Instance.new("ImageLabel")
        resizeIcon.Parent = resizeHandle
        resizeIcon.Size = UDim2.new(0, 12, 0, 12)
        resizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
        resizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        resizeIcon.BackgroundTransparency = 1
        resizeIcon.Image = "rbxassetid://138740476585338"
        resizeIcon.ImageColor3 = Colors.Text
        resizeIcon.ImageTransparency = 0.5
        resizeIcon.ZIndex = 21
        
        local resizing = false
        local startPos, startSize
        
        resizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true
                startPos = input.Position
                startSize = main.Size
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - startPos
                local newWidth = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
                local newHeight = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
                
                main.Size = UDim2.new(0, newWidth, 0, newHeight)
                originalSize = main.Size
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
    end
    
    -- Tab System
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Parent = main
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.Position = UDim2.new(0, 0, 0, 45)
    tabBar.BackgroundColor3 = Colors.Main
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = 11
    
    local tabBarLayout = Instance.new("UIListLayout")
    tabBarLayout.Parent = tabBar
    tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
    tabBarLayout.Padding = UDim.new(0, 4)
    tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local tabBarPadding = Instance.new("UIPadding")
    tabBarPadding.Parent = tabBar
    tabBarPadding.PaddingLeft = UDim.new(0, 10)
    tabBarPadding.PaddingRight = UDim.new(0, 10)
    
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Parent = tabBar
    tabContainer.Size = UDim2.new(1, 0, 1, 0)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ScrollBarThickness = 2
    tabContainer.ScrollBarImageColor3 = Colors.Accent
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabContainer.ZIndex = 11
    
    tabBarLayout.Parent = tabContainer
    
    local pagesContainer = Instance.new("Frame")
    pagesContainer.Name = "Pages"
    pagesContainer.Parent = main
    pagesContainer.Position = UDim2.new(0, 0, 0, 85)
    pagesContainer.Size = UDim2.new(1, 0, 1, -85)
    pagesContainer.BackgroundTransparency = 1
    pagesContainer.ZIndex = 10
    
    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.Elements = {}
    
    local visible = true
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == keybind then
            visible = not visible
            main.Visible = visible
        end
    end)
    
    function Window:CreateTab(tabSettings)
        tabSettings = tabSettings or {}
        local tabName = tabSettings.Name or "Tab"
        local tabIcon = tabSettings.Icon
        
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "_Tab"
        tabBtn.Parent = tabContainer
        tabBtn.Size = UDim2.new(0, tabIcon and 110 or 90, 0, 32)
        tabBtn.Text = ""
        tabBtn.BackgroundColor3 = Colors.Top
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 12
        
        Utility:CreateCorner(tabBtn, 6)
        
        if tabIcon then
            local icon = Instance.new("ImageLabel")
            icon.Parent = tabBtn
            icon.Size = UDim2.new(0, 18, 0, 18)
            icon.Position = UDim2.new(0, 10, 0.5, -9)
            icon.BackgroundTransparency = 1
            icon.Image = tabIcon
            icon.ImageColor3 = Colors.Text
            icon.ZIndex = 13
        end
        
        local label = Instance.new("TextLabel")
        label.Parent = tabBtn
        label.Text = tabName
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextColor3 = Colors.Text
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, tabIcon and 32 or 0, 0, 0)
        label.Size = UDim2.new(1, tabIcon and -32 or 0, 1, 0)
        label.TextXAlignment = tabIcon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        label.ZIndex = 13
        
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Parent = tabBtn
        indicator.Size = UDim2.new(0, 0, 0, 3)
        indicator.Position = UDim2.new(0.5, 0, 1, -3)
        indicator.AnchorPoint = Vector2.new(0.5, 0)
        indicator.BackgroundColor3 = Colors.Accent
        indicator.BorderSizePixel = 0
        indicator.ZIndex = 13
        
        Utility:CreateCorner(indicator, 1.5)
        
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "_Page"
        page.Parent = pagesContainer
        page.Size = UDim2.new(1, 0, 1, 0)
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = Colors.Accent
        page.BackgroundTransparency = 1
        page.Visible = false
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ZIndex = 10
        
        local pagePadding = Instance.new("UIPadding")
        pagePadding.Parent = page
        pagePadding.PaddingLeft = UDim.new(0, 15)
        pagePadding.PaddingRight = UDim.new(0, 15)
        pagePadding.PaddingTop = UDim.new(0, 15)
        pagePadding.PaddingBottom = UDim.new(0, 15)
        
        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Parent = page
        pageLayout.Padding = UDim.new(0, 10)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local Tab = {
            Name = tabName,
            Button = tabBtn,
            Page = page,
            Elements = {},
            Indicator = indicator
        }
        
        table.insert(Window.Tabs, Tab)
        
        tabBtn.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)
        
        tabBtn.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Utility:Tween(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Secondary})
            end
        end)
        
        tabBtn.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Utility:Tween(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Top})
            end
        end)
        
        if #Window.Tabs == 1 then
            Window:SelectTab(Tab)
        end
        
        local Elements = {}
        
        function Elements:AddSection(sectionSettings)
            sectionSettings = sectionSettings or {}
            local text = sectionSettings.Name or "Section"
            
            local section = Instance.new("Frame")
            section.Name = "Section_" .. text
            section.Parent = page
            section.Size = UDim2.new(1, 0, 0, 30)
            section.BackgroundTransparency = 1
            
            local label = Instance.new("TextLabel")
            label.Parent = section
            label.Text = text:upper()
            label.Font = Enum.Font.GothamBold
            label.TextSize = 12
            label.TextColor3 = Colors.Accent
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            
            local line = Instance.new("Frame")
            line.Parent = section
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 1, -5)
            line.BackgroundColor3 = Colors.Secondary
            line.BorderSizePixel = 0
            
            return section
        end
        
        function Elements:AddLabel(labelSettings)
            labelSettings = labelSettings or {}
            local text = labelSettings.Text or "Label"
            local icon = labelSettings.Icon
            
            local frame = Instance.new("Frame")
            frame.Parent = page
            frame.Size = UDim2.new(1, 0, 0, 30)
            frame.BackgroundTransparency = 1
            
            if icon then
                local img = Instance.new("ImageLabel")
                img.Parent = frame
                img.Size = UDim2.new(0, 20, 0, 20)
                img.Position = UDim2.new(0, 0, 0.5, -10)
                img.BackgroundTransparency = 1
                img.Image = icon
                img.ImageColor3 = Colors.Accent
            end
            
            local label = Instance.new("TextLabel")
            label.Parent = frame
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = Colors.Text
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, icon and 28 or 0, 0, 0)
            label.Size = UDim2.new(1, icon and -28 or 0, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextWrapped = true
            
            frame.AutomaticSize = Enum.AutomaticSize.Y
            
            return label
        end
        
        function Elements:AddButton(buttonSettings)
            buttonSettings = buttonSettings or {}
            local text = buttonSettings.Name or "Button"
            local callback = Utility:ValidateCallback(buttonSettings.Callback)
            local tooltip = buttonSettings.Tooltip
            local icon = buttonSettings.Icon
            
            local btn = Instance.new("TextButton")
            btn.Name = "Button_" .. text
            btn.Parent = page
            btn.Size = UDim2.new(1, 0, 0, 38)
            btn.Text = ""
            btn.BackgroundColor3 = Colors.Accent
            btn.AutoButtonColor = false
            btn.ZIndex = 10
            
            Utility:CreateCorner(btn, 8)
            
            if icon then
                local img = Instance.new("ImageLabel")
                img.Parent = btn
                img.Size = UDim2.new(0, 18, 0, 18)
                img.Position = UDim2.new(0, 12, 0.5, -9)
                img.BackgroundTransparency = 1
                img.Image = icon
                img.ImageColor3 = Color3.new(1, 1, 1)
                img.ZIndex = 11
            end
            
            local label = Instance.new("TextLabel")
            label.Parent = btn
            label.Text = text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.TextColor3 = Color3.new(1, 1, 1)
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, icon and 38 or 0, 0, 0)
            label.Size = UDim2.new(1, icon and -38 or 0, 1, 0)
            label.ZIndex = 11
            
            local originalSize = btn.Size
            
            btn.MouseButton1Down:Connect(function()
                Utility:Tween(btn, TweenInfo.new(0.1), {Size = UDim2.new(1, -4, 0, 34)})
            end)
            
            btn.MouseButton1Up:Connect(function()
                Utility:Tween(btn, TweenInfo.new(0.1), {Size = originalSize})
            end)
            
            btn.MouseButton1Click:Connect(function()
                Utility:PlaySound("rbxassetid://9113083740")
                local success, err = pcall(callback)
                if not success then
                    warn("Button callback error: " .. tostring(err))
                end
            end)
            
            btn.MouseEnter:Connect(function()
                Utility:Tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent:Lerp(Color3.new(1,1,1), 0.1)})
                if tooltip then
                    TooltipSystem:Show(btn, tooltip)
                end
            end)
            
            btn.MouseLeave:Connect(function()
                Utility:Tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent})
                TooltipSystem:Hide()
            end)
            
            return btn
        end
        
        function Elements:AddToggle(toggleSettings)
            toggleSettings = toggleSettings or {}
            local text = toggleSettings.Name or "Toggle"
            local default = toggleSettings.Default or false
            local callback = Utility:ValidateCallback(toggleSettings.Callback)
            local tooltip = toggleSettings.Tooltip
            
            local holder = Instance.new("Frame")
            holder.Name = "Toggle_" .. text
            holder.Parent = page
            holder.Size = UDim2.new(1, 0, 0, 40)
            holder.BackgroundColor3 = Colors.Top
            holder.ZIndex = 10
            
            Utility:CreateCorner(holder, 8)
            
            local label = Instance.new("TextLabel")
            label.Parent = holder
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = Colors.Text
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(1, -70, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 11
            
            local switch = Instance.new("Frame")
            switch.Parent = holder
            switch.Size = UDim2.new(0, 44, 0, 24)
            switch.Position = UDim2.new(1, -56, 0.5, -12)
            switch.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            switch.ZIndex = 11
            
            Utility:CreateCorner(switch, 12)
            
            local knob = Instance.new("Frame")
            knob.Parent = switch
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = UDim2.new(0, 2, 0.5, -10)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.ZIndex = 12
            
            Utility:CreateCorner(knob, 10)
            
            local state = default
            
            local function updateToggle()
                if state then
                    Utility:Tween(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -22, 0.5, -10)})
                    Utility:Tween(switch, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent})
                else
                    Utility:Tween(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -10)})
                    Utility:Tween(switch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)})
                end
                
                local success, err = pcall(function()
                    callback(state)
                end)
                if not success then
                    warn("Toggle callback error: " .. tostring(err))
                end
            end
            
            if state then
                knob.Position = UDim2.new(1, -22, 0.5, -10)
                switch.BackgroundColor3 = Colors.Accent
            end
            
            holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    state = not state
                    Utility:PlaySound("rbxassetid://9113083740")
                    updateToggle()
                end
            end)
            
            holder.MouseEnter:Connect(function()
                Utility:Tween(holder, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Secondary})
                if tooltip then
                    TooltipSystem:Show(holder, tooltip)
                end
            end)
            
            holder.MouseLeave:Connect(function()
                Utility:Tween(holder, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Top})
                TooltipSystem:Hide()
            end)
            
            local ToggleAPI = {}
            
            function ToggleAPI:Set(value)
                state = value
                updateToggle()
            end
            
            function ToggleAPI:Get()
                return state
            end
            
            return ToggleAPI
        end
        
        function Elements:AddSlider(sliderSettings)
            sliderSettings = sliderSettings or {}
            local text = sliderSettings.Name or "Slider"
            local min = sliderSettings.Min or 0
            local max = sliderSettings.Max or 100
            local default = math.clamp(sliderSettings.Default or min, min, max)
            local increment = sliderSettings.Increment or 1
            local suffix = sliderSettings.Suffix or ""
            local callback = Utility:ValidateCallback(sliderSettings.Callback)
            local tooltip = sliderSettings.Tooltip
            
            local holder = Instance.new("Frame")
            holder.Name = "Slider_" .. text
            holder.Parent = page
            holder.Size = UDim2.new(1, 0, 0, 60)
            holder.BackgroundColor3 = Colors.Top
            holder.ZIndex = 10
            
            Utility:CreateCorner(holder, 8)
            
            local label = Instance.new("TextLabel")
            label.Parent = holder
            label.Text = text .. ": " .. default .. suffix
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = Colors.Text
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 8)
            label.Size = UDim2.new(1, -24, 0, 20)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 11
            
            local barBg = Instance.new("Frame")
            barBg.Parent = holder
            barBg.Size = UDim2.new(1, -24, 0, 8)
            barBg.Position = UDim2.new(0, 12, 0, 38)
            barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            barBg.BorderSizePixel = 0
            barBg.ZIndex = 11
            
            Utility:CreateCorner(barBg, 4)
            
            local fill = Instance.new("Frame")
            fill.Parent = barBg
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Colors.Accent
            fill.BorderSizePixel = 0
            fill.ZIndex = 12
            
            Utility:CreateCorner(fill, 4)
            
            local knob = Instance.new("Frame")
            knob.Parent = barBg
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = UDim2.new(fill.Size.X.Scale, -8, 0.5, -8)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.ZIndex = 13
            
            Utility:CreateCorner(knob, 8)
            
            local dragging = false
            
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                local value = min + (max - min) * pos
                
                if increment > 0 then
                    value = math.floor(value / increment + 0.5) * increment
                end
                
                value = math.clamp(value, min, max)
                
                local scale = (value - min) / (max - min)
                fill.Size = UDim2.new(scale, 0, 1, 0)
                knob.Position = UDim2.new(scale, -8, 0.5, -8)
                
                label.Text = text .. ": " .. Utility:Round(value, 3) .. suffix
                
                local success, err = pcall(function()
                    callback(value)
                end)
                if not success then
                    warn("Slider callback error: " .. tostring(err))
                end
            end
            
            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            
            holder.MouseEnter:Connect(function()
                Utility:Tween(holder, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Secondary})
                if tooltip then
                    TooltipSystem:Show(holder, tooltip)
                end
            end)
            
            holder.MouseLeave:Connect(function()
                Utility:Tween(holder, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Top})
                TooltipSystem:Hide()
            end)
            
            local SliderAPI = {}
            
            function SliderAPI:Set(value)
                value = math.clamp(value, min, max)
                local scale = (value - min) / (max - min)
                fill.Size = UDim2.new(scale, 0, 1, 0)
                knob.Position = UDim2.new(scale, -8, 0.5, -8)
                label.Text = text .. ": " .. value .. suffix
                
                pcall(callback, value)
            end
            
            function SliderAPI:Get()
                local scale = fill.Size.X.Scale
                return min + (max - min) * scale
            end
            
            return SliderAPI
        end
        
        return Elements
    end
    
    function Window:SelectTab(tab)
        if self.ActiveTab == tab then return end
        
        if self.ActiveTab then
            Utility:Tween(self.ActiveTab.Button, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Top})
            Utility:Tween(self.ActiveTab.Indicator, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 3)})
            self.ActiveTab.Page.Visible = false
        end
        
        self.ActiveTab = tab
        Utility:Tween(tab.Button, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Secondary})
        Utility:Tween(tab.Indicator, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0.6, 0, 0, 3)})
        tab.Page.Visible = true
        tab.Page.CanvasPosition = Vector2.new(0, 0)
    end
    
    function Window:Notify(title, text, duration, type)
        return NotificationSystem:Notify(title, text, duration, type)
    end
    
    function Window:SetTheme(themeName)
        if Themes[themeName] then
            Colors = Themes[themeName]
        end
    end
    
    function Window:Destroy()
        screenGui:Destroy()
    end
    
    return Window
end

-- Global Config Functions
function Library:SaveConfig(name, data)
    return ConfigSystem:Save(name, data)
end

function Library:LoadConfig(name)
    return ConfigSystem:Load(name)
end

function Library:ListConfigs()
    return ConfigSystem:ListConfigs()
end

function Library:DeleteConfig(name)
    return ConfigSystem:Delete(name)
end

function Library:SetFolder(folder)
    Config.SaveFolder = folder
end

function Library:Notify(title, text, duration, type)
    return NotificationSystem:Notify(title, text, duration, type)
end

function Library:SetTheme(theme)
    Config.Theme = theme
    Colors = Themes[theme] or Themes.Dark
end

function Library:GetTheme()
    return Config.Theme
end

function Library:GetThemes()
    local list = {}
    for name, _ in pairs(Themes) do
        table.insert(list, name)
    end
    return list
end

return Library
