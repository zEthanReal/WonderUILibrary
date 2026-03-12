--// WonderUI Library
--// Mobile + PC Friendly
--// Includes: Tabs, Buttons, Toggle, Slider, Dropdown, Textbox, Label, Config Save

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Library = {}

local Config = {}

local Colors = {
	Main = Color3.fromRGB(25,25,30),
	Top = Color3.fromRGB(35,35,45),
	Accent = Color3.fromRGB(80,130,255),
	Text = Color3.fromRGB(230,230,230)
}

function Library:CreateWindow(title)

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Parent = PlayerGui
	ScreenGui.ResetOnSpawn = false

	local Main = Instance.new("Frame")
	Main.Parent = ScreenGui
	Main.Size = UDim2.new(0,360,0,420)
	Main.Position = UDim2.new(0.5,-180,0.5,-210)
	Main.BackgroundColor3 = Colors.Main
	Main.BorderSizePixel = 0
	Main.Active = true
	Main.Draggable = true

	local Corner = Instance.new("UICorner",Main)
	Corner.CornerRadius = UDim.new(0,10)

	local Stroke = Instance.new("UIStroke")
	Stroke.Parent = Main
	Stroke.Color = Colors.Accent
	Stroke.Thickness = 2

	-- TOP BAR

	local Top = Instance.new("Frame")
	Top.Parent = Main
	Top.Size = UDim2.new(1,0,0,40)
	Top.BackgroundColor3 = Colors.Top
	Top.BorderSizePixel = 0

	local TopCorner = Instance.new("UICorner",Top)
	TopCorner.CornerRadius = UDim.new(0,10)

	local Title = Instance.new("TextLabel")
	Title.Parent = Top
	Title.Text = title
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 16
	Title.TextColor3 = Colors.Text
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0,10,0,0)
	Title.Size = UDim2.new(1,-80,1,0)
	Title.TextXAlignment = Enum.TextXAlignment.Left

	-- MINIMIZE

	local Minimize = Instance.new("TextButton")
	Minimize.Parent = Top
	Minimize.Size = UDim2.new(0,30,0,30)
	Minimize.Position = UDim2.new(1,-70,0,5)
	Minimize.Text = "—"
	Minimize.BackgroundColor3 = Colors.Accent
	Minimize.TextColor3 = Color3.new(1,1,1)
	Minimize.Font = Enum.Font.GothamBold

	Instance.new("UICorner",Minimize)

	-- CLOSE

	local Close = Instance.new("TextButton")
	Close.Parent = Top
	Close.Size = UDim2.new(0,30,0,30)
	Close.Position = UDim2.new(1,-35,0,5)
	Close.Text = "✕"
	Close.BackgroundColor3 = Color3.fromRGB(255,80,80)
	Close.TextColor3 = Color3.new(1,1,1)
	Close.Font = Enum.Font.GothamBold

	Instance.new("UICorner",Close)

	Close.MouseButton1Click:Connect(function()
		ScreenGui:Destroy()
	end)

	-- TAB BAR

	local TabsBar = Instance.new("Frame")
	TabsBar.Parent = Main
	TabsBar.Size = UDim2.new(1,0,0,40)
	TabsBar.Position = UDim2.new(0,0,0,40)
	TabsBar.BackgroundTransparency = 1

	local TabLayout = Instance.new("UIListLayout")
	TabLayout.Parent = TabsBar
	TabLayout.FillDirection = Enum.FillDirection.Horizontal
	TabLayout.Padding = UDim.new(0,6)

	local Pages = Instance.new("Frame")
	Pages.Parent = Main
	Pages.Position = UDim2.new(0,0,0,80)
	Pages.Size = UDim2.new(1,0,1,-80)
	Pages.BackgroundTransparency = 1

	local Window = {}

	function Window:CreateTab(name)

		local Button = Instance.new("TextButton")
		Button.Parent = TabsBar
		Button.Size = UDim2.new(0,120,1,0)
		Button.Text = name
		Button.BackgroundColor3 = Colors.Top
		Button.TextColor3 = Colors.Text
		Button.Font = Enum.Font.GothamBold
		Button.TextSize = 14
		Instance.new("UICorner",Button)

		local Page = Instance.new("ScrollingFrame")
		Page.Parent = Pages
		Page.Size = UDim2.new(1,0,1,0)
		Page.CanvasSize = UDim2.new(0,0,0,0)
		Page.ScrollBarThickness = 3
		Page.BackgroundTransparency = 1
		Page.Visible = false

		local Layout = Instance.new("UIListLayout")
		Layout.Parent = Page
		Layout.Padding = UDim.new(0,8)

		Button.MouseButton1Click:Connect(function()

	for _,tab in pairs(TabsBar:GetChildren()) do
		if tab:IsA("TextButton") then
			tab.BackgroundColor3 = Colors.Top
		end
	end

	Button.BackgroundColor3 = Colors.Accent

	for _,v in pairs(Pages:GetChildren()) do
		if v:IsA("ScrollingFrame") then
			v.Visible = false
		end
	end

	Page.Visible = true

end)

		local Elements = {}

		-- LABEL

		function Elements:Label(text)

			local Label = Instance.new("TextLabel")
			Label.Parent = Page
			Label.Size = UDim2.new(1,-10,0,30)
			Label.Text = text
			Label.BackgroundTransparency = 1
			Label.TextColor3 = Colors.Text
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 14

		end

		-- BUTTON

		function Elements:Button(text,callback)

	local Button = Instance.new("TextButton")
	Button.Parent = Page
	Button.Size = UDim2.new(1,-10,0,36)
	Button.Text = text
	Button.BackgroundColor3 = Colors.Accent
	Button.TextColor3 = Color3.new(1,1,1)
	Button.Font = Enum.Font.GothamBold
	Button.TextSize = 14
	Instance.new("UICorner",Button)

	local original = Button.Size

	Button.MouseButton1Down:Connect(function()
		TweenService:Create(Button,TweenInfo.new(.08),{
			Size = UDim2.new(1,-14,0,32)
		}):Play()
	end)

	Button.MouseButton1Up:Connect(function()
		TweenService:Create(Button,TweenInfo.new(.08),{
			Size = original
		}):Play()
	end)

	Button.MouseButton1Click:Connect(callback)

