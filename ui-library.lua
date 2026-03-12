--[[
    WonderUI Library v3.0
    Professional Roblox UI Library
    
    Major Improvements:
    - Dynamic Theme System with live switching
    - Robust Error Handling & Logging
    - Advanced State Management
    - Performance Optimizations
    - Modern UI Components
    - Accessibility Features
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Error Handling System
local ErrorHandler = {
    Enabled = true,
    LogLevel = "Warn", -- "Debug", "Info", "Warn", "Error", "Fatal"
    Logs = {},
    MaxLogs = 100
}

function ErrorHandler:Log(level, message, context)
    if not self.Enabled then return end
    
    local levels = {Debug = 1, Info = 2, Warn = 3, Error = 4, Fatal = 5}
    local currentLevel = levels[self.LogLevel] or 3
    local msgLevel = levels[level] or 3
    
    if msgLevel < currentLevel then return end
    
    local logEntry = {
        Level = level,
        Message = message,
        Context = context or {},
        Timestamp = os.time(),
        Traceback = debug.traceback("", 2)
    }
    
    table.insert(self.Logs, 1, logEntry)
    
    -- Keep only last N logs
    while #self.Logs > self.MaxLogs do
        table.remove(self.Logs)
    end
    
    -- Output to console
    local output = string.format("[WonderUI %s] %s", level, message)
    if level == "Error" or level == "Fatal" then
        warn(output)
        if context and next(context) then
            warn("Context:", HttpService:JSONEncode(context))
        end
    elseif level == "Warn" then
        warn(output)
    else
        print(output)
    end
    
    return logEntry
end

function ErrorHandler:Try(func, context)
    return function(...)
        local success, result = pcall(func, ...)
        if not success then
            self:Log("Error", tostring(result), context or {})
            return nil, result
        end
        return result
    end
end

-- State Management System
local StateManager = {
    States = {},
    Listeners = {},
    GlobalListeners = {}
}

function StateManager:Create(id, initialValue, options)
    options = options or {}
    
    self.States[id] = {
        Value = initialValue,
        PreviousValue = nil,
        History = options.History and {initialValue} or nil,
        MaxHistory = options.MaxHistory or 50,
        Persist = options.Persist or false,
        Validate = options.Validate,
        Transform = options.Transform
    }
    
    self.Listeners[id] = {}
    
    -- Load persisted state
    if options.Persist and readfile then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile("WonderUI_States/" .. id .. ".json"))
        end)
        if success and data then
            self.States[id].Value = data
        end
    end
    
    return self:CreateAPI(id)
end

function StateManager:Get(id)
    local state = self.States[id]
    return state and state.Value
end

function StateManager:Set(id, value, silent)
    local state = self.States[id]
    if not state then
        ErrorHandler:Log("Warn", "State not found: " .. tostring(id))
        return false
    end
    
    -- Validate
    if state.Validate and not state.Validate(value) then
        ErrorHandler:Log("Warn", "State validation failed for: " .. tostring(id))
        return false
    end
    
    -- Transform
    if state.Transform then
        value = state.Transform(value)
    end
    
    -- No change check
    if value == state.Value then return true end
    
    state.PreviousValue = state.Value
    state.Value = value
    
    -- History
    if state.History then
        table.insert(state.History, value)
        while #state.History > state.MaxHistory do
            table.remove(state.History, 1)
        end
    end
    
    -- Persist
    if state.Persist and writefile then
        pcall(function()
            writefile("WonderUI_States/" .. id .. ".json", HttpService:JSONEncode(value))
        end)
    end
    
    -- Notify listeners
    if not silent then
        self:Notify(id, value, state.PreviousValue)
    end
    
    return true
end

function StateManager:Notify(id, newValue, oldValue)
    local listeners = self.Listeners[id]
    if listeners then
        for callback, _ in pairs(listeners) do
            task.spawn(function()
                local success, err = pcall(callback, newValue, oldValue, id)
                if not success then
                    ErrorHandler:Log("Error", "State listener error: " .. tostring(err))
                end
            end)
        end
    end
    
    -- Global listeners
    for callback, _ in pairs(self.GlobalListeners) do
        task.spawn(function()
            pcall(callback, id, newValue, oldValue)
        end)
    end
end

function StateManager:Subscribe(id, callback)
    if not self.Listeners[id] then
        self.Listeners[id] = {}
    end
    self.Listeners[id][callback] = true
    
    -- Return unsubscribe function
    return function()
        if self.Listeners[id] then
            self.Listeners[id][callback] = nil
        end
    end
end

function StateManager:SubscribeAll(callback)
    self.GlobalListeners[callback] = true
    return function()
        self.GlobalListeners[callback] = nil
    end
end

function StateManager:CreateAPI(id)
    return {
        Get = function() return StateManager:Get(id) end,
        Set = function(value, silent) return StateManager:Set(id, value, silent) end,
        Subscribe = function(callback) return StateManager:Subscribe(id, callback) end,
        Update = function(transformer)
            local current = StateManager:Get(id)
            local newValue = transformer(current)
            return StateManager:Set(id, newValue)
        end,
        Toggle = function()
            local current = StateManager:Get(id)
            if type(current) == "boolean" then
                return StateManager:Set(id, not current)
            end
        end,
        Reset = function()
            local state = StateManager.States[id]
            if state and state.History and #state.History > 0 then
                return StateManager:Set(id, state.History[1])
            end
        end,
        Undo = function()
            local state = StateManager.States[id]
            if state and state.PreviousValue ~= nil then
                return StateManager:Set(id, state.PreviousValue)
            end
        end
    }
end

-- Dynamic Theme System
local ThemeSystem = {
    CurrentTheme = "Dark",
    Themes = {},
    Elements = {}, -- Track all themed elements
    Animations = true
}

function ThemeSystem:RegisterTheme(name, themeData)
    self.Themes[name] = themeData
    ErrorHandler:Log("Info", "Theme registered: " .. name)
end

function ThemeSystem:SetTheme(name, animate)
    if not self.Themes[name] then
        ErrorHandler:Log("Error", "Theme not found: " .. name)
        return false
    end
    
    local oldTheme = self.CurrentTheme
    self.CurrentTheme = name
    local theme = self.Themes[name]
    
    -- Update all tracked elements
    for element, data in pairs(self.Elements) do
        if element and element.Parent then
            self:ApplyToElement(element, data, theme, animate)
        else
            self.Elements[element] = nil -- Cleanup destroyed elements
        end
    end
    
    StateManager:Notify("ThemeChanged", name, oldTheme)
    ErrorHandler:Log("Info", "Theme changed to: " .. name)
    return true
end

function ThemeSystem:ApplyToElement(element, data, theme, animate)
    local properties = data.Properties
    local themeKey = data.ThemeKey
    
    if not properties or not themeKey then return end
    
    local color = theme[themeKey]
    if not color then return end
    
    if animate and self.Animations then
        TweenService:Create(element, TweenInfo.new(0.3), {[properties] = color}):Play()
    else
        element[properties] = color
    end
end

function ThemeSystem:Track(element, property, themeKey, options)
    options = options or {}
    
    self.Elements[element] = {
        Properties = property,
        ThemeKey = themeKey,
        Options = options
    }
    
    -- Apply current theme
    local theme = self.Themes[self.CurrentTheme]
    if theme and theme[themeKey] then
        element[property] = theme[themeKey]
    end
    
    -- Cleanup on destroy
    element.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self.Elements[element] = nil
        end
    end)
end

function ThemeSystem:GetColor(key)
    local theme = self.Themes[self.CurrentTheme]
    return theme and theme[key]
end

-- Register default themes
ThemeSystem:RegisterTheme("Dark", {
    Background = Color3.fromRGB(25, 25, 30),
    BackgroundSecondary = Color3.fromRGB(35, 35, 45),
    BackgroundTertiary = Color3.fromRGB(45, 45, 55),
    Accent = Color3.fromRGB(80, 130, 255),
    AccentHover = Color3.fromRGB(100, 150, 255),
    Text = Color3.fromRGB(230, 230, 230),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    TextDisabled = Color3.fromRGB(120, 120, 120),
    Border = Color3.fromRGB(60, 60, 70),
    Success = Color3.fromRGB(80, 255, 120),
    Warning = Color3.fromRGB(255, 180, 80),
    Error = Color3.fromRGB(255, 80, 80),
    Info = Color3.fromRGB(80, 180, 255)
})

