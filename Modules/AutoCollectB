-- =================================================================
-- 🚀 MODULE: AUTO-COLLECT (BETA) - HIT & RUN STRATEGY
-- =================================================================

local AutoFarmBTab = _G.AutoFarmBTab
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Variables del Hilo Seguro (Coordenadas que me pasaste)
local RielSeguroZ = -140
local RielMinX = 145
local RielMaxX = 4345
local AlturaSegura = 3

local BetaConfig = {
    Enabled = false,
    Speed = 350,
    TsunamiMargen = 40 -- Distancia extra para no rozar la ola
}

local BetaTween = nil
local IsBetaFlying = false

-- Función de vuelo directo al punto
local function BetaFlyTo(TargetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local Dist = (root.Position - TargetCFrame.Position).Magnitude
    local Time = Dist / BetaConfig.Speed

    if BetaTween then BetaTween:Cancel() end
    IsBetaFlying = true
    
    -- Vuelo manteniendo la rotación recta
    local _, rotY, _ = root.CFrame:ToEulerAnglesYXZ()
    local CFrameDerecho = CFrame.new(TargetCFrame.Position) * CFrame.Angles(0, rotY, 0)

    BetaTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrameDerecho})
    BetaTween:Play()
    BetaTween.Completed:Wait() -- Esperamos a que llegue
    
    IsBetaFlying = false
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
end

-- Función experta para saber si la ola cruzó nuestro hilo hacia el ítem
local function CaminoBloqueadoPorOla(StartPos, EndPos)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return false end

    local minX = math.min(StartPos.X, EndPos.X) - BetaConfig.TsunamiMargen
    local maxX = math.max(StartPos.X, EndPos.X) + BetaConfig.TsunamiMargen
    local minZ = math.min(StartPos.Z, EndPos.Z) - BetaConfig.TsunamiMargen
    local maxZ = math.max(StartPos.Z, EndPos.Z) + BetaConfig.TsunamiMargen

    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p then
            -- Si la ola está dentro del cuadro imaginario entre nosotros y el brainrot
            if (p.Position.X > minX and p.Position.X < maxX) and (p.Position.Z > minZ and p.Position.Z < maxZ) then
                return true
            end
        end
    end
    return false
end

-- Interfaz en la pestaña BETA
AutoFarmBTab:Section({ Title = "--[ HIT & RUN (HILO SEGURO) ]--", Icon = "skull" })

AutoFarmBTab:Toggle({
    Title = "⚡ Activar Hit & Run (Brainrots/Lucky)",
    Callback = function(state)
        BetaConfig.Enabled = state
        
        if state then
            task.spawn(function()
                while BetaConfig.Enabled do
                    pcall(function()
                        local char = LocalPlayer.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if not root or char.Humanoid.Health <= 0 then return end

                        -- 1. Aquí usas tu función GetTarget() del script original para buscar el Brainrot
                        -- (Asegúrate de que la función GetTarget() esté accesible en esta parte del código)
                        local Target = GetTarget() 

                        if Target then
                            local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            local MovePart = Prompt and Prompt.Parent or Target:FindFirstChild("Root") or Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart", true)

                            if MovePart then
                                -- 2. Calcular nuestro punto exacto en el Hilo de Seguridad basado en la X del Brainrot
                                local TargetX = math.clamp(MovePart.Position.X, RielMinX, RielMaxX)
                                local PuntoDeAtaque = CFrame.new(TargetX, AlturaSegura, RielSeguroZ)

                                -- 3. Vamos al punto de ataque en el hilo primero (estamos a salvo aquí)
                                local distAlPuntoDeAtaque = (root.Position - PuntoDeAtaque.Position).Magnitude
                                if distAlPuntoDeAtaque > 5 then
                                    BetaFlyTo(PuntoDeAtaque)
                                else
                                    -- 4. Estamos alineados. ¿Viene el Tsunami por aquí?
                                    if CaminoBloqueadoPorOla(root.Position, MovePart.Position) then
                                        -- Esperamos pacientemente en el hilo
                                        root.Velocity = Vector3.zero
                                        task.wait(0.2)
                                    else
                                        -- 5. ¡VÍA LIBRE! Entramos rapidísimo
                                        BetaFlyTo(MovePart.CFrame)
                                        
                                        -- 6. Recogemos el Brainrot con tu spam súper potente
                                        if Prompt then
                                            Prompt.RequiresLineOfSight = false
                                            Prompt.HoldDuration = 0
                                            for i = 1, 15 do fireproximityprompt(Prompt) end
                                            task.wait(0.1) -- Damos tiempo a que el servidor registre el cobro
                                        end
                                        
                                        -- 7. Salimos corriendo de regreso al Hilo Seguro inmediatamente
                                        BetaFlyTo(PuntoDeAtaque)
                                    end
                                end
                            end
                        else
                            -- Si no hay Brainrots, nos quedamos descansando en el centro del hilo seguro
                            local CentroSeguro = CFrame.new((RielMinX + RielMaxX)/2, AlturaSegura, RielSeguroZ)
                            if (root.Position - CentroSeguro.Position).Magnitude > 20 then
                                BetaFlyTo(CentroSeguro)
                            end
                            task.wait(0.5)
                        end
                    end)
                    task.wait(0.05)
                end
            end)
            
            -- Activar el modo fantasma/plataforma para volar mejor
            RunService:BindToRenderStep("BetaFlyStabilizer", 1, function()
                if BetaConfig.Enabled and LocalPlayer.Character and IsBetaFlying then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.PlatformStand = true end 
                    for _,p in pairs(LocalPlayer.Character:GetDescendants()) do 
                        if p:IsA("BasePart") then p.CanCollide = false end 
                    end
                end
            end)
            
        else
            -- Apagar
            if BetaTween then BetaTween:Cancel() end
            IsBetaFlying = false
            RunService:UnbindFromRenderStep("BetaFlyStabilizer")
            
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then 
                    hum.PlatformStand = false 
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp) 
                end
                for _,p in pairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end
})
