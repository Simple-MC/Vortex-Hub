-- =================================================================
-- 🚀 MODULE: AUTO-COLLECT PRO + TOWER TRIAL EVENT (VIRTUAL VIM)
-- =================================================================

local BetaTab = _G.AutoFarmBTab
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- --- [ CONFIGURACIÓN BASE Y PUNTOS ] ---
local PuntoB = CFrame.new(145, 3, -140) -- BASE DE DESCARGA
local MULTIPLICADOR_MAX = 0.7 -- Properties Bypass

local TowerConfig = {
    AutoFarm = false,
    AutoReward = false,
    TargetDeposits = 10, -- Por defecto 10/10
}

local BetaTween = nil
local IsBetaFlying = false
local IsDoingSequence = false

-- --- [ LÓGICA DE BYPASS DE VUELO (COMO EL PRO) ] ---
local function getVelocidadBypass()
    local res = GuiService:GetScreenResolution()
    return (res.Magnitude * MULTIPLICADOR_MAX) * 0.9 -- Volamos al 90% del límite legal
end

local function EnsureAntiGravity()
    if not TowerConfig.AutoFarm then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and hum then
        local motor = root:FindFirstChild("BypassFlyMotor")
        if not motor then
            motor = Instance.new("BodyVelocity")
            motor.Name = "BypassFlyMotor"
            motor.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            motor.Velocity = Vector3.zero 
            motor.Parent = root
        end
        hum.PlatformStand = true
    end
end

local function RemoveAntiGravity()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BodyVelocity") and v.Name == "BypassFlyMotor" then v:Destroy() end
        end
    end
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    if root then
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
    end
end

local function BetaFlyTo(TargetCFrame)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    EnsureAntiGravity()

    local currentSpeed = getVelocidadBypass()
    local Dist = (root.Position - TargetCFrame.Position).Magnitude
    local Time = Dist / currentSpeed
    if Time < 0.05 then Time = 0.05 end

    if BetaTween then BetaTween:Cancel() end
    IsBetaFlying = true
    
    BetaTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(TargetCFrame.Position)})
    BetaTween:Play()
    
    local elapsed = 0
    while IsBetaFlying and elapsed < Time do
        if not TowerConfig.AutoFarm or not LocalPlayer.Character or LocalPlayer.Character.Humanoid.Health <= 0 then
            if BetaTween then BetaTween:Cancel() end
            IsBetaFlying = false
            return
        end
        task.wait() 
        elapsed = elapsed + 0.015
    end
    IsBetaFlying = false
end

-- --- [ FUNCIONES ESPECÍFICAS DE LA TORRE ] ---

-- Calcula la posición de la torre restando el offset que mencionaste
local function GetTowerCalculatedCFrame()
    local mainPart = workspace:FindFirstChild("GameObjects") 
        and workspace.GameObjects:FindFirstChild("PlaceSpecific") 
        and workspace.GameObjects.PlaceSpecific:FindFirstChild("root") 
        and workspace.GameObjects.PlaceSpecific.root:FindFirstChild("Tower") 
        and workspace.GameObjects.PlaceSpecific.root.Tower:FindFirstChild("Main")
        
    if mainPart then
        local pos = mainPart.Position
        -- Restamos X y Z como pediste, fijamos Y en 6
        return CFrame.new(pos.X - 21.3, 6, pos.Z - 46.1)
    end
    return nil
end

local function GetTowerPrompt()
    local mainPart = workspace:FindFirstChild("GameObjects") 
        and workspace.GameObjects:FindFirstChild("PlaceSpecific") 
        and workspace.GameObjects.PlaceSpecific:FindFirstChild("root") 
        and workspace.GameObjects.PlaceSpecific.root:FindFirstChild("Tower") 
        and workspace.GameObjects.PlaceSpecific.root.Tower:FindFirstChild("Main")
        
    if mainPart then
        return mainPart:FindFirstChild("Prompt") and mainPart.Prompt:FindFirstChild("ProximityPrompt")
    end
    return nil
end

-- Lee la UI para saber qué rareza nos piden
local function GetRequiredRarity()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local hud = pGui and pGui:FindFirstChild("TowerTrialHUD")
    if hud and hud:FindFirstChild("TrialBar") and hud.TrialBar.Visible then
        local reqText = hud.TrialBar:FindFirstChild("Requirement")
        if reqText then
            -- Busca la palabra dentro del formato <font color="#...">Rareza</font>
            local rarity = reqText.Text:match("<font.->(.-)</font>")
            return rarity
        end
    end
    return nil
