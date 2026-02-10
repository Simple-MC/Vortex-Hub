--[[
    MODULE: VORTEX AUTO-FARM v10 (IMMORTAL FIX)
    FIXES:
    1. Anti-Crash Logic: Script won't stop if you die.
    2. Auto-Respawn Detection: Finds new character instantly.
    3. Safe RootPart Checks: Prevents "Index nil" errors.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- --- [ ESPERAR TAB (SEGURIDAD) ] ---
local FarmTab = _G.AutoFarmTab
local t = 0
while not FarmTab and t < 5 do task.wait(0.1); t=t+0.1; FarmTab = _G.AutoFarmTab end
if not FarmTab then warn("Falta AutoFarmTab"); return end

-- --- [ CONFIGURACIÓN BASE ] ---
local HomeCF = CFrame.new(136.92, 3.11, -9.24) -- Tu base
local Collected = 0
local MaxInv = 4
local Processed = {}

local Config = {
    Enabled = false, Speed = 300, TsunamiRange = 300,
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false, Brainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

-- --- [ LISTAS SEGURAS ] ---
local SafeZones = {
    CFrame.new(136.92, 3.11, -9.24), -- Base
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

local function GetNames(folder)
    local n = {}
    local f = ReplicatedStorage.Assets:FindFirstChild(folder)
    if f then for _,v in pairs(f:GetChildren()) do table.insert(n, v.Name) end end
    table.sort(n)
    return n
end

-- --- [ UI INTERFACE ] ---
local Section = FarmTab:Section({ Title = "🌊 Auto-Farm Inmortal" })

Section:Toggle({ Title = "🔥 ACTIVAR", Callback = function(s) Config.Enabled = s; if s then Collected = 0 end end })

Section:Slider({
    Title = "Rango Detección Tsunami",
    Step = 10,
    Value = { Min = 50, Max = 1000, Default = 300 },
    Callback = function(v) Config.TsunamiRange = v end
})

Section:Button({ Title = "🏠 Fijar Casa Aquí", Callback = function() 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
        HomeCF = LocalPlayer.Character.HumanoidRootPart.CFrame 
    end 
end })

Section:Button({ Title = "🗑️ Resetear Memoria", Callback = function() Processed = {}; Collected = 0 end })

-- TARGETS
Section:Toggle({ Title = "Tickets", Callback = function(s) Config.Targets.Tickets = s end })
Section:Toggle({ Title = "Consolas", Callback = function(s) Config.Targets.Consoles = s end })
Section:Toggle({ Title = "Dinero", Callback = function(s) Config.Targets.Money = s end })
Section:Toggle({ Title = "Lucky Blocks", Callback = function(s) Config.Targets.LuckyBlocks = s end })
Section:Dropdown({ Title = "Select Lucky Blocks", Multi = true, Values = GetNames("LuckyBlocks"), Callback = function(v) Config.Sel.Lucky = v end })
Section:Toggle({ Title = "Brainrots", Callback = function(s) Config.Targets.Brainrots = s end })
Section:Dropdown({ Title = "Select Brainrots", Multi = true, Values = GetNames("Brainrots"), Callback = function(v) Config.Sel.Brain = v end })

-- --- [ CORE: FUNCIONES SEGURAS ] ---

-- Función auxiliar para obtener RootPart sin errores
local function GetRoot()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local CurTween = nil
local function Tween(TargetCF)
    local root = GetRoot()
    if not root then return end
    
    local Dist = (root.Position - TargetCF.Position).Magnitude
    local Time = Dist / Config.Speed
    
    if CurTween then CurTween:Cancel() end
    
    local Info = TweenInfo.new(Time, Enum.EasingStyle.Linear)
    CurTween = TweenService:Create(root, Info, {CFrame = TargetCF})
    CurTween:Play()
    
    -- Esperamos a que termine O que el personaje muera (Root borrado)
    local t = 0
    while t < Time do
        if not GetRoot() then -- Si morimos a medio vuelo
            if CurTween then CurTween:Cancel() end
            return 
        end
        if not Config.Enabled then CurTween:Cancel(); return end
        task.wait(0.1)
        t = t + 0.1
    end
    
    CurTween = nil
    if GetRoot() then root.Velocity = Vector3.zero end
end

local function CheckTsunami()
    local f = workspace:FindFirstChild("ActiveTsunamis")
    local root = GetRoot()
    if f and root then
        for _,w in pairs(f:GetChildren()) do
            local p = w:IsA("BasePart") and w or w:FindFirstChildWhichIsA("BasePart", true)
            if p and (root.Position - p.Position).Magnitude < Config.TsunamiRange then return true end
        end
    end
    return false
end

local function GetSafe()
    local c, sd = nil, math.huge
    local root = GetRoot()
    if not root then return SafeZones[1] end -- Si no hay root, devuelve base por defecto
    
    for _,cf in pairs(SafeZones) do
        local d = (root.Position - cf.Position).Magnitude
        if d < sd then sd = d; c = cf end
    end
    return c
end

local function GetTarget()
    local c, sd = nil, math.huge
    local root = GetRoot()
    if not root then return nil end
    local List = {}

    if Config.Targets.Tickets then local f=workspace:FindFirstChild("ArcadeEventTickets") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Consoles then local f=workspace:FindFirstChild("ArcadeEventConsoles") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Money then local f=workspace:FindFirstChild("MoneyEventParts") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end

    if Config.Targets.LuckyBlocks then
        local f=workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then for _,m in pairs(f:GetChildren()) do 
            if m:IsA("Model") and not Processed[m] then
                for _,s in pairs(Config.Sel.Lucky) do if m.Name:find(s) then table.insert(List,m) break end end
            end
        end end
    end

    if Config.Targets.Brainrots then
        local f=workspace:FindFirstChild("ActiveBrainrots")
        if f then for _,fold in pairs(f:GetChildren()) do
            if table.find(Config.Sel.Brain, fold.Name) then
                for _,m in pairs(fold:GetChildren()) do
                    if m.Name == "RenderedBrainrot" then
                        for _,r in pairs(m:GetChildren()) do if r:IsA("Model") and not Processed[r] then table.insert(List,r) end end
                    elseif m:IsA("Model") and not Processed[m] then table.insert(List,m) end
                end
            end
        end end
    end

    for _,v in pairs(List) do
        local p = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
        if p then local d = (root.Position - p.Position).Magnitude; if d < sd then sd = d; c = v end end
    end
    return c
end

-- --- [ LOOP "INMORTAL" (Anti-Crash) ] ---

RunService.Stepped:Connect(function()
    if Config.Enabled then
        local char = LocalPlayer.Character
        if char then
            for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
            if char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Velocity=Vector3.zero end
        end
    end
end)

task.spawn(function()
    while true do
        -- pcall evita que el script se detenga si hay un error (ej: personaje nulo)
        local success, err = pcall(function()
            if Config.Enabled then
                local root = GetRoot()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                
                -- Solo ejecutamos si estamos vivos
                if root and hum and hum.Health > 0 then
                    
                    if CheckTsunami() then
                        local Safe = GetSafe()
                        if Safe and (root.Position - Safe.Position).Magnitude > 5 then Tween(Safe) end
                    
                    elseif Collected >= MaxInv then
                        if (root.Position - HomeCF.Position).Magnitude > 5 then 
                            Tween(HomeCF) 
                        else 
                            Collected=0; Processed={}; task.wait(1) 
                        end
                    
                    else
                        local T = GetTarget()
                        if T then
                            local P = T:IsA("BasePart") and T or T:FindFirstChildWhichIsA("BasePart", true)
                            if P then
                                if (root.Position - P.Position).Magnitude > 4 then Tween(P.CFrame) end
                                local Pr = T:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if Pr then 
                                    fireproximityprompt(Pr); Processed[T]=true; Collected=Collected+1; task.wait(0.5) 
                                end
                            end
                        end
                    end
                else
                    -- Si estamos muertos, esperamos a revivir sin hacer nada
                    if CurTween then CurTween:Cancel(); CurTween = nil end
                    task.wait(1)
                end
            end
        end)

        if not success then
            -- Si algo falló, solo imprime aviso y sigue intentando (no crashea)
            warn("Vortex Auto-Farm: Pequeño error recuperado ->", err)
            task.wait(1)
        end
        
        task.wait(0.1)
    end
end)
