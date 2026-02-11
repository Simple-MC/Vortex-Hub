--[[
    MODULE: VORTEX AUTO-FARM v29 (UFO EDITION)
    ADDED: Auto Collect UFO Money (workspace.UFOEventParts).
    KEPT: Physics Fix, Survival Logic, Brainrot Deep Search.
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
local HomeCF = CFrame.new(136.92, 3.11, -9.24) + Vector3.new(0, 3, 0)
local Collected = 0
local MaxInv = 3
local Processed = {} 

local Config = {
    Enabled = false,
    DebugMode = true,
    Speed = 350, 
    TsunamiRange = 300, 
    Targets = { Tickets = false, Consoles = false, Money = false, UFO = false, LuckyBlocks = false, Brainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

-- --- [ ZONAS SEGURAS (+3 STUDS) ] ---
local SafeZones = {
    HomeCF,
    CFrame.new(199.82, -6.38, -4.25) + Vector3.new(0, 3, 0),
    CFrame.new(285.12, -6.38, -6.46) + Vector3.new(0, 3, 0),
    CFrame.new(396.30, -6.38, -3.62) + Vector3.new(0, 3, 0),
    CFrame.new(541.78, -6.38, 1.57) + Vector3.new(0, 3, 0),
    CFrame.new(755.17, -6.38, 0.97) + Vector3.new(0, 3, 0),
    CFrame.new(1072.66, -6.38, -1.53) + Vector3.new(0, 3, 0),
    CFrame.new(1548.96, -6.38, -0.52) + Vector3.new(0, 3, 0),
    CFrame.new(2244.32, -6.38, -6.54) + Vector3.new(0, 3, 0),
    CFrame.new(2598.85, -6.38, 6.92) + Vector3.new(0, 3, 0)
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

-- --- [ VUELO MEJORADO ] ---
local CurTween = nil
local IsFlying = false 

local function FlyTo(TargetCF, Emergency)
    local root = GetRoot()
    if not root then return end
    
    local Dist = (root.Position - TargetCF.Position).Magnitude
    local Time = Dist / Config.Speed
    
    if CurTween then CurTween:Cancel() end
    
    IsFlying = true 
    CurTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = TargetCF})
    CurTween:Play()
    
    local e = 0
    while e < Time do
        if not GetRoot() or not Config.Enabled then 
            if CurTween then CurTween:Cancel() end 
            IsFlying = false
            return 
        end
        
        if not Emergency and Config.Enabled then
             local folder = workspace:FindFirstChild("ActiveTsunamis")
             if folder then
                for _, w in pairs(folder:GetChildren()) do
                    local p = w:IsA("BasePart") and w or w:FindFirstChildWhichIsA("BasePart", true)
                    if p and (root.Position - p.Position).Magnitude < Config.TsunamiRange then
                        if CurTween then CurTween:Cancel() end
                        IsFlying = false
                        return 
                    end
                end
             end
        end

        task.wait(0.05); e=e+0.05
    end
    
    CurTween = nil
    IsFlying = false 
    if GetRoot() then root.Velocity = Vector3.zero end
end

-- --- [ SUPERVIVENCIA ] ---
local function IsPathBlocked(StartPos, EndPos)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return false end
    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p then
            local minX, maxX = math.min(StartPos.X, EndPos.X), math.max(StartPos.X, EndPos.X)
            if p.Position.X > minX and p.Position.X < maxX then return true end
        end
    end
    return false
end

local function GetSafe()
    local root = GetRoot()
    if not root then return SafeZones[1] end
    local best, shortest = nil, math.huge
    
    for _, cf in pairs(SafeZones) do
        if not IsPathBlocked(root.Position, cf.Position) then
            local d = (root.Position - cf.Position).Magnitude
            if d < shortest then shortest = d; best = cf end
        end
    end
    
    if not best then
        for _, cf in pairs(SafeZones) do
            local d = (root.Position - cf.Position).Magnitude
            if d < shortest then shortest = d; best = cf end
        end
    end
    return best or SafeZones[1]
end

-- --- [ ESCANER ] ---
local function GetTarget()
    local c, sd = nil, math.huge
    local root = GetRoot()
    if not root then return nil end
    local List = {}

    if Config.Targets.Tickets then local f=workspace:FindFirstChild("ArcadeEventTickets") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Consoles then local f=workspace:FindFirstChild("ArcadeEventConsoles") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Money then local f=workspace:FindFirstChild("MoneyEventParts") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    
    -- UFO MONEY (Nuevo)
    if Config.Targets.UFO then 
        local f=workspace:FindFirstChild("UFOEventParts") 
        if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end 
    end

    if Config.Targets.LuckyBlocks then
        local f=workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then 
            for _,obj in pairs(f:GetDescendants()) do 
                if obj:IsA("Model") and not Processed[obj] then
                    if obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                        for _,s in pairs(Config.Sel.Lucky) do if obj.Name:find(s) then table.insert(List,obj) break end end
                    end
                end
            end 
        end
    end

    if Config.Targets.Brainrots then
        local f=workspace:FindFirstChild("ActiveBrainrots")
        if f then 
            for _,rarityFolder in pairs(f:GetChildren()) do
                if table.find(Config.Sel.Brain, rarityFolder.Name) then
                    for _,obj in pairs(rarityFolder:GetDescendants()) do
                        if obj:IsA("Model") and not Processed[obj] then
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
local Section = FarmTab:Section({ Title = "🔥 VORTEX v29 (UFO EDITION)" })

Section:Toggle({ Title = "ACTIVAR", Callback = function(s) Config.Enabled = s; if s then Collected = 0; Notify("Farm Iniciado") end end })
Section:Toggle({ Title = "Modo Debug", Default = true, Callback = function(s) Config.DebugMode = s end })

Section:Slider({ Title = "Rango Detector Tsunami", Value = { Min = 200, Max = 500, Default = 300 }, Callback = function(v) Config.TsunamiRange = v end })
Section:Button({ Title = "🗑️ Limpiar Memoria", Callback = function() Processed = {}; Collected = 0 end })

Section:Toggle({ Title = "Tickets", Callback = function(s) Config.Targets.Tickets = s end })
Section:Toggle({ Title = "Consolas", Callback = function(s) Config.Targets.Consoles = s end })
Section:Toggle({ Title = "Dinero", Callback = function(s) Config.Targets.Money = s end })
Section:Toggle({ Title = "UFO Money 👽", Callback = function(s) Config.Targets.UFO = s end }) -- Nuevo Toggle

Section:Toggle({ Title = "Lucky Blocks", Callback = function(s) Config.Targets.LuckyBlocks = s end })
Section:Dropdown({ Title = "Filtro Lucky", Multi = true, Values = GetNames("LuckyBlocks"), Callback = function(v) Config.Sel.Lucky = v end })

Section:Toggle({ Title = "Brainrots", Callback = function(s) Config.Targets.Brainrots = s end })
Section:Dropdown({ Title = "Filtro Brainrot", Multi = true, Values = GetNames("Brainrots"), Callback = function(v) Config.Sel.Brain = v end })

-- --- [ LOOP FÍSICO ] ---
RunService.Stepped:Connect(function()
    if Config.Enabled and LocalPlayer.Character and IsFlying then
        for _,p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        if GetRoot() then GetRoot().Velocity = Vector3.zero end
    end
end)

-- --- [ LOOP PRINCIPAL ] ---
task.spawn(function()
    while true do
        pcall(function()
            if Config.Enabled then
                local root = GetRoot()
                if root and LocalPlayer.Character.Humanoid.Health > 0 then
                    
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

                    if isPanic then
                        Notify("⚠️ PELIGRO! Refugiándose...")
                        local SafeSpot = GetSafe()
                        FlyTo(SafeSpot, true) 
                        task.wait(0.2)
                        
                    elseif Collected >= MaxInv then
                        Notify("🎒 Lleno. Volviendo...")
                        FlyTo(HomeCF, true)
                        if (root.Position - HomeCF.Position).Magnitude < 10 then
                            task.wait(1.5)
                            Collected = 0
                            Processed = {}
                            Notify("✅ Listo.")
                        end
                        
                    else
                        local Target = GetTarget()
                        if Target then
                            local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            local MovePart = Prompt and Prompt.Parent or Target:FindFirstChild("Root") or Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart", true)

                            if MovePart then
                                if (root.Position - MovePart.Position).Magnitude > 2 then 
                                    FlyTo(MovePart.CFrame, false) 
                                end
                                
                                if Prompt then
                                    local distActual = (root.Position - MovePart.Position).Magnitude
                                    if distActual <= (Prompt.MaxActivationDistance + 3) then
                                        Notify("⚡ Recogiendo...")
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
