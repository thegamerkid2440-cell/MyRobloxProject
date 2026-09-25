-- CombinedScript.lua
-- Self-contained server/client Roblox Luau script.
--
-- This file combines the original server startup, shared MathUtil behavior,
-- client startup, GUI behavior, and the tall-avatar menu. It is designed to be
-- used as a Script on the server and as a LocalScript on the client. Roblox
-- still requires those separate execution contexts; this file detects which
-- context it is running in and executes the appropriate section.
--
-- This uses only normal Roblox Studio APIs. It does not use exploit APIs,
-- loadstring, or external code execution.

local RunService = game:GetService("RunService")

--==================================================
-- Shared functionality
--==================================================

local MathUtil = {}

function MathUtil.add(firstNumber: number, secondNumber: number): number
	return firstNumber + secondNumber
end

local REMOTES_FOLDER_NAME = "Remotes"
local TALL_AVATAR_REMOTE_NAME = "SetTallAvatar"
local TALL_AVATAR_ATTRIBUTE = "CombinedScriptTallAvatar"

--==================================================
-- Server section
--==================================================

if RunService:IsServer() then
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if not sharedFolder then
		sharedFolder = Instance.new("Folder")
		sharedFolder.Name = "Shared"
		sharedFolder.Parent = ReplicatedStorage
	end

	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end

	local tallAvatarRemote = remotesFolder:FindFirstChild(TALL_AVATAR_REMOTE_NAME)
	if not tallAvatarRemote then
		tallAvatarRemote = Instance.new("RemoteEvent")
		tallAvatarRemote.Name = TALL_AVATAR_REMOTE_NAME
		tallAvatarRemote.Parent = remotesFolder
	end

	local function applyTallAvatar(player: Player, character: Model?)
		local targetCharacter = character or player.Character
		if not targetCharacter then
			return
		end

		local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
			return
		end

		-- Preserve the player's existing avatar and change only R15 proportions.
		local success, description = pcall(function()
			return humanoid:GetAppliedDescription()
		end)
		if not success or not description then
			return
		end

		description.BodyHeightScale = 1.35
		description.BodyWidthScale = 0.65
		description.BodyDepthScale = 0.65
		description.HeadScale = 0.9

		pcall(function()
			humanoid:ApplyDescription(description)
		end)
	end

	local function watchPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			if player:GetAttribute(TALL_AVATAR_ATTRIBUTE) == true then
				-- Wait briefly for the character's HumanoidDescription to be ready.
				task.defer(function()
					character:WaitForChild("Humanoid", 10)
					task.wait(0.25)
					applyTallAvatar(player, character)
				end)
			end
		end)
	end

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end

	tallAvatarRemote.OnServerEvent:Connect(function(player: Player)
		-- The server owns the change; the client only requests it.
		player:SetAttribute(TALL_AVATAR_ATTRIBUTE, true)
		applyTallAvatar(player)
	end)

	print("Server started. Example result:", MathUtil.add(2, 3))
	return
end

--==================================================
-- Client section
--==================================================

