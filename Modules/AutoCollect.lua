--[[
    MODULE: VORTEX AUTO-FARM v18 (MOBILE ROOT FIX)
    TARGET: Root.TakePrompt / Any Prompt inside Root
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FarmTab = _G.AutoFarmTab
local t = 0
while not FarmTab and t < 5 do task.wait(0.1); t=t+0.1; FarmTab = _G.AutoFarmTab end
if not FarmTab then warn("Falta AutoFarmTab"); return end

-- CONFIG FIJA
local HomeCF = CFrame.new(136.925751, 3.11180735, -9.24574852, 0.00662881136, 0, -0.999978006, 0, 1, 0, 0.999978006, 0, 0.00662881136)
local Collected = 0
local MaxInv = 4
local Processed = {} 

local Config = {
    Enabled = false,
    Speed = 350, -- Un poco más rápido
    TsunamiRange = 250,
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false, Brainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

-- --- [ MOTOR ] ---
local function GetRoot() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end

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

-- --- [ ESCANER ] ---
local function GetTarget()
    local c, sd = nil, math.huge
    local root = GetRoot()
    if not root then return nil end
    local List = {}

    -- Brainrots & Lucky Blocks
    local folders = {workspace:FindFirstChild("ActiveLuckyBlocks"), workspace:FindFirstChild("ActiveBrainrots")}
    for _, f in pairs(folders) do
        if f then
            for _, obj in pairs(f:GetDescendants()) do
                if obj:IsA("Model") and not Processed[obj] then
                    -- Filtro por nombre (Dropdown)
                    local match = false
                    for _, n in pairs(Config.Sel.Lucky) do if obj.Name:find(n) then match = true break end end
                    for _, n in pairs(Config.Sel.Brain) do if obj.Name:find(n) then match = true break end end
                    
                    if match or Config.Targets.Tickets or Config.Targets.Money then
                        local p = obj:FindFirstChild("Root") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if p then
                            local d = (root.Position - p.Position).Magnitude
                            if d < sd then sd = d; c = obj end
                        end
                    end
                end
            end
        end
    end
    return c
end

-- --- [ INTERFAZ ] ---
local Section = FarmTab:Section({ Title = "⚡ VORTEX MOBILE TURBO" })
Section:Toggle({ Title = "🔥 ACTIVAR", Callback = function(s) Config.Enabled = s end })
Section:Toggle({ Title = "Tickets/Money", Callback = function(s) Config.Targets.Tickets = s; Config.Targets.Money = s end })
Section:Toggle({ Title = "Lucky Blocks", Callback = function(s) Config.Targets.LuckyBlocks = s end })
Section:Dropdown({ Title = "Lucky List", Multi = true, Values = {"Common", "Rare", "Epic", "Legendary", "Mythical"}, Callback = function(v) Config.Sel.Lucky = v end })
Section:Toggle({ Title = "Brainrots", Callback = function(s) Config.Targets.Brainrots = s end })
Section:Dropdown({ Title = "Brain List", Multi = true, Values = {"Common", "Rare", "Epic", "Legendary", "Mythical"}, Callback = function(v) Config.Sel.Brain = v end })

-- --- [ LOOP CORE ] ---
task.spawn(function()
    while true do
        if Config.Enabled then
            pcall(function()
                local char = LocalPlayer.Character
                local root = GetRoot()
                if root and char.Humanoid.Health > 0 then
                    
                    -- Check Tsunami (Esconderse)
                    local tsunamiFolder = workspace:FindFirstChild("ActiveTsunamis")
                    local nearWave = false
                    if tsunamiFolder then
                        for _, w in pairs(tsunamiFolder:GetChildren()) do
                            local wp = w:IsA("BasePart") and w or w:FindFirstChildWhichIsA("BasePart", true)
                            if wp and (root.Position - wp.Position).Magnitude < Config.TsunamiRange then nearWave = true break end
                        end
                    end

                    if nearWave or Collected >= MaxInv then
                        FlyTo(HomeCF)
                        if Collected >= MaxInv then task.wait(1); Collected = 0; Processed = {} end
                    else
                        local Target = GetTarget()
                        if Target then
                            -- PRIORIDAD: IR AL ROOT
                            local TargetPart = Target:FindFirstChild("Root") or Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart", true)
                            
                            if TargetPart then
                                -- Volar pegado (1.5 studs)
                                if (root.Position - TargetPart.Position).Magnitude > 2 then
                                    FlyTo(TargetPart.CFrame * CFrame.new(0, 0, 1.5))
                                end
                                
                                -- BUSCAR PROMPT EN ROOT
                                local Prompt = TargetPart:FindFirstChildWhichIsA("ProximityPrompt") or Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                                
                                if Prompt then
                                    -- BYPASS MOBILE
                                    Prompt.RequiresLineOfSight = false
                                    Prompt.HoldDuration = 0
                                    
                                    -- FIRE BURST
                                    for i = 1, 15 do
                                        fireproximityprompt(Prompt)
                                        if i % 5 == 0 then task.wait() end -- Pequeño respiro para el procesador del cel
                                    end
                                    
                                    Processed[Target] = true
                                    Collected = Collected + 1
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- Anti-Colisión
RunService.Stepped:Connect(function()
    if Config.Enabled and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
    end
end)
