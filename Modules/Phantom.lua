-- =================================================================
-- 👻 MODULE: PHANTOM EVENT (SAFE ELEVATOR FLY & AUTO-DELIVER)
-- =================================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

-- --- [ CONFIGURACIÓN ] ---
local RielSeguroZ = -160
local AlturaSeguraBase = 3 
local MULTIPLICADOR_MAX = 0.6 

local PhantomConfig = {
    Enabled = false,
    TargetPos = Vector3.new(446.6, 171.7, 333.1)
}

local PhantomTween = nil
local IsPhantomFlying = false

-- --- [ LECTOR DEL HUD (BOLAS ACTUALES) ] ---
local function GetBallsCount()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        local hud = gui:FindFirstChild("HUD")
        local val = hud 
            and hud:FindFirstChild("BottomLeft")
            and hud.BottomLeft:FindFirstChild("GeneralCurrencies")
            and hud.BottomLeft.GeneralCurrencies:FindFirstChild("Container")
            and hud.BottomLeft.GeneralCurrencies.Container:FindFirstChild("EventCurrency")
            and hud.BottomLeft.GeneralCurrencies.Container.EventCurrency:FindFirstChild("Value")
            
        if val and val.Text then
            -- Extrae únicamente los números del TextLabel
            local num = val.Text:match("%d+")
            return tonumber(num) or 0
        end
    end
    return 0
end

-- --- [ MOTOR DE VUELO BÁSICO ] ---
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
    pcall(function() RunService:UnbindFromRenderStep("PhantomGhost") end)
end

local function FlyDirect(TargetVector)
    local root = GetRoot()
    if not root then return false end
    EnsureAntiGravity()

    local currentSpeed = (GuiService:GetScreenResolution().Magnitude * MULTIPLICADOR_MAX) * 0.60
    local Dist = (root.Position - TargetVector).Magnitude
    local Time = Dist / currentSpeed
    if Time < 0.05 then Time = 0.05 end
    
    if PhantomTween then PhantomTween:Cancel() end
    IsPhantomFlying = true
    
    PhantomTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(TargetVector)})
    PhantomTween:Play()

    local elapsed = 0
    while IsPhantomFlying and elapsed < Time do
        -- Abortar si apagan el script o el mapa desaparece
        if not PhantomConfig.Enabled or not workspace:FindFirstChild("PhantomMap") then 
            IsPhantomFlying = false
            return false 
        end
        task.wait() elapsed = elapsed + 0.015
    end
    IsPhantomFlying = false
    return true
end

-- --- [ RUTAS DE VUELO SEGURAS ] ---

-- 1. Elevador Seguro para la Entrega (El que pediste para no morir)
local function DeliverySafeFly(TargetPos)
    local root = GetRoot()
    if not root then return end

    -- PASO 1: Subir al riel seguro en la posición X actual
    if math.abs(root.Position.Z - RielSeguroZ) > 5 or math.abs(root.Position.Y - AlturaSeguraBase) > 5 then
        FlyDirect(Vector3.new(root.Position.X, AlturaSeguraBase, RielSeguroZ))
    end

    -- PASO 2: Moverse en X por el riel seguro hasta estar alineado con la máquina
    FlyDirect(Vector3.new(TargetPos.X, AlturaSeguraBase, RielSeguroZ))

    -- PASO 3: Subir como elevador en Y (Aún estando en el riel seguro Z = -160)
    FlyDirect(Vector3.new(TargetPos.X, TargetPos.Y, RielSeguroZ))

    -- PASO 4: Cruzar en Z hacia la máquina
    FlyDirect(Vector3.new(TargetPos.X, TargetPos.Y, TargetPos.Z))
end

-- 2. L-Shape básico para recoger bolas en el suelo
local function CollectSafeFly(TargetPos)
    local root = GetRoot()
    if not root then return end
    
    if math.abs(root.Position.Z - RielSeguroZ) > 5 then 
        FlyDirect(Vector3.new(root.Position.X, AlturaSeguraBase, RielSeguroZ))
    end
    FlyDirect(Vector3.new(TargetPos.X, AlturaSeguraBase, RielSeguroZ))
    FlyDirect(TargetPos)
end

