--[[
    MODULE: VORTEX SURVIVAL AUTO-FARM
    LOGIC: Survival First > Farming Second
    FEATURES: Anti-Tsunami, Safe Zones, Auto-Interact (Prompts)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PathfindingService = game:GetService("PathfindingService")

-- --- [ ZONAS SEGURAS (Tus coordenadas) ] ---
local SafeZones = {
    CFrame.new(199.82, -6.38, -4.25),
    CFrame.new(285.12, -6.38, -6.46),
    CFrame.new(396.30, -6.38, -3.62),
    CFrame.new(541.78, -6.38, 1.57),
    CFrame.new(755.17, -6.38, 0.97),
    CFrame.new(1072.66, -6.38, -1.53),
    CFrame.new(1548.96, -6.38, -0.52),
    CFrame.new(2244.32, -6.38, -6.54),
    CFrame.new(2598.85, -6.38, 6.92),
}

-- --- [ CONFIGURACIÓN ] ---
local FarmConfig = {
    Enabled = false,
    Targets = {
        Tickets = false,
        Consoles = false,
        Money = false,
        LuckyBlocks = false
    }
}

-- --- [ INTERFAZ UI ] ---
local SectionFarm = _G.AutoFarmTab:Section({ Title = "🌊 Auto-Farm Inteligente" })

SectionFarm:Toggle({
    Title = "🔥 ACTIVAR FARM MAESTRO",
    Callback = function(s) FarmConfig.Enabled = s end
})

SectionFarm:Toggle({ Title = "Recoger Tickets", Callback = function(s) FarmConfig.Targets.Tickets = s end })
SectionFarm:Toggle({ Title = "Recoger Consolas", Callback = function(s) FarmConfig.Targets.Consoles = s end })
SectionFarm:Toggle({ Title = "Recoger Dinero (Money)", Callback = function(s) FarmConfig.Targets.Money = s end })
SectionFarm:Toggle({ Title = "Abrir Lucky Blocks", Callback = function(s) FarmConfig.Targets.LuckyBlocks = s end })

-- --- [ LÓGICA DE SUPERVIVENCIA ] ---

-- Detectar si hay un Tsunami activo
local function IsTsunamiActive()
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if folder and #folder:GetChildren() > 0 then
        return true
    end
    return false
end

-- Buscar la Zona Segura más cercana
local function GetClosestSafeZone()
    local closestCF = nil
    local shortestDist = math.huge
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        for _, cf in pairs(SafeZones) do
            local dist = (root.Position - cf.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closestCF = cf
            end
        end
    end
    return closestCF
end

-- --- [ LÓGICA DE FARMEO ] ---

local function GetBestTarget()
    local closest = nil
    local shortestDist = math.huge
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    -- Lista de carpetas habilitadas
    local FoldersToScan = {}
    
    if FarmConfig.Targets.Tickets then table.insert(FoldersToScan, workspace:FindFirstChild("ArcadeEventTickets")) end
    if FarmConfig.Targets.Consoles then table.insert(FoldersToScan, workspace:FindFirstChild("ArcadeEventConsoles")) end
    if FarmConfig.Targets.Money then table.insert(FoldersToScan, workspace:FindFirstChild("MoneyEventParts")) end
    if FarmConfig.Targets.LuckyBlocks then table.insert(FoldersToScan, workspace:FindFirstChild("ActiveLuckyBlocks")) end

    for _, folder in pairs(FoldersToScan) do
        if folder then
            for _, item in pairs(folder:GetChildren()) do
                -- Buscar parte base
                local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local dist = (root.Position - part.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = item -- Guardamos el MODELO entero para buscar el Prompt
                    end
                end
            end
        end
    end
    return closest
end

-- --- [ MOTOR PRINCIPAL ] ---

task.spawn(function()
    while true do
        if FarmConfig.Enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if hum and root and hum.Health > 0 then
                
                -- [ PRIORIDAD 1: ANTI-TSUNAMI ]
                if IsTsunamiActive() then
                    local safeZone = GetClosestSafeZone()
                    if safeZone then
                        -- Si estamos lejos de la zona segura, corremos
                        if (root.Position - safeZone.Position).Magnitude > 3 then
                            hum:MoveTo(safeZone.Position)
                            
                            -- Aviso visual opcional
                            local hint = Instance.new("Hint", workspace)
                            hint.Text = "⚠️ TSUNAMI DETECTADO - BUSCANDO REFUGIO ⚠️"
                            game:Debris:AddItem(hint, 0.1)
                        else
                            hum:MoveTo(root.Position) -- Quedarse quieto si ya llegó
                        end
                    end
                
                -- [ PRIORIDAD 2: FARMEO ]
                else
                    local targetModel = GetBestTarget()
                    if targetModel then
                        local targetPart = targetModel:IsA("BasePart") and targetModel or targetModel:FindFirstChildWhichIsA("BasePart", true)
                        
                        if targetPart then
                            hum:MoveTo(targetPart.Position)
                            
                            local dist = (root.Position - targetPart.Position).Magnitude
                            
                            -- Si estamos cerca (menos de 8 studs)
                            if dist < 8 then
                                -- A) Intentar activar ProximityPrompt (Lucky Blocks)
                                local prompt = targetModel:FindFirstChild("ProximityPrompt", true)
                                if prompt then
                                    fireproximityprompt(prompt)
                                end
                                
                                -- B) Si no tiene prompt, el simple hecho de tocarlo (caminar encima) debería bastar
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1) -- Velocidad de reacción rápida
    end
end)
