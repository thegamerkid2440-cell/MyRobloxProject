-- CombinedScript.lua
-- Single-source Tall Avatar system for a Roblox experience.
--
-- IMPORTANT INSTALLATION LIMITATION:
-- Roblox cannot execute one Script instance in both server and client contexts.
-- This same source must be installed as:
--   1) a normal Script in ServerScriptService, and
--   2) a normal LocalScript in StarterPlayerScripts (or StarterGui).
-- The server creates the RemoteEvent and owns avatar changes; the client owns
-- the UI and sends a request. No exploit APIs, loadstring, or external code.

local RunService = game:GetService("RunService")
local DEBUG = true

local REMOTES_FOLDER_NAME = "Remotes"
local TALL_AVATAR_REMOTE_NAME = "SetTallAvatar"
local TALL_AVATAR_ATTRIBUTE = "CombinedScriptTallAvatar"

local function log(tag: string, ...: any)
	if DEBUG then
		print("[TallAvatar][" .. tag .. "]", ...)
	end
end

local function warnLog(tag: string, ...: any)
	warn("[TallAvatar][" .. tag .. "]", ...)
end

--==================================================
-- Shared behavior from the original project
--==================================================

local MathUtil = {}
function MathUtil.add(firstNumber: number, secondNumber: number): number
	return firstNumber + secondNumber
end

--==================================================
-- SERVER: ServerScriptService/CombinedScript.lua
--==================================================