if RunService:IsClient() then
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local player = Players.LocalPlayer
	if not player then
		return
	end

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	local tallAvatarRemote = remotesFolder:WaitForChild(TALL_AVATAR_REMOTE_NAME) :: RemoteEvent

	print("Client started for", player.Name)

	-- Avoid making duplicate menus if the same file is accidentally placed in
	-- more than one client container during development.
	local playerGui = player:WaitForChild("PlayerGui")
	local existingGui = playerGui:FindFirstChild("CombinedTallAvatarGui")
	if existingGui then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CombinedTallAvatarGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local menu = Instance.new("Frame")
	menu.Name = "TallAvatarMenu"
	menu.Size = UDim2.fromOffset(300, 175)
	menu.Position = UDim2.new(0.5, -150, 0.5, -87)
	menu.BackgroundColor3 = Color3.fromRGB(32, 35, 45)
	menu.BorderSizePixel = 0
	menu.Active = true
	menu.Parent = screenGui

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0, 10)
	menuCorner.Parent = menu

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 42)
	titleBar.BackgroundColor3 = Color3.fromRGB(48, 52, 67)
	titleBar.BorderSizePixel = 0
	titleBar.Active = true
	titleBar.Parent = menu

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -55, 1, 0)
	title.Position = UDim2.fromOffset(14, 0)
	title.BackgroundTransparency = 1
	title.Text = "Avatar Menu"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 19
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.fromOffset(34, 34)
	closeButton.Position = UDim2.new(1, -39, 0, 4)
	closeButton.BackgroundColor3 = Color3.fromRGB(190, 65, 70)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 18
	closeButton.Font = Enum.Font.GothamBold
	closeButton.AutoButtonColor = true
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 7)
	closeCorner.Parent = closeButton

	local tallButton = Instance.new("TextButton")
	tallButton.Name = "TallAvatarButton"
	tallButton.Size = UDim2.new(1, -32, 0, 52)
	tallButton.Position = UDim2.fromOffset(16, 67)
	tallButton.BackgroundColor3 = Color3.fromRGB(67, 125, 218)
	tallButton.Text = "Change Avatar to Tall Avatar"
	tallButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	tallButton.TextSize = 16
	tallButton.Font = Enum.Font.GothamSemibold
	tallButton.AutoButtonColor = true
	tallButton.Parent = menu

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = tallButton

	local helpText = Instance.new("TextLabel")
	helpText.Name = "HelpText"
	helpText.Size = UDim2.new(1, -32, 0, 28)
	helpText.Position = UDim2.fromOffset(16, 128)
	helpText.BackgroundTransparency = 1
	helpText.Text = "Drag the title bar to move this menu"
	helpText.TextColor3 = Color3.fromRGB(190, 195, 210)
	helpText.TextSize = 12
	helpText.Font = Enum.Font.Gotham
	helpText.Parent = menu

	local reopenButton = Instance.new("TextButton")
	reopenButton.Name = "ReopenButton"
	reopenButton.Size = UDim2.fromOffset(52, 52)
	reopenButton.Position = UDim2.new(0, 20, 0.5, -26)
	reopenButton.BackgroundColor3 = Color3.fromRGB(67, 125, 218)
	reopenButton.Text = "A"
	reopenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	reopenButton.TextSize = 22
	reopenButton.Font = Enum.Font.GothamBold
	reopenButton.Visible = false
	reopenButton.Active = true
	reopenButton.Parent = screenGui

	local reopenCorner = Instance.new("UICorner")
	reopenCorner.CornerRadius = UDim.new(0, 10)
	reopenCorner.Parent = reopenButton

	local function makeDraggable(handle: GuiObject, target: GuiObject)
		local dragging = false
		local dragInput: InputObject?
		local dragStart: Vector3
		local startPosition: UDim2

		local function update(input: InputObject)
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end

		handle.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPosition = target.Position
				dragInput = input
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		handle.InputChanged:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		UserInputService.InputChanged:Connect(function(input: InputObject)
			if dragging and input == dragInput then
				update(input)
			end
		end)
	end

	makeDraggable(titleBar, menu)
	makeDraggable(reopenButton, reopenButton)

	closeButton.Activated:Connect(function()
		menu.Visible = false
		reopenButton.Visible = true
	end)

	reopenButton.Activated:Connect(function()
		reopenButton.Visible = false
		menu.Visible = true
	end)

	tallButton.Activated:Connect(function()
		tallButton.Text = "Changing Avatar..."
		tallButton.AutoButtonColor = false
		tallAvatarRemote:FireServer()
		task.delay(1, function()
			if tallButton.Parent then
				tallButton.Text = "Change Avatar to Tall Avatar"
				tallButton.AutoButtonColor = true
			end
		end)
	end)
end
