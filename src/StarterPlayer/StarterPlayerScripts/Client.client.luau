-- StarterPlayer/StarterPlayerScripts/Client.client.luau
-- This LocalScript runs for each player. Put client-only input and interface logic here.
-- Never trust client input for rewards, damage, currency, or other game rules.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
print("Client started for", player.Name)
