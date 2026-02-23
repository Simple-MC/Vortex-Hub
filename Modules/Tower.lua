-- =================================================================
-- 🏰 TOWER.LUA - AUTO FARM PERFECTO (ANTI-NINJA & SMART COOLDOWN)
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
local MULTIPLICADOR_MAX = 1 

local TowerConfig = {
    AutoFarm = false,
    AutoReward = false,
    TargetDeposits = 10, 
}

local TowerTween = nil
local IsTowerFlying = false
local IsDoingTower = false

-- --- [ LÓGICA DE VUELO Y BYPASS ] ---
local function getVelocidadBypass()
    local res = GuiService:GetScreenResolution()
    return (res.Magnitude * MULTIPLICADOR_MAX) * 0.9 
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
end

local function FlyDirect(TargetCFrame)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
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
            return
        end
        task.wait() elapsed = elapsed + 0.015
    end
    IsTowerFlying = false
end

local function EsSeguroMatematico(TargetX, TargetZ)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return true end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local currentSpeed = getVelocidadBypass()
    local DistanciaTotalViaje = math.abs(root.Position.Z - TargetZ) * 2
    local NuestroTiempoTotal = (DistanciaTotalViaje / currentSpeed) + 1 -- Añadimos 1s de margen
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

local function LShapeFlyTo(TargetCFrame)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local PuntoEntradaRiel = CFrame.new(root.Position.X, AlturaSegura, RielSeguroZ)
    local PuntoDeAtaque = CFrame.new(TargetCFrame.Position.X, AlturaSegura, RielSeguroZ)
    if math.abs(root.Position.Z - RielSeguroZ) > 10 then FlyDirect(PuntoEntradaRiel) end
    FlyDirect(PuntoDeAtaque)
    while TowerConfig.AutoFarm and not EsSeguroMatematico(TargetCFrame.Position.X, TargetCFrame.Position.Z) do task.wait() end
    if TowerConfig.AutoFarm then FlyDirect(TargetCFrame) end
end

-- --- [ NUEVO: FRENOS ABSOLUTOS DE 1 SEGUNDO ] ---
local function FirePromptSafely(prompt, duration)
    if not prompt then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    
    local start = tick()
    while tick() - start < duration do
        if root then 
            root.Velocity = Vector3.zero -- CONGELADO 100%
            root.RotVelocity = Vector3.zero 
        end
        fireproximityprompt(prompt)
        task.wait(0.05)
    end
end

-- --- [ FUNCIONES DE LA TORRE ] ---
local function GetTowerCalculatedCFrame()
    local mainPart = workspace:FindFirstChild("GameObjects") and workspace.GameObjects:FindFirstChild("PlaceSpecific") and workspace.GameObjects.PlaceSpecific:FindFirstChild("root") and workspace.GameObjects.PlaceSpecific.root:FindFirstChild("Tower") and workspace.GameObjects.PlaceSpecific.root.Tower:FindFirstChild("Main")
    if mainPart then return CFrame.new(mainPart.Position.X - 25.6884765625, 6, -2.5) end
    return nil
end

local function GetTowerPrompt()
    local m = workspace:FindFirstChild("GameObjects") and workspace.GameObjects:FindFirstChild("PlaceSpecific") and workspace.GameObjects.PlaceSpecific:FindFirstChild("root") and workspace.GameObjects.PlaceSpecific.root:FindFirstChild("Tower") and workspace.GameObjects.PlaceSpecific.root.Tower:FindFirstChild("Main")
    return m and m:FindFirstChild("Prompt") and m.Prompt:FindFirstChild("ProximityPrompt")
end

local function GetRequiredRarity()
    local hud = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TowerTrialHUD")
    if hud and hud:FindFirstChild("TrialBar") and hud.TrialBar.Visible then
        local req = hud.TrialBar:FindFirstChild("Requirement")
        if req then return req.Text:match("<font.->(.-)</font>") end
    end
    return nil
end

local function GetCurrentDeposits()
    local hud = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TowerTrialHUD")
    if hud and hud:FindFirstChild("TrialBar") and hud.TrialBar.Visible then
        local dep = hud.TrialBar:FindFirstChild("Deposits")
        if dep then return tonumber(dep.Text:match("(%d+)/%d+")) or 0 end
    end
    return 0
end

local function IsTrialActive()
    local hud = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TowerTrialHUD")
    return hud and hud:FindFirstChild("TrialBar") and hud.TrialBar.Visible
end

local function GetBrainrotByRarity(rarityName)
    if not rarityName then return nil end
    local f = workspace:FindFirstChild("ActiveBrainrots")
    if f then 
        for _, rf in pairs(f:GetChildren()) do
            if rf.Name:lower() == rarityName:lower() then
                for _, obj in pairs(rf:GetDescendants()) do
                    if obj:IsA("Model") and (obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("ProximityPrompt", true)) then return obj end
                end
            end
        end 
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
            local y = yesBtn.AbsolutePosition.Y + (yesBtn.AbsoluteSize.Y / 2) + 58
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            return true
        end
    end
    return false
end

