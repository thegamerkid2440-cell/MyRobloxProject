-- StarterPlayer/StarterPlayerScripts/CombinedClient.client.luau
-- Client UI and request path. This must run as a LocalScript.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PREFIX = "[TALL]"
local ERROR_PREFIX = "[TALL ERROR]"
local player = Players.LocalPlayer

local function log(message: string, ...: any)
	print(PREFIX, message, ...)
end

local function fail(message: string, ...: any)
	warn(ERROR_PREFIX, message, ...)
end

log("CLIENT STARTED", player and player.Name or "nil")
if not player then
	fail("LocalPlayer unavailable; this is not running as a valid LocalScript")
	return
end

local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
if not remotes then
	fail("REMOTE NOT FOUND: ReplicatedStorage.Remotes")
	return
end
local event = remotes:WaitForChild("SetTallAvatar", 15)
if not event or not event:IsA("RemoteEvent") then
	fail("REMOTE NOT FOUND: ReplicatedStorage.Remotes.SetTallAvatar")
	return
end
log("REMOTE FOUND", event:GetFullName())

local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
	fail("PlayerGui unavailable")
	return
end

local old = playerGui:FindFirstChild("TallAvatarGui")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "TallAvatarGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui
log("GUI CREATED")

local menu = Instance.new("Frame")
menu.Size = UDim2.fromOffset(310, 170)
menu.Position = UDim2.new(0.5, -155, 0.5, -85)
menu.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
menu.BorderSizePixel = 0
menu.Active = true
menu.Parent = gui
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 10)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(55, 60, 80)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = menu

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "Avatar Menu"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 34)
close.Position = UDim2.new(1, -39, 0, 4)
close.BackgroundColor3 = Color3.fromRGB(190, 60, 65)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 18
close.Font = Enum.Font.GothamBold
close.Parent = titleBar

local button = Instance.new("TextButton")
button.Name = "TallAvatarButton"
button.Size = UDim2.new(1, -30, 0, 54)
button.Position = UDim2.fromOffset(15, 65)
button.BackgroundColor3 = Color3.fromRGB(65, 125, 220)
button.Text = "Change Avatar to Tall Avatar"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 15
button.Font = Enum.Font.GothamSemibold
button.Parent = menu
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -30, 0, 26)
status.Position = UDim2.fromOffset(15, 130)
status.BackgroundTransparency = 1
status.Text = "R15 only"
status.TextColor3 = Color3.fromRGB(205, 210, 225)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.Parent = menu

local reopen = Instance.new("TextButton")
reopen.Size = UDim2.fromOffset(52, 52)
reopen.Position = UDim2.new(0, 20, 0.5, -26)
reopen.BackgroundColor3 = Color3.fromRGB(65, 125, 220)
reopen.Text = "A"
reopen.TextColor3 = Color3.new(1, 1, 1)
reopen.TextSize = 22
reopen.Font = Enum.Font.GothamBold
reopen.Visible = false
reopen.Active = true
reopen.Parent = gui
Instance.new("UICorner", reopen).CornerRadius = UDim.new(0, 10)
log("BUTTON CREATED")

local function draggable(handle: GuiObject, target: GuiObject)
	local dragging = false
	local startInput: InputObject?
	local startPosition: UDim2
	local startPoint: Vector3
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startInput = input
			startPosition = target.Position
			startPoint = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - startPoint
		target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
	end)
end

draggable(titleBar, menu)
draggable(reopen, reopen)

close.Activated:Connect(function()
	menu.Visible = false
	reopen.Visible = true
end)
reopen.Activated:Connect(function()
	reopen.Visible = false
	menu.Visible = true
end)

button.Activated:Connect(function()
	log("BUTTON PRESSED")
	status.Text = "Request sent..."
	log("FIRESERVER SENT")
	event:FireServer()
	task.delay(2, function()
		if status.Parent then status.Text = "R15 only" end
	end)
end)

log("CLIENT READY")
