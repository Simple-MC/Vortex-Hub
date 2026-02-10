local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local FarmTab = _G.AutoFarmTab
local t = 0
while not FarmTab and t < 5 do task.wait(0.1); t=t+0.1; FarmTab = _G.AutoFarmTab end
if not FarmTab then warn("Falta AutoFarmTab"); return end

-- Zonas Seguras (Tu CFrame es el primero)
local SafeZones = {
    CFrame.new(136.92, 3.11, -9.24), -- Tu base/inicio
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

local Collected = 0
local MaxInv = 4
local Processed = {}
local HomeCF = SafeZones[1] -- Por defecto tu base

local Config = {
    Enabled = false, Speed = 300, TsunamiRange = 300,
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false, Brainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

local function GetNames(folder)
    local n = {}
    local f = ReplicatedStorage.Assets:FindFirstChild(folder)
    if f then for _,v in pairs(f:GetChildren()) do table.insert(n, v.Name) end end
    return n
end

local Section = FarmTab:Section({ Title = "🌊 Auto-Farm Pro" })

Section:Toggle({ Title = "🔥 ACTIVAR", Callback = function(s) Config.Enabled = s; if s then Collected = 0 end end })

-- SLIDER CORREGIDO (Estructura Value)
Section:Slider({
    Title = "Rango Detección Tsunami",
    Step = 10,
    Value = { Min = 50, Max = 1000, Default = 300 },
    Callback = function(v) Config.TsunamiRange = v end
})

Section:Button({ Title = "🏠 Fijar Casa Aquí", Callback = function() 
    if LocalPlayer.Character then HomeCF = LocalPlayer.Character.HumanoidRootPart.CFrame end 
end })

Section:Button({ Title = "🗑️ Resetear Memoria", Callback = function() Processed = {}; Collected = 0 end })

Section:Toggle({ Title = "Tickets", Callback = function(s) Config.Targets.Tickets = s end })
Section:Toggle({ Title = "Consolas", Callback = function(s) Config.Targets.Consoles = s end })
Section:Toggle({ Title = "Dinero", Callback = function(s) Config.Targets.Money = s end })

Section:Toggle({ Title = "Lucky Blocks", Callback = function(s) Config.Targets.LuckyBlocks = s end })
Section:Dropdown({ Title = "Select Lucky Blocks", Multi = true, Values = GetNames("LuckyBlocks"), Callback = function(v) Config.Sel.Lucky = v end })

Section:Toggle({ Title = "Brainrots", Callback = function(s) Config.Targets.Brainrots = s end })
Section:Dropdown({ Title = "Select Brainrots", Multi = true, Values = GetNames("Brainrots"), Callback = function(v) Config.Sel.Brain = v end })

local CurTween = nil
local function Tween(CF)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local Time = (root.Position - CF.Position).Magnitude / Config.Speed
    if CurTween then CurTween:Cancel() end
    CurTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CF})
    CurTween:Play(); CurTween.Completed:Wait(); CurTween = nil; root.Velocity = Vector3.zero
end

local function CheckTsunami()
    local f = workspace:FindFirstChild("ActiveTsunamis")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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
    local root = LocalPlayer.Character.HumanoidRootPart
    for _,cf in pairs(SafeZones) do
        local d = (root.Position - cf.Position).Magnitude
        if d < sd then sd = d; c = cf end
    end
    return c
end

local function GetTarget()
    local c, sd = nil, math.huge
    local root = LocalPlayer.Character.HumanoidRootPart
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

RunService.Stepped:Connect(function()
    if Config.Enabled and LocalPlayer.Character then
        for _,p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Velocity=Vector3.zero end
    end
end)

task.spawn(function()
    while true do
        if Config.Enabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 then
                local Root = char.HumanoidRootPart
                
                if CheckTsunami() then
                    local Safe = GetSafe()
                    if Safe and (Root.Position - Safe.Position).Magnitude > 5 then Tween(Safe) else if CurTween then CurTween:Cancel() end Root.CFrame=Safe end
                
                elseif Collected >= MaxInv then
                    if (Root.Position - HomeCF.Position).Magnitude > 5 then Tween(HomeCF) else Collected=0; Processed={}; task.wait(1) end
                
                else
                    local T = GetTarget()
                    if T then
                        local P = T:IsA("BasePart") and T or T:FindFirstChildWhichIsA("BasePart", true)
                        if P then
                            if (Root.Position - P.Position).Magnitude > 4 then Tween(P.CFrame) end
                            local Pr = T:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if Pr then fireproximityprompt(Pr); Processed[T]=true; Collected=Collected+1; task.wait(0.5) end
                        end
                    end
                end
            end
        else if CurTween then CurTween:Cancel(); CurTween=nil end end
        task.wait()
    end
end)
