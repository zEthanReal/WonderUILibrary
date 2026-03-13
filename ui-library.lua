--// Modern iOS Inspired UI Library
--// Created for clean scripting and executor compatibility

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
    Background = Color3.fromRGB(18,18,22),
    Container = Color3.fromRGB(28,28,35),
    Accent = Color3.fromRGB(90,140,255),
    Text = Color3.fromRGB(255,255,255),
    SubText = Color3.fromRGB(200,200,200)
}

--// Tween Helper
local function Tween(obj,props,time)
    TweenService:Create(obj,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play()
end

--// Notification System
function Library:Notify(data)

    if not Library.NotificationHolder then
        local holder = Instance.new("ScreenGui")
        holder.Name = "Notifications"
        holder.Parent = PlayerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0,300,1,0)
        frame.Position = UDim2.new(1,-320,0,20)
        frame.BackgroundTransparency = 1
        frame.Parent = holder

        local layout = Instance.new("UIListLayout",frame)
        layout.Padding = UDim.new(0,10)

        Library.NotificationHolder = frame
    end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1,0,0,70)
    notif.BackgroundColor3 = Theme.Container
    notif.Parent = Library.NotificationHolder
    notif.BackgroundTransparency = 1
    notif.ClipsDescendants = true
    notif.AnchorPoint = Vector2.new(0,0)

    local corner = Instance.new("UICorner",notif)
    corner.CornerRadius = UDim.new(0,12)

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0,40,0,40)
    icon.Position = UDim2.new(0,10,0.5,-20)
    icon.BackgroundTransparency = 1
    icon.Image = data.Icon or ""
    icon.Parent = notif

    local title = Instance.new("TextLabel")
    title.Text = data.Title
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Theme.Text
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0,60,0,8)
    title.Size = UDim2.new(1,-70,0,20)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notif

    local desc = Instance.new("TextLabel")
    desc.Text = data.Description
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextColor3 = Theme.SubText
    desc.BackgroundTransparency = 1
    desc.Position = UDim2.new(0,60,0,30)
    desc.Size = UDim2.new(1,-70,0,20)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = notif

    Tween(notif,{BackgroundTransparency = 0},0.25)

    task.delay(data.Duration or 4,function()
        Tween(notif,{BackgroundTransparency = 1},0.25)
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
    writefile(ConfigFolder.."/"..name..".json",data)

    Library:Notify({
        Title="Config Saved",
        Description=name.." stored successfully",
        Duration=3
    })
end

function Library:LoadConfig(name)

    if not readfile then return end

    local path = ConfigFolder.."/"..name..".json"
    if not isfile(path) then return end

    local data = HttpService:JSONDecode(readfile(path))

    for flag,value in pairs(data) do
        if Library.Elements[flag] then
            Library.Elements[flag]:Set(value)
        end
    end

    Library:Notify({
        Title="Config Loaded",
        Description=name.." applied",
        Duration=3
    })
end

--// Create Window
function Library:CreateWindow(settings)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = PlayerGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0,420,0,420)
    Main.Position = UDim2.new(0.5,-210,0.5,-210)
    Main.BackgroundColor3 = Theme.Background
    Main.Parent = ScreenGui

    local corner = Instance.new("UICorner",Main)
    corner.CornerRadius = UDim.new(0,14)

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1,0,0,40)
    TitleBar.BackgroundTransparency = 1
    TitleBar.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Text = settings.Title or "Window"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextColor3 = Theme.Text
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0,15,0,0)
    Title.Size = UDim2.new(1,0,1,0)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0,30,0,30)
    Close.Position = UDim2.new(1,-35,0.5,-15)
    Close.Text = "X"
    Close.Font = Enum.Font.GothamBold
    Close.TextColor3 = Color3.new(1,1,1)
    Close.BackgroundColor3 = Color3.fromRGB(220,60,60)
    Close.Parent = TitleBar
    Instance.new("UICorner",Close).CornerRadius = UDim.new(1,0)

    local Min = Instance.new("TextButton")
    Min.Size = UDim2.new(0,30,0,30)
    Min.Position = UDim2.new(1,-70,0.5,-15)
    Min.Text = "-"
    Min.Font = Enum.Font.GothamBold
    Min.TextColor3 = Color3.new(1,1,1)
    Min.BackgroundColor3 = Color3.fromRGB(60,60,60)
    Min.Parent = TitleBar
    Instance.new("UICorner",Min).CornerRadius = UDim.new(1,0)

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1,-20,1,-60)
    Container.Position = UDim2.new(0,10,0,50)
    Container.BackgroundTransparency = 1
    Container.Parent = Main

    local Layout = Instance.new("UIListLayout",Container)
    Layout.Padding = UDim.new(0,10)

    --// Draggable (PC + Mobile)
    local dragging
    local dragStart
    local startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(input)
        dragging = false
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    Close.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    Min.MouseButton1Click:Connect(function()
        if Container.Visible then
            Tween(Container,{Size = UDim2.new(1,-20,0,0)},0.25)
            task.wait(.25)
            Container.Visible=false
        else
            Container.Visible=true
            Tween(Container,{Size = UDim2.new(1,-20,1,-60)},0.25)
        end
    end)

    local Window = {}

    --// Element Base
    function Window:CreateElement(name)

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1,0,0,50)
        holder.BackgroundColor3 = Theme.Container
        holder.Parent = Container

        Instance.new("UICorner",holder).CornerRadius = UDim.new(0,10)

        local label = Instance.new("TextLabel")
        label.Text = name
        label.Font = Enum.Font.Gotham
        label.TextSize = 15
        label.TextColor3 = Theme.Text
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0,12,0,0)
        label.Size = UDim2.new(1,-20,1,0)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = holder

        return holder,label
    end

    --// Toggle
    function Window:AddToggle(data)

        local holder,label = Window:CreateElement(data.Name)

        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(0,45,0,22)
        toggle.Position = UDim2.new(1,-55,0.5,-11)
        toggle.BackgroundColor3 = Color3.fromRGB(70,70,70)
        toggle.Parent = holder
        Instance.new("UICorner",toggle).CornerRadius = UDim.new(1,0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0,18,0,18)
        knob.Position = UDim2.new(0,2,0.5,-9)
        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.Parent = toggle
        Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

        local state = data.Default or false
        Library.Flags[data.Name] = state

        local function set(val)
            state = val
            Library.Flags[data.Name] = val

            if val then
                Tween(toggle,{BackgroundColor3 = Theme.Accent},0.2)
                Tween(knob,{Position = UDim2.new(1,-20,0.5,-9)},0.2)
            else
                Tween(toggle,{BackgroundColor3 = Color3.fromRGB(70,70,70)},0.2)
                Tween(knob,{Position = UDim2.new(0,2,0.5,-9)},0.2)
            end

            if data.Callback then
                data.Callback(val)
            end
        end

        set(state)

        holder.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                set(not state)
            end
        end)

        Library.Elements[data.Name] = {Set=set}

    end

    --// Button
    function Window:AddButton(data)

        local holder,label = Window:CreateElement(data.Name)

        holder.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                Tween(holder,{BackgroundColor3 = Theme.Accent},0.1)
                task.wait(.1)
                Tween(holder,{BackgroundColor3 = Theme.Container},0.1)
                data.Callback()
            end
        end)

    end

    --// Textbox
    function Window:AddTextbox(data)

        local holder,label = Window:CreateElement(data.Name)

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0,140,0,26)
        box.Position = UDim2.new(1,-150,0.5,-13)
        box.PlaceholderText = data.Placeholder
        box.Text = ""
        box.TextColor3 = Theme.Text
        box.BackgroundColor3 = Color3.fromRGB(40,40,50)
        box.Parent = holder
        Instance.new("UICorner",box).CornerRadius = UDim.new(0,8)

        box.FocusLost:Connect(function()
            Library.Flags[data.Name] = box.Text
            if data.Callback then
                data.Callback(box.Text)
            end
        end)

        Library.Elements[data.Name] = {
            Set=function(v)
                box.Text=v
            end
        }

    end

    return Window
end

return Library
