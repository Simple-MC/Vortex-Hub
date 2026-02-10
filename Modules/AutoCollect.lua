--[[
    MODULE: VORTEX SURVIVAL AUTO-FARM (ULTIMATE EDITION)
    FEATURES:
    1. Smart NoClip (Prevents getting stuck/spinning)
    2. Absolute Priority: Tsunami > Closest Item
    3. Omniscient Scanner: Detects Tickets, Gold, Brainrots & LuckyBlocks
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- --- [ ESPERAR A LA TAB (Seguridad) ] ---
local FarmTab = _G.AutoFarmTab
local timeout = 0
while not FarmTab and timeout < 5 do
    task.wait(0.1); timeout = timeout + 0.1; FarmTab = _G.AutoFarmTab
end

if not FarmTab then
    warn("❌ AutoFarmTab no encontrada. Ejecuta Main.lua primero.")
    return
end

-- --- [ ZONAS SEGURAS ] ---
local SafeZones = {
    {cf = CFrame.new(199.82, -6.38, -4.25)},
    {cf = CFrame.new(285.12, -6.38, -6.46)},
    {cf = CFrame.new(396.30, -6.38, -3.62)},
    {cf = CFrame.new(541.78, -6.38, 1.57)},
    {cf = CFrame.new(755.17, -6.38, 0.97)},
    {cf = CFrame.new(1072.66, -6.38, -1.53)},
    {cf = CFrame.new(1548.96, -6.38, -0.52)},
    {cf = CFrame.new(2244.32, -6.38, -6.54)},
    {cf = CFrame.new(2598.85, -6.38, 6.92)},
}

-- --- [ CONFIGURACIÓN ] ---
local FarmConfig = {
    Enabled = false,
    Targets = {
        Tickets = false,
        Consoles = false,
        Money = false,
        LuckyBlocks = false,
        Brainrots = false
    }
}

-- --- [ INTERFAZ UI ] ---
local SectionFarm = FarmTab:Section({ Title = "🌊 Auto-Farm & Survival" })

SectionFarm:Toggle({
    Title = "🔥 ACTIVAR FARM MAESTRO",
    Desc = "Prioriza Tsunami > Items más cercanos",
    Callback = function(s) FarmConfig.Enabled = s end
})

SectionFarm:Toggle({ Title = "Recoger Tickets", Callback = function(s) FarmConfig.Targets.Tickets = s end })
SectionFarm:Toggle({ Title = "Recoger Consolas", Callback = function(s) FarmConfig.Targets.Consoles = s end })
SectionFarm:Toggle({ Title = "Recoger Dinero", Callback = function(s) FarmConfig.Targets.Money = s end })
SectionFarm:Toggle({ Title = "Lucky Blocks (Auto-E)", Callback = function(s) FarmConfig.Targets.LuckyBlocks = s end })
SectionFarm:Toggle({ Title = "Recoger Brainrots", Callback = function(s) FarmConfig.Targets.Brainrots = s end })

-- --- [ FUNCIONES LÓGICAS ] ---

-- Activa NoClip para evitar trabarse en el piso/paredes
local function ActivateNoClip()
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                -- Mantenemos el Torso/RootPart con colisión a veces para no caer al vacío infinito
                -- Pero si se traba mucho, mejor quitar todo.
                part.CanCollide = false 
            end
        end
    end
end

local function IsTsunamiActive()
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    return folder and #folder:GetChildren() > 0
end

local function GetClosestSafeZone()
    local closestPos = nil
    local shortestDist = math.huge
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        for _, zoneData in pairs(SafeZones) do
            local safePos = zoneData.cf.Position 
            local dist = (root.Position - safePos).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closestPos = safePos
            end
        end
    end
    return closestPos
end

-- EL CEREBRO DEL FARM: Busca TODO y devuelve LO MÁS CERCANO
local function GetBestTarget()
    local closest = nil
    local shortestDist = math.huge
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local ObjectsToCheck = {}

    -- 1. Agregar Tickets
    if FarmConfig.Targets.Tickets then 
        local f = workspace:FindFirstChild("ArcadeEventTickets")
        if f then for _,v in pairs(f:GetChildren()) do table.insert(ObjectsToCheck, v) end end
    end
    
    -- 2. Agregar Consolas
    if FarmConfig.Targets.Consoles then 
        local f = workspace:FindFirstChild("ArcadeEventConsoles")
        if f then for _,v in pairs(f:GetChildren()) do table.insert(ObjectsToCheck, v) end end
    end
    
    -- 3. Agregar Dinero
    if FarmConfig.Targets.Money then 
        local f = workspace:FindFirstChild("MoneyEventParts")
        if f then for _,v in pairs(f:GetChildren()) do table.insert(ObjectsToCheck, v) end end
    end

    -- 4. Agregar Lucky Blocks (Recursivo por si usan carpetas)
    if FarmConfig.Targets.LuckyBlocks then 
        local f = workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then 
            for _,v in pairs(f:GetDescendants()) do 
                if v:IsA("Model") then table.insert(ObjectsToCheck, v) end 
            end 
        end
    end

    -- 5. Agregar Brainrots (Buscando dentro de carpetas de rareza)
    if FarmConfig.Targets.Brainrots then 
        local f = workspace:FindFirstChild("ActiveBrainrots")
        if f then 
            for _, rareza in pairs(f:GetChildren()) do
                -- Buscar dentro de la carpeta de rareza
                for _, mob in pairs(rareza:GetChildren()) do
                    -- Si hay contenedor 'RenderedBrainrot', entrar ahí
                    if mob.Name == "RenderedBrainrot" then
                        for _, realMob in pairs(mob:GetChildren()) do
                            if realMob:IsA("Model") then table.insert(ObjectsToCheck, realMob) end
                        end
                    elseif mob:IsA("Model") then
                        table.insert(ObjectsToCheck, mob)
                    end
                end
            end 
        end
    end

    -- COMPARAR DISTANCIAS DE TODO LO ENCONTRADO
    for _, item in pairs(ObjectsToCheck) do
        local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
        if part then
            local dist = (root.Position - part.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closest = item
            end
        end
    end

    return closest
end

-- --- [ MOTOR PRINCIPAL ] ---

-- Loop NoClip constante (Para que no te trabes NUNCA)
RunService.Stepped:Connect(function()
    if FarmConfig.Enabled then
        ActivateNoClip()
    end
end)

task.spawn(function()
    while true do
        if FarmConfig.Enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if hum and root and hum.Health > 0 then
                
                -- ==========================================
                -- [ PRIORIDAD 1: ANTI-TSUNAMI (PAUSA TODO LO DEMÁS) ]
                -- ==========================================
                if IsTsunamiActive() then
                    local safePos = GetClosestSafeZone()
                    if safePos then
                        -- Si estamos lejos, corremos
                        if (root.Position - safePos).Magnitude > 5 then
                            hum:MoveTo(safePos)
                            
                            -- Feedback visual
                            if not workspace:FindFirstChild("VortexAlert") then
                                local hint = Instance.new("Hint", workspace)
                                hint.Name = "VortexAlert"; hint.Text = "🌊 ¡TSUNAMI! PAUSANDO FARMEO -> ZONA SEGURA"
                                Debris:AddItem(hint, 2)
                            end
                        else
                            -- Si ya llegamos, nos quedamos quietos
                            hum:MoveTo(root.Position) 
                        end
                    end
                
                -- ==========================================
                -- [ PRIORIDAD 2: FARMEO (SOLO SI NO HAY TSUNAMI) ]
                -- ==========================================
                else
                    local targetModel = GetBestTarget()
                    
                    if targetModel then
                        local targetPart = targetModel:IsA("BasePart") and targetModel or targetModel:FindFirstChildWhichIsA("BasePart", true)
                        
                        if targetPart then
                            hum:MoveTo(targetPart.Position)
                            
                            local dist = (root.Position - targetPart.Position).Magnitude
                            
                            -- INTERACCIÓN AUTOMÁTICA
                            if dist < 10 then
                                -- 1. Intentar ProximityPrompt (Lucky Blocks / Brainrots interactuables)
                                local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then 
                                    fireproximityprompt(prompt) 
                                end
                                
                                -- 2. Si es un Ticket o Dinero, caminar encima basta (MoveTo lo hace)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1) -- Velocidad de actualización
    end
end)
