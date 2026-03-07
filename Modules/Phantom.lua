-- =================================================================
-- 👻 MODULE: PHANTOM EVENT - (ULTRA FAST & SAFE ELEVATOR)
-- =================================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

-- --- [ CONFIGURACIÓN PRINCIPAL ] ---
local RielSeguroZ = -160
local AlturaSeguraBase = 3 
local MULTIPLICADOR_MAX = 0.9 -- Velocidad casi al máximo permitido

local PhantomConfig = {
    Enabled = false,
    TargetPos = Vector3.new(446.6, 171.7, 333.1)
}

local PhantomTween = nil
local IsPhantomFlying = false

-- --- [ LECTOR DINÁMICO DEL HUD ] ---
local function GetEventValues()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local hud = gui and gui:FindFirstChild("HUD")
    local container = hud and hud:FindFirstChild("BottomLeft") 
        and hud.BottomLeft:FindFirstChild("GeneralCurrencies") 
        and hud.BottomLeft.GeneralCurrencies:FindFirstChild("Container") 
        and hud.BottomLeft.GeneralCurrencies.Container:FindFirstChild("EventCurrency")
        
    local valueObj = container and container:FindFirstChild("Value")
    
    if valueObj then
        -- Revisamos si es un TextLabel o un StringValue
        local texto = valueObj:IsA("TextLabel") and valueObj.Text or tostring(valueObj.Value or "")
        
        -- Si el formato es "80/100"
        local actual, maximo = texto:match("(%d+)/(%d+)")
        if actual and maximo then
            return tonumber(actual), tonumber(maximo)
        end
        
        -- Si solo es un número "100"
        local numeroSolo = texto:match("%d+")
        return tonumber(numeroSolo) or 0, 100 -- Asumimos 100 de máximo por defecto si no lo dice
    end
    return 0, 100
end

-- --- [ MOTOR DE VUELO ULTRA RÁPIDO ] ---
local function GetRoot() 
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
end

local function EnsureAntiGravity()
    local char = LocalPlayer.Character
    local root = GetRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root and hum then
        local motor = root:FindFirstChild("PhantomMotor")
        if not motor then
            motor = Instance.new("BodyVelocity")
            motor.Name = "PhantomMotor"
            motor.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            motor.Velocity = Vector3.zero 
            motor.Parent = root
        end
        hum.PlatformStand = true
    end
end

local function RemoveAntiGravity()
    local char = LocalPlayer.Character
    local root = GetRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if PhantomTween then PhantomTween:Cancel() end
    IsPhantomFlying = false
    
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BodyVelocity") and v.Name == "PhantomMotor" then v:Destroy() end
            if v:IsA("BasePart") then v.CanCollide = true end 
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

local function FlyDirect(TargetVector)
    local root = GetRoot()
    if not root then return false end
    EnsureAntiGravity()

    local currentSpeed = (GuiService:GetScreenResolution().Magnitude * MULTIPLICADOR_MAX) * 0.95
    local Dist = (root.Position - TargetVector).Magnitude
    local Time = Dist / currentSpeed
    if Time < 0.05 then Time = 0.05 end
    
    if PhantomTween then PhantomTween:Cancel() end
    IsPhantomFlying = true
    
    PhantomTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(TargetVector)})
    PhantomTween:Play()

    local elapsed = 0
    while IsPhantomFlying and elapsed < Time do
        if not PhantomConfig.Enabled or not workspace:FindFirstChild("PhantomMap") then 
            IsPhantomFlying = false
            return false 
        end
        task.wait() elapsed = elapsed + 0.015
    end
    IsPhantomFlying = false
    return true
end

-- --- [ RUTAS DE VUELO ] ---
local function DeliverySafeFly(TargetPos)
    local root = GetRoot()
    if not root then return end
    -- 1. Subir al Riel Seguro (Z = -160, Y = 3)
    FlyDirect(Vector3.new(root.Position.X, AlturaSeguraBase, RielSeguroZ))
    -- 2. Alinearse en X con la máquina
    FlyDirect(Vector3.new(TargetPos.X, AlturaSeguraBase, RielSeguroZ))
    -- 3. Elevador en Y (Sube para evitar cualquier ola)
    FlyDirect(Vector3.new(TargetPos.X, TargetPos.Y, RielSeguroZ))
    -- 4. Cruzar en Z hacia el objetivo final
    FlyDirect(TargetPos)
end