ThemeSystem:RegisterTheme("Light", {
    Background = Color3.fromRGB(245, 245, 250),
    BackgroundSecondary = Color3.fromRGB(235, 235, 240),
    BackgroundTertiary = Color3.fromRGB(225, 225, 230),
    Accent = Color3.fromRGB(60, 100, 220),
    AccentHover = Color3.fromRGB(80, 120, 240),
    Text = Color3.fromRGB(40, 40, 50),
    TextSecondary = Color3.fromRGB(100, 100, 110),
    TextDisabled = Color3.fromRGB(160, 160, 170),
    Border = Color3.fromRGB(200, 200, 210),
    Success = Color3.fromRGB(60, 180, 80),
    Warning = Color3.fromRGB(220, 160, 60),
    Error = Color3.fromRGB(220, 60, 60),
    Info = Color3.fromRGB(60, 140, 220)
})

ThemeSystem:RegisterTheme("Midnight", {
    Background = Color3.fromRGB(10, 10, 18),
    BackgroundSecondary = Color3.fromRGB(18, 18, 28),
    BackgroundTertiary = Color3.fromRGB(28, 28, 40),
    Accent = Color3.fromRGB(147, 112, 219),
    AccentHover = Color3.fromRGB(167, 132, 239),
    Text = Color3.fromRGB(230, 230, 250),
    TextSecondary = Color3.fromRGB(180, 180, 200),
    TextDisabled = Color3.fromRGB(120, 120, 140),
    Border = Color3.fromRGB(50, 50, 70),
    Success = Color3.fromRGB(100, 255, 150),
    Warning = Color3.fromRGB(255, 200, 100),
    Error = Color3.fromRGB(255, 100, 100),
    Info = Color3.fromRGB(100, 180, 255)
})

ThemeSystem:RegisterTheme("Ocean", {
    Background = Color3.fromRGB(15, 25, 35),
    BackgroundSecondary = Color3.fromRGB(25, 40, 55),
    BackgroundTertiary = Color3.fromRGB(35, 55, 75),
    Accent = Color3.fromRGB(0, 200, 255),
    AccentHover = Color3.fromRGB(50, 220, 255),
    Text = Color3.fromRGB(230, 245, 255),
    TextSecondary = Color3.fromRGB(180, 210, 230),
    TextDisabled = Color3.fromRGB(120, 150, 170),
    Border = Color3.fromRGB(40, 60, 80),
    Success = Color3.fromRGB(0, 255, 150),
    Warning = Color3.fromRGB(255, 200, 50),
    Error = Color3.fromRGB(255, 80, 100),
    Info = Color3.fromRGB(0, 180, 255)
})

ThemeSystem:RegisterTheme("Forest", {
    Background = Color3.fromRGB(20, 30, 25),
    BackgroundSecondary = Color3.fromRGB(30, 45, 35),
    BackgroundTertiary = Color3.fromRGB(40, 60, 45),
    Accent = Color3.fromRGB(100, 200, 100),
    AccentHover = Color3.fromRGB(120, 220, 120),
    Text = Color3.fromRGB(235, 245, 235),
    TextSecondary = Color3.fromRGB(180, 200, 180),
    TextDisabled = Color3.fromRGB(120, 140, 120),
    Border = Color3.fromRGB(50, 70, 55),
    Success = Color3.fromRGB(80, 255, 120),
    Warning = Color3.fromRGB(255, 200, 80),
    Error = Color3.fromRGB(255, 100, 100),
    Info = Color3.fromRGB(100, 200, 255)
})

-- Utility Functions
local Utility = {}

function Utility:Tween(obj, info, properties, callback)
    local tween = TweenService:Create(obj, info, properties)
    if callback then
        tween.Completed:Connect(callback)
    end
    tween:Play()
    return tween
end

function Utility:CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

function Utility:CreateStroke(parent, color, thickness, themeKey)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    
    if themeKey then
        ThemeSystem:Track(stroke, "Color", themeKey)
    elseif color then
        stroke.Color = color
    end
    
    stroke.Parent = parent
    return stroke
end

function Utility:CreateShadow(parent, intensity)
    intensity = intensity or 0.6
    
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://131604521931008"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 1 - intensity
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    
    return shadow
end

function Utility:CreateRipple(parent, color)
    local ripple = Instance.new("Frame")
    ripple.BackgroundColor3 = color or Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.8
    ripple.BorderSizePixel = 0
    ripple.ZIndex = parent.ZIndex + 10
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    return ripple
end

function Utility:FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

function Utility:ClampText(text, maxLength)
    if #text <= maxLength then return text end
    return text:sub(1, maxLength - 3) .. "..."
end

-- Advanced Notification System
local NotificationSystem = {
    Active = {},
    Queue = {},
    MaxVisible = 5,
    Spacing = 85,
    Position = "TopRight" -- "TopRight", "TopLeft", "BottomRight", "BottomLeft"
}

function NotificationSystem:Notify(data)
    data = type(data) == "table" and data or {
        Title = data,
        Text = "",
        Duration = 3
    }
    
    local id = data.Id or HttpService:GenerateGUID(false)
    
    -- Check for duplicate notifications
    if data.Id then
        for _, notif in ipairs(self.Active) do
            if notif.Id == data.Id then
                notif:Update(data)
                return notif
            end
        end
    end
    
    local notification = self:CreateNotification(data, id)
    
    if #self.Active >= self.MaxVisible then
        table.insert(self.Queue, notification)
    else
        self:Show(notification)
    end
    
    return notification
end

function NotificationSystem:CreateNotification(data, id)
    local notif = {
        Id = id,
        Data = data,
        Active = false,
        Paused = false,
        RemainingTime = data.Duration or 3,
        Connections = {}
    }
    
    function notif:Update(newData)
        if self.Frame then
            if newData.Title then
                self.Frame.Title.Text = newData.Title
            end
            if newData.Text then
                self.Frame.Description.Text = newData.Text
            end
            if newData.Duration then
                self.RemainingTime = newData.Duration
            end
        end
    end
    
    function notif:Destroy()
        self.Active = false
        
        -- Disconnect all
        for _, conn in ipairs(self.Connections) do
            conn:Disconnect()
        end
        
        if self.Frame then
            Utility:Tween(self.Frame, TweenInfo.new(0.3), {
                Position = UDim2.new(1, 20, self.Frame.Position.Y.Scale, self.Frame.Position.Y.Offset)
            }, function()
                self.Frame:Destroy()
            end)
        end
        
        -- Remove from active
        for i, n in ipairs(NotificationSystem.Active) do
            if n == self then
                table.remove(NotificationSystem.Active, i)
                break
            end
        end
        
        NotificationSystem:UpdatePositions()
        NotificationSystem:ProcessQueue()
    end
    
    function notif:Pause()
        self.Paused = true
    end
    
    function notif:Resume()
        self.Paused = false
    end
    
    return notif
end

