-- ServerScriptService/Server.server.luau
-- This Script runs on the server. Put trusted game rules and server-only setup here.
-- It uses only standard Roblox Studio Luau APIs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local mathUtil = require(sharedFolder:WaitForChild("MathUtil"))

print("Server started. Example result:", mathUtil.add(2, 3))
