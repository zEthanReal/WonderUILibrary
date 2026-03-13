--// Modern iOS Inspired UI Library
--// Fixed & Optimized

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Library = {}
Library.Flags = {}
Library.Elements = {}

local Theme = {
    Background = Color3.fromRGB(18, 18, 22),
    Container = Color3.fromRGB(28, 28, 35),
    Accent = Color3.fromRGB(90, 140, 255),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(200, 200, 200)
}

--// Tween Helper
local function Tween(obj, props, duration)
    TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

--// Notification System
function Library:Notify(data)
    if not Library.NotificationHolder then
        local holder = Instance.new("ScreenGui")
        holder.Name = "Notifications"
        holder.Parent = PlayerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 1, 0)
        frame.Position = UDim2.new(1, -320, 0, 20)
        frame.BackgroundTransparency = 1
        frame.Parent = holder

        local layout = Instance.new("UIListLayout", frame)
        layout.Padding = UDim.new(0, 10)
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

        Library.NotificationHolder = frame
    end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 70)
    notif.BackgroundColor3 = Theme.Container
    notif.Parent = Library.NotificationHolder
    notif.BackgroundTransparency = 1
    notif.ClipsDescendants = true

    local corner = Instance.new("UICorner", notif)
    corner.CornerRadius = UDim.new(0, 12)

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Image = data.Icon or ""
    icon.Parent = notif

    local title = Instance.new("TextLabel")
    title.Text = data.Title
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Theme.Text
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 60, 0, 8)
    title.Size = UDim2.new(1, -70, 0, 20)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notif

    local desc = Instance.new("TextLabel")
    desc.Text = data.Description
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextColor3 = Theme.SubText
    desc.BackgroundTransparency = 1
    desc.Position = UDim2.new(0, 60, 0, 30)
    desc.Size = UDim2.new(1, -70, 0, 20)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = notif

    Tween(notif, {BackgroundTransparency = 0}, 0.25)

    task.delay(data.Duration or 4, function()
        Tween(notif, {BackgroundTransparency = 1}, 0.25)
        task.wait(0.3)
        notif:Destroy()
    end)
end

--// Config System
local ConfigFolder = "UILibraryConfigs"

function Library:SaveConfig(name)
    if not writefile then return end

    if not isfolder(ConfigFolder) then
        makefolder(ConfigFolder)
    end

    local data = HttpService:JSONEncode(Library.Flags)
    writefile(ConfigFolder .. "/" .. name .. ".json", data)

    Library:Notify({
        Title = "Config Saved",
        Description = name .. " stored successfully",
        Duration = 3
    })
end

function Library:LoadConfig(name)
    if not readfile then return end

    local path = ConfigFolder .. "/" .. name .. ".json"
    if not isfile(path) then return end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if success and data then
        for flag, value in pairs(data) do
            if Library.Elements[flag] then
                Library.Elements[flag]:Set(value)
            end
        end

        Library:Notify({
            Title = "Config Loaded",
            Description = name .. " applied",
            Duration = 3
        })
    end
end