if RunService:IsServer() then
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	log("START", "server branch running")

	local remotes = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotes and not remotes:IsA("Folder") then
		warnLog("CONFIG", "ReplicatedStorage.Remotes exists but is not a Folder")
		remotes:Destroy()
		remotes = nil
	end
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = REMOTES_FOLDER_NAME
		remotes.Parent = ReplicatedStorage
	end

	local requestEvent = remotes:FindFirstChild(TALL_AVATAR_REMOTE_NAME)
	if requestEvent and not requestEvent:IsA("RemoteEvent") then
		warnLog("CONFIG", "Remotes.SetTallAvatar exists but is not a RemoteEvent")
		requestEvent:Destroy()
		requestEvent = nil
	end
	if not requestEvent then
		requestEvent = Instance.new("RemoteEvent")
		requestEvent.Name = TALL_AVATAR_REMOTE_NAME
		requestEvent.Parent = remotes
	end

	local function findHumanoid(player: Player, character: Model?): Humanoid?
		local target = character or player.Character
		if not target or not target:IsDescendantOf(game) then
			warnLog("CHARACTER", "character is missing or no longer in the DataModel")
			return nil
		end
		log("CHARACTER", target:GetFullName())
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			warnLog("HUMANOID", "no Humanoid found in " .. target:GetFullName())
			return nil
		end
		log("HUMANOID", humanoid:GetFullName(), "rig=", humanoid.RigType.Name)
		return humanoid
	end

	local function applyTallAvatar(player: Player, character: Model?): (boolean, string)
		log("FUNCTION", "applyTallAvatar called for", player.Name)
		local humanoid = findHumanoid(player, character)
		if not humanoid then
			return false, "Humanoid not found"
		end
		if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
			warnLog("RIG TYPE", "Tall Avatar scaling requires R15; found " .. humanoid.RigType.Name)
			return false, "R15 is required"
		end

		local okDescription, descriptionOrError = pcall(function()
			return humanoid:GetAppliedDescription()
		end)
		if not okDescription then
			warnLog("DESCRIPTION", "GetAppliedDescription failed:", descriptionOrError)
			return false, "GetAppliedDescription failed"
		end
		local description = descriptionOrError :: HumanoidDescription
		if not description then
			return false, "No HumanoidDescription returned"
		end
		log("DESCRIPTION", "base description obtained")

		-- CONFIRMED API FIX: HumanoidDescription uses HeightScale, WidthScale,
		-- DepthScale, and HeadScale. BodyHeightScale/BodyWidthScale/
		-- BodyDepthScale are not HumanoidDescription properties; assigning those
		-- names throws and the old pcall hid the failure.
		log("BEFORE", "height", description.HeightScale, "width", description.WidthScale, "depth", description.DepthScale, "head", description.HeadScale)
		description.HeightScale = 1.35
		description.WidthScale = 0.65
		description.DepthScale = 0.65
		description.HeadScale = 0.90
		log("SETTING SCALE", "height=1.35 width=0.65 depth=0.65 head=0.90")

		local applied = false
		local applyError
		-- Reset is useful when another script has altered the character model;
		-- fall back to the ordinary supported application method if unavailable or
		-- rejected by the current engine state.
		local okReset, resetError = pcall(function()
			humanoid:ApplyDescriptionReset(description)
		end)
		if okReset then
			applied = true
		else
			applyError = resetError
			warnLog("APPLY", "ApplyDescriptionReset failed; trying ApplyDescription:", resetError)
			local okApply, normalError = pcall(function()
				humanoid:ApplyDescription(description)
			end)
			if okApply then
				applied = true
			else
				applyError = normalError
			end
		end
		if not applied then
			warnLog("APPLY", "both supported appearance calls failed:", applyError)
			return false, "ApplyDescription failed"
		end

		log("AFTER", "description applied")
		local verifyOk, verifiedOrError = pcall(function()
			return humanoid:GetAppliedDescription()
		end)
		if verifyOk and verifiedOrError then
			local verified = verifiedOrError :: HumanoidDescription
			log("CHARACTER UPDATED", "height", verified.HeightScale, "width", verified.WidthScale, "depth", verified.DepthScale, "head", verified.HeadScale)
		else
			warnLog("FINAL RESULT", "could not read applied description:", verifiedOrError)
		end

		-- These values are useful diagnostics. They are generated by R15 and may
		-- be absent briefly or on custom rigs; HumanoidDescription remains the
		-- authoritative supported input above.
		for _, name in {"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale"} do
			local value = humanoid:FindFirstChild(name)
			if value and value:IsA("NumberValue") then
				log("SCALE FOUND", name, value.Value)
			else
				warnLog("SCALE", name .. " NumberValue is not present on this character")
			end
		end
		log("FINAL RESULT", "server accepted tall-avatar request for", player.Name)
		return true, "Tall Avatar applied"
	end

	local function applyAfterAppearance(player: Player, character: Model)
		task.defer(function()
			if not character:IsDescendantOf(game) then
				return
			end
			-- CharacterAppearanceLoaded is preferred; this small defer only lets
			-- final character parenting settle and is not the primary synchronization.
			local success, reason = applyTallAvatar(player, character)
			if not success then
				warnLog("RESPAWN", player.Name, reason)
			end
		end)
	end

	local function watchPlayer(player: Player)
		log("PLAYER", "watching", player.Name)
		player.CharacterAppearanceLoaded:Connect(function(character)
			log("CHARACTER", "appearance loaded for", player.Name)
			if player:GetAttribute(TALL_AVATAR_ATTRIBUTE) == true then
				applyAfterAppearance(player, character)
			end
		end)
		player.CharacterAdded:Connect(function(character)
			log("CHARACTER", "added for", player.Name)
			if player:GetAttribute(TALL_AVATAR_ATTRIBUTE) == true then
				-- Fallback for unusual/custom character pipelines that never fire
				-- CharacterAppearanceLoaded.
				task.delay(3, function()
					if character.Parent and player.Character == character and player:GetAttribute(TALL_AVATAR_ATTRIBUTE) == true then
						applyAfterAppearance(player, character)
					end
				end)
			end
		end)
	end

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end

	requestEvent.OnServerEvent:Connect(function(player: Player)
		log("REMOTE", "SetTallAvatar received from", player.Name)
		player:SetAttribute(TALL_AVATAR_ATTRIBUTE, true)
		local success, reason = applyTallAvatar(player)
		if not success then
			warnLog("REMOTE", player.Name, reason)
		end
	end)

	print("Server started. Example result:", MathUtil.add(2, 3))
	return