-- --- [ LÓGICA PRINCIPAL DEL EVENTO ] ---
_G.TogglePhantomEvent = function(state)
    PhantomConfig.Enabled = state
    
    if state then
        if not _G.GodModeEnabled and _G.ActivarGodModeTotal then 
            _G.ActivarGodModeTotal(true) 
        end

        task.spawn(function()
            local mapLost = false

            while PhantomConfig.Enabled do
                pcall(function()
                    if workspace:FindFirstChild("PhantomMap") then
                        mapLost = false
                        local actual, maximo = GetEventValues()
                        local root = GetRoot()

                        if root then
                            -- ¿ESTAMOS LLENOS?
                            if actual >= maximo then
                                warn("👻 ¡Límite alcanzado (" .. actual .. ")! Yendo a entregar...")
                                DeliverySafeFly(PhantomConfig.TargetPos)
                                
                                local prompt = workspace.PhantomMap:FindFirstChild("GhostCannon")
                                    and workspace.PhantomMap.GhostCannon:FindFirstChild("Part")
                                    and workspace.PhantomMap.GhostCannon.Part:FindFirstChild("Prompts")
                                    and workspace.PhantomMap.GhostCannon.Part.Prompts:FindFirstChild("ProximityPrompt")
                                
                                if prompt then
                                    for i = 1, 3 do
                                        fireproximityprompt(prompt, 1, true)
                                        task.wait(0.1)
                                    end
                                    warn("✨ ¡Bolas Phantom entregadas!")
                                    task.wait(0.5) -- Esperar a que el HUD se vacíe
                                end
                            else
                                -- HAY ESPACIO, BUSCAMOS BOLAS
                                local targetBall = nil
                                local minDist = math.huge
                                local folder = workspace:FindFirstChild("PhantomOrbParts") or workspace:FindFirstChild("PhantomMap")
                                
                                if folder then
                                    for _, obj in pairs(folder:GetDescendants()) do
                                        if obj:IsA("BasePart") and not obj.Parent:FindFirstChild("Humanoid") then
                                            -- Busca partes de orbes. (Si tienen un nombre distinto en Dex, puedes agregarlo aquí)
                                            if obj.Name:lower():find("orb") or obj.Name:lower():find("part") or folder.Name == "PhantomOrbParts" then
                                                local d = (root.Position - obj.Position).Magnitude
                                                if d < minDist then 
                                                    minDist = d
                                                    targetBall = obj 
                                                end
                                            end
                                        end
                                    end
                                end

                                if targetBall then
                                    -- Si está lejos, usamos L-Shape seguro; si está cerca, vuelo directo.
                                    if minDist > 50 then
                                        FlyDirect(Vector3.new(root.Position.X, AlturaSeguraBase, RielSeguroZ))
                                        FlyDirect(Vector3.new(targetBall.Position.X, AlturaSeguraBase, RielSeguroZ))
                                        FlyDirect(targetBall.Position)
                                    else
                                        FlyDirect(targetBall.Position)
                                    end
                                    
                                    -- Simulamos toque magnético
                                    if firetouchinterest then
                                        firetouchinterest(root, targetBall, 0)
                                        firetouchinterest(root, targetBall, 1)
                                    end
                                end
                            end
                        end
                    else
                        -- SI EL EVENTO ACABÓ O AÚN NO EMPIEZA
                        if not mapLost then
                            warn("🚫 PhantomMap no encontrado. En espera...")
                            RemoveAntiGravity()
                            mapLost = true
                        end
                    end
                end)
                task.wait(0.01) -- Ciclo extremadamente rápido para máxima fluidez
            end
            
            -- Si apagamos el toggle manualmente
            RemoveAntiGravity()
            pcall(function() RunService:UnbindFromRenderStep("PhantomGhost") end)
        end)

        -- NOCLIP ACTIVO SOLO CUANDO EL MAPA EXISTE
        RunService:BindToRenderStep("PhantomGhost", 1, function()
            if LocalPlayer.Character and PhantomConfig.Enabled and workspace:FindFirstChild("PhantomMap") then
                for _,p in pairs(LocalPlayer.Character:GetDescendants()) do 
                    if p:IsA("BasePart") then p.CanCollide = false end 
                end
            end
        end)
    else
        RemoveAntiGravity()
    end
end

-- =================================================================
-- 🎨 INTERFAZ GRÁFICA (Añadiéndolo a tu pestaña)
-- =================================================================
if _G.AutoFarmBTab then
    _G.AutoFarmBTab:Section({ Title = "--[ EVENTO: PHANTOM (GHOST CANNON) ]--", Icon = "ghost" })
    _G.AutoFarmBTab:Toggle({ 
        Title = "👻 Auto Phantom (Fast & Safe)", 
        Callback = function(state) 
            _G.TogglePhantomEvent(state) 
        end 
    })
end
