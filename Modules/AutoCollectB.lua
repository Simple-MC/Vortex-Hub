-- =================================================================
-- 🚀 MODULE: AUTO-COLLECT (BETA) - BODYVELOCITY + TSUNAMI MATH
-- =================================================================

local AutoFarmBTab = _G.AutoFarmBTab
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- --- [ CONFIGURACIÓN DE PUNTOS ] ---
local PuntoA = CFrame.new(4345, 3, -140)
local PuntoB = CFrame.new(145, 3, -140)

local RielSeguroZ = -140
local RielMinX = 145
local RielMaxX = 4345
local AlturaSegura = 3

local BetaConfig = {
    Enabled = false,
    RespawnOnStart = false,
    Speed = 800,
    ActiveFolders = {}, 
    Targets = { LuckyBlocks = false, Brainrots = false, SecretBrainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

local BetaTween = nil
local IsBetaFlying = false
local IsDoingSequence = false
local Processed = {}

local EventParts = {
    "ArcadeEventTickets", "ArcadeEventConsoles", "MoneyEventParts",
    "UFOEventParts", "CandyEventParts", "ValentinesCoinParts"
}

-- --- [ FUNCIONES VITALES ] ---
local function GetRoot() 
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
end

local function GetNames(folder)
    local n = {}
    local f = ReplicatedStorage.Assets:FindFirstChild(folder)
    if f then for _,v in pairs(f:GetChildren()) do table.insert(n, v.Name) end end
    table.sort(n)
    return n
end

local function ContarCargaActual()
    local char = LocalPlayer.Character
    local count = 0
    if char then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Model") and (v.Name:find("Lucky") or v.Name:find("Brainrot") or v.Name:find("NaturalSpawn") or v.Name:find("Secret")) then
                count = count + 1
            end
        end
    end
    return count
end

-- --- [ MOTOR ANTI-GRAVEDAD (REEMPLAZA AL ANCHORED) ] ---
local function EnsureAntiGravity()
    local root = GetRoot()
    if root then
        local bg = root:FindFirstChild("BetaAntiGravity")
        if not bg then
            bg = Instance.new("BodyVelocity")
            bg.Name = "BetaAntiGravity"
            bg.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bg.Velocity = Vector3.zero -- Nos mantiene flotando sin caer
            bg.Parent = root
        end
    end
end

local function RemoveAntiGravity()
    local root = GetRoot()
    if root then
        local bg = root:FindFirstChild("BetaAntiGravity")
        if bg then bg:Destroy() end
    end
end

-- --- [ VUELO TÁCTICO ] ---
local function BetaFlyTo(TargetCFrame)
    local root = GetRoot()
    if not root then return end

    EnsureAntiGravity() -- Activar flotación

    local Dist = (root.Position - TargetCFrame.Position).Magnitude
    local Time = Dist / BetaConfig.Speed
    if Time < 0.05 then Time = 0.05 end

    if BetaTween then BetaTween:Cancel() end
    IsBetaFlying = true
    
    BetaTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(TargetCFrame.Position)})
    BetaTween:Play()
    
    local elapsed = 0
    while IsBetaFlying and elapsed < Time do
        if not BetaConfig.Enabled or not GetRoot() or LocalPlayer.Character.Humanoid.Health <= 0 then
            BetaTween:Cancel()
            IsBetaFlying = false
            return
        end
        task.wait(0.05)
        elapsed = elapsed + 0.05
    end
    
    IsBetaFlying = false
end

-- --- [ MATEMÁTICAS: CALCULAR TIEMPO DE TSUNAMI ] ---
local function EsSeguroEntrar(TargetX, TargetZ)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return true end

    local root = GetRoot()
    if not root then return false end

    -- 1. Calcular el tiempo que YO necesito
    local DistanciaAItem = math.abs(root.Position.Z - TargetZ)
    local TiempoVueloIda = DistanciaAItem / BetaConfig.Speed
    local TiempoRecolectar = 2.0 -- 2 segundos recolectando
    local MargenError = 0.5
    local TiempoTotalNecesario = (TiempoVueloIda * 2) + TiempoRecolectar + MargenError

    -- 2. Calcular cuánto tarda la ola en llegar
    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p then
            local velX = p.AssemblyLinearVelocity.X
            local waveSpeed = math.abs(velX)
            
            -- Si la ola se mueve con Tweens y no físicas, usamos una velocidad promedio rápida de precaución
            if waveSpeed < 10 then waveSpeed = 150 end 
            
            local DistanciaOlaAItem = math.abs(p.Position.X - TargetX)
            local TiempoOla = DistanciaOlaAItem / waveSpeed

            -- Verificamos si la ola se está acercando al item o alejándose
            local seAcerca = false
            if velX > 0 and TargetX > p.Position.X then seAcerca = true end
            if velX < 0 and TargetX < p.Position.X then seAcerca = true end
            if waveSpeed == 150 and DistanciaOlaAItem < 800 then seAcerca = true end -- Caso de emergencia

            -- Si se acerca y llegará antes de que terminemos nuestro trabajo: PELIGRO
            if seAcerca and TiempoOla < TiempoTotalNecesario then
                return false 
            end
        end
    end
    
    return true -- Si pasa todas las pruebas, vía libre