-- --- [ LÓGICA PRINCIPAL DEL EVENTO ] ---
_G.TogglePhantomEvent = function(state)
    PhantomConfig.Enabled = state
    
    if state then
        -- Asegurar God Mode si existe
        if not _G.GodModeEnabled and _G.ActivarGodModeTotal then 
            _G.ActivarGodModeTotal(true) 
        end

        task.spawn(function()
            local fueDesactivadoPorMapa = false

            while PhantomConfig.Enabled do
                pcall(function()
                    -- Verificamos si el evento está activo
                    if workspace:FindFirstChild("PhantomMap") then
                        
                        -- Si antes no estaba, volvemos a activar el Noclip
                        if fueDesactivadoPorMapa then
                            fueDesactivadoPorMapa = false
                            RunService:BindToRenderStep("PhantomGhost", 1, function()
                                if LocalPlayer.Character and PhantomConfig.Enabled then
                                    for _,p in pairs(LocalPlayer.Character:GetDescendants()) do 
                                        if p:IsA("BasePart") then p.CanCollide = false end 
                                    end
                                end
                            end)
                        end

                        local currentBalls = GetBallsCount()
                        local root = GetRoot()

                        if root then
                            if currentBalls >= 100 then
                                -- ¡INVENTARIO LLENO! Vamos a entregar con el vuelo de elevador seguro
                                warn("👻 ¡100 Bolas Phantom alcanzadas! Yendo a la máquina...")
                                DeliverySafeFly(PhantomConfig.TargetPos)
                                
                                -- Activar el ProximityPrompt del cañón fantasma
                                local prompt = workspace:FindFirstChild("PhantomMap")
                                    and workspace.PhantomMap:FindFirstChild("GhostCannon")
                                    and workspace.PhantomMap.GhostCannon:FindFirstChild("Part")
                                    and workspace.PhantomMap.GhostCannon.Part:FindFirstChild("Prompts")
                                    and workspace.PhantomMap.GhostCannon.Part.Prompts:FindFirstChild("ProximityPrompt")
                                
                                if prompt then
                                    for i = 1, 3 do
                                        fireproximityprompt(prompt, 1, true)
                                        task.wait(0.1)
                                    end
                                    warn("✨ ¡Bolas Phantom entregadas!")
                                    task.wait(1) -- Pequeña pausa para que el HUD baje a 0
                                end
                            else
                                -- AÚN HAY ESPACIO: Buscar bolas en el mapa
                                -- (Usa PhantomOrbParts o busca genéricamente en el PhantomMap)
                                local targetBall = nil
                                local folder = workspace:FindFirstChild("PhantomOrbParts") or workspace.PhantomMap
                                
                                if folder then
                                    for _, obj in pairs(folder:GetDescendants()) do
                                        -- Filtramos partes que parezcan ser orbes recolectables
                                        if obj:IsA("BasePart") and not obj.Parent:FindFirstChild("Humanoid") then
                                            -- Agrega aquí condiciones extra si las bolas tienen un nombre específico
                                            if obj.Name:lower():find("orb") or obj.Name:lower():find("part") or folder.Name == "PhantomOrbParts" then
                                                targetBall = obj
                                                break
                                            end
                                        end
                                    end
                                end

                                if targetBall then
                                    CollectSafeFly(targetBall.Position)
                                    
                                    if firetouchinterest then
                                        firetouchinterest(root, targetBall, 0)
                                        task.wait(0.05)
                                        firetouchinterest(root, targetBall, 1)
                                    end
                                end
                            end
                        end
                    else
                        -- EL EVENTO NO ESTÁ ACTIVO (El mapa desapareció)
                        if not fueDesactivadoPorMapa then
                            warn("🚫 PhantomMap no encontrado. Esperando a que comience el evento...")
                            RemoveAntiGravity() -- Quita el vuelo y restaura al personaje
                            fueDesactivadoPorMapa = true
                        end
                    end
                end)
                task.wait(0.2)
            end
        end)

        -- INICIO DEL GHOST MODE
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
-- 🎨 INTERFAZ GRÁFICA (Integrado en AutoFarmBTab)
-- =================================================================
if _G.AutoFarmBTab then
    _G.AutoFarmBTab:Section({ Title = "--[ EVENTO: PHANTOM (GHOST CANNON) ]--", Icon = "ghost" })
    _G.AutoFarmBTab:Toggle({ 
        Title = "👻 Auto Phantom Event (Recoger & Entregar)", 
        Callback = function(state) 
            _G.TogglePhantomEvent(state) 
        end 
    })
end
