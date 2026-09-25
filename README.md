# MyRobloxProject

The active runtime implementation uses two Roblox script instances from two source files because Roblox requires separate server and client execution contexts.

## Active hierarchy

```text
ReplicatedStorage
├── Shared
└── Remotes
ServerScriptService
└── CombinedServer (Script)
StarterPlayer
└── StarterPlayerScripts
    └── CombinedClient (LocalScript)
```

Rojo maps `src/ServerScriptService/CombinedServer.server.luau` and `src/StarterPlayer/StarterPlayerScripts/CombinedClient.client.luau` into that hierarchy. The old starter scripts are no longer mapped.

The server creates `ReplicatedStorage.Remotes.SetTallAvatar`. The client creates the touch-compatible GUI and sends a request. The server verifies R15, modifies `HumanoidDescription.HeightScale`, `WidthScale`, `DepthScale`, and `HeadScale`, then applies the description with the current async API.

Roblox limits avatar-description scale ranges. This project uses a conservative height of `1.05`, width/depth `0.70`, and head `1.00`; values outside the platform's supported range can be clamped or rejected. R6 is reported as unsupported.