end

-- --- [ ESCÁNER ] ---
local function GetBetaTarget()
    local c, sd = nil, math.huge
    local root = GetRoot()
    if not root then return nil end
    local List = {}

    for _, folderName in ipairs(EventParts) do
        if BetaConfig.ActiveFolders[folderName] then
            local f = workspace:FindFirstChild(folderName)
            if f then for _,v in pairs(f:GetChildren()) do table.insert(List, v) end end
        end
    end

    if BetaConfig.Targets.LuckyBlocks then
        local f = workspace:FindFirstChild("ActiveLuckyBlocks")
        if f then 
            for _,obj in pairs(f:GetDescendants()) do 
                if obj:IsA("Model") and not Processed[obj] then
                    if obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                        for _,s in pairs(BetaConfig.Sel.Lucky) do if obj.Name:find(s) then table.insert(List,obj) break end end
                    end
                end
            end 
        end
    end

    if BetaConfig.Targets.Brainrots then
        local f = workspace:FindFirstChild("ActiveBrainrots")
        if f then 
            for _,rarityFolder in pairs(f:GetChildren()) do
                if table.find(BetaConfig.Sel.Brain, rarityFolder.Name) then
                    for _,obj in pairs(rarityFolder:GetDescendants()) do
                        if obj:IsA("Model") and not Processed[obj] then
                            if obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                                table.insert(List, obj)
                            end
                        end
                    end
                end
            end 
        end
    end

    -- Escanear Secret Brainrots en el Workspace entero
    if BetaConfig.Targets.SecretBrainrots then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find("secretbrainrot") and not Processed[obj] then
                if obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                    table.insert(List, obj)
                end
            end
        end
    end

    for _,v in pairs(List) do
        local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
        local partToCheck = prompt and prompt.Parent or v:FindFirstChild("Root") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true)
        if partToCheck then 
            local d = (root.Position - partToCheck.Position).Magnitude
            if d < sd then sd = d; c = v end 
        end
    end
    return c
end

-- =================================================================
-- 🎨 INTERFAZ GRÁFICA Y BUCLE PRINCIPAL
-- =================================================================
AutoFarmBTab:Section({ Title = "--[ L-SHAPE HIT & RUN MATEMÁTICO ]--", Icon = "skull" })

AutoFarmBTab:Toggle({
    Title = "💀 Renacer al Encender (Llegar rápido)",
    Callback = function(state)
        BetaConfig.RespawnOnStart = state
    end
})

