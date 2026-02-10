--[[
    MODULE: VORTEX AUTO-FARM v8 (FINAL FIX)
    CHANGES:
    1. Hardcoded Home CFrame (Your specific Safe Zone).
    2. Tsunami Range Check (Farms until the wave is close).
    3. Auto-Deposit Logic (Goes home when full).
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

-- --- [ TU BASE (Zona Segura Personalizada) ] ---
-- Este es el CFrame exacto que me diste:
local RealBaseCFrame = CFrame.new(136.925751, 3.11180735, -9.24574852, 0.00662881136, 0, -0.999978006, 0, 1, 0, 0.999978006, 0, 0.00662881136)

-- --- [ VARIABLES DE ESTADO ] ---
local CollectedCount = 0
local MaxInventory = 4 
local ProcessedIDs = {} 

-- --- [ CONFIGURACIÓN ] ---
local FarmConfig = {
    Enabled = false,
    Speed = 300,
    TsunamiRange = 300, -- Distancia a la que el script se asusta (15 es muy poco, sugiero 150-300)
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false, Brainrots = false },
    Selection = { LuckyBlocks = {}, Brainrots = {} }
}

-- --- [ FUNCIONES DE LISTA ] ---
local function GetRarityNames()
    local names = {}
    local f = ReplicatedStorage.Assets:FindFirstChild("Brainrots")
    if f then for _, i in pairs(f:GetChildren()) do if i:IsA("Folder") then table.insert(names, i.Name) end end end
    table.sort(names)
    return names
end

local function GetLuckyBlockNames()
    local names = {}
    local f = ReplicatedStorage.Assets:FindFirstChild("LuckyBlocks")
    if f then for _, i in pairs(f:GetChildren()) do table.insert(names, i.Name) end end
    table.sort(names)
    return names
end

-- --- [ UI INTERFACE ] ---
local SectionFarm = FarmTab:Section({ Title = "🌊 Auto-Farm Inteligente" })

SectionFarm:Toggle({
    Title = "🔥 ACTIVAR AUTO-FARM",
    Desc = "Prioridad: Tsunami Cerca > Inventario Lleno > Farmear",
    Callback = function(s) 
        FarmConfig.Enabled = s 
        if s then CollectedCount = 0 end 
    end
})

SectionFarm:Slider({
    Title = "Distancia de Pánico (Tsunami)",
    Desc = "Si la ola está a menos de X studs, corre a la base",
    Min = 50, Max = 1000, Default = 300, -- Puedes bajarlo, pero cuidado
    Callback = function(v) FarmConfig.TsunamiRange = v end
})

SectionFarm:Button({
    Title = "🗑️ Resetear Inventario",
    Callback = function() ProcessedIDs = {}; CollectedCount = 0 end
})

-- CATEGORÍAS
SectionFarm:Toggle({ Title = "Recoger Tickets", Callback = function(s) FarmConfig.Targets.Tickets = s end })
SectionFarm:Toggle({ Title = "Recoger Consolas", Callback = function(s) FarmConfig.Targets.Consoles = s end })
SectionFarm:Toggle({ Title = "Recoger Dinero", Callback = function(s) FarmConfig.Targets.Money = s end })

SectionFarm:Toggle({ Title = "Recoger Lucky Blocks", Callback = function(s) FarmConfig.Targets.LuckyBlocks = s end })
SectionFarm:Dropdown({
    Title = "Seleccionar Lucky Blocks", Multi = true, Values = GetLuckyBlockNames(),
    Callback = function(v) FarmConfig.Selection.LuckyBlocks = v end
})

SectionFarm:Toggle({ Title = "Recoger Brainrots", Callback = function(s) FarmConfig.Targets.Brainrots = s end })
SectionFarm:Dropdown({
    Title = "Seleccionar Rareza (Brainrots)", Multi = true, Values = GetRarityNames(),
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
    root.Velocity = Vector3.zero
end

-- --- [ LÓGICA DE ESCANEO ] ---

-- NUEVA LÓGICA: Solo devuelve TRUE si el tsunami está CERCA
local function IsTsunamiThreat()
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if folder and root then
        for _, wave in pairs(folder:GetChildren()) do
            -- Buscamos la parte física de la ola
            local wavePart = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
            if wavePart then
                local dist = (root.Position - wavePart.Position).Magnitude
                -- AQUÍ ESTÁ EL CAMBIO: Solo nos asustamos si está dentro del rango
                if dist < FarmConfig.TsunamiRange then
                    return true
                end
            end
        end
    end
    return false
end

local function GetBestTarget()
    local closest, shortDist = nil, math.huge
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local Candidates = {}

    -- 1. Tickets/Consolas/Dinero
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

    -- 2. Lucky Blocks
    if FarmConfig.Targets.LuckyBlocks then
        local f = workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then
            for _, m in pairs(f:GetChildren()) do
                if m:IsA("Model") and not ProcessedIDs[m] then
                    for _, sel in pairs(FarmConfig.Selection.LuckyBlocks) do
                        if m.Name:find(sel) then table.insert(Candidates, m); break end
                    end
                end
            end
        end
    end

    -- 3. Brainrots
    if FarmConfig.Targets.Brainrots then
        local f = workspace:FindFirstChild("ActiveBrainrots")
        if f then
            for _, rFolder in pairs(f:GetChildren()) do
                if table.find(FarmConfig.Selection.Brainrots, rFolder.Name) then
                    for _, m in pairs(rFolder:GetChildren()) do
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
                
                -- [ ESTADO 1: TSUNAMI CERCA (Peligro Inminente) ]
                if IsTsunamiThreat() then
                    -- Si estamos lejos de la base, vamos para allá
                    if (root.Position - RealBaseCFrame.Position).Magnitude > 5 then
                        -- Feedback Visual
                        if not workspace:FindFirstChild("VortexAlert") then
                            local h = Instance.new("Hint", workspace); h.Name="VortexAlert"; h.Text="🌊 TSUNAMI CERCA - RETIRADA A LA BASE"; Debris:AddItem(h, 1)
                        end
                        MoverRapido(RealBaseCFrame)
                    else
                        -- Si ya estamos en la base, nos quedamos quietos y esperamos a que la ola se aleje
                        if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
                        root.CFrame = RealBaseCFrame
                    end

                -- [ ESTADO 2: INVENTARIO LLENO (Depositar) ]
                elseif CollectedCount >= MaxInventory then
                    if (root.Position - RealBaseCFrame.Position).Magnitude > 5 then
                         if not workspace:FindFirstChild("VortexAlert") then
                            local h = Instance.new("Hint", workspace); h.Name="VortexAlert"; h.Text="🎒 INVENTARIO LLENO - DEPOSITANDO"; Debris:AddItem(h, 1)
                        end
                        MoverRapido(RealBaseCFrame)
                    else
                        -- Llegamos a la base
                        CollectedCount = 0
                        ProcessedIDs = {} 
                        task.wait(1.5) -- Esperar un poco en la base para asegurar que deposite
                    end

                -- [ ESTADO 3: FARMEO (Zona Segura y con Espacio) ]
                else
                    local Target = GetBestTarget()
                    if Target then
                        local Part = Target:IsA("BasePart") and Target or Target:FindFirstChildWhichIsA("BasePart", true)
                        
                        if Part then
                            if (root.Position - Part.Position).Magnitude > 3 then
                                MoverRapido(Part.CFrame)
                            end

                            local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if Prompt then
                                fireproximityprompt(Prompt)
                                ProcessedIDs[Target] = true
                                CollectedCount = CollectedCount + 1
                                task.wait(0.5)
                            end
                        end
                    else
                         -- Si no hay nada que farmear, nos quedamos en el aire o quietos, NO vamos a la base innecesariamente
                         -- Opcional: Ir a la base si no hay nada que hacer para estar seguros
                    end
                end
            end
        else
             if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
        end
        task.wait()
    end
end)
