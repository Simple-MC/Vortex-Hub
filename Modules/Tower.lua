-- =================================================================
-- 🏰 TOWER.LUA - V14 (RUTA L-SHAPE REAL & VELOCIDAD EXTREMA)
-- =================================================================

local AutoFarmBTab = _G.AutoFarmBTab 
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local PuntoB = CFrame.new(145, 3, -140)
local RielSeguroZ = -140
local AlturaSegura = 3 
local MULTIPLICADOR_MAX = 1.5 -- 🚀 VELOCIDAD AUMENTADA (Aprovechando que el anticheat está flojo)

local TowerConfig = {
    AutoFarm = false,
    AutoReward = false,
    TargetDeposits = 20, 
}

local TowerTween = nil
local IsTowerFlying = false
local IsDoingTower = false
local IsWaitingForCooldown = false 

-- --- [ LÓGICA DE VUELO ULTRA RÁPIDO ] ---
local function getVelocidadBypass()
    local res = GuiService:GetScreenResolution()
    return (res.Magnitude * MULTIPLICADOR_MAX) * 0.95
end

local function EnsureAntiGravity()
    if not TowerConfig.AutoFarm then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root and hum then
        local motor = root:FindFirstChild("TowerFlyMotor")
        if not motor then
            motor = Instance.new("BodyVelocity")
            motor.Name = "TowerFlyMotor"
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
    if TowerTween then TowerTween:Cancel() end
    IsTowerFlying = false
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BodyVelocity") and v.Name == "TowerFlyMotor" then v:Destroy() end
            if v:IsA("BasePart") then v.CanCollide = true end 
        end
    end
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    if root then root.Velocity = Vector3.zero root.RotVelocity = Vector3.zero end
    pcall(function() RunService:UnbindFromRenderStep("TowerGhost") end)
end

local function FlyDirect(TargetCFrame, targetObj)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    EnsureAntiGravity()

    local currentSpeed = getVelocidadBypass()
    local Dist = (root.Position - TargetCFrame.Position).Magnitude
    local Time = Dist / currentSpeed
    if Time < 0.05 then Time = 0.05 end

    if TowerTween then TowerTween:Cancel() end
    IsTowerFlying = true
    TowerTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(TargetCFrame.Position)})
    TowerTween:Play()

    local elapsed = 0
    while IsTowerFlying and elapsed < Time do
        if not TowerConfig.AutoFarm or LocalPlayer.Character.Humanoid.Health <= 0 then
            if TowerTween then TowerTween:Cancel() end
            IsTowerFlying = false
            return false
        end
        if targetObj and not targetObj.Parent then
            if TowerTween then TowerTween:Cancel() end
            IsTowerFlying = false
            return false 
        end
        task.wait() elapsed = elapsed + 0.015
    end
    IsTowerFlying = false
    return true
end

-- --- [ NUEVA RUTA: RIEL -> X PERFECTO -> CAÍDA ] ---
local function LShapeFlyTo(TargetCFrame, esTorre, targetObj)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- 1. Subir al Riel Seguro (Solo si no estamos en él)
    local PuntoEntradaRiel = CFrame.new(root.Position.X, AlturaSegura, RielSeguroZ)
    if math.abs(root.Position.Z - RielSeguroZ) > 10 then 
        if not FlyDirect(PuntoEntradaRiel, targetObj) then return false end
    end

    -- 2. Viajar rapidísimo por el riel hasta quedar exactamente frente al objetivo
    local PuntoDeAtaque = CFrame.new(TargetCFrame.Position.X, AlturaSegura, RielSeguroZ)
    if not FlyDirect(PuntoDeAtaque, targetObj) then return false end

    -- 3. Si vamos a un Brainrot, esperar ola. Si vamos a la Torre, bajar de golpe.
    if not esTorre then
        local folder = workspace:FindFirstChild("ActiveTsunamis")
        if folder then
            for _, wave in pairs(folder:GetChildren()) do
                local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
                if p then
                    local VelX = math.abs(p.AssemblyLinearVelocity.X)
                    local Dist = math.abs(p.Position.X - TargetCFrame.Position.X)
                    if Dist < 100 then task.wait(0.5) end -- Solo espera si la ola está justo abajo
                end
            end
        end
    end

    -- 4. Caída directa
    return FlyDirect(TargetCFrame, targetObj)
end

-- --- [ INTERACCIONES Y LECTORES ESTRICTOS ] ---
local function InteractTower(prompt)
    if not prompt then return end
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    fireproximityprompt(prompt) 
end

local function SpamBrainrotPrompt(prompt)
    if not prompt then return end
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    for i = 1, 15 do 
        fireproximityprompt(prompt)
        task.wait(0.01)
    end
end

local function ShouldCompleteTrial()
    local hud = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TowerTrialHUD")
    if hud and hud:FindFirstChild("TrialBar") and hud.TrialBar.Visible then
        local depText = hud.TrialBar:FindFirstChild("Deposits")
        if depText then
            local actual, maximo = depText.Text:match("(%d+)/(%d+)")
            if actual and maximo and tonumber(actual) >= tonumber(maximo) then return true end
        end
        local timerText = hud.TrialBar:FindFirstChild("Timer") or hud.TrialBar:FindFirstChild("Time")
        if timerText and (timerText.Text:find("00:00") or timerText.Text:find("0:00")) then return true end
    end
    return false
end

