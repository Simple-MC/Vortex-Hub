--[[
    MODULE: VORTEX COLLECTOR (SMART INVENTORY)
    FEATURES:
    1. Select Specific Targets (Dropdowns)
    2. Inventory Management (Return to Base after X items)
    3. Proxy Memory (Ignores collected items)
    4. Set Home Button
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- --- [ SEGURIDAD DE TAB ] ---
local FarmTab = _G.AutoFarmTab
local timeout = 0
while not FarmTab and timeout < 5 do task.wait(0.1); timeout = timeout+0.1; FarmTab = _G.AutoFarmTab end
if not FarmTab then warn("❌ Falta AutoFarmTab"); return end

-- --- [ VARIABLES DE ESTADO ] ---
local HomeCFrame = nil -- Aquí se guardará tu base
local CollectedCount = 0 -- Contador de items
local MaxInventory = 4 -- Límite antes de regresar
local ProcessedIDs = {} -- Memoria de lo que ya recogimos

-- --- [ ZONAS SEGURAS (Anti-Tsunami) ] ---
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
    Speed = 300,
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false, Brainrots = false },
    Selection = { LuckyBlocks = {}, Brainrots = {} } -- Listas del Dropdown
}

-- --- [ FUNCIONES DE LISTA (Igual que el ESP) ] ---
local function GetRarityNames()
    local names = {}
    local folder = ReplicatedStorage.Assets:FindFirstChild("Brainrots")
    if folder then for _, f in pairs(folder:GetChildren()) do if f:IsA("Folder") then table.insert(names, f.Name) end end end
    table.sort(names)
    return names
end

local function GetLuckyBlockNames()
    local names = {}
    local folder = ReplicatedStorage.Assets:FindFirstChild("LuckyBlocks")
    if folder then for _, f in pairs(folder:GetChildren()) do table.insert(names, f.Name) end end
    table.sort(names)
    return names
end

-- --- [ UI INTERFACE ] ---
local SectionFarm = FarmTab:Section({ Title = "🎒 Recolección Inteligente" })

SectionFarm:Toggle({
    Title = "🔥 ACTIVAR AUTO-COLLECT",
    Desc = "Prioridad: Tsunami > Inventario Lleno > Items",
    Callback = function(s) 
        FarmConfig.Enabled = s 
        if s then CollectedCount = 0 end -- Reiniciar contador al activar
    end
})

-- BOTÓN DE CASA
SectionFarm:Button({
    Title = "🏠 Fijar Punto de Inicio (BASE)",
    Desc = "Guarda tu posición actual como 'Casa'",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            HomeCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            WindUI:Notify({ Title = "Ubicación Guardada", Content = "Volveré aquí cuando el inventario esté lleno.", Duration = 3 })
        end
    end
})

-- BOTÓN DE LIMPIEZA
SectionFarm:Button({
    Title = "🗑️ Resetear Memoria",
    Desc = "Olvida los items recogidos (Si se bugea)",
    Callback = function() ProcessedIDs = {}; CollectedCount = 0 end
})

-- CATEGORÍAS SIMPLES
SectionFarm:Toggle({ Title = "Recoger Tickets", Callback = function(s) FarmConfig.Targets.Tickets = s end })
SectionFarm:Toggle({ Title = "Recoger Consolas", Callback = function(s) FarmConfig.Targets.Consoles = s end })
SectionFarm:Toggle({ Title = "Recoger Dinero", Callback = function(s) FarmConfig.Targets.Money = s end })

-- CATEGORÍAS CON DROPDOWN
SectionFarm:Toggle({ Title = "Recoger Lucky Blocks", Callback = function(s) FarmConfig.Targets.LuckyBlocks = s end })
SectionFarm:Dropdown({
    Title = "Seleccionar Lucky Blocks",
    Multi = true,
    Values = GetLuckyBlockNames(),
    Callback = function(v) FarmConfig.Selection.LuckyBlocks = v end
})

SectionFarm:Toggle({ Title = "Recoger Brainrots", Callback = function(s) FarmConfig.Targets.Brainrots = s end })
SectionFarm:Dropdown({
    Title = "Seleccionar Rareza (Brainrots)",
    Multi = true,
    Values = GetRarityNames(),
    Callback = function(v) FarmConfig.Selection.Brainrots = v end
})


-- --- [ MOTOR DE MOVIMIENTO ] ---
local CurrentTween = nil