function NotificationSystem:Show(notif)
    local data = notif.Data
    
    local frame = Instance.new("Frame")
    frame.Name = "Notification_" .. notif.Id
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 1000
    
    -- Background with theme support
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BorderSizePixel = 0
    bg.Parent = frame
    
    ThemeSystem:Track(bg, "BackgroundColor3", "BackgroundSecondary")
    Utility:CreateCorner(bg, 10)
    Utility:CreateStroke(bg, nil, 1.5, "Border")
    
    -- Icon
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "IconFrame"
    iconFrame.Size = UDim2.new(0, 40, 1, -20)
    iconFrame.Position = UDim2.new(0, 10, 0, 10)
    iconFrame.BackgroundTransparency = 1
    iconFrame.Parent = bg
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 28, 0, 28)
    icon.Position = UDim2.new(0.5, -14, 0.5, -14)
    icon.BackgroundTransparency = 1
    icon.Image = data.Icon or self:GetIconForType(data.Type)
    icon.Parent = iconFrame
    
    ThemeSystem:Track(icon, "ImageColor3", data.Type == "Error" and "Error" or 
        data.Type == "Success" and "Success" or 
        data.Type == "Warning" and "Warning" or "Accent")
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = data.Title or "Notification"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 60, 0, 12)
    title.Size = UDim2.new(1, -80, 0, 20)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = bg
    
    ThemeSystem:Track(title, "TextColor3", "Text")
    
    -- Description
    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.Text = data.Text or ""
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 13
    desc.BackgroundTransparency = 1
    desc.Position = UDim2.new(0, 60, 0, 35)
    desc.Size = UDim2.new(1, -70, 0, 35)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.TextWrapped = true
    desc.Parent = bg
    
    ThemeSystem:Track(desc, "TextColor3", "TextSecondary")
    
    -- Progress bar
    if data.Duration and data.Duration > 0 then
        local progressBg = Instance.new("Frame")
        progressBg.Name = "ProgressBg"
        progressBg.Size = UDim2.new(1, -20, 0, 3)
        progressBg.Position = UDim2.new(0, 10, 1, -8)
        progressBg.BorderSizePixel = 0
        progressBg.Parent = bg
        
        ThemeSystem:Track(progressBg, "BackgroundColor3", "BackgroundTertiary")
        Utility:CreateCorner(progressBg, 1.5)
        
        local progress = Instance.new("Frame")
        progress.Name = "Progress"
        progress.Size = UDim2.new(1, 0, 1, 0)
        progress.BorderSizePixel = 0
        progress.Parent = progressBg
        
        ThemeSystem:Track(progress, "BackgroundColor3", data.Type == "Error" and "Error" or 
            data.Type == "Success" and "Success" or 
            data.Type == "Warning" and "Warning" or "Accent")
        Utility:CreateCorner(progress, 1.5)
        
        notif.ProgressBar = progress
    end
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 8)
    closeBtn.Text = "×"
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = bg
    
    ThemeSystem:Track(closeBtn, "TextColor3", "TextSecondary")
    
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = ThemeSystem:GetColor("Error")}):Play()
    end)
    
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = ThemeSystem:GetColor("TextSecondary")}):Play()
    end)
    
    table.insert(notif.Connections, closeBtn.MouseButton1Click:Connect(function()
        notif:Destroy()
    end))
    
    -- Hover to pause
    if data.PauseOnHover ~= false then
        table.insert(notif.Connections, bg.MouseEnter:Connect(function()
            notif:Pause()
        end))
        table.insert(notif.Connections, bg.MouseLeave:Connect(function()
            notif:Resume()
        end))
    end
    
    frame.Parent = PlayerGui
    
    -- Position off-screen initially
    local startPos = self:GetStartPosition()
    frame.Position = startPos.offScreen
    
    notif.Frame = frame
    notif.Active = true
    
    table.insert(self.Active, notif)
    self:UpdatePositions()
    
    -- Animate in
    Utility:Tween(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
        Position = startPos.onScreen
    })
    
    -- Progress animation
    if notif.ProgressBar then
        Utility:Tween(notif.ProgressBar, TweenInfo.new(notif.RemainingTime, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0)
        })
    end
    
    -- Auto close
    task.spawn(function()
        while notif.Active and notif.RemainingTime > 0 do
            if not notif.Paused then
                notif.RemainingTime = notif.RemainingTime - 0.1
            end
            task.wait(0.1)
        end
        
        if notif.Active then
            notif:Destroy()
        end
    end)
    
    return notif
end

function NotificationSystem:GetStartPosition()
    local viewport = workspace.CurrentCamera.ViewportSize
    
    if self.Position == "TopRight" then
        return {
            offScreen = UDim2.new(0, viewport.X + 320, 0, 20),
            onScreen = UDim2.new(1, -320, 0, 20)
        }
    elseif self.Position == "TopLeft" then
        return {
            offScreen = UDim2.new(0, -320, 0, 20),
            onScreen = UDim2.new(0, 20, 0, 20)
        }
    elseif self.Position == "BottomRight" then
        return {
            offScreen = UDim2.new(0, viewport.X + 320, 1, -100),
            onScreen = UDim2.new(1, -320, 1, -100)
        }
    else -- BottomLeft
        return {
            offScreen = UDim2.new(0, -320, 1, -100),
            onScreen = UDim2.new(0, 20, 1, -100)
        }
    end
end

function NotificationSystem:UpdatePositions()
    for i, notif in ipairs(self.Active) do
        if notif.Frame and notif.Frame.Parent then
            local targetY = (i - 1) * self.Spacing
            local pos = self.Position:find("Top") and 20 + targetY or -100 - targetY
            
            local targetPos = self.Position:find("Right") and 
                UDim2.new(1, -320, self.Position:find("Top") and 0 or 1, pos) or
                UDim2.new(0, 20, self.Position:find("Top") and 0 or 1, pos)
            
            Utility:Tween(notif.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Position = targetPos
            })
        end
    end
end

function NotificationSystem:ProcessQueue()
    if #self.Queue > 0 and #self.Active < self.MaxVisible then
        local nextNotif = table.remove(self.Queue, 1)
        self:Show(nextNotif)
    end
end

function NotificationSystem:GetIconForType(type)
    local icons = {
        Success = "rbxassetid://90853647693818",
        Error = "rbxassetid://90853647693818",
        Warning = "rbxassetid://140013216202448",
        Info = "rbxassetid://140013216202448"
    }
    return icons[type] or icons.Info
end

-- Main Library
local Library = {
    Version = "3.0",
    Windows = {},
    Config = {
        AnimationSpeed = 1,
        SoundEnabled = false,
        Theme = "Dark"
    }
}

function Library:Init()
    ThemeSystem:SetTheme(self.Config.Theme, false)
    ErrorHandler:Log("Info", "WonderUI v" .. self.Version .. " initialized")
    return self
end

function Library:SetTheme(name)
    return ThemeSystem:SetTheme(name, true)
end

function Library:GetThemes()
    local list = {}
    for name, _ in pairs(ThemeSystem.Themes) do
        table.insert(list, name)
    end
    return list
end

function Library:CreateState(id, initialValue, options)
    return StateManager:Create(id, initialValue, options)
end

function Library:Notify(data)
    return NotificationSystem:Notify(data)
end

