-- CombinedScript.lua
-- Self-contained version of the current MyRobloxProject behavior.
--
-- IMPORTANT:
-- Roblox requires server and client code to run in different execution contexts.
-- This one source file supports both contexts: place it as a Script in
-- ServerScriptService and/or as a LocalScript in StarterPlayerScripts or under
-- a ScreenGui. The same source detects its context and runs the appropriate
-- section. It has no require() dependency on the original project files.

local RunService = game:GetService("RunService")

--==================================================
-- Shared functionality
--==================================================

local MathUtil = {}

function MathUtil.add(firstNumber: number, secondNumber: number): number
	return firstNumber + secondNumber
end

--==================================================
-- Server section
-- Equivalent to Server.server.luau
--==================================================

if RunService:IsServer() then
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- The original project expected these containers to be supplied by Rojo.
	-- Create them here so this file is self-contained when used by itself.
	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if not sharedFolder then
		sharedFolder = Instance.new("Folder")
		sharedFolder.Name = "Shared"
		sharedFolder.Parent = ReplicatedStorage
	end

	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	-- The shared MathUtil module is embedded above, so requiring the original
	-- ReplicatedStorage module is no longer necessary.
	print("Server started. Example result:", MathUtil.add(2, 3))

	return
end

--==================================================
-- Client section
-- Equivalent to Client.client.luau and MainGui.client.luau
--==================================================

if RunService:IsClient() then
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	if not player then
		return
	end

	print("Client started for", player.Name)

	-- If this file is placed under a ScreenGui, use that existing GUI.
	-- Otherwise create the same MainGui container that the Rojo mapping creates.
	local screenGui: ScreenGui
	if script.Parent:IsA("ScreenGui") then
		screenGui = script.Parent
	else
		local playerGui = player:WaitForChild("PlayerGui")
		screenGui = playerGui:FindFirstChild("MainGui") :: ScreenGui

		if not screenGui then
			screenGui = Instance.new("ScreenGui")
			screenGui.Name = "MainGui"
			screenGui.Parent = playerGui
		end
	end

	-- Preserve the original UI behavior.
	screenGui.ResetOnSpawn = false
end
