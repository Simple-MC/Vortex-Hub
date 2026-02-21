--[[
    MODULE: UTILITIES
    FEATURES: Free VIP (Wall Bypass), Instant Prompt, FPS Boost, Server Hop
]]

local Section = _G.UtilitiesTab:Section({ Title = "Ventajas de Mapa" })
local SystemSection = _G.UtilitiesTab:Section({ Title = "Sistema y Rendimiento" })
local Player = game.Players.LocalPlayer

-- --- [ 1. FREE VIP & WALL BYPASS ] ---
_G.VIPEnabled = false
Section:Toggle({
    Title = "Desbloquear VIP (Free VIP)",
    Callback = function(state)
        _G.VIPEnabled = state
        if state then
            task.spawn(function()
                while _G.VIPEnabled do
                    pcall(function()
                        -- Lista de nombres de carpetas donde suelen estar los muros VIP
                        local vipFolders = {
                            "DefaultMap_SharedInstances", 
                            "MoneyMap_SharedInstances", 
                            "MarsMap_SharedInstances", 
                            "RadioactiveMap_SharedInstances", 
                            "ArcadeMap_SharedInstances"
                        }
                        
                        for _, folderName in pairs(vipFolders) do
                            local folder = workspace:FindFirstChild(folderName)
                            if folder then
                                -- Buscamos modelos o partes llamadas VIP, Wall, o Mud
                                for _, obj in pairs(folder:GetDescendants()) do
                                    if obj:IsA("BasePart") and (obj.Name:find("VIP") or obj.Name:find("Wall") or obj.Name:find("Mud")) then
                                        obj.CanCollide = false
                                        obj.Transparency = 0.5 -- Para saber que el hack está activo
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(2) -- No necesita ser tan rápido para ahorrar CPU
                end
            end)
        else
            -- Al apagar, intentamos restaurar colisiones (opcional)
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:find("VIP") or v.Name:find("Wall")) then
                        v.CanCollide = true
                        v.Transparency = 0
                    end
                end
            end)
        end
    end
})

-- --- [ 2. INSTANT PROMPT ] ---
_G.InstantEnabled = false
Section:Toggle({
    Title = "Recoger Items Instantáneo",
    Callback = function(v) _G.InstantEnabled = v end
})

task.spawn(function()
    while true do
        if _G.InstantEnabled then
            pcall(function()
                for _, p in pairs(workspace:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        p.HoldDuration = 0
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- --- [ 3. SYSTEM TOOLS ] ---

-- FPS BOOST
SystemSection:Button({
    Title = "🔥 FPS Boost (Modo Papa)",
    Callback = function()
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v:Destroy()
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Enabled = false
                end
            end
        end)
    end
})

-- SERVER HOP
SystemSection:Button({
    Title = "🌎 Cambiar de Servidor",
    Callback = function()
        local ts = game:GetService("TeleportService")
        pcall(function()
            ts:Teleport(game.PlaceId, Player)
        end)
    end
})
