-- =================================================================
-- 🏰 TOWER.LUA - V20 (MÉTODO INFINITE YIELD - CERO GRAVEDAD)
-- =================================================================

local AutoFarmBTab = _G.AutoFarmBTab 
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local PuntoB = CFrame.new(145, 6, -160)
local ALTURA_FARM = -0   
local ALTURA_TORRE = 6   
local VELOCIDAD_TWEEN = 750 

local TowerConfig = {
    AutoFarm = false,
    AutoReward = false,
    TargetDeposits = 20, 
}

local CurrentTween = nil
local IsDoingTower = false
local IsWaitingForCooldown = false 

-- --- [ MOTOR ANTI-CAÍDA (ESTILO INFINITE YIELD) ] ---
local function EnableIYAntiGravity()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Remover anteriores si existen
    if root:FindFirstChild("IY_Float") then root.IY_Float:Destroy() end
    if root:FindFirstChild("IY_Gyro") then root.IY_Gyro:Destroy() end

    -- Crear Gravedad Cero (Cancela la caída)
    local float = Instance.new("BodyVelocity")
    float.Name = "IY_Float"
    float.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    float.Velocity = Vector3.zero -- Mantenerse quieto
    float.Parent = root

    -- Crear Estabilizador (Evita dar vueltas)
    local gyro = Instance.new("BodyGyro")
    gyro.Name = "IY_Gyro"
    gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    gyro.P = 9e4
    gyro.CFrame = root.CFrame
    gyro.Parent = root
end

local function DisableIYAntiGravity()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        if root:FindFirstChild("IY_Float") then root.IY_Float:Destroy() end
        if root:FindFirstChild("IY_Gyro") then root.IY_Gyro:Destroy() end
    end
end

local function CancelTween()
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
    end
end

local function TweenTo(targetPos)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not TowerConfig.AutoFarm or LocalPlayer.Character.Humanoid.Health <= 0 then return false end

    CancelTween()
    
    local dist = (root.Position - targetPos).Magnitude
    local tiempo = dist / VELOCIDAD_TWEEN
    if tiempo < 0.05 then tiempo = 0.05 end 

    local tweenInfo = TweenInfo.new(tiempo, Enum.EasingStyle.Linear)
    CurrentTween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
    
    local completed = false
    local connection
    connection = CurrentTween.Completed:Connect(function()
        completed = true
    end)
    
    CurrentTween:Play()
    
    while not completed do
        if not TowerConfig.AutoFarm or LocalPlayer.Character.Humanoid.Health <= 0 then
            CancelTween()
            if connection then connection:Disconnect() end
            return false
        end
        task.wait()
    end
    
    if connection then connection:Disconnect() end
    return true
end

local function SmartMove(targetCFrame, esTorre)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    local targetPos = targetCFrame.Position

    if not TweenTo(Vector3.new(root.Position.X, ALTURA_FARM, root.Position.Z)) then return false end
    if not TweenTo(Vector3.new(targetPos.X, ALTURA_FARM, targetPos.Z)) then return false end

    if esTorre then
        if not TweenTo(Vector3.new(targetPos.X, ALTURA_TORRE, targetPos.Z)) then return false end
    end

    return true
end

-- --- [ INTERACCIONES ] ---
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

local function GrabClosestReward()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local f = workspace:FindFirstChild("ActiveBrainrots")
    if f then 
        for _, obj in pairs(f:GetDescendants()) do 
            if obj:IsA("Model") then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local part = prompt and prompt.Parent or obj:FindFirstChild("Root")
                if part and (root.Position - part.Position).Magnitude < 100 then
                    root.CFrame = part.CFrame
                    SpamBrainrotPrompt(prompt)
                    warn("💎 ¡RECOMPENSA RECOLECTADA!")
                    return true
                end
            end
        end 
    end
    return false
end

-- =================================================================
-- 🚀 BUCLE PRINCIPAL
-- =================================================================

AutoFarmBTab:Section({ Title = "--Tower Event--", Icon = "castle" })