end

		-- IOS SWITCH

		function Elements:Toggle(text,callback)

			local Holder = Instance.new("Frame")
			Holder.Parent = Page
			Holder.Size = UDim2.new(1,-10,0,35)
			Holder.BackgroundColor3 = Colors.Top
			Instance.new("UICorner",Holder)

			local Label = Instance.new("TextLabel")
			Label.Parent = Holder
			Label.Text = text
			Label.BackgroundTransparency = 1
			Label.TextColor3 = Colors.Text
			Label.Font = Enum.Font.Gotham
			Label.Position = UDim2.new(0,10,0,0)
			Label.Size = UDim2.new(1,-60,1,0)

			local Switch = Instance.new("Frame")
			Switch.Parent = Holder
			Switch.Size = UDim2.new(0,40,0,20)
			Switch.Position = UDim2.new(1,-50,0.5,-10)
			Switch.BackgroundColor3 = Color3.fromRGB(70,70,70)
			Instance.new("UICorner",Switch)

			local Knob = Instance.new("Frame")
			Knob.Parent = Switch
			Knob.Size = UDim2.new(0,18,0,18)
			Knob.Position = UDim2.new(0,1,0,1)
			Knob.BackgroundColor3 = Color3.new(1,1,1)
			Instance.new("UICorner",Knob)

			local state = false

			Holder.InputBegan:Connect(function()
				state = not state

				if state then
					TweenService:Create(Knob,TweenInfo.new(.2),{Position=UDim2.new(1,-19,0,1)}):Play()
					Switch.BackgroundColor3 = Colors.Accent
				else
					TweenService:Create(Knob,TweenInfo.new(.2),{Position=UDim2.new(0,1,0,1)}):Play()
					Switch.BackgroundColor3 = Color3.fromRGB(70,70,70)
				end

				callback(state)
			end)

		end

		-- SLIDER

		function Elements:Slider(text,min,max,default,callback)

	local UIS = game:GetService("UserInputService")

	local Frame = Instance.new("Frame")
	Frame.Parent = Page
	Frame.Size = UDim2.new(1,-10,0,50)
	Frame.BackgroundColor3 = Colors.Top
	Instance.new("UICorner",Frame)

	local Label = Instance.new("TextLabel")
	Label.Parent = Frame
	Label.Text = text.." : "..default
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Colors.Text
	Label.Font = Enum.Font.Gotham
	Label.Position = UDim2.new(0,10,0,0)
	Label.Size = UDim2.new(1,-20,0,20)

	local Bar = Instance.new("Frame")
	Bar.Parent = Frame
	Bar.Size = UDim2.new(1,-20,0,6)
	Bar.Position = UDim2.new(0,10,0,30)
	Bar.BackgroundColor3 = Color3.fromRGB(70,70,70)
	Instance.new("UICorner",Bar)

	local Fill = Instance.new("Frame")
	Fill.Parent = Bar
	Fill.Size = UDim2.new(default/max,0,1,0)
	Fill.BackgroundColor3 = Colors.Accent
	Instance.new("UICorner",Fill)

	local Knob = Instance.new("Frame")
Knob.Parent = Bar
Knob.Size = UDim2.new(0,14,0,14)
Knob.AnchorPoint = Vector2.new(0.5,0.5)
Knob.Position = UDim2.new(Fill.Size.X.Scale,0,0.5,0)
Knob.BackgroundColor3 = Color3.new(1,1,1)
Instance.new("UICorner",Knob)

