--[[
    MODULE: VORTEX AUTO-FARM v23 (ULTIMATE GEMINI PRO)
    LOGIC:
    1. Attribute Reader: Lee velocidad real de olas.
    2. Predictive Pathing: Calcula si la ola te interceptará.
    3. Turbo Exploit: Recolección instantánea y masiva.
    4. Mobile Root Fix: Vuela al núcleo del objeto.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- --- [ SEGURIDAD: ESPERAR CARGA ] ---
local FarmTab = _G.AutoFarmTab
local t = 0
while not FarmTab and t < 5 do task.wait(0.1); t=t+0.1; FarmTab = _G.AutoFarmTab end
if not FarmTab then warn("❌ Error: AutoFarmTab no cargó"); return end

-- --- [ CONFIGURACIÓN MAESTRA ] ---
local HomeCF = CFrame.new(136.925751, 3.11180735, -9.24574852, 0.00662881136, 0, -0.999978006, 0, 1, 0, 0.999978006, 0, 0.00662881136)
local Collected = 0
local MaxInv = 4
local Processed = {} 

local Config = {
    Enabled = false,
    Speed = 350, -- Velocidad de vuelo
    TsunamiRange = 350, -- Distancia de pánico base
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false, Brainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

-- --- [ ZONAS SEGURAS ] ---
local SafeZones = {
    HomeCF, -- Prioridad 1: Casa
    CFrame.new(199.82, -6.38, -4.25),
    CFrame.new(285.12, -6.38, -6.46),
    CFrame.new(396.30, -6.38, -3.62),
    CFrame.new(541.78, -6.38, 1.57),
    CFrame.new(755.17, -6.38, 0.97),
    CFrame.new(1072.66, -6.38, -1.53),
    CFrame.new(1548.96, -6.38, -0.52),
    CFrame.new(2244.32, -6.38, -6.54),
    CFrame.new(2598.85, -6.38, 6.92)
}

-- --- [ UTILIDADES ] ---
local function GetNames(folder)
    local n = {}
    local f = ReplicatedStorage.Assets:FindFirstChild(folder)
    if f then for _,v in pairs(f:GetChildren()) do table.insert(n, v.Name) end end
    table.sort(n)
    return n
end

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- --- [ SISTEMA DE VUELO (TWEEN) ] ---
local CurTween = nil
local function FlyTo(TargetCF)
    local root = GetRoot()
    if not root then return end
    
    local Dist = (root.Position - TargetCF.Position).Magnitude
    local Time = Dist / Config.Speed
    
    if CurTween then CurTween:Cancel() end
    CurTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = TargetCF})
    CurTween:Play()
    
    local elapsed = 0
    while elapsed < Time do
        if not GetRoot() or not Config.Enabled then if CurTween then CurTween:Cancel() end return end
        task.wait(0.05); elapsed = elapsed + 0.05
    end
    CurTween = nil; if GetRoot() then root.Velocity = Vector3.zero end
end

-- --- [ CEREBRO DE SUPERVIVENCIA (PATHFINDING + PREDICCIÓN) ] ---

-- Revisa si el camino hacia un punto está bloqueado por una ola
local function IsPathBlocked(StartPos, EndPos)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return false end
    
    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p then
            -- Si la ola está entre nosotros y el destino en el eje X (donde se mueven)
            local minX = math.min(StartPos.X, EndPos.X)
            local maxX = math.max(StartPos.X, EndPos.X)
            if p.Position.X > minX and p.Position.X < maxX then
                return true -- Camino bloqueado
            end
        end
    end
    return false
end

-- Busca la mejor zona segura basándose en TIEMPO y RIESGO
local function GetSafe()
    local root = GetRoot()
    if not root then return SafeZones[1] end
    
    local bestZone = nil
    local shortestDist = math.huge
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    
    for _, cf in pairs(SafeZones) do
        local distToZone = (root.Position - cf.Position).Magnitude
        local timeToReach = distToZone / Config.Speed -- Cuánto tardamos nosotros
        local isZoneRisky = false
        
        -- 1. Verificar si el camino está cortado
        if IsPathBlocked(root.Position, cf.Position) then
            isZoneRisky = true
        else
            -- 2. Verificar si la ola llegará antes que nosotros (Predicción)
            if folder then
                for _, wave in pairs(folder:GetChildren()) do
                    local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
                    if p then
                        -- LEER ATRIBUTO REAL
                        local realSpeed = p:GetAttribute("Speed") or 500 
                        local distWaveToZone = (p.Position - cf.Position).Magnitude
                        local waveTTI = distWaveToZone / realSpeed -- Tiempo de impacto de la ola
                        
                        -- Si la ola llega antes o casi al mismo tiempo (margen 1.5s)
                        if waveTTI < (timeToReach + 1.5) then
                            isZoneRisky = true
                            break
                        end
                        
                        -- Si la ola ya está muy cerca de la zona (50 studs)
                        if distWaveToZone < 50 then isZoneRisky = true; break end
                    end
                end
            end
        end
        
        if not isZoneRisky then
            if distToZone < shortestDist then
                shortestDist = distToZone
                bestZone = cf
            end
        end
    end
    
    return bestZone or HomeCF -- Si todo falla, volvemos a casa
end

-- --- [ ESCANER DE OBJETIVOS (OPTIMIZADO) ] ---
local function GetTarget()
    local c, sd = nil, math.huge
    local root = GetRoot()
    if not root then return nil end
    local List = {}

    -- Tickets / Consolas / Dinero
    if Config.Targets.Tickets then local f=workspace:FindFirstChild("ArcadeEventTickets") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Consoles then local f=workspace:FindFirstChild("ArcadeEventConsoles") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Money then local f=workspace:FindFirstChild("MoneyEventParts") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end

    -- Lucky Blocks (Con filtro)
    if Config.Targets.LuckyBlocks then
        local f=workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then for _,obj in pairs(f:GetDescendants()) do 
            if obj:IsA("Model") and not Processed[obj] then
                for _,s in pairs(Config.Sel.Lucky) do if obj.Name:find(s) then table.insert(List,obj) break end end
            end
        end end
    end

    -- Brainrots (Con filtro)
    if Config.Targets.Brainrots then
        local f=workspace:FindFirstChild("ActiveBrainrots")
        if f then for _,obj in pairs(f:GetDescendants()) do
            if obj:IsA("Model") and not Processed[obj] then
                for _,s in pairs(Config.Sel.Brain) do if obj.Name:find(s) then table.insert(List,obj) break end end
            end
        end end
    end

    -- Selección del más cercano
    for _,v in pairs(List) do
        -- Buscamos el PROMPT primero para calcular distancia real al botón
        local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
        -- Si no hay prompt, buscamos Root o PrimaryPart
        local partToCheck = prompt and prompt.Parent or v:FindFirstChild("Root") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true)
        
        if partToCheck then 
            local d = (root.Position - partToCheck.Position).Magnitude
            if d < sd then sd = d; c = v end 
        end
    end
    return c
