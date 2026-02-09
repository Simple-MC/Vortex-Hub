--[[
    MODULE: AUTO-FARM & SURVIVAL (VORTEX COORDS)
    LOGIC: Monitor ActiveTsunamis -> Speed 60 -> Walk to Vortex Safe Zones
]]

local Section = _G.AutoFarmTab:Section({ Title = "Granja & Supervivencia" })
local Player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local Config = {
    Farming = false,
    AntiDeath = false,
    DetectionRadius = 15, 
    RunSpeed = 60         
}

-- --- [ LISTA DE COORDENADAS VORTEX ] ---
local SafeZones = {
    {size = Vector3.new(12, 2, 12), cf = CFrame.new(199.8230438232422, -6.388181209564209, -4.251100063323975, 0.02236330322921276, 4.731766090060319e-09, -0.9997498989105225, 7.935094004096754e-08, 1, 6.50794307333058e-09, 0.9997498989105225, -7.94766350509235e-08, 0.02236330322921276)},
    {size = Vector3.new(12, 2, 12), cf = CFrame.new(285.1240234375, -6.388181209564209, -6.462066173553467, 0.022363483905792236, -9.792859856361247e-08, -0.9997498989105225, -5.25375476456702e-08, 1, -9.912830734037925e-08, 0.9997498989105225, 5.474126396620704e-08, 0.022363483905792236)},
    {size = Vector3.new(12, 2, 12), cf = CFrame.new(396.3044738769531, -6.388181209564209, -3.625314712524414, -0.02126467227935791, -2.4013447230686324e-08, -0.9997738599777222, 5.725279450530252e-08, 1, -2.5236616352231067e-08, 0.9997738599777222, -5.777649647598082e-08, -0.02126467227935791)},
    {size = Vector3.new(12, 2, 12), cf = CFrame.new(541.787109375, -6.388181209564209, 1.5795786380767822, -0.03871738910675049, 1.4260471026261712e-08, -0.9992501735687256, -4.1319694332742074e-08, 1, 1.5872162251184818e-08, 0.9992501735687256, 4.190324176533977e-08, -0.03871738910675049)},
    {size = Vector3.new(12, 2, 12), cf = CFrame.new(755.1702270507812, -6.388181209564209, 0.9757502675056458, 0.0005314946174621582, 4.342071591167951e-08, -0.9999998807907104, -1.4157412131510227e-08, 1, 4.3413198369535166e-08, 0.9999998807907104, 1.4134336367987999e-08, 0.0005314946174621582)},
    {size = Vector3.new(12, 2, 12), cf = CFrame.new(1072.664794921875, -6.388181686401367, -1.5353976488113403, 0.004853308200836182, -4.728368452333598e-08, -0.9999881982803345, -1.495230250725399e-08, 1, -4.735681002898673e-08, 0.9999881982803345, 1.518196413030637e-08, 0.004853308200836182)},
    {size = Vector3.new(12, 2, 12), cf = CFrame.new(1548.9649658203125, -6.388181209564209, -0.5249959826469421, 0.002760767936706543, -3.162510253673645e-08, -0.9999961853027344, 5.181613715876665e-08, 1, -3.148216976001095e-08, 0.9999961853027344, -5.172902461936246e-08, 0.002760767936706543)},
    {size = Vector3.new(12, 2, 12), cf = CFrame.new(2244.320556640625, -6.388181686401367, -6.547964096069336, 0.02843308448791504, -7.348205155466303e-09, -0.9995957016944885, 3.350805144464175e-08, 1, -6.3980545306208114e-09, 0.9995957016944885, -3.3312588243461505e-08, 0.02843308448791504)},
    {size = Vector3.new(12, 2, 12), cf = CFrame.new(2598.8583984375, -6.388181209564209, 6.928470134735107, 0.015345394611358643, 1.2669414850563498e-08, -0.9998822808265686, 5.543025238807786e-08, 1, 1.3521605168875794e-08, 0.9998822808265686, -5.563121874274657e-08, 0.015345394611358643)},
}

-- --- [ FUNCIONES ] ---

local function GetCharacter()
    return Player.Character, Player.Character and Player.Character:FindFirstChild("Humanoid"), Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
end

-- Revisa si hay olas en la carpeta ActiveTsunamis
local function IsDangerNear(myPos)
    local Folder = workspace:FindFirstChild("ActiveTsunamis")
    if not Folder then return false end
    for _, tsu in pairs(Folder:GetChildren()) do
        local p = tsu.PrimaryPart or tsu:FindFirstChildWhichIsA("BasePart")
        if p and (p.Position - myPos).Magnitude < Config.DetectionRadius then
            -- Solo peligro si la ola no está muy por debajo de nosotros
            if p.Position.Y > myPos.Y - 10 then return true end
        end
    end
    return false
end

-- Encuentra la zona Vortex más cercana que no esté inundada
local function GetBestVortexZone(myPos)
    local bestZone = nil
    local shortestDist = math.huge
    local Folder = workspace:FindFirstChild("ActiveTsunamis")

    for _, data in pairs(SafeZones) do
        local zonePos = data.cf.Position
        local flooded = false
        
        -- Verificar si la zona ya tiene agua encima
        if Folder then
            for _, tsu in pairs(Folder:GetChildren()) do
                local p = tsu.PrimaryPart or tsu:FindFirstChildWhichIsA("BasePart")
                if p and p.Position.Y > zonePos.Y + 2 then
                    flooded = true; break
                end
            end
        end

        if not flooded then
            local d = (myPos - zonePos).Magnitude
            if d < shortestDist then
                shortestDist = d
                bestZone = zonePos
            end
        end
    end
    return bestZone
end

-- --- [ BUCLE IA ] ---
task.spawn(function()
    while true do
        local Char, Hum, Root = GetCharacter()
        if Char and Hum and Root then
            
            local Danger = IsDangerNear(Root.Position)
            
            if Config.AntiDeath and Danger then
                -- MODO HUIDA VORTEX
                local Target = GetBestVortexZone(Root.Position)
                if Target then
                    Hum.WalkSpeed = Config.RunSpeed
                    Hum:MoveTo(Target)
                    -- Salto de seguridad
                    if (Root.Position - Target).Magnitude < 8 then Hum.Jump = true end
                end
            else
                -- VELOCIDAD NORMAL & FARMEO
                if Hum.WalkSpeed == Config.RunSpeed then Hum.WalkSpeed = 16 end
                
                if Config.Farming then
                    -- Lógica simple para buscar monedas mientras no hay tsunami
                    local Coin = workspace:FindFirstChild("Coin", true) or workspace:FindFirstChild("Money", true)
                    if Coin and Coin:IsA("BasePart") then
                        Hum:MoveTo(Coin.Position)
                        if (Root.Position - Coin.Position).Magnitude < 5 then
                            firetouchinterest(Root, Coin, 0)
                            firetouchinterest(Root, Coin, 1)
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- --- [ UI ] ---
Section:Toggle({ Title = "🏃 Supervivencia Vortex (Placas)", Callback = function(v) Config.AntiDeath = v end })
Section:Toggle({ Title = "💰 Auto Farm Monedas", Callback = function(v) Config.Farming = v end })
Section:Slider({ Title = "Detección (Studs)", Min = 5, Max = 50, Default = 15, Callback = function(v) Config.DetectionRadius = v end })