local dragging = false

	Bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UIS.InputChanged:Connect(function(input)

		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then

			local pos = (input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X
			pos = math.clamp(pos,0,1)

			TweenService:Create(Fill,TweenInfo.new(.08),{
				Size = UDim2.new(pos,0,1,0)
			}):Play()

			local value = math.floor(min + (max-min)*pos)

			Label.Text = text.." : "..value

			callback(value)

		end

	end)

end

                   ---Dropdown
                 
                       function Elements:Dropdown(text,options,callback)

	local Frame = Instance.new("Frame")
	Frame.Parent = Page
	Frame.Size = UDim2.new(1,-10,0,36)
	Frame.BackgroundColor3 = Colors.Top
	Instance.new("UICorner",Frame)

	local Button = Instance.new("TextButton")
	Button.Parent = Frame
	Button.Size = UDim2.new(1,0,1,0)
	Button.Text = text
	Button.BackgroundTransparency = 1
	Button.TextColor3 = Colors.Text
	Button.Font = Enum.Font.Gotham

	local List = Instance.new("Frame")
	List.Parent = Frame
	List.Position = UDim2.new(0,0,1,4)
	List.Size = UDim2.new(1,0,0,0)
	List.ClipsDescendants = true
	List.BackgroundColor3 = Colors.Top
	List.Visible = false
	Instance.new("UICorner",List)

	local Layout = Instance.new("UIListLayout")
	Layout.Parent = List

	local opened = false
	local size = #options * 30

	for _,option in pairs(options) do

		local Item = Instance.new("TextButton")
		Item.Parent = List
		Item.Size = UDim2.new(1,0,0,30)
		Item.Text = option
		Item.BackgroundTransparency = 1
		Item.TextColor3 = Colors.Text
		Item.Font = Enum.Font.Gotham

		Item.MouseButton1Click:Connect(function()

			Button.Text = option

			TweenService:Create(List,TweenInfo.new(.25),{
				Size = UDim2.new(1,0,0,0)
			}):Play()

			task.wait(.25)

			List.Visible = false
			opened = false

			callback(option)

		end)

	end

	Button.MouseButton1Click:Connect(function()

		opened = not opened

		if opened then

			List.Visible = true

			TweenService:Create(List,TweenInfo.new(.25),{
				Size = UDim2.new(1,0,0,size)
			}):Play()

		else

			TweenService:Create(List,TweenInfo.new(.25),{
				Size = UDim2.new(1,0,0,0)
			}):Play()

			task.wait(.25)
			List.Visible = false

		end

	end)

end

	-- TEXTBOX

		function Elements:Textbox(text,callback)

			local Box = Instance.new("TextBox")
			Box.Parent = Page
			Box.Size = UDim2.new(1,-10,0,35)
			Box.PlaceholderText = text
			Box.BackgroundColor3 = Colors.Top
			Box.TextColor3 = Colors.Text
			Box.Font = Enum.Font.Gotham
			Instance.new("UICorner",Box)

			Box.FocusLost:Connect(function()
				callback(Box.Text)
			end)

		end

		--Container System
function Elements:Section(title)

	local SectionFrame = Instance.new("Frame")
	SectionFrame.Parent = Page
	SectionFrame.Size = UDim2.new(1,-10,0,30)
	SectionFrame.BackgroundTransparency = 1

	local Label = Instance.new("TextLabel")
	Label.Parent = SectionFrame
	Label.Size = UDim2.new(1,0,1,0)
	Label.BackgroundTransparency = 1
	Label.Text = title
	Label.TextColor3 = Colors.Text
	Label.Font = Enum.Font.GothamBold
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left

end

return Elements
	end

	return Window
end

--Config System
local HttpService = game:GetService("HttpService")

local ConfigSystem = {}

function ConfigSystem:Save(name,data)

	if writefile then
		writefile(name..".json",HttpService:JSONEncode(data))
	end

end

function ConfigSystem:Load(name)

	if readfile and isfile(name..".json") then
		return HttpService:JSONDecode(readfile(name..".json"))
	end

end

--NOTIFICATION SYSTEM
local Notifications = {}

function Notifications:Notify(title,text,time)

	local Holder = Instance.new("Frame")
	Holder.Parent = PlayerGui
	Holder.Size = UDim2.new(0,260,0,70)
	Holder.Position = UDim2.new(1,300,1,-80)
	Holder.BackgroundColor3 = Colors.Top
	Instance.new("UICorner",Holder)

	local Title = Instance.new("TextLabel")
	Title.Parent = Holder
	Title.Text = title
	Title.Font = Enum.Font.GothamBold
	Title.TextColor3 = Colors.Text
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0,10,0,6)

	local Desc = Instance.new("TextLabel")
	Desc.Parent = Holder
	Desc.Text = text
	Desc.Font = Enum.Font.Gotham
	Desc.TextColor3 = Colors.Text
	Desc.BackgroundTransparency = 1
	Desc.Position = UDim2.new(0,10,0,30)

	TweenService:Create(Holder,TweenInfo.new(.35),{
		Position = UDim2.new(1,-270,1,-80)
	}):Play()

	task.wait(time or 3)

	TweenService:Create(Holder,TweenInfo.new(.35),{
		Position = UDim2.new(1,300,1,-80)
	}):Play()

	task.wait(.4)

	Holder:Destroy()

end

return Library