--// Create Window
function Library:CreateWindow(settings)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = PlayerGui
    ScreenGui.ResetOnSpawn = false

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 420, 0, 420)
    Main.Position = UDim2.new(0.5, -210, 0.5, -210)
    Main.BackgroundColor3 = Theme.Background
    Main.ClipsDescendants = true -- Important for minimize animation
    Main.Parent = ScreenGui

    local corner = Instance.new("UICorner", Main)
    corner.CornerRadius = UDim.new(0, 14)

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundTransparency = 1
    TitleBar.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Text = settings.Title or "Window"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextColor3 = Theme.Text
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 30, 0, 30)
    Close.Position = UDim2.new(1, -35, 0.5, -15)
    Close.Text = "X"
    Close.Font = Enum.Font.GothamBold
    Close.TextColor3 = Color3.new(1, 1, 1)
    Close.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    Close.Parent = TitleBar
    Instance.new("UICorner", Close).CornerRadius = UDim.new(1, 0)

    local Min = Instance.new("TextButton")
    Min.Size = UDim2.new(0, 30, 0, 30)
    Min.Position = UDim2.new(1, -70, 0.5, -15)
    Min.Text = "-"
    Min.Font = Enum.Font.GothamBold
    Min.TextColor3 = Color3.new(1, 1, 1)
    Min.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Min.Parent = TitleBar
    Instance.new("UICorner", Min).CornerRadius = UDim.new(1, 0)

    local Container = Instance.new("ScrollingFrame")
    Container.Size = UDim2.new(1, -20, 1, -60)
    Container.Position = UDim2.new(0, 10, 0, 50)
    Container.BackgroundTransparency = 1
    Container.ScrollBarThickness = 2
    Container.Parent = Main

    local Layout = Instance.new("UIListLayout", Container)
    Layout.Padding = UDim.new(0, 10)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    --// Dragging Logic
    local dragging, dragInput, dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    --// Window Controls
    Close.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local minimized = false
    Min.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(Main, {Size = UDim2.new(0, 420, 0, 40)}, 0.25)
        else
            Tween(Main, {Size = UDim2.new(0, 420, 0, 420)}, 0.25)
        end
    end)

    local Window = {}

    --// Element Base
    function Window:CreateElement(name)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 50)
        holder.BackgroundColor3 = Theme.Container
        holder.Parent = Container

        Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 10)

        local label = Instance.new("TextLabel")
        label.Text = name
        label.Font = Enum.Font.Gotham
        label.TextSize = 15
        label.TextColor3 = Theme.Text
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 12, 0, 0)
        label.Size = UDim2.new(1, -20, 1, 0)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = holder

        -- Update canvas size automatically
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
        end)

        return holder, label
    end

    --// Toggle
    function Window:AddToggle(data)
        local holder, label = Window:CreateElement(data.Name)

        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(0, 45, 0, 22)
        toggle.Position = UDim2.new(1, -55, 0.5, -11)
        toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        toggle.Parent = holder
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = UDim2.new(0, 2, 0.5, -9)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Parent = toggle
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = data.Default or false
        Library.Flags[data.Name] = state

        local function set(val)
            state = val
            Library.Flags[data.Name] = val

            if val then
                Tween(toggle, {BackgroundColor3 = Theme.Accent}, 0.2)
                Tween(knob, {Position = UDim2.new(1, -20, 0.5, -9)}, 0.2)
            else
                Tween(toggle, {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}, 0.2)
                Tween(knob, {Position = UDim2.new(0, 2, 0.5, -9)}, 0.2)
            end

            if data.Callback then
                data.Callback(val)
            end
        end

        set(state)

        holder.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                set(not state)
            end
        end)

        Library.Elements[data.Name] = {Set = set}
    end

    --// Button
    function Window:AddButton(data)
        local holder, label = Window:CreateElement(data.Name)

        holder.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                Tween(holder, {BackgroundColor3 = Theme.Accent}, 0.1)
                task.wait(0.1)
                Tween(holder, {BackgroundColor3 = Theme.Container}, 0.1)
                
                if data.Callback then
                    data.Callback()
                end
            end
        end)
    end

    --// Textbox
    function Window:AddTextbox(data)
        local holder, label = Window:CreateElement(data.Name)

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 140, 0, 26)
        box.Position = UDim2.new(1, -150, 0.5, -13)
        box.PlaceholderText = data.Placeholder or "Enter..."
        box.Text = ""
        box.TextColor3 = Theme.Text
        box.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        box.Parent = holder
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

        box.FocusLost:Connect(function()
            Library.Flags[data.Name] = box.Text
            if data.Callback then
                data.Callback(box.Text)
            end
        end)

        Library.Elements[data.Name] = {
            Set = function(v)
                box.Text = v
                Library.Flags[data.Name] = v
            end
        }
    end
    --// Slider
    function Window:AddSlider(data)
        local holder, label = Window:CreateElement(data.Name)

        local min = data.Min or 0
        local max = data.Max or 100
        local default = data.Default or min

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 40, 0, 20)
        valueLabel.Position = UDim2.new(1, -50, 0, 15)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = Theme.SubText
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextSize = 14
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = holder

        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(1, -24, 0, 6)
        sliderBg.Position = UDim2.new(0, 12, 1, -15)
        sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        sliderBg.Parent = holder
        Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Theme.Accent
        sliderFill.Parent = sliderBg
        Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

        Library.Flags[data.Name] = default

        local dragging = false

        local function updateSlider(input)
            local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + ((max - min) * pos))
            
            Tween(sliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1)
            valueLabel.Text = tostring(value)
            Library.Flags[data.Name] = value

            if data.Callback then
                data.Callback(value)
            end
        end

        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input)
            end
        end)

        Library.Elements[data.Name] = {
            Set = function(v)
                local pos = math.clamp((v - min) / (max - min), 0, 1)
                Tween(sliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1)
                valueLabel.Text = tostring(v)
                Library.Flags[data.Name] = v
            end
        }
    end

    --// Dropdown
    function Window:AddDropdown(data)
        local holder, label = Window:CreateElement(data.Name)
        holder.ClipsDescendants = true
        
        local open = false
        local options = data.Options or {}
        local selected = data.Default or options[1] or "None"

        local mainBtn = Instance.new("TextButton")
        mainBtn.Size = UDim2.new(0, 140, 0, 26)
        mainBtn.Position = UDim2.new(1, -150, 0, 12)
        mainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        mainBtn.Text = selected
        mainBtn.TextColor3 = Theme.Text
        mainBtn.Font = Enum.Font.Gotham
        mainBtn.TextSize = 13
        mainBtn.Parent = holder
        Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 8)

        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 20, 0, 20)
        arrow.Position = UDim2.new(1, -25, 0.5, -10)
        arrow.BackgroundTransparency = 1
        arrow.Text = "v"
        arrow.TextColor3 = Theme.SubText
        arrow.Font = Enum.Font.GothamBold
        arrow.Parent = mainBtn

        local optionContainer = Instance.new("Frame")
        optionContainer.Size = UDim2.new(1, -24, 0, 0)
        optionContainer.Position = UDim2.new(0, 12, 0, 50)
        optionContainer.BackgroundTransparency = 1
        optionContainer.Parent = holder

        local listLayout = Instance.new("UIListLayout", optionContainer)
        listLayout.Padding = UDim.new(0, 4)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        Library.Flags[data.Name] = selected

        local function toggleDropdown()
            open = not open
            local containerHeight = listLayout.AbsoluteContentSize.Y
            local targetHeight = open and (50 + containerHeight + 10) or 50

            Tween(holder, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.25)
            Tween(arrow, {Rotation = open and 180 or 0}, 0.25)
        end

        mainBtn.MouseButton1Click:Connect(toggleDropdown)

        local function createOption(optName)
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 26)
            optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            optBtn.Text = "  " .. optName
            optBtn.TextColor3 = Theme.SubText
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 13
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.Parent = optionContainer
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 6)

            optBtn.MouseButton1Click:Connect(function()
                selected = optName
                mainBtn.Text = selected
                Library.Flags[data.Name] = selected
                toggleDropdown()

                if data.Callback then
                    data.Callback(selected)
                end
            end)
        end

        for _, opt in ipairs(options) do
            createOption(opt)
        end

        Library.Elements[data.Name] = {
            Set = function(v)
                selected = v
                mainBtn.Text = v
                Library.Flags[data.Name] = v
            end
        }
    end
return Window
end

return Library

