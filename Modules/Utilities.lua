--[[
    MODULE: UTILITIES
    FEATURES: Free VIP (Wall Bypass), Instant Prompt, FPS Boost, Server Hop
]]

local Section = _G.UtilitiesTab:Section({ Title = "Ventajas de Mapa" })
local SystemSection = _G.UtilitiesTab:Section({ Title = "Sistema y Rendimiento" })
local Player = game.Players.LocalPlayer

-- --- [ 1. FREE VIP & WALL BYPASS ] ---
_G.VIPEnabled = false
local Almacen = game:GetService("Lighting")
local MapaAlmacenado = {} -- Tabla para recordar el origen de cada carpeta VIP

Section:Toggle({
    Title = "Desbloquear VIP (Mover a Almacén)",
    Callback = function(state)
        _G.VIPEnabled = state
        
        -- Lista de las rutas de los mapas
        local rutasMapas = {
            workspace:FindFirstChild("DefaultMap_SharedInstances"),
            workspace:FindFirstChild("MoneyMap_SharedInstances"),
            workspace:FindFirstChild("MarsMap_SharedInstances"),
            workspace:FindFirstChild("RadioactiveMap_SharedInstances"),
            workspace:FindFirstChild("ArcadeMap_SharedInstances")
        }

        if state then
            -- --- MODO ACTIVADO: Enviar a Lighting ---
            for _, mapa in pairs(rutasMapas) do
                if mapa then
                    local vipWalls = mapa:FindFirstChild("VIPWalls")
                    if vipWalls then
                        -- Guardamos quién es su "papá" original antes de moverlo
                        MapaAlmacenado[vipWalls] = mapa
                        vipWalls.Parent = Almacen
                    end
                end
            end
        else
            -- --- MODO DESACTIVADO: Regresar a su mapa ---
            for objetoVip, destinoOriginal in pairs(MapaAlmacenado) do
                if objetoVip and destinoOriginal then
                    objetoVip.Parent = destinoOriginal
                end
            end
            -- Limpiamos la tabla para que no ocupe memoria
            MapaAlmacenado = {}
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