end

-- Lee cuántos brainrots llevamos (Ej: saca el "3" de "3/10")
local function GetCurrentDeposits()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local hud = pGui and pGui:FindFirstChild("TowerTrialHUD")
    if hud and hud:FindFirstChild("TrialBar") and hud.TrialBar.Visible then
        local depText = hud.TrialBar:FindFirstChild("Deposits")
        if depText then
            local current = depText.Text:match("(%d+)/%d+")
            return tonumber(current) or 0
        end
    end
    return 0
end

local function IsTrialActive()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local hud = pGui and pGui:FindFirstChild("TowerTrialHUD")
    return hud and hud:FindFirstChild("TrialBar") and hud.TrialBar.Visible
end

-- Busca el Brainrot exacto en el mapa según la rareza
local function GetBrainrotByRarity(rarityName)
    if not rarityName then return nil end
    local f = workspace:FindFirstChild("ActiveBrainrots")
    if f then 
        for _, rarityFolder in pairs(f:GetChildren()) do
            -- Si la carpeta coincide con la rareza pedida
            if rarityFolder.Name:lower() == rarityName:lower() then
                for _, obj in pairs(rarityFolder:GetDescendants()) do
                    if obj:IsA("Model") and (obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("ProximityPrompt", true)) then
                        return obj
                    end
                end
            end
        end 
    end
    return nil
end

-- Robo rápido: El más cercano, sin importar rareza
local function GrabClosestReward()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local c, sd = nil, 200 -- Buscar en un radio de 200 studs max
    local f = workspace:FindFirstChild("ActiveBrainrots")
    
    if f then 
        for _, obj in pairs(f:GetDescendants()) do 
            if obj:IsA("Model") then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local part = prompt and prompt.Parent or obj:FindFirstChild("Root")
                if part then
                    local d = (root.Position - part.Position).Magnitude
                    if d < sd then 
                        sd = d
                        c = obj 
                    end
                end
            end
        end 
    end
    
    if c then
        local prompt = c:FindFirstChildWhichIsA("ProximityPrompt", true)
        local part = prompt and prompt.Parent or c:FindFirstChild("Root")
        if part and prompt then
            -- MODO RELÁMPAGO: Ir y spamear
            BetaFlyTo(part.CFrame)
            prompt.RequiresLineOfSight = false
            prompt.HoldDuration = 0
            for i = 1, 20 do fireproximityprompt(prompt) task.wait(0.01) end
            
            -- Huir a la base
            BetaFlyTo(PuntoB)
        end
    end
end

-- Simula el Click al botón "Yes" de tu imagen
local function ClickVirtualYes()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local yesBtn = pGui:FindFirstChild("ChoiceGui") 
            and pGui.ChoiceGui:FindFirstChild("Choice") 
            and pGui.ChoiceGui.Choice:FindFirstChild("Choices") 
            and pGui.ChoiceGui.Choice.Choices:FindFirstChild("Yes")
            
        if yesBtn and yesBtn.Visible then
            local x = yesBtn.AbsolutePosition.X + (yesBtn.AbsoluteSize.X / 2)
            local y = yesBtn.AbsolutePosition.Y + (yesBtn.AbsoluteSize.Y / 2) + 58
            
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            warn("✔️ Botón YES clickeado virtualmente.")
            return true
        end
    end
    return false
end

local function HasBrainrotInBack()
    local char = LocalPlayer.Character
    if char then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Model") and (v.Name:find("Brainrot") or v.Name:find("NaturalSpawn")) then
                return true
            end
        end
    end
    return false
end

-- =================================================================
-- 🎨 INTERFAZ GRÁFICA (WIND UI)
-- =================================================================

BetaTab:Section({ Title = "--Tower Event--" })

