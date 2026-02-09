--[[
    MODULE: UTILITIES & SYSTEM
    FEATURES: VIP Bypass, Instant Prompt, Server Hop, FPS Boost
]]

local Section = _G.UtilitiesTab:Section({ Title = "Ventajas de Juego" })
local SystemSection = _G.UtilitiesTab:Section({ Title = "Sistema y Rendimiento" })

-- --- [ GAMEPLAY ] ---

-- 1. VIP & WALL BYPASS
local VIPEnabled = false
Section:Toggle({
    Title = "Desbloquear VIP y Muros",
    Callback = function(state)
        VIPEnabled = state
        if state then
            task.spawn(function()
                while VIPEnabled do
                    pcall(function()
                        local vips = {
                            "DefaultMap_SharedInstances", "MoneyMap_SharedInstances", 
                            "MarsMap_SharedInstances", "RadioactiveMap_SharedInstances", 
                            "ArcadeMap_SharedInstances"
                        }
                        for _, name in pairs(vips) do
                            local folder = workspace:FindFirstChild(name)
                            local walls = folder and folder:FindFirstChild("VIPWalls")
                            if walls then
                                for _, part in pairs(walls:GetDescendants()) do
                                    if part:IsA("BasePart") then part.CanCollide = false end
                                end
                            end
                        end
                        -- Bypass General (Muros molestos)
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v.Name == "Mud" or v.Name == "Wall" then v.CanCollide = false end
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

-- 2. INSTANT PROMPT
local InstantEnabled = false
Section:Toggle({
    Title = "Recoger Items Instantáneo",
    Callback = function(state)
        InstantEnabled = state
        if state then
            task.spawn(function()
                while InstantEnabled do
                    for _, prompt in pairs(workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then prompt.HoldDuration = 0 end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- --- [ SYSTEM TOOLS ] ---

-- 3. FPS BOOSTER (Modo Papa)
SystemSection:Button({
    Title = "🔥 FPS Boost (Borrar Texturas)",
    Callback = function()
        local terrain = workspace.Terrain
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
        
        local lighting = game.Lighting
        lighting.GlobalShadows = false
        lighting.FogEnd = 9e9
        lighting.Brightness = 0
        
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
    end
})

-- 4. SERVER HOP (Cambio de Servidor)
SystemSection:Button({
    Title = "🌎 Cambiar de Servidor (Server Hop)",
    Callback = function()
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local Api = "https://games.roblox.com/v1/games/"
        local _place = game.PlaceId
        local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
        
        local function ListServers(cursor)
            local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
            return Http:JSONDecode(Raw)
        end
        
        local Server, Next; repeat
            local Servers = ListServers(Next)
            Server = Servers.data[1]
            Next = Servers.nextPageCursor
        until Server
        
        TPS:TeleportToPlaceInstance(_place, Server.id, game.Players.LocalPlayer)
    end
})

-- 5. REJOIN (Reconectar)
SystemSection:Button({
    Title = "🔄 Rejoin (Reconectar)",
    Callback = function()
        local ts = game:GetService("TeleportService")
        local p = game:Players.LocalPlayer
        ts:Teleport(game.PlaceId, p)
    end
})
