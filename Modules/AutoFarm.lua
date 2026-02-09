--[[
    MODULE: AUTO-FARM & SURVIVAL (VORTEX COORDS)
    LOGIC: Detect model in ActiveTsunamis -> Run to Safe Plate
]]

local Section = _G.MainTab:Section({ Title = "Granja & Supervivencia" })
local Player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local Config = {
    Farming = false,
    AntiDeath = false,
    DetectionRadius = 18, -- Un poco más de margen por las velocidades
    RunSpeed = 60         
}

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

local function GetCharacter()
    return Player.Character, Player.Character and Player.Character:FindFirstChild("Humanoid"), Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
end

local function IsDangerNear(myPos)
    local Folder = workspace:FindFirstChild("ActiveTsunamis")
    if not Folder then return false end
    
    for _, tsu in pairs(Folder:GetChildren()) do
        -- Buscamos cualquier parte de la ola para medir distancia
        local p = tsu:IsA("BasePart") and tsu or tsu:FindFirstChildWhichIsA("BasePart", true)
        if p then
            local dist = (Vector2.new(p.Position.X, p.Position.Z) - Vector2.new(myPos.X, myPos.Z)).Magnitude
            if dist < Config.DetectionRadius then
                return true
            end
        end
    end
    return false
end

local function GetBestPlate(myPos)
    local best = nil
    local dist = math.huge
    for _, data in pairs(SafeZones) do
        local d = (myPos - data.cf.Position).Magnitude
        if d < dist then
            dist = d
            best = data.cf.Position
        end
    end
    return best
end

task.spawn(function()
    while true do
        local Char, Hum, Root = GetCharacter()
        if Char and Hum and Root then
            local Danger = IsDangerNear(Root.Position)
            
            if Config.AntiDeath and Danger then
                local Plate = GetBestPlate(Root.Position)
                if Plate then
                    Hum.WalkSpeed = Config.RunSpeed
                    Hum:MoveTo(Plate)
                end
            else
                if Hum.WalkSpeed == Config.RunSpeed then Hum.WalkSpeed = 16 end
                
                if Config.Farming then
                    local Coin = workspace:FindFirstChild("Coin", true) or workspace:FindFirstChild("Money", true)
                    if Coin and Coin:IsA("BasePart") then
                        Hum:MoveTo(Coin.Position)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

Section:Toggle({ Title = "🏃 Esquivar Olas (Placas)", Callback = function(v) Config.AntiDeath = v end })
Section:Toggle({ Title = "💰 Auto Farm Monedas", Callback = function(v) Config.Farming = v end })