-- --- [ NUEVO: AUTO REWARD INSTANTÁNEO (ANTI NINJAS) ] ---
local function GrabClosestReward()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    local f = workspace:FindFirstChild("ActiveBrainrots")
    if f then 
        for _, obj in pairs(f:GetDescendants()) do 
            if obj:IsA("Model") then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local part = prompt and prompt.Parent or obj:FindFirstChild("Root")
                -- Escanea en un radio de 50 studs (Ya estamos en la torre)
                if part and (root.Position - part.Position).Magnitude < 50 then
                    -- TELETRANSPORTE INSTANTÁNEO AL ITEM
                    root.CFrame = part.CFrame
                    prompt.RequiresLineOfSight = false
                    prompt.HoldDuration = 0
                    for i = 1, 20 do fireproximityprompt(prompt) task.wait(0.01) end
                    warn("💎 ¡RECOMPENSA ROBADA CON ÉXITO A LOS NINJAS!")
                    return true
                end
            end
        end 
    end
    return false
end

-- =================================================================
-- 🎨 INTERFAZ GRÁFICA Y BUCLE
-- =================================================================

AutoFarmBTab:Section({ Title = "--Tower Event--", Icon = "castle" })

AutoFarmBTab:Toggle({
    Title = "⚔️ Auto Farm",
    Callback = function(state)
        TowerConfig.AutoFarm = state
        
        if state then
            if _G.ToggleAutoCollectPro then _G.ToggleAutoCollectPro(false) end
            
            -- ACTIVAR GOD MODE AUTOMÁTICO
            if _G.GodModeEnabled == false and _G.ActivarGodModeTotal then
                _G.ActivarGodModeTotal(true)
                warn("🛡️ God Mode Activado para la Torre")
            end
            
            IsDoingTower = false
            
            task.spawn(function()
                while TowerConfig.AutoFarm do
                    pcall(function()
                        if not IsDoingTower then
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if not root or LocalPlayer.Character.Humanoid.Health <= 0 then return end

                            local towerPos = GetTowerCalculatedCFrame()
                            local prompt = GetTowerPrompt()

                            if towerPos and prompt then
                                -- 1. CHECK DE COOLDOWN INTELIGENTE
                                if not prompt.Enabled then
                                    if (root.Position - PuntoB.Position).Magnitude > 50 then
                                        LShapeFlyTo(PuntoB)
                                        RemoveAntiGravity()
                                    end
                                    return -- Se detiene y espera en base hasta que Enabled sea true
                                end

                                if not IsTrialActive() then
                                    -- INICIAR MISIÓN (Se queda 1 segundo quieto)
                                    if prompt.ActionText == "Start Trial!" then
                                        IsDoingTower = true
                                        LShapeFlyTo(towerPos)
                                        FirePromptSafely(prompt, 1) 
                                        LShapeFlyTo(PuntoB)
                                        RemoveAntiGravity()
                                        IsDoingTower = false
                                    end
                                else
                                    local current = GetCurrentDeposits()
                                    
                                    -- COMPLETAR MISIÓN (Solo si alcanzamos la meta elegida en Dropdown)
                                    if current >= TowerConfig.TargetDeposits or prompt.ActionText == "Complete Trial" then
                                        IsDoingTower = true
                                        LShapeFlyTo(towerPos)
                                        FirePromptSafely(prompt, 1) 
                                        
                                        task.wait(0.6) 
                                        if ClickVirtualYes() then
                                            if TowerConfig.AutoReward then
                                                warn("⏳ Escaneando aparición de recompensa... (Modo Anti-Ninja)")
                                                local agarrado = false
                                                -- Espera hasta 3 segundos, escaneando cada milisegundo
                                                for i = 1, 30 do
                                                    if GrabClosestReward() then 
                                                        agarrado = true 
                                                        break 
                                                    end
                                                    task.wait(0.1)
                                                end
                                                if not agarrado then warn("❌ Ninguna recompensa spawneó.") end
                                            end
                                        end
                                        
                                        LShapeFlyTo(PuntoB)
                                        RemoveAntiGravity()
                                        IsDoingTower = false
                                        
                                    else
                                        -- ENTREGAR BRAINROT (Frenos puestos)
                                        if HasBrainrotInBack() then
                                            IsDoingTower = true
                                            LShapeFlyTo(towerPos)
                                            FirePromptSafely(prompt, 1)
                                            warn("📦 Entregado! Volviendo a base a esperar la interfaz...")
                                            
                                            LShapeFlyTo(PuntoB)
                                            RemoveAntiGravity()
                                            task.wait(1) -- Pequeña pausa para que actualice la UI
                                            IsDoingTower = false
                                        else
                                            -- BUSCAR BRAINROT
                                            local reqRarity = GetRequiredRarity()
                                            if reqRarity then
                                                local targetObj = GetBrainrotByRarity(reqRarity)
                                                if targetObj then
                                                    IsDoingTower = true
                                                    local p = targetObj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                                    local base = p and p.Parent or targetObj:FindFirstChild("Root")
                                                    
                                                    if p and base then
                                                        LShapeFlyTo(base.CFrame)
                                                        FirePromptSafely(p, 1) -- Quieto agarrándolo
                                                    end
                                                    IsDoingTower = false
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

local ListaBrainrots = {"1/10", "2/10", "3/10", "4/10", "5/10", "6/10", "7/10", "8/10", "9/10", "10/10"}
AutoFarmBTab:Dropdown({
    Title = "🎯 Brainrots Must Take",
    Multi = false,
    Values = ListaBrainrots,
    Callback = function(value)
        local target = string.match(value, "(%d+)/")
        if target then TowerConfig.TargetDeposits = tonumber(target) end
    end
})
