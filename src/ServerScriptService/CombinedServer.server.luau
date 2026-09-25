-- ServerScriptService/CombinedServer.server.luau
-- Server-authoritative Tall Avatar implementation.
-- This must run as a normal Script in ServerScriptService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PREFIX = "[TALL]"
local ERROR_PREFIX = "[TALL ERROR]"
local REMOTES_NAME = "Remotes"
local EVENT_NAME = "SetTallAvatar"
local ATTRIBUTE_NAME = "TallAvatarEnabled"

local TARGET_HEIGHT = 1.05
local TARGET_WIDTH = 0.70
local TARGET_DEPTH = 0.70
local TARGET_HEAD = 1.00

local function log(message: string, ...: any)
	print(PREFIX, message, ...)
end

local function fail(message: string, ...: any)
	warn(ERROR_PREFIX, message, ...)
end

log("SERVER STARTED")

local remotes = ReplicatedStorage:FindFirstChild(REMOTES_NAME)
if remotes and not remotes:IsA("Folder") then
	fail("ReplicatedStorage.Remotes exists but is not a Folder")
	remotes:Destroy()
	remotes = nil
end
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = REMOTES_NAME
	remotes.Parent = ReplicatedStorage
end

local event = remotes:FindFirstChild(EVENT_NAME)
if event and not event:IsA("RemoteEvent") then
	fail("Remotes.SetTallAvatar exists but is not a RemoteEvent")
	event:Destroy()
	event = nil
end
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = EVENT_NAME
	event.Parent = remotes
end
log("REMOTE READY", event:GetFullName())

local function getCharacterParts(player: Player): (Model?, Humanoid?, string?)
	local character = player.Character
	if not character or not character.Parent then
		return nil, nil, "current Character is missing"
	end
	log("CHARACTER FOUND", character:GetFullName())
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return character, nil, "Humanoid is missing"
	end
	log("HUMANOID FOUND", humanoid:GetFullName())
	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return character, humanoid, "R15 REQUIRED; rig is " .. humanoid.RigType.Name
	end
	log("R15 CONFIRMED")
	return character, humanoid, nil
end

local function applyTall(player: Player): boolean
	log("PLAYER VALID", player.Name, player.UserId)
	local character, humanoid, reason = getCharacterParts(player)
	if not humanoid then
		fail(reason or "Humanoid unavailable")
		return false
	end

	local beforeHeight = character:GetExtentsSize().Y
	local okGet, descriptionOrError = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not okGet then
		fail("GetAppliedDescription failed", descriptionOrError)
		return false
	end
	local description = descriptionOrError :: HumanoidDescription
	if not description then
		fail("GetAppliedDescription returned nil")
		return false
	end

	log("DESCRIPTION FOUND")
	log("OLD HEIGHT", description.HeightScale, "visual Y", beforeHeight)
	description.HeightScale = TARGET_HEIGHT
	description.WidthScale = TARGET_WIDTH
	description.DepthScale = TARGET_DEPTH
	description.HeadScale = TARGET_HEAD
	log("NEW HEIGHT", description.HeightScale)
	log("APPLYING DESCRIPTION")

	local okApply, applyError = pcall(function()
		-- Async APIs are the current supported appearance APIs.
		humanoid:ApplyDescriptionResetAsync(description)
	end)
	if not okApply then
		fail("ApplyDescriptionResetAsync failed", applyError)
		return false
	end
	log("DESCRIPTION APPLIED")

	local okVerify, finalDescriptionOrError = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not okVerify or not finalDescriptionOrError then
		fail("final GetAppliedDescription failed", finalDescriptionOrError)
		return false
	end
	local finalDescription = finalDescriptionOrError :: HumanoidDescription
	local afterHeight = character:GetExtentsSize().Y
	log("FINAL HEIGHT", finalDescription.HeightScale, "visual Y", afterHeight)

	if math.abs(finalDescription.HeightScale - TARGET_HEIGHT) > 0.001 then
		fail("description was applied but HeightScale was clamped/overwritten", finalDescription.HeightScale)
		return false
	end
	if afterHeight <= beforeHeight + 0.01 then
		fail("HeightScale verified, but character bounding-box height did not increase", beforeHeight, afterHeight)
		return false
	end

	player:SetAttribute(ATTRIBUTE_NAME, true)
	log("TALL AVATAR COMPLETE", player.Name)
	return true
end

local function reapplyAfterRespawn(player: Player, character: Model)
	if player:GetAttribute(ATTRIBUTE_NAME) ~= true then
		return
	end
	local appearanceLoaded = false
	local connection
	connection = player.CharacterAppearanceLoaded:Connect(function(loadedCharacter)
		if loadedCharacter == character then
			appearanceLoaded = true
			connection:Disconnect()
			applyTall(player)
		end
	end)
	task.delay(10, function()
		if connection and connection.Connected then
			connection:Disconnect()
			if not appearanceLoaded and player.Character == character then
				applyTall(player)
			end
		end
	end)
end

local function watchPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		log("CHARACTER ADDED", player.Name)
		reapplyAfterRespawn(player, character)
	end)
end

Players.PlayerAdded:Connect(watchPlayer)
for _, player in Players:GetPlayers() do
	watchPlayer(player)
end

event.OnServerEvent:Connect(function(player: Player)
	log("SERVER RECEIVED REQUEST", player.Name)
	applyTall(player)
end)
