--[[
    MODULE: VORTEX SURVIVAL AUTO-FARM (Fixed)
    FIXES: 
    1. SafeZones table format matched to user's code.
    2. UI Tab safety check (Creates window if _G.AutoFarmTab is missing).
    3. Added 'Debris' service correctly.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")

-- --- [ ZONAS SEGURAS (Formato Correcto) ] ---
-- Usamos el formato que tú tienes: {cf = CFrame...}
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
        LuckyBlocks = false
    }
}

-- --- [ INTERFAZ UI (ANTI-ERROR) ] ---
local FarmTab = _G.AutoFarmTab

-- Si no existe la pestaña (porque probamos el script solo), creamos una temporal
if not FarmTab then
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local Window = Fluent:CreateWindow({
        Title = "Vortex Debug",
        SubTitle = "Test Mode",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
    FarmTab = Window:AddTab({ Title = "AutoFarm", Icon = "" })
    print("⚠ AVISO: Se creó una ventana temporal porque _G.AutoFarmTab no existía.")
end

local SectionFarm = FarmTab:Section({ Title = "🌊 Auto-Farm Inteligente" })

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
    -- Verificamos si la carpeta existe Y tiene hijos
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
        for _, zoneData in pairs(SafeZones) do
            -- AQUÍ ESTABA EL ERROR: Accedemos a .cf.Position
            local safePos = zoneData.cf.Position 
            local dist = (root.Position - safePos).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closestCF = safePos -- Guardamos la posición (Vector3)
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
                -- Buscar parte base dentro del modelo o item
                local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local dist = (root.Position - part.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = item -- Devolvemos el objeto entero (Modelo o Parte)
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
                    local safePos = GetClosestSafeZone()
                    if safePos then
                        -- Si estamos a más de 5 studs de la zona segura, corremos
                        if (root.Position - safePos).Magnitude > 5 then
                            hum:MoveTo(safePos)
                            
                            -- Aviso visual para saber qué pasa
                            if not workspace:FindFirstChild("VortexAlert") then
                                local hint = Instance.new("Hint", workspace)
                                hint.Name = "VortexAlert"
                                hint.Text = "⚠️ TSUNAMI DETECTADO - BUSCANDO REFUGIO ⚠️"
                                Debris:AddItem(hint, 2)
                            end
                        else
                            -- Si ya llegamos, nos aseguramos de no movernos
                            hum:MoveTo(root.Position) 
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
                                -- Intentar activar ProximityPrompt (Lucky Blocks) si existe
                                local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then
                                    fireproximityprompt(prompt)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)
