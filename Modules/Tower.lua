-- =================================================================
-- 🏰 TOWER.LUA - V15 (RUTA SEGURA OBLIGATORIA & CAÍDA SIN MIEDO)
-- =================================================================

local AutoFarmBTab = _G.AutoFarmBTab 
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local PuntoB = CFrame.new(145, 3, -160)
local RielSeguroZ = -160
local AlturaSegura = 3 
local MULTIPLICADOR_MAX = 0.8 -- 🚀 Sigue rapidísimo

local TowerConfig = {
    AutoFarm = false,
    AutoReward = false,
    TargetDeposits = 20, 
}

local TowerTween = nil
local IsTowerFlying = false
local IsDoingTower = false
local IsWaitingForCooldown = false 

-- --- [ MOTOR DE VUELO ] ---
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

local function EsSeguroMatematico(TargetX, TargetZ)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return true end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local currentSpeed = getVelocidadBypass()
    local DistanciaTotalViaje = math.abs(root.Position.Z - TargetZ) * 2
    local NuestroTiempoTotal = (DistanciaTotalViaje / currentSpeed) + 0.5 

    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p then
            local VelX = p.AssemblyLinearVelocity.X
            local SpeedOla = math.abs(VelX) < 10 and 250 or math.abs(VelX)
            local PosOlaX = p.Position.X
            local DistanciaOlaAlItem = math.abs(PosOlaX - TargetX)
            if DistanciaOlaAlItem < 90 then return false end
            local seAcerca = (VelX > 0 and PosOlaX < TargetX) or (VelX < 0 and PosOlaX > TargetX) or (SpeedOla >= 250 and DistanciaOlaAlItem < 1200)
            if seAcerca and (DistanciaOlaAlItem / SpeedOla) - NuestroTiempoTotal < 0.5 then return false end
        end
    end
    return true
end

-- --- [ 🛠️ RUTA L-SHAPE ARREGLADA ] ---
local function LShapeFlyTo(TargetCFrame, esTorre, targetObj)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- 1. OBLIGATORIO: Subir al Riel Seguro primero (Z = -140)
    local PuntoEntradaRiel = CFrame.new(root.Position.X, AlturaSegura, RielSeguroZ)
    if math.abs(root.Position.Z - RielSeguroZ) > 10 then 
        if not FlyDirect(PuntoEntradaRiel, targetObj) then return false end
    end

    -- 2. OBLIGATORIO: Viajar seguro por la autopista del riel
    local PuntoDeAtaque = CFrame.new(TargetCFrame.Position.X, AlturaSegura, RielSeguroZ)
    if not FlyDirect(PuntoDeAtaque, targetObj) then return false end

    -- 3. Si vamos por un ítem, cuidarnos de las olas. Si vamos a la torre, ignorar este paso.
    if not esTorre then
        while TowerConfig.AutoFarm and not EsSeguroMatematico(TargetCFrame.Position.X, TargetCFrame.Position.Z) do 
            if targetObj and not targetObj.Parent then return false end 
            task.wait() 
        end
    end

    -- 4. Caída final hacia el objetivo (Desde la seguridad del riel)
    if TowerConfig.AutoFarm then 
        return FlyDirect(TargetCFrame, targetObj) 
    end
    return false
end

-- --- [ INTERACCIONES ] ---
local function InteractTower(prompt)
    if not prompt then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    if root then root.Velocity = Vector3.zero root.RotVelocity = Vector3.zero end
    fireproximityprompt(prompt) 
end

local function SpamBrainrotPrompt(prompt)
    if not prompt then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    if root then root.Velocity = Vector3.zero root.RotVelocity = Vector3.zero end
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

local function GetRequiredRarity()
    local hud = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TowerTrialHUD")
    if hud and hud:FindFirstChild("TrialBar") and hud.TrialBar.Visible then
        local req = hud.TrialBar:FindFirstChild("Requirement")
        if req then return req.Text:match("<font.->(.-)</font>") end
    end
    return nil
end

local function HasBrainrotInBack()
    local char = LocalPlayer.Character
    if char then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Model") and (v.Name:find("Brainrot") or v.Name:find("NaturalSpawn")) then return true end
        end
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
    Title = "⚔️ Auto Farm V15",
    Callback = function(state)
        TowerConfig.AutoFarm = state
        if state then
            if _G.ToggleAutoCollectPro then _G.ToggleAutoCollectPro(false) end
            if _G.GodModeEnabled == false and _G.ActivarGodModeTotal then _G.ActivarGodModeTotal(true) end

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
                                    local hasBrainrot = false
                                    for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                                        if v:IsA("Model") and (v.Name:find("Brainrot") or v.Name:find("NaturalSpawn")) then hasBrainrot = true break end
                                    end

                                    if hasBrainrot then
                                        IsDoingTower = true
                                        LShapeFlyTo(towerPos, true) -- ✨ Ahora sí viajará por el riel
                                        InteractTower(prompt)
                                        warn("📦 Entregado! Esperando 3.5s...")
                                        if root then root.Velocity = Vector3.zero end
                                        task.wait(3.5) 
                                        IsDoingTower = false
                                        
                                    elseif ShouldCompleteTrial() then
                                        IsDoingTower = true
                                        LShapeFlyTo(towerPos, true) 
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

                                        LShapeFlyTo(PuntoB, true) 
                                        RemoveAntiGravity()
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

            RunService:BindToRenderStep("TowerGhost", 1, function()
                if TowerConfig.AutoFarm and LocalPlayer.Character then
                    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if root and root:FindFirstChild("TowerFlyMotor") then
                        for _,p in pairs(LocalPlayer.Character:GetDescendants()) do 
                            if p:IsA("BasePart") then p.CanCollide = false end 
                        end
                    end
                end
            end)

        else
            RemoveAntiGravity()
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