BetaTab:Toggle({
    Title = "⚔️ Auto Farm",
    Callback = function(state)
        TowerConfig.AutoFarm = state
        
        if state then
            IsDoingSequence = false
            
            task.spawn(function()
                while TowerConfig.AutoFarm do
                    pcall(function()
                        if not IsDoingSequence then
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if not root or LocalPlayer.Character.Humanoid.Health <= 0 then return end

                            local towerPos = GetTowerCalculatedCFrame()
                            local prompt = GetTowerPrompt()

                            if towerPos and prompt then
                                if not IsTrialActive() then
                                    -- FASE 1: INICIAR MISIÓN
                                    if prompt.ActionText == "Start Trial!" then
                                        IsDoingSequence = true
                                        BetaFlyTo(towerPos)
                                        prompt.RequiresLineOfSight = false
                                        prompt.HoldDuration = 0
                                        fireproximityprompt(prompt)
                                        task.wait(0.5)
                                        IsDoingSequence = false
                                    end
                                else
                                    -- FASE 2 Y 3: MISIÓN ACTIVA
                                    local current = GetCurrentDeposits()
                                    
                                    if current >= TowerConfig.TargetDeposits or prompt.ActionText == "Complete Trial" then
                                        -- FASE 3: FINALIZAR (Logramos la meta)
                                        IsDoingSequence = true
                                        BetaFlyTo(towerPos)
                                        prompt.RequiresLineOfSight = false
                                        prompt.HoldDuration = 0
                                        fireproximityprompt(prompt) -- Hacemos que salga la UI
                                        
                                        task.wait(0.6) -- Esperar a que la UI anime
                                        if ClickVirtualYes() then
                                            if TowerConfig.AutoReward then
                                                task.wait(0.2) -- Micro pausa para que spawnee la recompensa
                                                GrabClosestReward()
                                            end
                                        end
                                        IsDoingSequence = false
                                        
                                    else
                                        -- FASE 2: BUSCAR Y ENTREGAR
                                        if HasBrainrotInBack() then
                                            -- Ya tenemos uno en la espalda, ir a entregar
                                            IsDoingSequence = true
                                            BetaFlyTo(towerPos)
                                            prompt.RequiresLineOfSight = false
                                            prompt.HoldDuration = 0
                                            fireproximityprompt(prompt)
                                            task.wait(3) -- Pausa táctica que pediste
                                            IsDoingSequence = false
                                        else
                                            -- Leer la UI y buscar en el mapa
                                            local reqRarity = GetRequiredRarity()
                                            if reqRarity then
                                                local targetObj = GetBrainrotByRarity(reqRarity)
                                                if targetObj then
                                                    IsDoingSequence = true
                                                    local p = targetObj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                                    local base = p and p.Parent or targetObj:FindFirstChild("Root")
                                                    
                                                    if p and base then
                                                        BetaFlyTo(base.CFrame)
                                                        p.RequiresLineOfSight = false
                                                        p.HoldDuration = 0
                                                        for i = 1, 15 do fireproximityprompt(p) end
                                                        task.wait(0.1)
                                                    end
                                                    IsDoingSequence = false
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
            
            -- Ghost mode
            RunService:BindToRenderStep("TowerGhost", 1, function()
                if TowerConfig.AutoFarm and LocalPlayer.Character then
                    for _,p in pairs(LocalPlayer.Character:GetDescendants()) do 
                        if p:IsA("BasePart") then p.CanCollide = false end 
                    end
                end
            end)
            
        else
            -- APAGADO Y LIMPIEZA
            if BetaTween then BetaTween:Cancel() end
            IsBetaFlying = false
            IsDoingSequence = false
            RunService:UnbindFromRenderStep("TowerGhost")
            
            RemoveAntiGravity()
            
            if LocalPlayer.Character then
                for _,p in pairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end
})

BetaTab:Toggle({
    Title = "💎 Auto Brainrot Reward",
    Callback = function(state) TowerConfig.AutoReward = state end
})

local ListaBrainrots = {"1/10", "2/10", "3/10", "4/10", "5/10", "6/10", "7/10", "8/10", "9/10", "10/10"}
BetaTab:Dropdown({
    Title = "🎯 Brainrots Must Take",
    Multi = false,
    Values = ListaBrainrots,
    Callback = function(value)
        -- Extrae el número. Ej: de "3/10" saca el 3.
        local target = string.match(value, "(%d+)/")
        if target then
            TowerConfig.TargetDeposits = tonumber(target)
            warn("🎯 Meta ajustada a: " .. TowerConfig.TargetDeposits)
        end
    end
})