function Library:CreateWindow(settings)
    settings = settings or {}
    
    local windowId = HttpService:GenerateGUID(false)
    local title = settings.Title or "WonderUI"
    local size = settings.Size or Vector2.new(450, 550)
    
    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WonderUI_" .. windowId
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not screenGui.Parent then
        screenGui.Parent = PlayerGui
    end
    
    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, size.X, 0, size.Y)
    main.Position = UDim2.new(0.5, -size.X/2, 0.5, -size.Y/2)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.ZIndex = 10
    
    ThemeSystem:Track(main, "BackgroundColor3", "Background")
    Utility:CreateCorner(main, 12)
    Utility:CreateShadow(main, 0.4)
    
    -- Make draggable
    local dragging = false
    local dragStart, startPos
    
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    -- Top Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 11
    topBar.Parent = main
    
    ThemeSystem:Track(topBar, "BackgroundColor3", "BackgroundSecondary")
    
    local topBarCorner = Utility:CreateCorner(topBar, 12)
    
    -- Fix corners
    local fix = Instance.new("Frame")
    fix.Size = UDim2.new(1, 0, 0.5, 0)
    fix.Position = UDim2.new(0, 0, 0.5, 0)
    fix.BorderSizePixel = 0
    fix.ZIndex = 11
    fix.Parent = topBar
    
    ThemeSystem:Track(fix, "BackgroundColor3", "BackgroundSecondary")
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.Size = UDim2.new(1, -140, 1, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 12
    titleLabel.Parent = topBar
    
    ThemeSystem:Track(titleLabel, "TextColor3", "Text")
    
    -- Window Controls
    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Size = UDim2.new(0, 110, 1, 0)
    controls.Position = UDim2.new(1, -115, 0, 0)
    controls.BackgroundTransparency = 1
    controls.ZIndex = 12
    controls.Parent = topBar
    
    local controlsLayout = Instance.new("UIListLayout")
    controlsLayout.FillDirection = Enum.FillDirection.Horizontal
    controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlsLayout.Padding = UDim.new(0, 10)
    controlsLayout.Parent = controls
    
    -- Minimize Button
    local minimized = StateManager:Create(windowId .. "_minimized", false, {
        Persist = settings.PersistState
    })
    
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 32, 0, 32)
    minBtn.Text = "—"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.AutoButtonColor = false
    minBtn.ZIndex = 13
    
    ThemeSystem:Track(minBtn, "BackgroundColor3", "BackgroundTertiary")
    ThemeSystem:Track(minBtn, "TextColor3", "Text")
    Utility:CreateCorner(minBtn, 8)
    
    minBtn.Parent = controls
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Text = "×"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 13
    
    ThemeSystem:Track(closeBtn, "BackgroundColor3", "Error")
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    Utility:CreateCorner(closeBtn, 8)
    
    closeBtn.Parent = controls
    
    -- Content Container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -50)
    content.Position = UDim2.new(0, 0, 0, 50)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = main
    
    -- Tab System
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = content
    
    local tabBarScroll = Instance.new("ScrollingFrame")
    tabBarScroll.Size = UDim2.new(1, -20, 1, 0)
    tabBarScroll.Position = UDim2.new(0, 10, 0, 0)
    tabBarScroll.BackgroundTransparency = 1
    tabBarScroll.ScrollBarThickness = 0
    tabBarScroll.ScrollingDirection = Enum.ScrollingDirection.X
    tabBarScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabBarScroll.Parent = tabBar
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBarScroll
    
    local pages = Instance.new("Frame")
    pages.Name = "Pages"
    pages.Size = UDim2.new(1, 0, 1, -40)
    pages.Position = UDim2.new(0, 0, 0, 40)
    pages.BackgroundTransparency = 1
    pages.Parent = content
    
    -- Window Object
    local Window = {
        Id = windowId,
        Main = main,
        Content = content,
        Tabs = {},
        ActiveTab = nil,
        State = {
            Minimized = minimized,
            Size = StateManager:Create(windowId .. "_size", size, {Persist = settings.PersistState}),
            Position = StateManager:Create(windowId .. "_position", nil, {Persist = settings.PersistState})
        }
    }
    
    -- Minimize functionality
    local originalSize = size
    
    minimized:Subscribe(function(isMinimized)
        if isMinimized then
            -- Store current size
            originalSize = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
            
            -- Animate to minimized
            Utility:Tween(main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0, main.Size.X.Offset, 0, 50)
            })
            content.Visible = false
            minBtn.Text = "+"
        else
            content.Visible = true
            Utility:Tween(main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0, originalSize.X, 0, originalSize.Y)
            })
            minBtn.Text = "—"
        end
    end)
    
    minBtn.MouseButton1Click:Connect(function()
        minimized:Set(not minimized:Get())
    end)
    
    -- Close functionality
    closeBtn.MouseButton1Click:Connect(function()
        Utility:Tween(main, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}, function()
            screenGui:Destroy()
            Library.Windows[windowId] = nil
        end)
    end)
    
    -- Hover effects
    for _, btn in ipairs({minBtn, closeBtn}) do
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = btn == closeBtn and ThemeSystem:GetColor("Error"):lerp(Color3.new(1,1,1), 0.2) or 
                    ThemeSystem:GetColor("Accent")
            }):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = btn == closeBtn and ThemeSystem:GetColor("Error") or 
                    ThemeSystem:GetColor("BackgroundTertiary")
            }):Play()
        end)
    end
    
    -- Tab Creation
    function Window:CreateTab(tabSettings)
        tabSettings = tabSettings or {}
        local tabName = tabSettings.Name or "Tab"
        local tabIcon = tabSettings.Icon
        
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "_Tab"
        tabBtn.Size = UDim2.new(0, tabIcon and 120 or 100, 0, 36)
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 12
        
        ThemeSystem:Track(tabBtn, "BackgroundColor3", "BackgroundTertiary")
        Utility:CreateCorner(tabBtn, 8)
        
        tabBtn.Parent = tabBarScroll
        
        -- Icon
        if tabIcon then
            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0, 18, 0, 18)
            icon.Position = UDim2.new(0, 12, 0.5, -9)
            icon.BackgroundTransparency = 1
            icon.Image = tabIcon
            icon.ZIndex = 13
            icon.Parent = tabBtn
            
            ThemeSystem:Track(icon, "ImageColor3", "Text")
        end
        
        -- Label
        local label = Instance.new("TextLabel")
        label.Text = tabName
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, tabIcon and 36 or 0, 0, 0)
        label.Size = UDim2.new(1, tabIcon and -36 or 0, 1, 0)
        label.ZIndex = 13
        label.Parent = tabBtn
        
        ThemeSystem:Track(label, "TextColor3", "Text")
        
        -- Indicator
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 0, 0, 3)
        indicator.Position = UDim2.new(0.5, 0, 1, -6)
        indicator.AnchorPoint = Vector2.new(0.5, 0)
        indicator.BorderSizePixel = 0
        indicator.ZIndex = 13
        indicator.Parent = tabBtn
        
        ThemeSystem:Track(indicator, "BackgroundColor3", "Accent")
        Utility:CreateCorner(indicator, 1.5)
        
        -- Page
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "_Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.ScrollBarThickness = 4
        page.BackgroundTransparency = 1
        page.Visible = false
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ZIndex = 10
        page.Parent = pages
        
        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingLeft = UDim.new(0, 20)
        pagePadding.PaddingRight = UDim.new(0, 20)
        pagePadding.PaddingTop = UDim.new(0, 15)
        pagePadding.PaddingBottom = UDim.new(0, 15)
        pagePadding.Parent = page
        
        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 12)
        pageLayout.Parent = page
        
        local Tab = {
            Name = tabName,
            Button = tabBtn,
            Page = page,
            Indicator = indicator,
            Elements = {}
        }
        
        table.insert(self.Tabs, Tab)
        
        -- Click handler
        tabBtn.MouseButton1Click:Connect(function()
            self:SelectTab(Tab)
        end)
        
        -- Hover
        tabBtn.MouseEnter:Connect(function()
            if self.ActiveTab ~= Tab then
                TweenService:Create(tabBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary"):lerp(ThemeSystem:GetColor("Accent"), 0.3)
                }):Play()
            end
        end)
        
        tabBtn.MouseLeave:Connect(function()
            if self.ActiveTab ~= Tab then
                TweenService:Create(tabBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
                }):Play()
            end
        end)
        
        -- Auto select first tab
        if #self.Tabs == 1 then
            self:SelectTab(Tab)
        end
        
        -- Element Creation API
        local Elements = {}
        
        function Elements:AddSection(sectionData)
            sectionData = sectionData or {}
            local text = sectionData.Name or "Section"
            
            local section = Instance.new("Frame")
            section.Name = "Section_" .. text
            section.Size = UDim2.new(1, 0, 0, 35)
            section.BackgroundTransparency = 1
            section.Parent = page
            
            local label = Instance.new("TextLabel")
            label.Text = text:upper()
            label.Font = Enum.Font.GothamBold
            label.TextSize = 12
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 0, 25)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = section
            
            ThemeSystem:Track(label, "TextColor3", "Accent")
            
            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 2)
            line.Position = UDim2.new(0, 0, 1, -8)
            line.BorderSizePixel = 0
            line.Parent = section
            
            ThemeSystem:Track(line, "BackgroundColor3", "BackgroundTertiary")
            Utility:CreateCorner(line, 1)
            
            return section
        end
        
        function Elements:AddButton(buttonData)
            buttonData = buttonData or {}
            local text = buttonData.Name or "Button"
            local callback = Utility:ValidateCallback(buttonData.Callback)
            local tooltip = buttonData.Tooltip
            
            local btn = Instance.new("TextButton")
            btn.Name = "Button_" .. text
            btn.Size = UDim2.new(1, 0, 0, 42)
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.ZIndex = 10
            
            ThemeSystem:Track(btn, "BackgroundColor3", "Accent")
            Utility:CreateCorner(btn, 10)
            
            btn.Parent = page
            
            -- Icon
            if buttonData.Icon then
                local icon = Instance.new("ImageLabel")
                icon.Size = UDim2.new(0, 20, 0, 20)
                icon.Position = UDim2.new(0, 15, 0.5, -10)
                icon.BackgroundTransparency = 1
                icon.Image = buttonData.Icon
                icon.ZIndex = 11
                icon.Parent = btn
                
                ThemeSystem:Track(icon, "ImageColor3", "Text")
            end
            
            -- Label
            local label = Instance.new("TextLabel")
            label.Text = text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, buttonData.Icon and 45 or 0, 0, 0)
            label.Size = UDim2.new(1, buttonData.Icon and -45 or 0, 1, 0)
            label.ZIndex = 11
            label.Parent = btn
            
            ThemeSystem:Track(label, "TextColor3", "Text")
            
            -- Ripple effect
            local function createRipple(pos)
                local ripple = Utility:CreateRipple(btn, Color3.new(1, 1, 1))
                ripple.Size = UDim2.new(0, 0, 0, 0)
                ripple.Position = UDim2.new(0, pos.X - btn.AbsolutePosition.X, 0, pos.Y - btn.AbsolutePosition.Y)
                ripple.Parent = btn
                
                local size = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2
                
                Utility:Tween(ripple, TweenInfo.new(0.6), {
                    Size = UDim2.new(0, size, 0, size),
                    Position = UDim2.new(0, pos.X - btn.AbsolutePosition.X - size/2, 0, pos.Y - btn.AbsolutePosition.Y - size/2),
                    BackgroundTransparency = 1
                }, function()
                    ripple:Destroy()
                end)
            end
            
            -- Click handlers
            btn.MouseButton1Down:Connect(function(input)
                createRipple(input)
                
                Utility:Tween(btn, TweenInfo.new(0.1), {
                    Size = UDim2.new(1, -4, 0, 38)
                })
            end)
            
            btn.MouseButton1Up:Connect(function()
                Utility:Tween(btn, TweenInfo.new(0.1), {
                    Size = UDim2.new(1, 0, 0, 42)
                })
            end)
            
            btn.MouseButton1Click:Connect(function()
                local success, err = pcall(callback)
                if not success then
                    ErrorHandler:Log("Error", "Button callback failed: " .. tostring(err))
                    Library:Notify({
                        Title = "Error",
                        Text = "Button action failed",
                        Type = "Error",
                        Duration = 3
                    })
                end
            end)
            
            -- Hover
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("AccentHover")
                }):Play()
                
                if tooltip then
                    -- Show tooltip
                end
            end)
            
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("Accent")
                }):Play()
            end)
            
            return btn
        end
        
        function Elements:AddToggle(toggleData)
            toggleData = toggleData or {}
            local text = toggleData.Name or "Toggle"
            local default = toggleData.Default or false
            local callback = Utility:ValidateCallback(toggleData.Callback)
            
            -- Create state
            local stateId = windowId .. "_" .. tabName .. "_toggle_" .. text
            local state = StateManager:Create(stateId, default, {
                Persist = toggleData.PersistState,
                Validate = function(v) return type(v) == "boolean" end
            })
            
            local holder = Instance.new("Frame")
            holder.Name = "Toggle_" .. text
            holder.Size = UDim2.new(1, 0, 0, 45)
            holder.BorderSizePixel = 0
            holder.ZIndex = 10
            
            ThemeSystem:Track(holder, "BackgroundColor3", "BackgroundSecondary")
            Utility:CreateCorner(holder, 10)
            
            holder.Parent = page
            
            -- Label
            local label = Instance.new("TextLabel")
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 15, 0, 0)
            label.Size = UDim2.new(1, -80, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 11
            label.Parent = holder
            
            ThemeSystem:Track(label, "TextColor3", "Text")
            
            -- Switch background
            local switch = Instance.new("Frame")
            switch.Size = UDim2.new(0, 50, 0, 26)
            switch.Position = UDim2.new(1, -65, 0.5, -13)
            switch.BorderSizePixel = 0
            switch.ZIndex = 11
            switch.Parent = holder
            
            ThemeSystem:Track(switch, "BackgroundColor3", "BackgroundTertiary")
            Utility:CreateCorner(switch, 13)
            
            -- Knob
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 22, 0, 22)
            knob.Position = UDim2.new(0, 2, 0.5, -11)
            knob.BorderSizePixel = 0
            knob.ZIndex = 12
            knob.Parent = switch
            
            ThemeSystem:Track(knob, "BackgroundColor3", "Text")
            Utility:CreateCorner(knob, 11)
            
            -- Update visual state
            local function updateVisual(isEnabled)
                if isEnabled then
                    TweenService:Create(switch, TweenInfo.new(0.3), {
                        BackgroundColor3 = ThemeSystem:GetColor("Accent")
                    }):Play()
                    TweenService:Create(knob, TweenInfo.new(0.3), {
                        Position = UDim2.new(1, -24, 0.5, -11)
                    }):Play()
                else
                    TweenService:Create(switch, TweenInfo.new(0.3), {
                        BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
                    }):Play()
                    TweenService:Create(knob, TweenInfo.new(0.3), {
                        Position = UDim2.new(0, 2, 0.5, -11)
                    }):Play()
                end
            end
            
            -- Initial state
            updateVisual(state:Get())
            
            -- Subscribe to state changes
            state:Subscribe(function(newValue)
                updateVisual(newValue)
                local success, err = pcall(callback, newValue)
                if not success then
                    ErrorHandler:Log("Error", "Toggle callback failed: " .. tostring(err))
                end
            end)
            
            -- Click handler
            holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    state:Toggle()
                end
            end)
            
            -- Hover
            holder.MouseEnter:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
                }):Play()
            end)
            
            holder.MouseLeave:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundSecondary")
                }):Play()
            end)
            
            -- Return API
            return {
                Set = function(v) state:Set(v) end,
                Get = function() return state:Get() end,
                Toggle = function() state:Toggle() end,
                Subscribe = function(cb) return state:Subscribe(cb) end
            }
        end
        
        function Elements:AddSlider(sliderData)
            sliderData = sliderData or {}
            local text = sliderData.Name or "Slider"
            local min = sliderData.Min or 0
            local max = sliderData.Max or 100
            local default = math.clamp(sliderData.Default or min, min, max)
            local increment = sliderData.Increment or 1
            
            -- State
            local stateId = windowId .. "_" .. tabName .. "_slider_" .. text
            local state = StateManager:Create(stateId, default, {
                Persist = sliderData.PersistState,
                Validate = function(v) return type(v) == "number" and v >= min and v <= max end,
                Transform = function(v)
                    if increment > 0 then
                        v = math.floor(v / increment + 0.5) * increment
                    end
                    return math.clamp(v, min, max)
                end
            })
            
            local holder = Instance.new("Frame")
            holder.Name = "Slider_" .. text
            holder.Size = UDim2.new(1, 0, 0, 65)
            holder.BorderSizePixel = 0
            holder.ZIndex = 10
            
            ThemeSystem:Track(holder, "BackgroundColor3", "BackgroundSecondary")
            Utility:CreateCorner(holder, 10)
            
            holder.Parent = page
            
            -- Title with value
            local title = Instance.new("TextLabel")
            title.Text = text .. ": " .. default
            title.Font = Enum.Font.Gotham
            title.TextSize = 14
            title.BackgroundTransparency = 1
            title.Position = UDim2.new(0, 15, 0, 10)
            title.Size = UDim2.new(1, -30, 0, 20)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.ZIndex = 11
            title.Parent = holder
            
            ThemeSystem:Track(title, "TextColor3", "Text")
            
            -- Slider bar background
            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -30, 0, 8)
            barBg.Position = UDim2.new(0, 15, 0, 42)
            barBg.BorderSizePixel = 0
            barBg.ZIndex = 11
            barBg.Parent = holder
            
            ThemeSystem:Track(barBg, "BackgroundColor3", "BackgroundTertiary")
            Utility:CreateCorner(barBg, 4)
            
            -- Fill
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BorderSizePixel = 0
            fill.ZIndex = 12
            fill.Parent = barBg
            
            ThemeSystem:Track(fill, "BackgroundColor3", "Accent")
            Utility:CreateCorner(fill, 4)
            
            -- Knob
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 18, 0, 18)
            knob.Position = UDim2.new(fill.Size.X.Scale, -9, 0.5, -9)
            knob.BorderSizePixel = 0
            knob.ZIndex = 13
            knob.Parent = barBg
            
            ThemeSystem:Track(knob, "BackgroundColor3", "Text")
            Utility:CreateCorner(knob, 9)
            
            -- Dragging logic
            local dragging = false
            
            local function updateFromInput(input)
                local pos = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                local value = min + (max - min) * pos
                state:Set(value)
            end
            
            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromInput(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            
            -- Subscribe to changes
            state:Subscribe(function(value)
                local scale = (value - min) / (max - min)
                fill.Size = UDim2.new(scale, 0, 1, 0)
                knob.Position = UDim2.new(scale, -9, 0.5, -9)
                title.Text = text .. ": " .. Utility:FormatNumber(value)
                
                if sliderData.Callback then
                    local success, err = pcall(sliderData.Callback, value)
                    if not success then
                        ErrorHandler:Log("Error", "Slider callback failed: " .. tostring(err))
                    end
                end
            end)
            
            -- Hover
            holder.MouseEnter:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
                }):Play()
            end)
            
            holder.MouseLeave:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundSecondary")
                }):Play()
            end)
            
            return {
                Set = function(v) state:Set(v) end,
                Get = function() return state:Get() end,
                Subscribe = function(cb) return state:Subscribe(cb) end
            }
        end
        
        function Elements:AddDropdown(dropdownData)
            dropdownData = dropdownData or {}
            local text = dropdownData.Name or "Dropdown"
            local options = dropdownData.Options or {}
            local multi = dropdownData.Multi or false
            
            -- State
            local stateId = windowId .. "_" .. tabName .. "_dropdown_" .. text
            local default = multi and (dropdownData.Default or {}) or (dropdownData.Default or options[1])
            local state = StateManager:Create(stateId, default, {
                Persist = dropdownData.PersistState
            })
            
            local holder = Instance.new("Frame")
            holder.Name = "Dropdown_" .. text
            holder.Size = UDim2.new(1, 0, 0, 45)
            holder.BorderSizePixel = 0
            holder.ZIndex = 15
            holder.ClipsDescendants = false
            
            ThemeSystem:Track(holder, "BackgroundColor3", "BackgroundSecondary")
            Utility:CreateCorner(holder, 10)
            
            holder.Parent = page
            
            -- Label
            local label = Instance.new("TextLabel")
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 15, 0, 0)
            label.Size = UDim2.new(1, -30, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 16
            label.Parent = holder
            
            ThemeSystem:Track(label, "TextColor3", "Text")
            
            -- Selected text
            local selected = Instance.new("TextLabel")
            selected.Text = multi and (#default > 0 and table.concat(default, ", ") or "Select...") or tostring(default)
            selected.Font = Enum.Font.GothamBold
            selected.TextSize = 13
            selected.BackgroundTransparency = 1
            selected.Position = UDim2.new(0, 0, 0, 0)
            selected.Size = UDim2.new(1, -50, 1, 0)
            selected.TextXAlignment = Enum.TextXAlignment.Right
            selected.ZIndex = 16
            selected.Parent = holder
            
            ThemeSystem:Track(selected, "TextColor3", "Accent")
            
            -- Arrow
            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.new(0, 20, 0, 20)
            arrow.Position = UDim2.new(1, -35, 0.5, -10)
            arrow.BackgroundTransparency = 1
            arrow.Image = "rbxassetid://138740476585338"
            arrow.Rotation = 0
            arrow.ZIndex = 16
            arrow.Parent = holder
            
            ThemeSystem:Track(arrow, "ImageColor3", "TextSecondary")
            
            -- Dropdown list
            local list = Instance.new("Frame")
            list.Name = "List"
            list.Position = UDim2.new(0, 0, 1, 5)
            list.Size = UDim2.new(1, 0, 0, 0)
            list.BorderSizePixel = 0
            list.Visible = false
            list.ClipsDescendants = true
            list.ZIndex = 20
            list.Parent = holder
            
            ThemeSystem:Track(list, "BackgroundColor3", "BackgroundTertiary")
            Utility:CreateCorner(list, 10)
            
            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 2)
            listLayout.Parent = list
            
            local listPadding = Instance.new("UIPadding")
            listPadding.PaddingTop = UDim.new(0, 5)
            listPadding.PaddingBottom = UDim.new(0, 5)
            listPadding.PaddingLeft = UDim.new(0, 5)
            listPadding.PaddingRight = UDim.new(0, 5)
            listPadding.Parent = list
            
            -- Search box (if many options)
            local searchBox
            if #options > 8 or dropdownData.Searchable then
                searchBox = Instance.new("TextBox")
                searchBox.Size = UDim2.new(1, -10, 0, 32)
                searchBox.PlaceholderText = "Search..."
                searchBox.Font = Enum.Font.Gotham
                searchBox.TextSize = 13
                searchBox.ClearTextOnFocus = false
                searchBox.ZIndex = 21
                searchBox.Parent = list
                
                ThemeSystem:Track(searchBox, "BackgroundColor3", "Background")
                ThemeSystem:Track(searchBox, "TextColor3", "Text")
                ThemeSystem:Track(searchBox, "PlaceholderColor3", "TextDisabled")
                Utility:CreateCorner(searchBox, 6)
            end
            
            -- Options container
            local optionsScroll = Instance.new("ScrollingFrame")
            optionsScroll.Size = UDim2.new(1, 0, 1, searchBox and -42 or 0)
            optionsScroll.Position = UDim2.new(0, 0, 0, searchBox and 42 or 0)
            optionsScroll.BackgroundTransparency = 1
            optionsScroll.ScrollBarThickness = 3
            optionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            optionsScroll.ZIndex = 21
            optionsScroll.Parent = list
            
            local optionsLayout = Instance.new("UIListLayout")
            optionsLayout.Padding = UDim.new(0, 2)
            optionsLayout.Parent = optionsScroll
            
            local optionButtons = {}
            local opened = false
            
            local function createOption(option)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 34)
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.ZIndex = 22
                
                ThemeSystem:Track(btn, "BackgroundColor3", "BackgroundSecondary")
                Utility:CreateCorner(btn, 6)
                
                -- Checkbox for multi-select
                local check = Instance.new("Frame")
                check.Size = UDim2.new(0, 20, 0, 20)
                check.Position = UDim2.new(0, 10, 0.5, -10)
                check.BorderSizePixel = 0
                check.ZIndex = 23
                check.Parent = btn
                
                ThemeSystem:Track(check, "BackgroundColor3", "Background")
                Utility:CreateCorner(check, 4)
                
                local isSelected = false
                if multi then
                    isSelected = table.find(state:Get(), option) ~= nil
                else
                    isSelected = state:Get() == option
                end
                
                if isSelected then
                    check.BackgroundColor3 = ThemeSystem:GetColor("Accent")
                    local checkmark = Instance.new("ImageLabel")
                    checkmark.Size = UDim2.new(0.7, 0, 0.7, 0)
                    checkmark.Position = UDim2.new(0.15, 0, 0.15, 0)
                    checkmark.BackgroundTransparency = 1
                    checkmark.Image = "rbxassetid://90853647693818"
                    checkmark.ImageColor3 = Color3.new(1, 1, 1)
                    checkmark.ZIndex = 24
                    checkmark.Parent = check
                end
                
                local lbl = Instance.new("TextLabel")
                lbl.Text = option
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 13
                lbl.BackgroundTransparency = 1
                lbl.Position = UDim2.new(0, 40, 0, 0)
                lbl.Size = UDim2.new(1, -50, 1, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 23
                lbl.Parent = btn
                
                ThemeSystem:Track(lbl, "TextColor3", "Text")
                
                btn.MouseButton1Click:Connect(function()
                    if multi then
                        local current = state:Get()
                        local idx = table.find(current, option)
                        
                        if idx then
                            table.remove(current, idx)
                            check.BackgroundColor3 = ThemeSystem:GetColor("Background")
                            for _, child in ipairs(check:GetChildren()) do
                                child:Destroy()
                            end
                        else
                            table.insert(current, option)
                            check.BackgroundColor3 = ThemeSystem:GetColor("Accent")
                            local checkmark = Instance.new("ImageLabel")
                            checkmark.Size = UDim2.new(0.7, 0, 0.7, 0)
                            checkmark.Position = UDim2.new(0.15, 0, 0.15, 0)
                            checkmark.BackgroundTransparency = 1
                            checkmark.Image = "rbxassetid://90853647693818"
                            checkmark.ImageColor3 = Color3.new(1, 1, 1)
                            checkmark.ZIndex = 24
                            checkmark.Parent = check
                        end
                        
                        state:Set(current)
                    else
                        state:Set(option)
                        
                        -- Close dropdown
                        opened = false
                        Utility:Tween(list, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)})
                        Utility:Tween(arrow, TweenInfo.new(0.2), {Rotation = 0})
                        task.delay(0.2, function()
                            list.Visible = false
                        end)
                    end
                end)
                
                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {
                        BackgroundColor3 = ThemeSystem:GetColor("Accent")
                    }):Play()
                end)
                
                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {
                        BackgroundColor3 = ThemeSystem:GetColor("BackgroundSecondary")
                    }):Play()
                end)
                
                table.insert(optionButtons, {Button = btn, Option = option})
                return btn
            end
            
            for _, opt in ipairs(options) do
                createOption(opt).Parent = optionsScroll
            end
            
            -- Search functionality
            if searchBox then
                searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local search = searchBox.Text:lower()
                    for _, data in ipairs(optionButtons) do
                        local visible = data.Option:lower():find(search) ~= nil
                        data.Button.Visible = visible
                    end
                end)
            end
            
            -- Toggle dropdown
            holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    -- Check if click was on list
                    if list.Visible then
                        local pos = input.Position
                        local listPos = list.AbsolutePosition
                        local listSize = list.AbsoluteSize
                        
                        if pos.X >= listPos.X and pos.X <= listPos.X + listSize.X and
                           pos.Y >= listPos.Y and pos.Y <= listPos.Y + listSize.Y then
                            return
                        end
                    end
                    
                    opened = not opened
                    
                    if opened then
                        list.Visible = true
                        local targetHeight = math.min(#options * 36 + (searchBox and 42 or 10) + 10, 250)
                        Utility:Tween(list, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, targetHeight)})
                        Utility:Tween(arrow, TweenInfo.new(0.25), {Rotation = 180})
                    else
                        Utility:Tween(list, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, 0)})
                        Utility:Tween(arrow, TweenInfo.new(0.25), {Rotation = 0})
                        task.delay(0.25, function()
                            if not opened then
                                list.Visible = false
                            end
                        end)
                    end
                end
            end)
            
            -- Update selected text
            state:Subscribe(function(value)
                if multi then
                    local text = #value > 0 and table.concat(value, ", ") or "Select..."
                    if #text > 25 then
                        text = text:sub(1, 22) .. "..."
                    end
                    selected.Text = text
                else
                    selected.Text = tostring(value)
                end
                
                if dropdownData.Callback then
                    local success, err = pcall(dropdownData.Callback, value)
                    if not success then
                        ErrorHandler:Log("Error", "Dropdown callback failed: " .. tostring(err))
                    end
                end
            end)
            
            -- Hover
            holder.MouseEnter:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
                }):Play()
            end)
            
            holder.MouseLeave:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundSecondary")
                }):Play()
            end)
            
            return {
                Set = function(v) state:Set(v) end,
                Get = function() return state:Get() end,
                Subscribe = function(cb) return state:Subscribe(cb) end,
                Refresh = function(newOptions)
                    for _, data in ipairs(optionButtons) do
                        data.Button:Destroy()
                    end
                    optionButtons = {}
                    
                    for _, opt in ipairs(newOptions) do
                        createOption(opt).Parent = optionsScroll
                    end
                end
            }
        end
        
        function Elements:AddInput(inputData)
            inputData = inputData or {}
            local text = inputData.Name or "Input"
            local placeholder = inputData.Placeholder or "Enter text..."
            local numeric = inputData.Numeric or false
            
            -- State
            local stateId = windowId .. "_" .. tabName .. "_input_" .. text
            local state = StateManager:Create(stateId, inputData.Default or "", {
                Persist = inputData.PersistState,
                Validate = function(v)
                    if numeric then
                        return tonumber(v) ~= nil
                    end
                    return type(v) == "string"
                end
            })
            
            local holder = Instance.new("Frame")
            holder.Name = "Input_" .. text
            holder.Size = UDim2.new(1, 0, 0, 75)
            holder.BorderSizePixel = 0
            holder.ZIndex = 10
            
            ThemeSystem:Track(holder, "BackgroundColor3", "BackgroundSecondary")
            Utility:CreateCorner(holder, 10)
            
            holder.Parent = page
            
            -- Label
            local label = Instance.new("TextLabel")
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 15, 0, 10)
            label.Size = UDim2.new(1, -30, 0, 20)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 11
            label.Parent = holder
            
            ThemeSystem:Track(label, "TextColor3", "Text")
            
            -- Input box
            local box = Instance.new("TextBox")
            box.Text = state:Get()
            box.PlaceholderText = placeholder
            box.Font = Enum.Font.Gotham
            box.TextSize = 14
            box.ClearTextOnFocus = false
            box.Position = UDim2.new(0, 15, 0, 35)
            box.Size = UDim2.new(1, -30, 0, 32)
            box.ZIndex = 11
            box.Parent = holder
            
            ThemeSystem:Track(box, "BackgroundColor3", "Background")
            ThemeSystem:Track(box, "TextColor3", "Text")
            ThemeSystem:Track(box, "PlaceholderColor3", "TextDisabled")
            Utility:CreateCorner(box, 8)
            
            -- Padding
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 12)
            padding.PaddingRight = UDim.new(0, 12)
            padding.Parent = box
            
            -- Numeric validation
            if numeric then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    local newText = box.Text
                    if newText ~= "" and not newText:match("^%-?%d*%.?%d*$") then
                        box.Text = newText:gsub("[^%-%d.]", "")
                        local _, count = box.Text:gsub("%.", ".")
                        if count > 1 then
                            box.Text = box.Text:sub(1, #box.Text - 1)
                        end
                    end
                end)
            end
            
            -- Focus effects
            box.Focused:Connect(function()
                TweenService:Create(box, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
                }):Play()
            end)
            
            box.FocusLost:Connect(function(enterPressed)
                TweenService:Create(box, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("Background")
                }):Play()
                
                local value = box.Text
                if numeric then
                    value = tonumber(value) or 0
                end
                
                state:Set(value)
            end)
            
            -- Subscribe to state
            state:Subscribe(function(value)
                if box.Text ~= tostring(value) then
                    box.Text = tostring(value)
                end
                
                if inputData.Callback then
                    local success, err = pcall(inputData.Callback, value)
                    if not success then
                        ErrorHandler:Log("Error", "Input callback failed: " .. tostring(err))
                    end
                end
            end)
            
            -- Hover
            holder.MouseEnter:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
                }):Play()
            end)
            
            holder.MouseLeave:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundSecondary")
                }):Play()
            end)
            
            return {
                Set = function(v) state:Set(v) end,
                Get = function() return state:Get() end,
                Focus = function() box:CaptureFocus() end,
                Subscribe = function(cb) return state:Subscribe(cb) end
            }
        end
        
        function Elements:AddKeybind(keybindData)
            keybindData = keybindData or {}
            local text = keybindData.Name or "Keybind"
            
            -- State
            local stateId = windowId .. "_" .. tabName .. "_keybind_" .. text
            local state = StateManager:Create(stateId, keybindData.Default, {
                Persist = keybindData.PersistState
            })
            
            local holder = Instance.new("Frame")
            holder.Name = "Keybind_" .. text
            holder.Size = UDim2.new(1, 0, 0, 45)
            holder.BorderSizePixel = 0
            holder.ZIndex = 10
            
            ThemeSystem:Track(holder, "BackgroundColor3", "BackgroundSecondary")
            Utility:CreateCorner(holder, 10)
            
            holder.Parent = page
            
            -- Label
            local label = Instance.new("TextLabel")
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 15, 0, 0)
            label.Size = UDim2.new(1, -110, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 11
            label.Parent = holder
            
            ThemeSystem:Track(label, "TextColor3", "Text")
            
            -- Key button
            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0, 80, 0, 32)
            keyBtn.Position = UDim2.new(1, -95, 0.5, -16)
            keyBtn.Text = state:Get() and state:Get().Name or "None"
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.TextSize = 12
            keyBtn.AutoButtonColor = false
            keyBtn.ZIndex = 11
            keyBtn.Parent = holder
            
            ThemeSystem:Track(keyBtn, "BackgroundColor3", "Background")
            ThemeSystem:Track(keyBtn, "TextColor3", "Accent")
            Utility:CreateCorner(keyBtn, 8)
            
            local listening = false
            
            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode ~= Enum.KeyCode.Escape then
                            state:Set(input.KeyCode)
                        else
                            keyBtn.Text = state:Get() and state:Get().Name or "None"
                        end
                        listening = false
                        connection:Disconnect()
                    end
                end)
            end)
            
            -- Global keybind
            UserInputService.InputBegan:Connect(function(input)
                if not listening and state:Get() and input.KeyCode == state:Get() then
                    if keybindData.Callback then
                        local success, err = pcall(keybindData.Callback, state:Get(), true)
                        if not success then
                            ErrorHandler:Log("Error", "Keybind callback failed: " .. tostring(err))
                        end
                    end
                end
            end)
            
            -- Update display
            state:Subscribe(function(key)
                keyBtn.Text = key and key.Name or "None"
            end)
            
            -- Hover
            holder.MouseEnter:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
                }):Play()
            end)
            
            holder.MouseLeave:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundSecondary")
                }):Play()
            end)
            
            return {
                Set = function(v) state:Set(v) end,
                Get = function() return state:Get() end,
                Subscribe = function(cb) return state:Subscribe(cb) end
            }
        end
        
        function Elements:AddColorPicker(colorData)
            colorData = colorData or {}
            local text = colorData.Name or "Color"
            
            -- State
            local stateId = windowId .. "_" .. tabName .. "_color_" .. text
            local state = StateManager:Create(stateId, colorData.Default or Color3.fromRGB(255, 255, 255), {
                Persist = colorData.PersistState
            })
            
            local holder = Instance.new("Frame")
            holder.Name = "Color_" .. text
            holder.Size = UDim2.new(1, 0, 0, 45)
            holder.BorderSizePixel = 0
            holder.ZIndex = 15
            holder.ClipsDescendants = false
            
            ThemeSystem:Track(holder, "BackgroundColor3", "BackgroundSecondary")
            Utility:CreateCorner(holder, 10)
            
            holder.Parent = page
            
            -- Label
            local label = Instance.new("TextLabel")
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 15, 0, 0)
            label.Size = UDim2.new(1, -70, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 16
            label.Parent = holder
            
            ThemeSystem:Track(label, "TextColor3", "Text")
            
            -- Color display
            local colorBtn = Instance.new("TextButton")
            colorBtn.Size = UDim2.new(0, 40, 0, 28)
            colorBtn.Position = UDim2.new(1, -55, 0.5, -14)
            colorBtn.Text = ""
            colorBtn.AutoButtonColor = false
            colorBtn.ZIndex = 16
            colorBtn.Parent = holder
            
            Utility:CreateCorner(colorBtn, 6)
            Utility:CreateStroke(colorBtn, nil, 2, "Border")
            
            -- Color picker popup (simplified)
            local picker = Instance.new("Frame")
            picker.Name = "Picker"
            picker.Position = UDim2.new(1, -210, 1, 5)
            picker.Size = UDim2.new(0, 200, 0, 0)
            picker.BorderSizePixel = 0
            picker.Visible = false
            picker.ClipsDescendants = true
            picker.ZIndex = 20
            picker.Parent = holder
            
            ThemeSystem:Track(picker, "BackgroundColor3", "BackgroundTertiary")
            Utility:CreateCorner(picker, 10)
            
            local opened = false
            
            colorBtn.MouseButton1Click:Connect(function()
                opened = not opened
                
                if opened then
                    picker.Visible = true
                    Utility:Tween(picker, TweenInfo.new(0.25), {Size = UDim2.new(0, 200, 0, 200)})
                else
                    Utility:Tween(picker, TweenInfo.new(0.25), {Size = UDim2.new(0, 200, 0, 0)})
                    task.delay(0.25, function()
                        if not opened then
                            picker.Visible = false
                        end
                    end)
                end
            end)
            
            -- Update color
            state:Subscribe(function(color)
                colorBtn.BackgroundColor3 = color
                
                if colorData.Callback then
                    local success, err = pcall(colorData.Callback, color)
                    if not success then
                        ErrorHandler:Log("Error", "Color picker callback failed: " .. tostring(err))
                    end
                end
            end)
            
            -- Initial color
            colorBtn.BackgroundColor3 = state:Get()
            
            -- Hover
            holder.MouseEnter:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
                }):Play()
            end)
            
            holder.MouseLeave:Connect(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    BackgroundColor3 = ThemeSystem:GetColor("BackgroundSecondary")
                }):Play()
            end)
            
            return {
                Set = function(v) state:Set(v) end,
                Get = function() return state:Get() end,
                Subscribe = function(cb) return state:Subscribe(cb) end
            }
        end
        
        function Elements:AddLabel(labelData)
            labelData = labelData or {}
            local text = labelData.Text or "Label"
            
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 30)
            holder.BackgroundTransparency = 1
            holder.Parent = page
            
            local lbl = Instance.new("TextLabel")
            lbl.Text = text
            lbl.Font = labelData.Bold and Enum.Font.GothamBold or Enum.Font.Gotham
            lbl.TextSize = labelData.Size or 14
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.TextXAlignment = labelData.Alignment or Enum.TextXAlignment.Left
            lbl.TextWrapped = true
            lbl.Parent = holder
            
            ThemeSystem:Track(lbl, "TextColor3", labelData.Color or "Text")
            
            holder.AutomaticSize = Enum.AutomaticSize.Y
            
            return {
                SetText = function(t) lbl.Text = t end,
                SetColor = function(c) 
                    if ThemeSystem.Themes[ThemeSystem.CurrentTheme][c] then
                        lbl.TextColor3 = ThemeSystem:GetColor(c)
                    else
                        lbl.TextColor3 = c
                    end
                end
            }
        end
        
        return Elements
    end
    
    function Window:SelectTab(tab)
        if self.ActiveTab == tab then return end
        
        -- Deselect current
        if self.ActiveTab then
            TweenService:Create(self.ActiveTab.Button, TweenInfo.new(0.2), {
                BackgroundColor3 = ThemeSystem:GetColor("BackgroundTertiary")
            }):Play()
            TweenService:Create(self.ActiveTab.Indicator, TweenInfo.new(0.2), {
                Size = UDim2.new(0, 0, 0, 3)
            }):Play()
            self.ActiveTab.Page.Visible = false
        end
        
        -- Select new
        self.ActiveTab = tab
        TweenService:Create(tab.Button, TweenInfo.new(0.2), {
            BackgroundColor3 = ThemeSystem:GetColor("Accent")
        }):Play()
        TweenService:Create(tab.Indicator, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0.6, 0, 0, 3)
        }):Play()
        tab.Page.Visible = true
        
        -- Animate content
        tab.Page.CanvasPosition = Vector2.new(0, 0)
    end
    
    function Window:Notify(data)
        return NotificationSystem:Notify(data)
    end
    
    function Window:SetTheme(name)
        return ThemeSystem:SetTheme(name, true)
    end
    
    function Window:GetState(id)
        return StateManager:Get(windowId .. "_" .. id)
    end
    
    function Window:SetState(id, value)
        return StateManager:Set(windowId .. "_" .. id, value)
    end
    
    function Window:Destroy()
        screenGui:Destroy()
        Library.Windows[windowId] = nil
    end
    
    Library.Windows[windowId] = Window
    
    return Window