AutoFarmBTab:Toggle({
    Title = "⚡ Activar Auto-Collect (Anti-Tsunami)",
    Callback = function(state)
        BetaConfig.Enabled = state
        
        if state then
            Processed = {} 
            IsDoingSequence = false
            
            if BetaConfig.RespawnOnStart then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.Health = 0 
                    LocalPlayer.CharacterAdded:Wait() 
                    task.wait(1.5) 
                end
            end
            
            if not BetaConfig.Enabled then return end

            if _G.GodModeEnabled == false and _G.ActivarGodModeTotal then
                _G.ActivarGodModeTotal(true)
            end
            
            task.spawn(function()
                while BetaConfig.Enabled do
                    pcall(function()
                        if not IsDoingSequence then
                            local root = GetRoot()
                            if not root or LocalPlayer.Character.Humanoid.Health <= 0 then return end

                            if ContarCargaActual() >= 3 then
                                IsDoingSequence = true
                                BetaFlyTo(PuntoB) 
                                task.wait(1.5) 
                                Processed = {} 
                                IsDoingSequence = false
                                return 
                            end

                            local Target = GetBetaTarget()

                            if Target then
                                local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                                local MovePart = Prompt and Prompt.Parent or Target:FindFirstChild("Root") or Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart", true)

                                if MovePart then
                                    IsDoingSequence = true 
                                    
                                    task.spawn(function()
                                        local TargetX = math.clamp(MovePart.Position.X, RielMinX, RielMaxX)
                                        local TargetZ = MovePart.Position.Z
                                        
                                        local PuntoDeAtaque = CFrame.new(TargetX, AlturaSegura, RielSeguroZ)

                                        -- 1. Si no estamos en el riel seguro, ir al riel primero (Evita diagonales locas)
                                        if math.abs(root.Position.Z - RielSeguroZ) > 10 then
                                            BetaFlyTo(CFrame.new(root.Position.X, AlturaSegura, RielSeguroZ))
                                        end

                                        -- 2. Movernos por el riel seguro hasta la X del item
                                        BetaFlyTo(PuntoDeAtaque)

                                        -- 3. ESPERA MATEMÁTICA: Revisar si la ola nos golpearía a medio camino
                                        while BetaConfig.Enabled and not EsSeguroEntrar(TargetX, TargetZ) do
                                            task.wait(0.1) 
                                        end

                                        -- 4. ATAQUE: Entrar al mapa
                                        if BetaConfig.Enabled then
                                            BetaFlyTo(MovePart.CFrame)
                                            
                                            -- 5. RECOLECTAR: 2 segundos fijos mandando la señal
                                            local tiempoSpam = 0
                                            while BetaConfig.Enabled and tiempoSpam < 2.0 do
                                                if Prompt then
                                                    Prompt.RequiresLineOfSight = false
                                                    Prompt.HoldDuration = 0
                                                    fireproximityprompt(Prompt)
                                                end
                                                task.wait(0.1)
                                                tiempoSpam = tiempoSpam + 0.1
                                            end
                                            
                                            Processed[Target] = true
                                            
                                            -- 6. SALIDA RÁPIDA: Regresar directo al riel
                                            BetaFlyTo(PuntoDeAtaque)
                                        end
                                        
                                        IsDoingSequence = false
                                    end)
                                end
                            else
                                if (root.Position - PuntoB.Position).Magnitude > 50 then
                                    BetaFlyTo(PuntoB)
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
            
            -- Ghost mode
            RunService:BindToRenderStep("BetaFlyStabilizer", 1, function()
                if BetaConfig.Enabled and LocalPlayer.Character then
                    for _,p in pairs(LocalPlayer.Character:GetDescendants()) do 
                        if p:IsA("BasePart") then p.CanCollide = false end 
                    end
                end
            end)
            
        else
            if BetaTween then BetaTween:Cancel() end
            IsBetaFlying = false
            IsDoingSequence = false
            RunService:UnbindFromRenderStep("BetaFlyStabilizer")
            RemoveAntiGravity() -- Restauramos la gravedad al apagar
            
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

-- --- [ SELECCIÓN DE ITEMS ] ---
AutoFarmBTab:Section({ Title = "--[ EVENTOS LIGEROS (Al toque) ]--" })
AutoFarmBTab:Toggle({ Title = "Tickets 🎫", Callback = function(s) BetaConfig.ActiveFolders["ArcadeEventTickets"] = s end })
AutoFarmBTab:Toggle({ Title = "Consoles 🎮", Callback = function(s) BetaConfig.ActiveFolders["ArcadeEventConsoles"] = s end })
AutoFarmBTab:Toggle({ Title = "Gold Money 🪙", Callback = function(s) BetaConfig.ActiveFolders["MoneyEventParts"] = s end })
AutoFarmBTab:Toggle({ Title = "UFO Money 👽", Callback = function(s) BetaConfig.ActiveFolders["UFOEventParts"] = s end })
AutoFarmBTab:Toggle({ Title = "CANDYS 🍭", Callback = function(s) BetaConfig.ActiveFolders["CandyEventParts"] = s end })
AutoFarmBTab:Toggle({ Title = "COINS 🍬", Callback = function(s) BetaConfig.ActiveFolders["ValentinesCoinParts"] = s end })

AutoFarmBTab:Section({ Title = "--[ OBJETOS PESADOS (Límite 3) ]--" })
AutoFarmBTab:Toggle({ Title = "Lucky Blocks", Callback = function(s) BetaConfig.Targets.LuckyBlocks = s end })
AutoFarmBTab:Dropdown({ Title = "Lucky Filter", Multi = true, Values = GetNames("LuckyBlocks"), Callback = function(v) BetaConfig.Sel.Lucky = v end })
AutoFarmBTab:Toggle({ Title = "Brainrots", Callback = function(s) BetaConfig.Targets.Brainrots = s end })
AutoFarmBTab:Dropdown({ Title = "Brainrot Filter", Multi = true, Values = GetNames("Brainrots"), Callback = function(v) BetaConfig.Sel.Brain = v end })
AutoFarmBTab:Toggle({ Title = "⭐ Secret Brainrots (Buscar todos)", Callback = function(s) BetaConfig.Targets.SecretBrainrots = s end })
