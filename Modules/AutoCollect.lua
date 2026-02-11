--[[
    MODULE: VORTEX AUTO-FARM v26 (FINAL FIX)
    LOGIC:
    1. Brainrot Scanner: Búsqueda profunda (Deep Search) en carpetas de rareza.
    2. Smart Pathing: Evita zonas seguras bloqueadas por la ola.
    3. Slider Tsunami: Rango ajustable (200-500).
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- --- [ SEGURIDAD ] ---
local FarmTab = _G.AutoFarmTab
local t = 0
while not FarmTab and t < 5 do task.wait(0.1); t=t+0.1; FarmTab = _G.AutoFarmTab end
if not FarmTab then warn("❌ AutoFarmTab no cargó"); return end

-- --- [ CONFIGURACIÓN ] ---
local HomeCF = CFrame.new(136.92, 3.11, -9.24)
local Collected = 0
local MaxInv = 3
local Processed = {} 

local Config = {
    Enabled = false,
    DebugMode = true,
    Speed = 350, 
    TsunamiRange = 300, -- Valor por defecto
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false, Brainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

-- --- [ ZONAS SEGURAS ] ---
local SafeZones = {
    HomeCF,
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
local function Notify(msg)
    if Config.DebugMode then
        StarterGui:SetCore("SendNotification", {Title="Vortex", Text=msg, Duration=1})
    end
end

local function GetNames(folder)
    local n = {}
    local f = ReplicatedStorage.Assets:FindFirstChild(folder)
    if f then for _,v in pairs(f:GetChildren()) do table.insert(n, v.Name) end end
    table.sort(n)
    return n
end

local function GetRoot() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end

-- --- [ VUELO ] ---
local CurTween = nil
local function FlyTo(TargetCF)
    local root = GetRoot()
    if not root then return end
    
    local Dist = (root.Position - TargetCF.Position).Magnitude
    local Time = Dist / Config.Speed
    
    if CurTween then CurTween:Cancel() end
    CurTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = TargetCF})
    CurTween:Play()
    
    local e = 0
    while e < Time do
        if not GetRoot() or not Config.Enabled then if CurTween then CurTween:Cancel() end return end
        task.wait(0.05); e=e+0.05
    end
    CurTween = nil; if GetRoot() then root.Velocity = Vector3.zero end
end

-- --- [ SUPERVIVENCIA INTELIGENTE ] ---

-- Detecta si hay una ola entre tú y el destino
local function IsPathBlocked(StartPos, EndPos)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return false end
    
    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p then
            -- Comprobación simple de eje X (Asumiendo que las olas se mueven en X)
            local minX = math.min(StartPos.X, EndPos.X)
            local maxX = math.max(StartPos.X, EndPos.X)
            
            -- Si la ola está "en medio" del camino
            if p.Position.X > minX and p.Position.X < maxX then
                return true 
            end
        end
    end
    return false
end

local function GetSafe()
    local root = GetRoot()
    if not root then return SafeZones[1] end
    
    local bestZone = nil
    local shortestDist = math.huge
    
    for _, cf in pairs(SafeZones) do
        -- 1. Verificar si el camino está bloqueado
        if not IsPathBlocked(root.Position, cf.Position) then
            local d = (root.Position - cf.Position).Magnitude
            if d < shortestDist then
                shortestDist = d
                bestZone = cf
            end
        end
    end
    
    -- Si TODAS están bloqueadas (Pánico), vamos a la más cercana física
    if not bestZone then
        for _, cf in pairs(SafeZones) do
            local d = (root.Position - cf.Position).Magnitude
            if d < shortestDist then shortestDist = d; bestZone = cf end
        end
    end
    
    return bestZone or SafeZones[1]
end

-- --- [ ESCANER MEJORADO (DEEP SEARCH) ] ---
local function GetTarget()
    local c, sd = nil, math.huge
    local root = GetRoot()
    if not root then return nil end
    local List = {}

    if Config.Targets.Tickets then local f=workspace:FindFirstChild("ArcadeEventTickets") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Consoles then local f=workspace:FindFirstChild("ArcadeEventConsoles") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Money then local f=workspace:FindFirstChild("MoneyEventParts") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end

    -- LUCKY BLOCKS
    if Config.Targets.LuckyBlocks then
        local f=workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then 
            -- Busca recursivamente en TODA la carpeta
            for _,obj in pairs(f:GetDescendants()) do 
                if obj:IsA("Model") and not Processed[obj] then
                    -- Verifica si tiene Prompt o Root
                    if obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                        for _,s in pairs(Config.Sel.Lucky) do if obj.Name:find(s) then table.insert(List,obj) break end end
                    end
                end
            end 
        end
    end

    -- BRAINROTS (FIXED)
    if Config.Targets.Brainrots then
        local f=workspace:FindFirstChild("ActiveBrainrots")
        if f then 
            for _,rarityFolder in pairs(f:GetChildren()) do
                -- Verifica si la carpeta coincide con la selección (Common, Rare...)
                if table.find(Config.Sel.Brain, rarityFolder.Name) then
                    -- Busca PROFUNDO en la carpeta de esa rareza
                    for _,obj in pairs(rarityFolder:GetDescendants()) do
                        if obj:IsA("Model") and not Processed[obj] then
                            -- El objeto es válido si tiene una parte "Root" o un Prompt dentro
                            if obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                                table.insert(List, obj)
                            end
                        end
                    end
                end
            end 
        end
    end

    for _,v in pairs(List) do
        local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
        local partToCheck = prompt and prompt.Parent or v:FindFirstChild("Root") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true)
        
        if partToCheck then 
            local d = (root.Position - partToCheck.Position).Magnitude
            if d < sd then sd = d; c = v end 
        end
    end
    return c
end

-- --- [ INTERFAZ ] ---
local Section = FarmTab:Section({ Title = "🔥 VORTEX v26 (FINAL)" })

Section:Toggle({ Title = "ACTIVAR", Callback = function(s) Config.Enabled = s; if s then Collected = 0; Notify("Farm Iniciado") end end })
Section:Toggle({ Title = "Modo Debug", Default = true, Callback = function(s) Config.DebugMode = s end })

-- SLIDER NUEVO
Section:Slider({ 
    Title = "Rango Detector Tsunami", 
    Value = { Min = 200, Max = 500, Default = 300 },
    Callback = function(v) Config.TsunamiRange = v end 
})

Section:Button({ Title = "🗑️ Limpiar Memoria", Callback = function() Processed = {}; Collected = 0 end })

Section:Toggle({ Title = "Tickets", Callback = function(s) Config.Targets.Tickets = s end })
Section:Toggle({ Title = "Consolas", Callback = function(s) Config.Targets.Consoles = s end })
Section:Toggle({ Title = "Dinero", Callback = function(s) Config.Targets.Money = s end })

Section:Toggle({ Title = "Lucky Blocks", Callback = function(s) Config.Targets.LuckyBlocks = s end })
Section:Dropdown({ Title = "Filtro Lucky", Multi = true, Values = GetNames("LuckyBlocks"), Callback = function(v) Config.Sel.Lucky = v end })

Section:Toggle({ Title = "Brainrots", Callback = function(s) Config.Targets.Brainrots = s end })
Section:Dropdown({ Title = "Filtro Brainrot", Multi = true, Values = GetNames("Brainrots"), Callback = function(v) Config.Sel.Brain = v end })

-- --- [ LOOP PRINCIPAL ] ---
RunService.Stepped:Connect(function()
    if Config.Enabled and LocalPlayer.Character then
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
                    
                    -- 1. DETECTAR PELIGRO
                    local isPanic = false
                    local folder = workspace:FindFirstChild("ActiveTsunamis")
                    if folder then
                        for _, w in pairs(folder:GetChildren()) do
                            local p = w:IsA("BasePart") and w or w:FindFirstChildWhichIsA("BasePart", true)
                            if p and (root.Position - p.Position).Magnitude < Config.TsunamiRange then 
                                isPanic = true; break 
                            end
                        end
                    end

                    -- 2. DECISIÓN
                    if isPanic then
                        Notify("⚠️ OLA CERCA! Huyendo...")
                        local SafeSpot = GetSafe() -- Ahora usa IsPathBlocked
                        FlyTo(SafeSpot)
                        task.wait(0.5) 
                        
                    elseif Collected >= MaxInv then
                        Notify("🎒 Inventario Lleno. Volviendo...")
                        FlyTo(HomeCF)
                        if (root.Position - HomeCF.Position).Magnitude < 10 then
                            task.wait(1.5)
                            Collected = 0
                            Processed = {}
                            Notify("✅ Limpio. A trabajar.")
                        end
                        
                    else
                        local Target = GetTarget()
                        if Target then
                            local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            local MovePart = Prompt and Prompt.Parent or Target:FindFirstChild("Root") or Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart", true)

                            if MovePart then
                                if (root.Position - MovePart.Position).Magnitude > 2 then 
                                    FlyTo(MovePart.CFrame) 
                                end
                                
                                if Prompt then
                                    local distActual = (root.Position - MovePart.Position).Magnitude
                                    if distActual <= (Prompt.MaxActivationDistance + 3) then
                                        Notify("⚡ Recogiendo " .. Target.Name)
                                        Prompt.RequiresLineOfSight = false
                                        Prompt.HoldDuration = 0
                                        for i = 1, 15 do fireproximityprompt(Prompt) end
                                        Processed[Target] = true
                                        Collected = Collected + 1
                                        task.wait(0.1) 
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.05)
    end
end)