end

-- Global functions
function Library:Notify(data)
    return NotificationSystem:Notify(data)
end

function Library:SetTheme(name)
    return ThemeSystem:SetTheme(name, true)
end

function Library:GetTheme()
    return ThemeSystem.CurrentTheme
end

function Library:GetThemes()
    local list = {}
    for name, _ in pairs(ThemeSystem.Themes) do
        table.insert(list, name)
    end
    return list
end

function Library:CreateState(id, initialValue, options)
    return StateManager:Create(id, initialValue, options)
end

function Library:GetLogs(level)
    if level then
        local filtered = {}
        for _, log in ipairs(ErrorHandler.Logs) do
            if log.Level == level then
                table.insert(filtered, log)
            end
        end
        return filtered
    end
    return ErrorHandler.Logs
end

function Library:ExportLogs()
    return HttpService:JSONEncode(ErrorHandler.Logs)
end

function Library:SaveConfig(name, data)
    if not writefile then
        ErrorHandler:Log("Warn", "writefile not available")
        return false
    end
    
    local success, err = pcall(function()
        writefile("WonderUI_Configs/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    
    if not success then
        ErrorHandler:Log("Error", "Failed to save config: " .. tostring(err))
        return false
    end
    
    return true
end

function Library:LoadConfig(name)
    if not readfile or not isfile then
        ErrorHandler:Log("Warn", "readfile not available")
        return nil
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile("WonderUI_Configs/" .. name .. ".json"))
    end)
    
    if not success then
        ErrorHandler:Log("Error", "Failed to load config: " .. tostring(data))
        return nil
    end
    
    return data
end

-- Initialize
return Library:Init()