AutoFarmBTab:Toggle({
    Title = "⚔️ Auto Farm V20 (IY Anti-Fall)",
    Callback = function(state)
        TowerConfig.AutoFarm = state
        if state then
            if _G.ToggleAutoCollectPro then _G.ToggleAutoCollectPro(false) end
            if _G.GodModeEnabled == false and _G.ActivarGodModeTotal then _G.ActivarGodModeTotal(true) end

            IsDoingTower = false
            IsWaitingForCooldown = false 
            
            -- Aplicamos la gravedad cero desde que se activa
            EnableIYAntiGravity()

            -- Noclip y PlatformStand constante
            RunService:BindToRenderStep("TowerGhost", 1, function()
                if TowerConfig.AutoFarm and LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.PlatformStand = true end
                    
                    for _,p in pairs(LocalPlayer.Character:GetDescendants()) do 
                        if p:IsA("BasePart") then p.CanCollide = false end 
                    end
                end
            end)

            task.spawn(function()
                while TowerConfig.AutoFarm do
                    pcall(function()
                        if not IsDoingTower then
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if not root or LocalPlayer.Character.Humanoid.Health <= 0 then return end

                            local towerMain = workspace:FindFirstChild("GameObjects") and workspace.GameObjects:FindFirstChild("PlaceSpecific") and workspace.GameObjects.PlaceSpecific:FindFirstChild("root") and workspace.GameObjects.PlaceSpecific.root:FindFirstChild("Tower") and workspace.GameObjects.PlaceSpecific.root.Tower:FindFirstChild("Main")
                            if not towerMain then return end

                            local towerPos = CFrame.new(towerMain.Position.X - 25.68, ALTURA_TORRE, towerMain.Position.Z - 2.5)
                            local prompt = towerMain:FindFirstChild("Prompt") and towerMain.Prompt:FindFirstChild("ProximityPrompt")

                            if towerPos and prompt then
                                if not prompt.Enabled then
                                    if not IsWaitingForCooldown then
                                        IsWaitingForCooldown = true
                                        warn("⏳ Cooldown activo. Esperando en la base...")
                                        SmartMove(PuntoB, true) 
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
                                        SmartMove(towerPos, true) 
                                        InteractTower(prompt) 
                                        task.wait(0.5)
                                        IsDoingTower = false
                                    end
                                else
                                    local hasBrainrot = false
                                    for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                                        if v:IsA("Model") and (v.Name:find("Brainrot") or v.Name:find("NaturalSpawn")) then hasBrainrot = true break end
                                    end

                                    if hasBrainrot then
                                        IsDoingTower = true
                                        SmartMove(towerPos, true)
                                        InteractTower(prompt) 
                                        warn("📦 Entregado! Esperando 3.5s por cooldown...")
                                        task.wait(3.5) 
                                        IsDoingTower = false

                                    elseif ShouldCompleteTrial() then
                                        IsDoingTower = true
                                        SmartMove(towerPos, true) 
                                        InteractTower(prompt) 

                                        task.wait(0.6) 
                                        if ClickVirtualYes() then
                                            warn("💸 ¡Cobro exitoso!")
                                            if TowerConfig.AutoReward then
                                                local agarrado = false
                                                for i = 1, 30 do
                                                    if GrabClosestReward() then agarrado = true break end
                                                    task.wait(0.1)
                                                end
                                            end
                                        else
                                            warn("⚠️ Falló el click en YES")
                                        end

                                        SmartMove(PuntoB, true) 
                                        IsDoingTower = false

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
                                                    local success = SmartMove(base.CFrame, false) 
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

        else
            CancelTween()
            DisableIYAntiGravity()
            pcall(function() RunService:UnbindFromRenderStep("TowerGhost") end)
            
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum.PlatformStand = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp) 
            end
            
            for _,p in pairs(LocalPlayer.Character:GetDescendants()) do 
                if p:IsA("BasePart") then p.CanCollide = true end 
            end
        end
    end
})

AutoFarmBTab:Toggle({
    Title = "💎 Auto Brainrot Reward",
    Callback = function(state) TowerConfig.AutoReward = state end
})

local ListaNumeros = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"}
AutoFarmBTab:Dropdown({
    Title = "🎯 Target Brainrots (Máx)",
    Multi = false,
    Values = ListaNumeros,
    Default = "20",
    Callback = function(value)
        TowerConfig.TargetDeposits = tonumber(value) or 20
        warn("🎯 Meta actualizada a: " .. TowerConfig.TargetDeposits)
    end
})
