--[[
    MODULE: VORTEX SURVIVAL AUTO-FARM
    COMPATIBILITY: Matches Main.lua syntax (:Section, :Toggle)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Debris = game:GetService("Debris")

-- --- [ ESPERAR A QUE CARGUE LA TAB ] ---
-- Esperamos hasta 5 segundos por si el Main tarda un poco
local FarmTab = _G.AutoFarmTab
local timeout = 0
while not FarmTab and timeout < 5 do
    task.wait(0.1)
    timeout = timeout + 0.1
    FarmTab = _G.AutoFarmTab
end

if not FarmTab then
    warn("❌ Error: AutoFarmTab no encontrada. Asegúrate de ejecutar Main.lua primero.")
    return -- Detiene el script para no dar errores feos
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
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false }
}

-- --- [ INTERFAZ UI (SYNTAX CORREGIDA) ] ---
-- Usamos :Section en lugar de :AddSection
local SectionFarm = FarmTab:Section({ Title = "🌊 Auto-Farm Inteligente" })

SectionFarm:Toggle({
    Title = "🔥 ACTIVAR FARM MAESTRO",
    Callback = function(s) FarmConfig.Enabled = s end
})

SectionFarm:Toggle({ Title = "Recoger Tickets", Callback = function(s) FarmConfig.Targets.Tickets = s end })
SectionFarm:Toggle({ Title = "Recoger Consolas", Callback = function(s) FarmConfig.Targets.Consoles = s end })
SectionFarm:Toggle({ Title = "Recoger Dinero", Callback = function(s) FarmConfig.Targets.Money = s end })
SectionFarm:Toggle({ Title = "Lucky Blocks (Auto-E)", Callback = function(s) FarmConfig.Targets.LuckyBlocks = s end })

-- --- [ FUNCIONES LÓGICAS ] ---

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

local function GetBestTarget()
    local closest = nil
    local shortestDist = math.huge
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local FoldersToScan = {}
    if FarmConfig.Targets.Tickets then table.insert(FoldersToScan, workspace:FindFirstChild("ArcadeEventTickets")) end
    if FarmConfig.Targets.Consoles then table.insert(FoldersToScan, workspace:FindFirstChild("ArcadeEventConsoles")) end
    if FarmConfig.Targets.Money then table.insert(FoldersToScan, workspace:FindFirstChild("MoneyEventParts")) end
    if FarmConfig.Targets.LuckyBlocks then table.insert(FoldersToScan, workspace:FindFirstChild("ActiveLuckyBlocks")) end

    for _, folder in pairs(FoldersToScan) do
        if folder then
            for _, item in pairs(folder:GetChildren()) do
                local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local dist = (root.Position - part.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = item
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
                
                -- PRIORIDAD 1: ANTI-TSUNAMI
                if IsTsunamiActive() then
                    local safePos = GetClosestSafeZone()
                    if safePos then
                        if (root.Position - safePos).Magnitude > 5 then
                            hum:MoveTo(safePos)
                            if not workspace:FindFirstChild("VortexAlert") then
                                local hint = Instance.new("Hint", workspace)
                                hint.Name = "VortexAlert"; hint.Text = "🌊 ¡TSUNAMI! CORRIENDO A ZONA SEGURA 🌊"
                                Debris:AddItem(hint, 2)
                            end
                        else
                            hum:MoveTo(root.Position) -- Quedarse quieto
                        end
                    end
                
                -- PRIORIDAD 2: FARMEO
                else
                    local targetModel = GetBestTarget()
                    if targetModel then
                        local targetPart = targetModel:IsA("BasePart") and targetModel or targetModel:FindFirstChildWhichIsA("BasePart", true)
                        
                        if targetPart then
                            hum:MoveTo(targetPart.Position)
                            if (root.Position - targetPart.Position).Magnitude < 8 then
                                local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then fireproximityprompt(prompt) end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)