end

--==================================================
-- CLIENT: StarterPlayerScripts/CombinedScript.lua
--==================================================

if RunService:IsClient() then
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	local player = Players.LocalPlayer
	if not player then
		warnLog("PLAYER", "LocalPlayer is unavailable; client script is not running in a valid client context")
		return
	end

	log("START", "client branch running for", player.Name)
	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME, 15)
	if not remotes then
		warnLog("CONFIG", "ReplicatedStorage.Remotes was not created; install the server copy in ServerScriptService")
		return
	end
	local requestEvent = remotes:WaitForChild(TALL_AVATAR_REMOTE_NAME, 15)
	if not requestEvent or not requestEvent:IsA("RemoteEvent") then
		warnLog("CONFIG", "Remotes.SetTallAvatar is missing or is not a RemoteEvent")
		return
	end
	local playerGui = player:WaitForChild("PlayerGui", 15)
	if not playerGui then
		warnLog("UI", "PlayerGui did not become available")
		return
	end

	local oldGui = playerGui:FindFirstChild("CombinedTallAvatarGui")
	if oldGui then oldGui:Destroy() end
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
	title.Size = UDim2.new(1, -55, 1, 0)
	title.Position = UDim2.fromOffset(14, 0)
	title.BackgroundTransparency = 1
	title.Text = "Avatar Menu"
	title.TextColor3 = Color3.new(1, 1, 1)
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
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextSize = 18
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar

	local tallButton = Instance.new("TextButton")
	tallButton.Name = "TallAvatarButton"
	tallButton.Size = UDim2.new(1, -32, 0, 52)
	tallButton.Position = UDim2.fromOffset(16, 67)
	tallButton.BackgroundColor3 = Color3.fromRGB(67, 125, 218)
	tallButton.Text = "Change Avatar to Tall Avatar"
	tallButton.TextColor3 = Color3.new(1, 1, 1)
	tallButton.TextSize = 16
	tallButton.Font = Enum.Font.GothamSemibold
	tallButton.Parent = menu
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = tallButton

	local helpText = Instance.new("TextLabel")
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
	reopenButton.TextColor3 = Color3.new(1, 1, 1)
	reopenButton.TextSize = 22
	reopenButton.Font = Enum.Font.GothamBold
	reopenButton.Visible = false
	reopenButton.Active = true
	reopenButton.Parent = screenGui

	local function makeDraggable(handle: GuiObject, target: GuiObject)
		local dragging = false
		local dragStart: Vector3
		local startPosition: UDim2
		local dragInput: InputObject?
		local function update(input: InputObject)
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		end
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPosition = target.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		handle.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input == dragInput then update(input) end
		end)
	end

	makeDraggable(titleBar, menu)
	makeDraggable(reopenButton, reopenButton)
	closeButton.Activated:Connect(function()
		log("UI", "X pressed")
		menu.Visible = false
		reopenButton.Visible = true
	end)
	reopenButton.Activated:Connect(function()
		log("UI", "reopen button pressed")
		reopenButton.Visible = false
		menu.Visible = true
	end)
	tallButton.Activated:Connect(function()
		log("BUTTON PRESSED", "Change Avatar to Tall Avatar")
		tallButton.Text = "Changing Avatar..."
		tallButton.AutoButtonColor = false
		log("REMOTE", "sending SetTallAvatar")
		requestEvent:FireServer()
		task.delay(1, function()
			if tallButton.Parent then
				tallButton.Text = "Change Avatar to Tall Avatar"
				tallButton.AutoButtonColor = true
			end
		end)
	end)
	log("UI", "menu initialized")
end
