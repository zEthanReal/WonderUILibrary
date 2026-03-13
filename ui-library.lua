--// Modern iOS-Inspired UI Library
--// Improved & Fixed

local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Library = {}
Library.Flags    = {}
Library.Elements = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Theme
-- ─────────────────────────────────────────────────────────────────────────────
local Theme = {
    Background     = Color3.fromRGB(14, 14, 20),
    Container      = Color3.fromRGB(24, 24, 34),
    ContainerHover = Color3.fromRGB(32, 32, 46),
    Accent         = Color3.fromRGB(100, 149, 255),
    Text           = Color3.fromRGB(235, 235, 245),
    SubText        = Color3.fromRGB(150, 150, 170),
    Divider        = Color3.fromRGB(42, 42, 58),
    Success        = Color3.fromRGB(72, 199, 116),
    Warning        = Color3.fromRGB(255, 188, 60),
    Error          = Color3.fromRGB(255, 80, 80),
    Info           = Color3.fromRGB(100, 149, 255),
}

function Library:SetTheme(overrides)
    for k, v in pairs(overrides) do
        Theme[k] = v
    end
end

function Library:GetFlag(name)
    return Library.Flags[name]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Utilities
-- ─────────────────────────────────────────────────────────────────────────────
local function Tween(obj, props, duration, style, direction)
    local t = TweenService:Create(obj, TweenInfo.new(
        duration or 0.2,
        style     or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color        or Color3.fromRGB(55, 55, 75)
    s.Thickness    = thickness    or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function Padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 8)
    p.PaddingBottom = UDim.new(0, bottom or 8)
    p.PaddingLeft   = UDim.new(0, left   or 8)
    p.PaddingRight  = UDim.new(0, right  or 8)
    p.Parent = parent
    return p
end

local function Ripple(parent, inputPos)
    local holder = Instance.new("Frame")
    holder.Size                = UDim2.new(1, 0, 1, 0)
    holder.BackgroundTransparency = 1
    holder.ClipsDescendants    = true
    holder.ZIndex              = parent.ZIndex + 5
    holder.Parent              = parent
    Corner(holder, 10)

    local circle = Instance.new("Frame")
    circle.Size                = UDim2.new(0, 0, 0, 0)
    circle.AnchorPoint         = Vector2.new(0.5, 0.5)
    circle.Position            = UDim2.new(
        0, inputPos.X - parent.AbsolutePosition.X,
        0, inputPos.Y - parent.AbsolutePosition.Y
    )
    circle.BackgroundColor3    = Theme.Accent
    circle.BackgroundTransparency = 0.65
    circle.ZIndex              = holder.ZIndex + 1
    circle.Parent              = holder
    Corner(circle, 999)

    Tween(circle, {Size = UDim2.new(0, 220, 0, 220), BackgroundTransparency = 1}, 0.55, Enum.EasingStyle.Quad)
    task.delay(0.6, function() holder:Destroy() end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Notification System
-- ─────────────────────────────────────────────────────────────────────────────
function Library:Notify(data)
    local typeColor = ({
        success = Theme.Success,
        warning = Theme.Warning,
        error   = Theme.Error,
        info    = Theme.Info,
    })[data.Type] or Theme.Accent

    -- Build holder once
    if not Library._notifGui then
        local gui = Instance.new("ScreenGui")
        gui.Name          = "UILib_Notifications"
        gui.ResetOnSpawn  = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent        = PlayerGui

        local frame = Instance.new("Frame")
        frame.Size                = UDim2.new(0, 300, 1, -40)
        frame.Position            = UDim2.new(1, -312, 0, 20)
        frame.BackgroundTransparency = 1
        frame.Parent              = gui

        local layout = Instance.new("UIListLayout")
        layout.Padding           = UDim.new(0, 8)
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.SortOrder         = Enum.SortOrder.LayoutOrder
        layout.Parent            = frame

        Library._notifGui    = gui
        Library._notifFrame  = frame
    end

    local duration = data.Duration or 4

    -- Card
    local card = Instance.new("Frame")
    card.Size                = UDim2.new(1, 0, 0, 76)
    card.BackgroundColor3    = Theme.Container
    card.BackgroundTransparency = 1
    card.ClipsDescendants    = true
    card.Parent              = Library._notifFrame
    Corner(card, 12)
    Stroke(card, typeColor, 1, 0.6)

    -- Accent side bar
    local bar = Instance.new("Frame")
    bar.Size            = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = typeColor
    bar.BorderSizePixel = 0
    bar.Parent          = card
    Corner(bar, 2)

    local title = Instance.new("TextLabel")
    title.Text               = data.Title or "Notice"
    title.Font               = Enum.Font.GothamBold
    title.TextSize           = 14
    title.TextColor3         = Theme.Text
    title.TextTransparency   = 1
    title.BackgroundTransparency = 1
    title.Position           = UDim2.new(0, 16, 0, 12)
    title.Size               = UDim2.new(1, -20, 0, 18)
    title.TextXAlignment     = Enum.TextXAlignment.Left
    title.Parent             = card

    local desc = Instance.new("TextLabel")
    desc.Text                = data.Description or ""
    desc.Font                = Enum.Font.Gotham
    desc.TextSize            = 12
    desc.TextColor3          = Theme.SubText
    desc.TextTransparency    = 1
    desc.BackgroundTransparency = 1
    desc.Position            = UDim2.new(0, 16, 0, 34)
    desc.Size                = UDim2.new(1, -20, 0, 28)
    desc.TextXAlignment      = Enum.TextXAlignment.Left
    desc.TextWrapped         = true
    desc.Parent              = card

    -- Progress bar
    local progBg = Instance.new("Frame")
    progBg.Size            = UDim2.new(1, 0, 0, 2)
    progBg.Position        = UDim2.new(0, 0, 1, -2)
    progBg.BackgroundColor3 = Theme.Divider
    progBg.BorderSizePixel = 0
    progBg.Parent          = card

    local prog = Instance.new("Frame")
    prog.Size            = UDim2.new(1, 0, 1, 0)
    prog.BackgroundColor3 = typeColor
    prog.BorderSizePixel = 0
    prog.Parent          = progBg

    -- Animate in
    Tween(card,  {BackgroundTransparency = 0},   0.3)
    Tween(title, {TextTransparency = 0},          0.3)
    Tween(desc,  {TextTransparency = 0},          0.3)
    Tween(prog,  {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(card,  {BackgroundTransparency = 1}, 0.3)
        Tween(title, {TextTransparency = 1},        0.3)
        Tween(desc,  {TextTransparency = 1},        0.3)
        task.wait(0.35)
        card:Destroy()
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Config System
-- ─────────────────────────────────────────────────────────────────────────────
local CONFIG_FOLDER = "UILibraryConfigs"

function Library:SaveConfig(name)
    if not writefile then
        self:Notify({Title = "Config", Description = "Filesystem unavailable", Type = "error"})
        return
    end
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end

    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Library.Flags)
    if ok then
        writefile(CONFIG_FOLDER .. "/" .. name .. ".json", encoded)
        self:Notify({Title = "Config Saved", Description = name .. " stored", Type = "success", Duration = 3})
    else
        self:Notify({Title = "Save Failed", Description = "Encode error", Type = "error", Duration = 3})
    end
end

function Library:LoadConfig(name)
    if not readfile then
        self:Notify({Title = "Config", Description = "Filesystem unavailable", Type = "error"})
        return
    end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then
        self:Notify({Title = "Not Found", Description = name .. " doesn't exist", Type = "error", Duration = 3})
        return
    end

    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if ok and data then
        for flag, value in pairs(data) do
            local el = Library.Elements[flag]
            if el and el.Set then el:Set(value) end
        end
        self:Notify({Title = "Config Loaded", Description = name .. " applied", Type = "success", Duration = 3})
    else
        self:Notify({Title = "Load Failed", Description = "File is corrupted", Type = "error", Duration = 3})
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateWindow
-- ─────────────────────────────────────────────────────────────────────────────
function Library:CreateWindow(settings)
    settings = settings or {}

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name          = "UILib_" .. (settings.Title or "Window")
    ScreenGui.ResetOnSpawn  = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent        = PlayerGui

    -- Main frame
    local Main = Instance.new("Frame")
    Main.Size             = UDim2.new(0, 440, 0, 500)
    Main.Position         = UDim2.new(0.5, -220, 0.5, -250)
    Main.BackgroundColor3 = Theme.Background
    Main.ClipsDescendants = true
    Main.Parent           = ScreenGui
    Corner(Main, 16)
    Stroke(Main, Color3.fromRGB(55, 55, 78), 1, 0)

    -- ── Title bar ─────────────────────────────────────────────────────────
    local TitleBar = Instance.new("Frame")
    TitleBar.Size             = UDim2.new(1, 0, 0, 50)
    TitleBar.BackgroundColor3 = Theme.Container
    TitleBar.BorderSizePixel  = 0
    TitleBar.Parent           = Main

    -- Bottom divider
    local titleDivider = Instance.new("Frame")
    titleDivider.Size            = UDim2.new(1, 0, 0, 1)
    titleDivider.Position        = UDim2.new(0, 0, 1, -1)
    titleDivider.BackgroundColor3 = Theme.Divider
    titleDivider.BorderSizePixel = 0
    titleDivider.Parent          = TitleBar

    -- Accent dot
    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 8, 0, 8)
    dot.Position         = UDim2.new(0, 15, 0.5, -4)
    dot.BackgroundColor3 = Theme.Accent
    dot.Parent           = TitleBar
    Corner(dot, 4)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text               = settings.Title or "Window"
    TitleLabel.Font               = Enum.Font.GothamBold
    TitleLabel.TextSize           = 15
    TitleLabel.TextColor3         = Theme.Text
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position           = UDim2.new(0, 32, 0, 0)
    TitleLabel.Size               = UDim2.new(1, -130, 1, 0)
    TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
    TitleLabel.Parent             = TitleBar

    -- macOS-style control buttons
    local function ControlBtn(xOffset, bgColor, symbol)
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0, 26, 0, 26)
        btn.Position         = UDim2.new(1, xOffset, 0.5, -13)
        btn.BackgroundColor3 = bgColor
        btn.Text             = ""
        btn.AutoButtonColor  = false
        btn.Parent           = TitleBar
        Corner(btn, 13)

        local lbl = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1, 0, 1, 0)
        lbl.Text               = symbol
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextSize           = 14
        lbl.TextColor3         = Color3.new(0, 0, 0)
        lbl.TextTransparency   = 1
        lbl.BackgroundTransparency = 1
        lbl.Parent             = btn

        btn.MouseEnter:Connect(function()
            Tween(lbl, {TextTransparency = 0}, 0.12)
            Tween(btn, {BackgroundColor3 = bgColor:Lerp(Color3.new(1,1,1), 0.2)}, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            Tween(lbl, {TextTransparency = 1}, 0.12)
            Tween(btn, {BackgroundColor3 = bgColor}, 0.12)
        end)
        return btn
    end

    local CloseBtn = ControlBtn(-12, Color3.fromRGB(255, 95,  87), "×")
    local MinBtn   = ControlBtn(-46, Color3.fromRGB(255, 189, 46), "−")

    -- ── Tab bar ───────────────────────────────────────────────────────────
    local TabBar = Instance.new("Frame")
    TabBar.Size                = UDim2.new(1, 0, 0, 42)
    TabBar.Position            = UDim2.new(0, 0, 0, 50)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent              = Main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding        = UDim.new(0, 0)
    tabLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Parent         = tabLayout -- will be reparented below
    tabLayout.Parent         = TabBar
    Padding(TabBar, 6, 6, 12, 12)

    local tabDivider = Instance.new("Frame")
    tabDivider.Size            = UDim2.new(1, 0, 0, 1)
    tabDivider.Position        = UDim2.new(0, 0, 1, -1)
    tabDivider.BackgroundColor3 = Theme.Divider
    tabDivider.BorderSizePixel = 0
    tabDivider.Parent          = TabBar

    -- ── Content area ──────────────────────────────────────────────────────
    local ContentArea = Instance.new("Frame")
    ContentArea.Size                = UDim2.new(1, 0, 1, -92)
    ContentArea.Position            = UDim2.new(0, 0, 0, 92)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants    = true
    ContentArea.Parent              = Main

    -- ── Drag logic ────────────────────────────────────────────────────────
    local dragging, dragInput, dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local vp    = workspace.CurrentCamera.ViewportSize
            local newX  = math.clamp(startPos.X.Offset + delta.X, 0, vp.X - Main.AbsoluteSize.X)
            local newY  = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - Main.AbsoluteSize.Y)
            Main.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    -- ── Window controls ───────────────────────────────────────────────────
    CloseBtn.MouseButton1Click:Connect(function()
        local cx = Main.Position.X.Offset + Main.AbsoluteSize.X / 2
        local cy = Main.Position.Y.Offset + Main.AbsoluteSize.Y / 2
        Tween(Main, {
            Size     = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, cx, 0, cy),
        }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.28, function() ScreenGui:Destroy() end)
    end)

    local minimized = false
    local fullSize  = UDim2.new(0, 440, 0, 500)

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(Main, {Size = minimized and UDim2.new(0, 440, 0, 50) or fullSize}, 0.25)
    end)

    -- ── Window object ─────────────────────────────────────────────────────
    local Window = {}
    local tabs       = {}
    local currentTab = nil

    function Window:Destroy()
        ScreenGui:Destroy()
    end

    -- ── CreateTab ─────────────────────────────────────────────────────────
    function Window:CreateTab(tabSettings)
        tabSettings = tabSettings or {}
        local tabName = tabSettings.Name or ("Tab" .. (#tabs + 1))

        -- Tab button
        local tabBtn = Instance.new("TextButton")
        tabBtn.AutoButtonColor  = false
        tabBtn.AutomaticSize    = Enum.AutomaticSize.X
        tabBtn.Size             = UDim2.new(0, 0, 1, 0)
        tabBtn.BackgroundTransparency = 1
        tabBtn.Font             = Enum.Font.Gotham
        tabBtn.TextSize         = 13
        tabBtn.TextColor3       = Theme.SubText
        tabBtn.Text             = "  " .. tabName .. "  "
        tabBtn.Parent           = TabBar

        local indicator = Instance.new("Frame")
        indicator.Size               = UDim2.new(1, 0, 0, 2)
        indicator.Position           = UDim2.new(0, 0, 1, -2)
        indicator.BackgroundColor3   = Theme.Accent
        indicator.BackgroundTransparency = 1
        indicator.BorderSizePixel    = 0
        indicator.Parent             = tabBtn

        -- Scrolling content frame
        local Container = Instance.new("ScrollingFrame")
        Container.Size                = UDim2.new(1, 0, 1, 0)
        Container.BackgroundTransparency = 1
        Container.ScrollBarThickness  = 3
        Container.ScrollBarImageColor3 = Theme.Accent
        Container.ScrollBarImageTransparency = 0.4
        Container.BorderSizePixel     = 0
        Container.Visible             = false
        Container.Parent              = ContentArea
        Padding(Container, 10, 10, 10, 10)

        local Layout = Instance.new("UIListLayout")
        Layout.Padding   = UDim.new(0, 8)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent    = Container

        -- FIX: Connect canvas resize ONCE per tab, not per element
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
        end)

        local Tab   = {}
        local entry = {btn = tabBtn, container = Container, indicator = indicator}
        table.insert(tabs, entry)

        local function selectTab()
            for _, t in ipairs(tabs) do
                t.container.Visible = false
                Tween(t.btn,       {TextColor3 = Theme.SubText}, 0.15)
                Tween(t.indicator, {BackgroundTransparency = 1}, 0.15)
            end
            Container.Visible = true
            Tween(tabBtn,    {TextColor3 = Theme.Text}, 0.15)
            Tween(indicator, {BackgroundTransparency = 0}, 0.15)
            currentTab = entry
        end

        tabBtn.MouseButton1Click:Connect(selectTab)
        if not currentTab then selectTab() end   -- auto-select first tab

        -- ──────────────────────────────────────────────────────────────────
        -- Internal element builder
        -- ──────────────────────────────────────────────────────────────────
        local function BaseElement(name, height)
            local holder = Instance.new("Frame")
            holder.Size             = UDim2.new(1, 0, 0, height or 50)
            holder.BackgroundColor3 = Theme.Container
            holder.BorderSizePixel  = 0
            holder.Parent           = Container
            Corner(holder, 10)
            Stroke(holder, Color3.fromRGB(42, 42, 60))

            local label
            if name and name ~= "" then
                label = Instance.new("TextLabel")
                label.Text               = name
                label.Font               = Enum.Font.Gotham
                label.TextSize           = 14
                label.TextColor3         = Theme.Text
                label.BackgroundTransparency = 1
                label.Position           = UDim2.new(0, 14, 0, 0)
                label.Size               = UDim2.new(0.55, 0, 0, 50)
                label.TextXAlignment     = Enum.TextXAlignment.Left
                label.Parent             = holder
            end

            -- Generic hover tint
            holder.MouseEnter:Connect(function()
                Tween(holder, {BackgroundColor3 = Theme.ContainerHover}, 0.15)
            end)
            holder.MouseLeave:Connect(function()
                Tween(holder, {BackgroundColor3 = Theme.Container}, 0.15)
            end)

            return holder, label
        end

        -- ── Section ───────────────────────────────────────────────────────
        function Tab:AddSection(name)
            local f = Instance.new("Frame")
            f.Size                = UDim2.new(1, 0, 0, 22)
            f.BackgroundTransparency = 1
            f.Parent              = Container

            local lbl = Instance.new("TextLabel")
            lbl.Text              = string.upper(name or "")
            lbl.Font              = Enum.Font.GothamBold
            lbl.TextSize          = 10
            lbl.TextColor3        = Theme.Accent
            lbl.BackgroundTransparency = 1
            lbl.Position          = UDim2.new(0, 4, 0, 0)
            lbl.Size              = UDim2.new(0.45, 0, 1, 0)
            lbl.TextXAlignment    = Enum.TextXAlignment.Left
            lbl.Parent            = f

            local line = Instance.new("Frame")
            line.Size             = UDim2.new(0.52, 0, 0, 1)
            line.Position         = UDim2.new(0.47, 0, 0.5, 0)
            line.BackgroundColor3 = Theme.Divider
            line.BorderSizePixel  = 0
            line.Parent           = f
        end

        -- ── Label ─────────────────────────────────────────────────────────
        function Tab:AddLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Text               = text or ""
            lbl.Font               = Enum.Font.Gotham
            lbl.TextSize           = 13
            lbl.TextColor3         = Theme.SubText
            lbl.BackgroundTransparency = 1
            lbl.Size               = UDim2.new(1, 0, 0, 26)
            lbl.TextXAlignment     = Enum.TextXAlignment.Left
            lbl.TextWrapped        = true
            lbl.Parent             = Container
            Padding(lbl, 0, 0, 4, 0)

            return {Set = function(_, v) lbl.Text = v end}
        end

        -- ── Toggle ────────────────────────────────────────────────────────
        function Tab:AddToggle(data)
            local holder, label = BaseElement(data.Name)

            local track = Instance.new("Frame")
            track.Size             = UDim2.new(0, 46, 0, 24)
            track.Position         = UDim2.new(1, -58, 0.5, -12)
            track.BackgroundColor3 = Color3.fromRGB(50, 50, 68)
            track.Parent           = holder
            Corner(track, 12)
            Stroke(track, Color3.fromRGB(65, 65, 88))

            local knob = Instance.new("Frame")
            knob.Size             = UDim2.new(0, 18, 0, 18)
            knob.Position         = UDim2.new(0, 3, 0.5, -9)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.ZIndex           = 2
            knob.Parent           = track
            Corner(knob, 9)

            local state = data.Default or false
            Library.Flags[data.Name] = state

            local function set(val)
                state = val
                Library.Flags[data.Name] = val
                if val then
                    Tween(track, {BackgroundColor3 = Theme.Accent}, 0.2)
                    Tween(knob,  {Position = UDim2.new(1, -21, 0.5, -9)}, 0.2)
                else
                    Tween(track, {BackgroundColor3 = Color3.fromRGB(50, 50, 68)}, 0.2)
                    Tween(knob,  {Position = UDim2.new(0, 3, 0.5, -9)}, 0.2)
                end
                if data.Callback then pcall(data.Callback, val) end
            end

            set(state)  -- apply default

            holder.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    set(not state)
                end
            end)

            local el = {
                Set = function(_, v) set(v) end,
                Get = function()    return state end,
            }
            Library.Elements[data.Name] = el
            return el
        end

        -- ── Button ────────────────────────────────────────────────────────
        function Tab:AddButton(data)
            local holder, label = BaseElement(data.Name)

            local hint = Instance.new("TextLabel")
            hint.Text               = data.Hint or "›"
            hint.Font               = Enum.Font.GothamBold
            hint.TextSize           = 18
            hint.TextColor3         = Theme.SubText
            hint.BackgroundTransparency = 1
            hint.Position           = UDim2.new(1, -36, 0, 0)
            hint.Size               = UDim2.new(0, 26, 1, 0)
            hint.Parent             = holder

            holder.MouseEnter:Connect(function()
                Tween(hint, {TextColor3 = Theme.Accent}, 0.15)
            end)
            holder.MouseLeave:Connect(function()
                Tween(hint, {TextColor3 = Theme.SubText}, 0.15)
            end)

            holder.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    Ripple(holder, i.Position)
                    if data.Callback then task.spawn(data.Callback) end   -- FIX: no blocking task.wait
                end
            end)
        end

        -- ── Textbox ───────────────────────────────────────────────────────
        function Tab:AddTextbox(data)
            local holder, label = BaseElement(data.Name, 64)

            local boxBg = Instance.new("Frame")
            boxBg.Size             = UDim2.new(1, -28, 0, 28)
            boxBg.Position         = UDim2.new(0, 14, 1, -36)
            boxBg.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
            boxBg.Parent           = holder
            Corner(boxBg, 8)
            local boxStroke = Stroke(boxBg, Color3.fromRGB(48, 48, 66))

            local box = Instance.new("TextBox")
            box.Size               = UDim2.new(1, -16, 1, 0)
            box.Position           = UDim2.new(0, 8, 0, 0)
            box.PlaceholderText    = data.Placeholder or "Enter value…"
            box.Text               = data.Default     or ""
            box.TextColor3         = Theme.Text
            box.PlaceholderColor3  = Theme.SubText
            box.BackgroundTransparency = 1
            box.Font               = Enum.Font.Gotham
            box.TextSize           = 13
            box.ClearTextOnFocus   = data.ClearOnFocus ~= false
            box.Parent             = boxBg

            -- FIX: update the stored UIStroke, don't create new ones
            box.Focused:Connect(function()
                Tween(boxStroke, {Color = Theme.Accent}, 0.15)
            end)
            box.FocusLost:Connect(function()
                Tween(boxStroke, {Color = Color3.fromRGB(48, 48, 66)}, 0.15)
                Library.Flags[data.Name] = box.Text
                if data.Callback then pcall(data.Callback, box.Text) end
            end)

            Library.Flags[data.Name] = box.Text

            local el = {
                Set = function(_, v)
                    box.Text = tostring(v)
                    Library.Flags[data.Name] = tostring(v)
                end,
                Get = function() return box.Text end,
            }
            Library.Elements[data.Name] = el
            return el
        end

        -- ── Slider ────────────────────────────────────────────────────────
        function Tab:AddSlider(data)
            local holder, label = BaseElement(data.Name, 68)

            local min       = data.Min     or 0
            local max       = data.Max     or 100
            local default   = math.clamp(data.Default or min, min, max)
            local increment = data.Increment or 1
            local suffix    = data.Suffix   or ""

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size               = UDim2.new(0, 60, 0, 50)
            valueLabel.Position           = UDim2.new(1, -68, 0, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text               = tostring(default) .. suffix
            valueLabel.TextColor3         = Theme.Accent
            valueLabel.Font               = Enum.Font.GothamBold
            valueLabel.TextSize           = 14
            valueLabel.TextXAlignment     = Enum.TextXAlignment.Right
            valueLabel.Parent             = holder

            -- Track
            local track = Instance.new("Frame")
            track.Size             = UDim2.new(1, -28, 0, 6)
            track.Position         = UDim2.new(0, 14, 1, -20)
            track.BackgroundColor3 = Color3.fromRGB(36, 36, 52)
            track.Parent           = holder
            Corner(track, 3)

            local fill = Instance.new("Frame")
            fill.Size             = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.Parent           = track
            Corner(fill, 3)

            -- Thumb
            local thumb = Instance.new("Frame")
            thumb.Size             = UDim2.new(0, 14, 0, 14)
            thumb.Position         = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
            thumb.BackgroundColor3 = Color3.new(1, 1, 1)
            thumb.ZIndex           = 3
            thumb.Parent           = track
            Corner(thumb, 7)
            Stroke(thumb, Theme.Accent, 2)

            Library.Flags[data.Name] = default

            local dragSlider = false

            local function updateSlider(inputX)
                local rel   = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local raw   = min + (max - min) * rel
                local value = math.clamp(
                    math.round(raw / increment) * increment,
                    min, max
                )
                local pos = (value - min) / (max - min)

                Tween(fill,  {Size     = UDim2.new(pos, 0, 1, 0)},    0.06)
                Tween(thumb, {Position = UDim2.new(pos, -7, 0.5, -7)}, 0.06)
                valueLabel.Text           = tostring(value) .. suffix
                Library.Flags[data.Name] = value

                if data.Callback then pcall(data.Callback, value) end
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragSlider = true
                    updateSlider(i.Position.X)
                end
            end)

            -- FIX: Use UserInputService connections (not the original's double-binding bug)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragSlider = false
                end
            end)

            UserInputService.InputChanged:Connect(function(i)
                if dragSlider and (
                    i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch
                ) then
                    updateSlider(i.Position.X)
                end
            end)

            local el = {
                Set = function(_, v)
                    v = math.clamp(v, min, max)
                    local pos = (v - min) / (max - min)
                    Tween(fill,  {Size     = UDim2.new(pos, 0, 1, 0)},    0.1)
                    Tween(thumb, {Position = UDim2.new(pos, -7, 0.5, -7)}, 0.1)
                    valueLabel.Text           = tostring(v) .. suffix
                    Library.Flags[data.Name] = v
                end,
                Get = function() return Library.Flags[data.Name] end,
            }
            Library.Elements[data.Name] = el
            return el
        end

        -- ── Dropdown ──────────────────────────────────────────────────────
        function Tab:AddDropdown(data)
            local holder, label = BaseElement(data.Name)

            local options  = data.Options  or {}
            local selected = data.Default  or options[1] or "None"
            local open     = false

            local mainBtn = Instance.new("TextButton")
            mainBtn.Size             = UDim2.new(0, 140, 0, 28)
            mainBtn.Position         = UDim2.new(1, -154, 0.5, -14)
            mainBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 46)
            mainBtn.Text             = ""
            mainBtn.AutoButtonColor  = false
            mainBtn.Parent           = holder
            Corner(mainBtn, 8)
            Stroke(mainBtn, Color3.fromRGB(52, 52, 72))

            local selLabel = Instance.new("TextLabel")
            selLabel.Size               = UDim2.new(1, -28, 1, 0)
            selLabel.Position           = UDim2.new(0, 10, 0, 0)
            selLabel.BackgroundTransparency = 1
            selLabel.Text               = selected
            selLabel.Font               = Enum.Font.Gotham
            selLabel.TextSize           = 13
            selLabel.TextColor3         = Theme.Text
            selLabel.TextXAlignment     = Enum.TextXAlignment.Left
            selLabel.Parent             = mainBtn

            local arrow = Instance.new("TextLabel")
            arrow.Size               = UDim2.new(0, 20, 1, 0)
            arrow.Position           = UDim2.new(1, -22, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text               = "▾"
            arrow.Font               = Enum.Font.GothamBold
            arrow.TextSize           = 14
            arrow.TextColor3         = Theme.SubText
            arrow.Parent             = mainBtn

            -- Option list expands the holder itself (ClipsDescendants handles reveal)
            -- FIX: removed `holder.ClipsDescendants = true` set-before-use;
            -- it is only applied once the list is built and the size is known.
            local optContainer = Instance.new("Frame")
            optContainer.Size                = UDim2.new(1, -28, 0, 0)
            optContainer.Position            = UDim2.new(0, 14, 0, 54)
            optContainer.BackgroundTransparency = 1
            optContainer.ClipsDescendants    = true
            optContainer.Parent              = holder

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding   = UDim.new(0, 4)
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent    = optContainer

            Library.Flags[data.Name] = selected

            local ITEM_H  = 28
            local PADDING  = 8

            local function buildListHeight()
                return #options * (ITEM_H + 4) + PADDING
            end

            local function closeDropdown()
                open = false
                Tween(holder,       {Size = UDim2.new(1, 0, 0, 50)},              0.22)
                Tween(optContainer, {Size = UDim2.new(1, -28, 0, 0)},             0.22)
                Tween(arrow,        {Rotation = 0},                                0.22)
                task.delay(0.23, function()
                    holder.ClipsDescendants = false
                end)
            end

            local function openDropdown()
                open = true
                local h = buildListHeight()
                holder.ClipsDescendants = true
                Tween(holder,       {Size = UDim2.new(1, 0, 0, 50 + h + 8)},     0.22)
                Tween(optContainer, {Size = UDim2.new(1, -28, 0, h)},             0.22)
                Tween(arrow,        {Rotation = 180},                              0.22)
            end

            mainBtn.MouseButton1Click:Connect(function()
                if open then closeDropdown() else openDropdown() end
            end)

            local optButtons = {}

            local function addOption(optName)
                local optBtn = Instance.new("TextButton")
                optBtn.Size             = UDim2.new(1, 0, 0, ITEM_H)
                optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
                optBtn.Text             = ""
                optBtn.AutoButtonColor  = false
                optBtn.Parent           = optContainer
                Corner(optBtn, 7)

                local optLbl = Instance.new("TextLabel")
                optLbl.Size               = UDim2.new(1, -12, 1, 0)
                optLbl.Position           = UDim2.new(0, 10, 0, 0)
                optLbl.BackgroundTransparency = 1
                optLbl.Text               = optName
                optLbl.Font               = Enum.Font.Gotham
                optLbl.TextSize           = 13
                optLbl.TextColor3         = Theme.SubText
                optLbl.TextXAlignment     = Enum.TextXAlignment.Left
                optLbl.Parent             = optBtn

                optBtn.MouseEnter:Connect(function()
                    Tween(optBtn, {BackgroundColor3 = Theme.Accent:Lerp(Color3.fromRGB(30,30,44), 0.8)}, 0.12)
                    Tween(optLbl, {TextColor3 = Theme.Text}, 0.12)
                end)
                optBtn.MouseLeave:Connect(function()
                    local isSelected = (optName == selected)
                    Tween(optBtn, {BackgroundColor3 = isSelected
                        and Theme.Accent:Lerp(Color3.fromRGB(30,30,44), 0.75)
                        or  Color3.fromRGB(30,30,44)}, 0.12)
                    Tween(optLbl, {TextColor3 = isSelected and Theme.Text or Theme.SubText}, 0.12)
                end)

                optBtn.MouseButton1Click:Connect(function()
                    selected                  = optName
                    selLabel.Text             = optName
                    Library.Flags[data.Name] = optName
                    closeDropdown()
                    if data.Callback then pcall(data.Callback, optName) end
                end)

                table.insert(optButtons, {btn = optBtn, lbl = optLbl})
            end

            for _, opt in ipairs(options) do
                addOption(opt)
            end

            local el = {
                Set = function(_, v)
                    selected                  = v
                    selLabel.Text             = v
                    Library.Flags[data.Name] = v
                end,
                Get = function() return selected end,
                -- Refresh the option list at runtime
                Refresh = function(_, newOptions)
                    options = newOptions
                    for _, ob in ipairs(optButtons) do ob.btn:Destroy() end
                    optButtons = {}
                    for _, opt in ipairs(newOptions) do addOption(opt) end
                    if open then
                        local h = buildListHeight()
                        optContainer.Size = UDim2.new(1, -28, 0, h)
                        holder.Size       = UDim2.new(1, 0, 0, 50 + h + 8)
                    end
                end,
            }
            Library.Elements[data.Name] = el
            return el
        end

        -- ── Keybind ───────────────────────────────────────────────────────
        function Tab:AddKeybind(data)
            local holder, label = BaseElement(data.Name)

            local currentKey = data.Default or Enum.KeyCode.Unknown
            local listening  = false
            Library.Flags[data.Name] = currentKey

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size             = UDim2.new(0, 90, 0, 28)
            keyBtn.Position         = UDim2.new(1, -104, 0.5, -14)
            keyBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 46)
            keyBtn.Font             = Enum.Font.Gotham
            keyBtn.TextSize         = 12
            keyBtn.TextColor3       = Theme.Text
            keyBtn.Text             = currentKey.Name
            keyBtn.AutoButtonColor  = false
            keyBtn.Parent           = holder
            Corner(keyBtn, 8)
            Stroke(keyBtn, Color3.fromRGB(52, 52, 72))

            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening     = true
                keyBtn.Text   = "[ … ]"
                Tween(keyBtn, {BackgroundColor3 = Theme.Accent:Lerp(Color3.fromRGB(32,32,46), 0.7)}, 0.15)
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    listening                 = false
                    currentKey                = input.KeyCode
                    Library.Flags[data.Name] = currentKey
                    keyBtn.Text              = currentKey.Name
                    Tween(keyBtn, {BackgroundColor3 = Color3.fromRGB(32,32,46)}, 0.15)
                    if data.Callback then pcall(data.Callback, currentKey) end

                elseif not listening and not gpe and input.KeyCode == currentKey then
                    if data.OnPress then pcall(data.OnPress) end
                end
            end)

            local el = {
                Set = function(_, v)
                    currentKey                = v
                    Library.Flags[data.Name] = v
                    keyBtn.Text              = v.Name
                end,
                Get = function() return currentKey end,
            }
            Library.Elements[data.Name] = el
            return el
        end

        return Tab
    end -- CreateTab

    return Window
end -- CreateWindow

return Library