local function ClickVirtualYes()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local yesBtn = pGui:FindFirstChild("ChoiceGui") and pGui.ChoiceGui:FindFirstChild("Choice") and pGui.ChoiceGui.Choice:FindFirstChild("Choices") and pGui.ChoiceGui.Choice.Choices:FindFirstChild("Yes")
        if yesBtn and yesBtn.Visible then
            -- 🎯 CORRECCIÓN PARA CELULAR: +36 de Inset (Barra de notificaciones)
            local x = yesBtn.AbsolutePosition.X + (yesBtn.AbsoluteSize.X / 2)
            local y = yesBtn.AbsolutePosition.Y + (yesBtn.AbsoluteSize.Y / 2) + 36 
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            return true
        end
    end
    return false
end

-- =================================================================
-- 🚀 BUCLE PRINCIPAL (CON PRIORIDADES Y WAIT RESTAURADO)
-- =================================================================

AutoFarmBTab:Toggle({
    Title = "⚔️ Auto Farm V14",
    Callback = function(state)
        TowerConfig.AutoFarm = state
        if state then
            IsDoingTower = false
            IsWaitingForCooldown = false 

            task.spawn(function()
                while TowerConfig.AutoFarm do
                    pcall(function()
                        if not IsDoingTower then
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if not root or LocalPlayer.Character.Humanoid.Health <= 0 then return end

                            local towerMain = workspace:FindFirstChild("GameObjects") and workspace.GameObjects:FindFirstChild("PlaceSpecific") and workspace.GameObjects.PlaceSpecific:FindFirstChild("root") and workspace.GameObjects.PlaceSpecific.root:FindFirstChild("Tower") and workspace.GameObjects.PlaceSpecific.root.Tower:FindFirstChild("Main")
                            if not towerMain then return end
                            
                            local towerPos = CFrame.new(towerMain.Position.X - 25.68, 6, towerMain.Position.Z - 2.5)
                            local prompt = towerMain:FindFirstChild("Prompt") and towerMain.Prompt:FindFirstChild("ProximityPrompt")

                            if towerPos and prompt then
                                if not prompt.Enabled then
                                    if not IsWaitingForCooldown then
                                        IsWaitingForCooldown = true
                                        warn("⏳ Cooldown activo. Yendo a base...")
                                        LShapeFlyTo(PuntoB, true) 
                                        RemoveAntiGravity()
                                    end
                                    return 
                                else
                                    IsWaitingForCooldown = false 
                                end

                                local hud = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TowerTrialHUD")
                                local isTrialActive = hud and hud:FindFirstChild("TrialBar") and hud.TrialBar.Visible

                                if not isTrialActive then
                                    if prompt.ActionText == "Start Trial!" then
                                        IsDoingTower = true
                                        LShapeFlyTo(towerPos, true) 
                                        InteractTower(prompt) 
                                        task.wait(0.5)
                                        IsDoingTower = false
                                    end
                                else
                                    -- 1️⃣ PRIORIDAD: ENTREGAR
                                    local hasBrainrot = false
                                    for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                                        if v:IsA("Model") and (v.Name:find("Brainrot") or v.Name:find("NaturalSpawn")) then hasBrainrot = true break end
                                    end

                                    if hasBrainrot then
                                        IsDoingTower = true
                                        LShapeFlyTo(towerPos, true)
                                        InteractTower(prompt)
                                        warn("📦 Entregado! Esperando 3.5s nueva UI...")
                                        if root then root.Velocity = Vector3.zero end
                                        task.wait(3.5) -- ⏰ RESTAURADO A PETICIÓN TUYA
                                        IsDoingTower = false
                                        
                                    -- 2️⃣ PRIORIDAD: COBRAR
                                    elseif ShouldCompleteTrial() then
                                        IsDoingTower = true
                                        LShapeFlyTo(towerPos, true) 
                                        InteractTower(prompt) 

                                        task.wait(0.6) 
                                        if ClickVirtualYes() then
                                            warn("💸 ¡Cobro exitoso!")
                                        else
                                            warn("⚠️ Falló el click en YES")
                                        end

                                        LShapeFlyTo(PuntoB, true) 
                                        RemoveAntiGravity()
                                        IsDoingTower = false

                                    -- 3️⃣ PRIORIDAD: BUSCAR MÁS
                                    else
                                        local reqRarity = nil
                                        if hud.TrialBar:FindFirstChild("Requirement") then reqRarity = hud.TrialBar.Requirement.Text:match("<font.->(.-)</font>") end
                                        
                                        if reqRarity then
                                            local targetObj = nil
                                            local f = workspace:FindFirstChild("ActiveBrainrots")
                                            if f then 
                                                for _, rf in pairs(f:GetChildren()) do
                                                    if rf.Name:lower() == reqRarity:lower() then
                                                        for _, obj in pairs(rf:GetDescendants()) do
                                                            if obj:IsA("Model") and (obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("ProximityPrompt", true)) then 
                                                                targetObj = obj break 
                                                            end
                                                        end
                                                    end
                                                end 
                                            end

                                            if targetObj then
                                                IsDoingTower = true
                                                local p = targetObj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                                local base = p and p.Parent or targetObj:FindFirstChild("Root")

                                                if p and base then
                                                    local success = LShapeFlyTo(base.CFrame, false, targetObj) 
                                                    if success then SpamBrainrotPrompt(p) end
                                                end
                                                IsDoingTower = false
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
            -- [Bucle Fantasma omitido aquí por brevedad, está igual]
