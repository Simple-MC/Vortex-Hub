--[[
    MODULE: VORTEX AUTO-FARM v12 (PROMPT FIX)
    LOGIC: Uses 'MaxActivationDistance' check before firing.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- --- [ SEGURIDAD TAB ] ---
local FarmTab = _G.AutoFarmTab
local t = 0
while not FarmTab and t < 5 do task.wait(0.1); t=t+0.1; FarmTab = _G.AutoFarmTab end
if not FarmTab then warn("Falta AutoFarmTab"); return end

-- --- [ CONFIGURACIÓN ] ---
local HomeCF = CFrame.new(136.92, 3.11, -9.24)
local Collected = 0
local MaxInv = 4
local Processed = {} 

local Config = {
    Enabled = false, Speed = 300, TsunamiRange = 300,
    Targets = { Tickets = false, Consoles = false, Money = false, LuckyBlocks = false, Brainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

-- --- [ ZONAS SEGURAS ] ---
local SafeZones = {
    CFrame.new(136.92, 3.11, -9.24),
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
local Section = FarmTab:Section({ Title = "🌊 Auto-Farm Precision" })

Section:Toggle({ Title = "🔥 ACTIVAR", Callback = function(s) Config.Enabled = s; if s then Collected = 0 end end })

Section:Slider({
    Title = "Rango Tsunami", Step = 10, Value = { Min = 50, Max = 1000, Default = 300 },
    Callback = function(v) Config.TsunamiRange = v end
})

Section:Button({ Title = "🏠 Fijar Casa", Callback = function() 
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


-- --- [ LÓGICA CORE ] ---

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local CurTween = nil
local function Tween(TargetCF)
    local root = GetRoot()
    if not root then return end
    
    local Dist = (root.Position - TargetCF.Position).Magnitude
    local Time = Dist / Config.Speed
    
    if CurTween then CurTween:Cancel() end
    CurTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = TargetCF})
    CurTween:Play()
    
    local t = 0
    while t < Time do
        if not GetRoot() or not Config.Enabled then if CurTween then CurTween:Cancel() end return end
        task.wait(0.1); t=t+0.1
    end
    CurTween = nil; if GetRoot() then root.Velocity = Vector3.zero end
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
    if not root then return SafeZones[1] end
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

    -- Tickets/Money
    if Config.Targets.Tickets then local f=workspace:FindFirstChild("ArcadeEventTickets") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Consoles then local f=workspace:FindFirstChild("ArcadeEventConsoles") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end
    if Config.Targets.Money then local f=workspace:FindFirstChild("MoneyEventParts") if f then for _,v in pairs(f:GetChildren()) do table.insert(List,v) end end end

    -- Lucky Blocks
    if Config.Targets.LuckyBlocks then
        local f=workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then for _,m in pairs(f:GetChildren()) do 
            if m:IsA("Model") and not Processed[m] then
                for _,s in pairs(Config.Sel.Lucky) do if m.Name:find(s) then table.insert(List,m) break end end
            end
        end end
    end

    -- Brainrots (LÓGICA ACTUALIZADA)
    if Config.Targets.Brainrots then
        local f=workspace:FindFirstChild("ActiveBrainrots")
        if f then for _,rarityFolder in pairs(f:GetChildren()) do
            if table.find(Config.Sel.Brain, rarityFolder.Name) then
                for _,container in pairs(rarityFolder:GetChildren()) do
                    if container.Name == "RenderedBrainrot" then
                        for _,mob in pairs(container:GetChildren()) do
                            if mob:IsA("Model") and not Processed[mob] then table.insert(List, mob) end
                        end
                    elseif container:IsA("Model") and not Processed[container] then
                        table.insert(List, container)
                    end
                end
            end
        end end
    end

    -- Buscar más cercano
    for _,v in pairs(List) do
        -- Priorizamos encontrar una parte con Prompt, sino la parte base
        local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
        local partToCheck = prompt and prompt.Parent or (v:IsA("BasePart") and v) or v:FindFirstChildWhichIsA("BasePart", true)
        
        if partToCheck then 
            local d = (root.Position - partToCheck.Position).Magnitude
            if d < sd then sd = d; c = v end 
        end
    end
    return c
end

-- --- [ LOOP PRINCIPAL ] ---

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
        local success, err = pcall(function()
            if Config.Enabled then
                local root = GetRoot()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                
                if root and hum and hum.Health > 0 then
                    
                    -- 1. Tsunami Check
                    if CheckTsunami() then
                        local Safe = GetSafe()
                        if Safe and (root.Position - Safe.Position).Magnitude > 5 then Tween(Safe) end
                    
                    -- 2. Inventory Check
                    elseif Collected >= MaxInv then
                        if (root.Position - HomeCF.Position).Magnitude > 5 then Tween(HomeCF) 
                        else Collected=0; Processed={}; task.wait(1.5) end
                    
                    -- 3. Farming
                    else
                        local Target = GetTarget()
                        if Target then
                            -- Buscar el Prompt dentro del Target (recursivo por si está escondido)
                            local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            local MovePart = nil

                            if Prompt then
                                MovePart = Prompt.Parent -- Nos movemos hacia la parte que tiene el prompt
                            else
                                -- Si no hay prompt (tickets/money), vamos a la parte física
                                MovePart = Target:IsA("BasePart") and Target or Target:FindFirstChildWhichIsA("BasePart", true)
                            end

                            if MovePart then
                                -- Moverse
                                if (root.Position - MovePart.Position).Magnitude > 3 then 
                                    Tween(MovePart.CFrame) 
                                end
                                
                                -- INTERACCIÓN (TU LÓGICA)
                                if Prompt then
                                    local dist = (root.Position - MovePart.Position).Magnitude
                                    
                                    -- Usamos MaxActivationDistance para disparar solo cuando sea válido
                                    if dist <= Prompt.MaxActivationDistance then
                                        fireproximityprompt(Prompt)
                                        Processed[Target] = true
                                        Collected = Collected + 1
                                        task.wait(0.5) 
                                    end
                                end
                            end
                        end
                    end
                else
                    if CurTween then CurTween:Cancel(); CurTween=nil end
                    task.wait(1)
                end
            end
        end)
        if not success then task.wait(1) end
        task.wait(0.1)
    end
end)