end

-- --- [ INTERFAZ UI ] ---
local Section = FarmTab:Section({ Title = "🔥 ULTIMATE AUTO-FARM" })

Section:Toggle({ Title = "ACTIVAR TODO", Callback = function(s) Config.Enabled = s; if s then Collected = 0 end end })
Section:Slider({ Title = "Rango Pánico Tsunami", Value = { Min = 50, Max = 1000, Default = 300 }, Callback = function(v) Config.TsunamiRange = v end })
Section:Button({ Title = "🗑️ Limpiar Memoria", Callback = function() Processed = {}; Collected = 0 end })

Section:Toggle({ Title = "Tickets", Callback = function(s) Config.Targets.Tickets = s end })
Section:Toggle({ Title = "Consolas", Callback = function(s) Config.Targets.Consoles = s end })
Section:Toggle({ Title = "Dinero", Callback = function(s) Config.Targets.Money = s end })

Section:Toggle({ Title = "Lucky Blocks", Callback = function(s) Config.Targets.LuckyBlocks = s end })
Section:Dropdown({ Title = "Filtro Lucky", Multi = true, Values = GetNames("LuckyBlocks"), Callback = function(v) Config.Sel.Lucky = v end })

Section:Toggle({ Title = "Brainrots", Callback = function(s) Config.Targets.Brainrots = s end })
Section:Dropdown({ Title = "Filtro Brainrot", Multi = true, Values = GetNames("Brainrots"), Callback = function(v) Config.Sel.Brain = v end })

-- --- [ LOOP PRINCIPAL (GEMINI CORE) ] ---
RunService.Stepped:Connect(function()
    if Config.Enabled and LocalPlayer.Character then
        -- Anti-Colisión y Anti-Gravedad
        for _,p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        if GetRoot() then GetRoot().Velocity = Vector3.zero end
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            if Config.Enabled then
                local root = GetRoot()
                if root and LocalPlayer.Character.Humanoid.Health > 0 then
                    
                    -- 1. DETECCIÓN DE PELIGRO (ATRIBUTOS)
                    local isTsunami = false
                    local folder = workspace:FindFirstChild("ActiveTsunamis")
                    if folder then
                        for _, w in pairs(folder:GetChildren()) do
                            local p = w:IsA("BasePart") and w or w:FindFirstChildWhichIsA("BasePart", true)
                            if p and (root.Position - p.Position).Magnitude < Config.TsunamiRange then 
                                isTsunami = true 
                                break
                            end
                        end
                    end

                    -- 2. DECISIÓN DE MOVIMIENTO
                    if isTsunami or Collected >= MaxInv then
                        local Safe = GetSafe() -- Calcula ruta segura sin bloqueos
                        FlyTo(Safe)
                        if Collected >= MaxInv then 
                            task.wait(1.5)
                            Collected = 0
                            Processed = {} 
                        end
                    else
                        -- 3. FARMEO TURBO
                        local Target = GetTarget()
                        if Target then
                            local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            -- Buscamos el objetivo exacto (Root > Prompt Parent > BasePart)
                            local MovePart = Prompt and Prompt.Parent or Target:FindFirstChild("Root") or Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart", true)

                            if MovePart then
                                -- Vuelo de aproximación
                                if (root.Position - MovePart.Position).Magnitude > 2 then 
                                    FlyTo(MovePart.CFrame) 
                                end
                                
                                -- INTERACCIÓN HACK
                                if Prompt then
                                    local distActual = (root.Position - MovePart.Position).Magnitude
                                    
                                    -- Dispara si estamos en rango (MaxDistance + margen de error)
                                    if distActual <= (Prompt.MaxActivationDistance + 3) then
                                        Prompt.RequiresLineOfSight = false -- Ver a través de paredes
                                        Prompt.HoldDuration = 0 -- Instantáneo
                                        
                                        -- RÁFAGA DE 15 DISPAROS
                                        for i = 1, 15 do
                                            fireproximityprompt(Prompt)
                                        end
                                        
                                        Processed[Target] = true
                                        Collected = Collected + 1
                                        task.wait(0.05) 
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.05) -- 20 ticks por segundo para máxima velocidad
    end
end)
