--[[
    MODULE: VORTEX SPEED-FARM (TWEEN EDITION)
    MODE: Fast Glide (No Walking, No Instant TP)
    SPEED: 350 Studs/Second (Super Fast)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- --- [ SEGURIDAD DE TAB ] ---
local FarmTab = _G.AutoFarmTab
local timeout = 0
while not FarmTab and timeout < 5 do task.wait(0.1); timeout = timeout+0.1; FarmTab = _G.AutoFarmTab end
if not FarmTab then warn("❌ Falta AutoFarmTab"); return end

-- --- [ CONFIGURACIÓN ] ---
local FarmConfig = {
    Enabled = false,
    Speed = 350, -- Velocidad del deslizamiento (16 es caminar, 350 es un cohete)
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false, Brainrots = false }
}

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

-- --- [ UI INTERFACE ] ---
local SectionFarm = FarmTab:Section({ Title = "⚡ Speed Auto-Farm" })

SectionFarm:Toggle({
    Title = "🔥 ACTIVAR SPEED FARM",
    Desc = "Prioridad: Tsunami > Items (Movimiento Rápido)",
    Callback = function(s) 
        FarmConfig.Enabled = s 
        if not s then
            -- Cancelar movimiento si se apaga
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then 
                for _, t in pairs(TweenService:GetTweens()) do 
                    if t.Instance == root then t:Cancel() end 
                end
            end
        end
    end
})

SectionFarm:Toggle({ Title = "Tickets", Callback = function(s) FarmConfig.Targets.Tickets = s end })
SectionFarm:Toggle({ Title = "Consolas", Callback = function(s) FarmConfig.Targets.Consoles = s end })
SectionFarm:Toggle({ Title = "Dinero", Callback = function(s) FarmConfig.Targets.Money = s end })
SectionFarm:Toggle({ Title = "Lucky Blocks", Callback = function(s) FarmConfig.Targets.LuckyBlocks = s end })
SectionFarm:Toggle({ Title = "Brainrots", Callback = function(s) FarmConfig.Targets.Brainrots = s end })

-- --- [ MOTOR DE MOVIMIENTO (TWEEN) ] ---

-- Variable para guardar el Tween actual y poder cancelarlo si viene un Tsunami
local CurrentTween = nil

local function MoverRapido(DestinoCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Calcular distancia para mantener velocidad constante
    local Distancia = (root.Position - DestinoCFrame.Position).Magnitude
    local Tiempo = Distancia / FarmConfig.Speed -- Fórmula de Física: T = D / V
    
    -- Crear la información del Tween (Lineal para que sea constante)
    local Info = TweenInfo.new(Tiempo, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    
    -- Si ya nos estamos moviendo, cancelamos el anterior para no buguearnos
    if CurrentTween then CurrentTween:Cancel() end
    
    -- Crear y reproducir el nuevo movimiento
    CurrentTween = TweenService:Create(root, Info, {CFrame = DestinoCFrame})
    CurrentTween:Play()
    
    -- Esperar a que llegue (o se cancele externamente)
    CurrentTween.Completed:Wait()
    CurrentTween = nil
    
    -- Al llegar, anulamos la velocidad para no salir volando
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
    
    -- Escaneo agresivo de todas las carpetas
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
    if FarmConfig.Targets.LuckyBlocks then 
        local f = workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then for _,v in pairs(f:GetDescendants()) do if v:IsA("Model") then table.insert(Candidates, v) end end end
    end
    if FarmConfig.Targets.Brainrots then
        local f = workspace:FindFirstChild("ActiveBrainrots")
        if f then
            for _, r in pairs(f:GetChildren()) do
                for _, m in pairs(r:GetChildren()) do
                    if m.Name == "RenderedBrainrot" then
                        for _, real in pairs(m:GetChildren()) do if real:IsA("Model") then table.insert(Candidates, real) end end
                    elseif m:IsA("Model") then table.insert(Candidates, m) end
                end
            end
        end
    end

    -- Matemáticas para encontrar el más cercano
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

-- Anti-Stuck Loop (NoClip Permanente mientras farmeas)
RunService.Stepped:Connect(function()
    if FarmConfig.Enabled and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
        -- Evitar caer al vacío si el juego no tiene piso
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity = Vector3.new(0,0,0) end 
    end
end)

task.spawn(function()
    while true do
        if FarmConfig.Enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root and hum and hum.Health > 0 then
                
                -- [ PRIORIDAD 1: TSUNAMI (Modo Pánico) ]
                if IsTsunamiActive() then
                    local SafeSpot = GetClosestSafeZone()
                    if SafeSpot then
                        -- Si estamos lejos, volamos hacia allá
                        if (root.Position - SafeSpot.Position).Magnitude > 5 then
                            -- AVISO VISUAL
                            if not workspace:FindFirstChild("VortexAlert") then
                                local h = Instance.new("Hint", workspace); h.Name="VortexAlert"; h.Text="🌊 TSUNAMI - VOLANDO A ZONA SEGURA 🌊"; Debris:AddItem(h, 2)
                            end
                            
                            -- ¡VUELO RÁPIDO A ZONA SEGURA!
                            MoverRapido(SafeSpot) 
                        else
                            -- Si ya llegamos, cancelamos cualquier movimiento residual
                            if CurrentTween then CurrentTween:Cancel() end
                            root.CFrame = SafeSpot -- Anclarse ahí
                        end
                    end

                -- [ PRIORIDAD 2: FARMEO (Solo si es seguro) ]
                else
                    local Target = GetBestTarget()
                    if Target then
                        local Part = Target:IsA("BasePart") and Target or Target:FindFirstChildWhichIsA("BasePart", true)
                        if Part then
                            -- Calcular si vale la pena moverse
                            if (root.Position - Part.Position).Magnitude > 4 then
                                MoverRapido(Part.CFrame)
                            end
                            
                            -- Interacción al llegar
                            local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if Prompt then 
                                fireproximityprompt(Prompt)
                                task.wait(0.1) -- Pequeña pausa para que procese el click
                            end
                        end
                    end
                end
            end
        else
            -- Si se apaga, asegúrate de cancelar el vuelo
            if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
        end
        task.wait() -- Sin espera larga para reacción instantánea
    end
end)
