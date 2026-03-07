-- =================================================================
-- ❄️🔥 MODULE: FIRE & ICE EVENT (TEAM LOGIC + AUTO SACRIFICE)
-- =================================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local MULTIPLICADOR_MAX = 1

local FireIceConfig = {
    Enabled = false,
    MaxItems = 7, -- Se ajusta solo
    Team = "None" -- "None", "Fire", o "Ice"
}

local BetaTween = nil
local IsBetaFlying = false

-- --- [ DETECTOR DE LÍMITE Y DE EQUIPO (NOTIFICACIONES) ] ---
if not _G.FireIceListener then
    _G.FireIceListener = true
    
    local function SetupUIListener()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if playerGui then
            local notifs = playerGui:WaitForChild("NewNotifications", 5)
            local itemsFolder = notifs and notifs:WaitForChild("Items", 5)
            
            if itemsFolder then
                itemsFolder.ChildAdded:Connect(function(child)
                    task.wait(0.1) 
                    -- Buscamos el TextLabel profundamente por si está dentro de un Frame
                    local textLabel = child:FindFirstChild("TextLabel", true)
                    
                    if textLabel then
                        local txt = textLabel.Text
                        
                        -- 1. Chequeo de Límite
                        if txt == "Carry limit reached!" then
                            local char = LocalPlayer.Character
                            if char then
                                local count = 0
                                for _, v in pairs(char:GetChildren()) do
                                    if v.Name == "RenderedBrainrot" then count = count + 1 end
                                end
                                if count > 0 and FireIceConfig.MaxItems ~= count then
                                    FireIceConfig.MaxItems = count
                                    print("✨ VORTEX: ¡Límite máximo detectado! Nuevo límite: " .. count)
                                end
                            end
                        
                        -- 2. Chequeo de Equipos
                        elseif string.find(txt, "Team Fire") then
                            if FireIceConfig.Team ~= "Fire" then
                                FireIceConfig.Team = "Fire"
                                print("🔥 VORTEX: ¡Asignado al Equipo FUEGO!")
                            end
                        elseif string.find(txt, "Team Ice") then
                            if FireIceConfig.Team ~= "Ice" then
                                FireIceConfig.Team = "Ice"
                                print("❄️ VORTEX: ¡Asignado al Equipo HIELO!")
                            end
                        end
                    end
                end)
            end
        end
    end
    task.spawn(SetupUIListener)
end

-- --- [ MATEMÁTICA ESPACIAL: ¿ESTÁ ADENTRO DE LA ZONA? ] ---
local function IsInsidePart(point, part)
    if not part then return false end
    -- Convierte la posición del mundo a la posición relativa de la zona (ignora rotaciones)
    local offset = part.CFrame:PointToObjectSpace(point)
    local size = part.Size / 2
    return math.abs(offset.X) <= size.X and math.abs(offset.Y) <= size.Y and math.abs(offset.Z) <= size.Z
end

local function IsValidForTeam(handlePos)
    if FireIceConfig.Team == "None" then return true end -- Si aún no sabemos el equipo, intentamos agarrar cualquiera
    
    local vfx = workspace:FindFirstChild("FireAndIceMap") and workspace.FireAndIceMap:FindFirstChild("VFX")
    local bgfx = vfx and vfx:FindFirstChild("Fire&IceWorldBGFX")
    local fxArea = bgfx and bgfx:FindFirstChild("FXArea")
    
    if not fxArea then return true end -- Seguridad por si no ha cargado el mapa
    
    local prefix = (FireIceConfig.Team == "Fire") and "firefxarea" or "icefxarea"
    
    for i = 1, 10 do
        local areaPart = fxArea:FindFirstChild(prefix .. i)
        if areaPart and IsInsidePart(handlePos, areaPart) then
            return true -- ¡Está dentro de una zona válida de nuestro equipo!
        end
    end
    
    return false -- Está en la zona del equipo contrario
end

-- --- [ AUTO-CLICKER UI (BOTÓN SACRIFICAR) ] ---
local function ClickVisibleButtons()
    -- Busca botones de confirmación en la pantalla y les hace clic
    for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible and gui.Active then
            local name = gui.Name:lower()
            local text = (gui:IsA("TextButton") and gui.Text:lower()) or ""
            
            -- Busca palabras clave comunes o simplemente clica los botones de confirmación
            if name:find("confirm") or name:find("sacrific") or name:find("yes") or text:find("sacrific") or text:find("yes") then
                local absPos = gui.AbsolutePosition
                local absSize = gui.AbsoluteSize
                local centerX = absPos.X + (absSize.X / 2)
                local centerY = absPos.Y + (absSize.Y / 2)
                
                -- Simula un clic real en el centro del botón
                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
            end
        end
    end
end

-- --- [ MOTOR DE VUELO (BETA FLY) ] ---
local function GetRoot() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end

local function EnsureAntiGravity()
    if not FireIceConfig.Enabled then return end
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
    
    if BetaTween then BetaTween:Cancel() end
    IsBetaFlying = false
    
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BodyVelocity") and v.Name == "BypassFlyMotor" then v:Destroy() end
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
    RunService:UnbindFromRenderStep("FireIceGhost")
end