local function MoverRapido(DestinoCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local Distancia = (root.Position - DestinoCFrame.Position).Magnitude
    local Tiempo = Distancia / FarmConfig.Speed
    local Info = TweenInfo.new(Tiempo, Enum.EasingStyle.Linear)
    
    if CurrentTween then CurrentTween:Cancel() end
    CurrentTween = TweenService:Create(root, Info, {CFrame = DestinoCFrame})
    CurrentTween:Play()
    CurrentTween.Completed:Wait()
    CurrentTween = nil
    root.Velocity = Vector3.new(0,0,0)
end

-- --- [ LÓGICA DE ESCANEO ] ---

local function IsTsunamiActive()
    local f = workspace:FindFirstChild("ActiveTsunamis")
    return f and #f:GetChildren() > 0
end

local function GetClosestSafeZone()
    local closest, shortDist = nil, math.huge
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        for _, z in pairs(SafeZones) do
            local dist = (root.Position - z.cf.Position).Magnitude
            if dist < shortDist then shortDist = dist; closest = z.cf end
        end
    end
    return closest
end

local function GetBestTarget()
    local closest, shortDist = nil, math.huge
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local Candidates = {}

    -- 1. Tickets/Consolas/Dinero (Sin filtro de nombre)
    if FarmConfig.Targets.Tickets then 
        local f = workspace:FindFirstChild("ArcadeEventTickets")
        if f then for _,v in pairs(f:GetChildren()) do table.insert(Candidates, v) end end
    end
    if FarmConfig.Targets.Consoles then 
        local f = workspace:FindFirstChild("ArcadeEventConsoles")
        if f then for _,v in pairs(f:GetChildren()) do table.insert(Candidates, v) end end
    end
    if FarmConfig.Targets.Money then 
        local f = workspace:FindFirstChild("MoneyEventParts")
        if f then for _,v in pairs(f:GetChildren()) do table.insert(Candidates, v) end end
    end

    -- 2. Lucky Blocks (Con filtro de Dropdown)
    if FarmConfig.Targets.LuckyBlocks then
        local f = workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then
            for _, m in pairs(f:GetChildren()) do
                if m:IsA("Model") and not ProcessedIDs[m] then
                    -- Verificar si el nombre coincide con la selección
                    for _, selectedName in pairs(FarmConfig.Selection.LuckyBlocks) do
                        if m.Name:find(selectedName) then
                            table.insert(Candidates, m)
                            break
                        end
                    end
                end
            end
        end
    end

    -- 3. Brainrots (Con filtro de Rareza)
    if FarmConfig.Targets.Brainrots then
        local f = workspace:FindFirstChild("ActiveBrainrots")
        if f then
            for _, rarityFolder in pairs(f:GetChildren()) do
                -- Verificar si la carpeta de rareza está seleccionada
                if table.find(FarmConfig.Selection.Brainrots, rarityFolder.Name) then
                    for _, m in pairs(rarityFolder:GetChildren()) do
                        -- Lógica RenderedBrainrot
                        if m.Name == "RenderedBrainrot" then
                            for _, real in pairs(m:GetChildren()) do 
                                if real:IsA("Model") and not ProcessedIDs[real] then table.insert(Candidates, real) end 
                            end
                        elseif m:IsA("Model") and not ProcessedIDs[m] then
                            table.insert(Candidates, m)
                        end
                    end
                end
            end
        end
    end

    -- Buscar el más cercano
    for _, item in pairs(Candidates) do
        local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
        if part then
            local dist = (root.Position - part.Position).Magnitude
            if dist < shortDist then shortDist = dist; closest = item end
        end
    end
    return closest
end

-- --- [ MOTOR PRINCIPAL ] ---

RunService.Stepped:Connect(function()
    if FarmConfig.Enabled and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity = Vector3.zero end
    end
end)

task.spawn(function()
    while true do
        if FarmConfig.Enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root and hum and hum.Health > 0 then
                
                -- [ ESTADO 1: TSUNAMI (Peligro Máximo) ]
                if IsTsunamiActive() then
                    local SafeSpot = GetClosestSafeZone()
                    if SafeSpot and (root.Position - SafeSpot.Position).Magnitude > 5 then
                        MoverRapido(SafeSpot)
                    end

                -- [ ESTADO 2: INVENTARIO LLENO (Regresar a Casa) ]
                elseif CollectedCount >= MaxInventory then
                    if HomeCFrame then
                        if (root.Position - HomeCFrame.Position).Magnitude > 5 then
                            MoverRapido(HomeCFrame)
                        else
                            -- Llegamos a casa, reseteamos el contador
                            CollectedCount = 0
                            ProcessedIDs = {} -- Limpiamos memoria para volver a empezar
                            task.wait(1) -- Tiempo para depositar
                        end
                    else
                        -- Si no hay casa fijada, solo reseteamos y seguimos
                        CollectedCount = 0
                    end

                -- [ ESTADO 3: FARMEO ]
                else
                    local Target = GetBestTarget()
                    if Target then
                        local Part = Target:IsA("BasePart") and Target or Target:FindFirstChildWhichIsA("BasePart", true)
                        
                        if Part then
                            -- Moverse si está lejos
                            if (root.Position - Part.Position).Magnitude > 3 then
                                MoverRapido(Part.CFrame)
                            end

                            -- Acciones al llegar
                            local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if Prompt then
                                -- Es Brainrot o Lucky Block
                                fireproximityprompt(Prompt)
                                ProcessedIDs[Target] = true -- Marcar como recogido
                                CollectedCount = CollectedCount + 1 -- Sumar al inventario
                                task.wait(0.5) -- Pausa para la animación
                            else
                                -- Es Ticket o Dinero (Solo tocar)
                                -- No suman al límite de inventario de 4, ya que son infinitos
                            end
                        end
                    end
                end
            end
        else
             if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
        end
        task.wait()
    end
end)