local function BetaFlyTo(TargetCFrame)
    local root = GetRoot()
    if not root then return end

    EnsureAntiGravity()

    local currentSpeed = (GuiService:GetScreenResolution().Magnitude * MULTIPLICADOR_MAX) * 0.9 
    local Dist = (root.Position - TargetCFrame.Position).Magnitude
    local Time = Dist / currentSpeed
    if Time < 0.05 then Time = 0.05 end

    if BetaTween then BetaTween:Cancel() end
    IsBetaFlying = true
    
    BetaTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(TargetCFrame.Position)})
    BetaTween:Play()
    
    local elapsed = 0
    while IsBetaFlying and elapsed < Time do
        if not FireIceConfig.Enabled or not GetRoot() or LocalPlayer.Character.Humanoid.Health <= 0 then
            if BetaTween then BetaTween:Cancel() end
            IsBetaFlying = false
            return
        end
        task.wait() 
        elapsed = elapsed + 0.015
    end
    IsBetaFlying = false
end

-- --- [ LÓGICA PRINCIPAL DEL EVENTO ] ---
local function GetRarity(brainrotName)
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local brainrots = assets and assets:FindFirstChild("Brainrots")
    if brainrots then
        for _, rarityFolder in pairs(brainrots:GetChildren()) do
            if rarityFolder:FindFirstChild(brainrotName) then return rarityFolder.Name end
        end
    end
    return "Unknown"
end

_G.ToggleFireIce = function(state)
    FireIceConfig.Enabled = state
    
    if state then
        task.spawn(function()
            while FireIceConfig.Enabled do
                pcall(function()
                    if workspace:FindFirstChild("FireAndIceMap") then
                        local root = GetRoot()
                        local char = LocalPlayer.Character
                        local hum = char and char:FindFirstChild("Humanoid")
                        local backpack = LocalPlayer:FindFirstChild("Backpack")

                        if root and hum and backpack and char.Humanoid.Health > 0 then
                            
                            -- 1. Contar objetos en la mano ("RenderedBrainrot")
                            local objetosEnMano = 0
                            for _, v in pairs(char:GetChildren()) do
                                if v.Name == "RenderedBrainrot" then objetosEnMano = objetosEnMano + 1 end
                            end

                            -- 2. Filtrar Secretos/Celestiales
                            local valiosos = {}
                            for _, tool in pairs(backpack:GetChildren()) do
                                if tool:IsA("Tool") then
                                    local bName = tool:GetAttribute("BrainrotName")
                                    if bName then
                                        local rar = GetRarity(bName)
                                        if rar == "Secret" or rar == "Celestial" then
                                            table.insert(valiosos, tool)
                                        end
                                    end
                                end
                            end

                            -- 3. ¿INVENTARIO LLENO? -> Sacrificar
                            if objetosEnMano >= FireIceConfig.MaxItems and #valiosos > 0 then
                                BetaFlyTo(CFrame.new(317.3, 3.1, 0.2))
                                task.wait(0.5) 
                                
                                local prompt = workspace.FireAndIceMap:FindFirstChild("FireAndIceSacraficeMachine") 
                                    and workspace.FireAndIceMap.FireAndIceSacraficeMachine:FindFirstChild("Primary") 
                                    and workspace.FireAndIceMap.FireAndIceSacraficeMachine.Primary:FindFirstChild("Prompt") 
                                    and workspace.FireAndIceMap.FireAndIceSacraficeMachine.Primary.Prompt:FindFirstChild("ProximityPrompt")
                                
                                if prompt then
                                    for _, tool in ipairs(valiosos) do
                                        if not FireIceConfig.Enabled then break end
                                        hum:EquipTool(tool)
                                        task.wait(0.2)
                                        
                                        -- Activar el prompt
                                        fireproximityprompt(prompt, 1, true)
                                        task.wait(0.2) -- Esperar a que la UI aparezca
                                        
                                        -- Hacer clic automático en el botón que salga
                                        ClickVisibleButtons()
                                        task.wait(0.1)
                                    end
                                end
                            else
                                -- 4. RECOLECTAR DEL MAPA (Respetando el Equipo)
                                for _, obj in pairs(workspace:GetDescendants()) do
                                    if not FireIceConfig.Enabled then break end
                                    
                                    if obj:IsA("Tool") and obj.Parent and not obj.Parent:FindFirstChild("Humanoid") then
                                        local bName = obj:GetAttribute("BrainrotName")
                                        if bName then
                                            local rar = GetRarity(bName)
                                            if rar == "Secret" or rar == "Celestial" then
                                                local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
                                                
                                                -- Verificamos si está dentro del área de nuestro equipo
                                                if handle and IsValidForTeam(handle.Position) then
                                                    BetaFlyTo(handle.CFrame)
                                                    if firetouchinterest then
                                                        firetouchinterest(root, handle, 0)
                                                        task.wait(0.05)
                                                        firetouchinterest(root, handle, 1)
                                                    end
                                                    break -- Rompemos para actualizar conteo
                                                end
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
        
        RunService:BindToRenderStep("FireIceGhost", 1, function()
            if FireIceConfig.Enabled and LocalPlayer.Character then
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
-- 🎨 INTERFAZ GRÁFICA
-- =================================================================
if _G.AutoFarmBTab then
    _G.AutoFarmBTab:Section({ Title = "--[ EVENTO: FIRE & ICE ]--", Icon = "flame" })
    _G.AutoFarmBTab:Toggle({ 
        Title = "❄️🔥 Auto Sacrificio (Secrets & Celestials)", 
        Callback = function(state) 
            _G.ToggleFireIce(state) 
        end 
    })
end
