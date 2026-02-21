-- =================================================================
-- 🚀 MODULE: AUTO-COLLECT (BETA) - ULTRA FAST + PERFECT MATH
-- =================================================================

local AutoFarmBTab = _G.AutoFarmBTab
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- --- [ CONFIGURACIÓN DE PUNTOS ] ---
local PuntoA = CFrame.new(4345, 3, -140)
local PuntoB = CFrame.new(145, 3, -140) -- SOLO PARA DESCARGAR 3 ITEMS

local RielSeguroZ = -140
local RielMinX = 145
local RielMaxX = 4345
local AlturaSegura = 3

local BetaConfig = {
    Enabled = false,
    RespawnOnStart = false,
    Speed = 2500, -- 🚀 MÁXIMA VELOCIDAD POSIBLE
    ActiveFolders = {}, 
    Targets = { LuckyBlocks = false, Brainrots = false },
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
            if v:IsA("Model") and (v.Name:find("Lucky") or v.Name:find("Brainrot") or v.Name:find("NaturalSpawn")) then
                count = count + 1
            end
        end
    end
    return count
end

-- --- [ MOTOR ANTI-GRAVEDAD A PRUEBA DE FALLOS ] ---
local function EnsureAntiGravity()
    local root = GetRoot()
    if root then
        if not root:FindFirstChild("BetaAntiGravity") then
            local bg = Instance.new("BodyVelocity")
            bg.Name = "BetaAntiGravity"
            bg.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bg.Velocity = Vector3.zero
            bg.Parent = root
        end
    end
end

local function RemoveAntiGravity()
    local char = LocalPlayer.Character
    if char then
        -- Búsqueda forzada en todo el personaje para que no se quede pegado
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BodyVelocity") and v.Name == "BetaAntiGravity" then
                v:Destroy()
            end
        end
    end
end

-- --- [ VUELO TÁCTICO EXTREMO ] ---
local function BetaFlyTo(TargetCFrame)
    local root = GetRoot()
    if not root then return end

    EnsureAntiGravity()

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
        task.wait() -- Usamos el tiempo mínimo absoluto de Roblox
        elapsed = elapsed + 0.015
    end
    
    IsBetaFlying = false
end

-- --- [ MATEMÁTICAS EXACTAS DEL TSUNAMI ] ---
local function EsSeguroMatematico(TargetX, TargetZ)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return true end

    local root = GetRoot()
    if not root then return false end

    -- 1. Nuestro Tiempo (Vuelo rapidísimo + 0.1s de recoger)
    local DistanciaViajeSoloIda = math.abs(root.Position.Z - TargetZ)
    local DistanciaTotalViaje = DistanciaViajeSoloIda * 2
    local TiempoVuelo = DistanciaTotalViaje / BetaConfig.Speed
    local TiempoRecoger = 0.1 -- ⚡ Reacción casi instantánea
    local NuestroTiempoTotal = TiempoVuelo + TiempoRecoger

    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p then
            local VelX = p.AssemblyLinearVelocity.X
            local SpeedOla = math.abs(VelX)
            
            if SpeedOla < 10 then SpeedOla = 250 end 
            
            local PosOlaX = p.Position.X
            local DistanciaOlaAlItem = math.abs(PosOlaX - TargetX)

            if DistanciaOlaAlItem < 90 then return false end

            local seAcerca = false
            if VelX > 0 and PosOlaX < TargetX then seAcerca = true end
            if VelX < 0 and PosOlaX > TargetX then seAcerca = true end
            if SpeedOla == 250 and DistanciaOlaAlItem < 1200 then seAcerca = true end 

            if seAcerca then
                local TiempoOlaLlega = DistanciaOlaAlItem / SpeedOla
                local Diferencia = TiempoOlaLlega - NuestroTiempoTotal
                
                -- Si la ola llega en el mismo tiempo que nosotros o menos, ES PELIGROSO
                if Diferencia < 0.5 then
                    return false
                end
            end
        end
    end
    
    return true
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
AutoFarmBTab:Section({ Title = "--[ L-SHAPE HIT & RUN ]--", Icon = "skull" })

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

                            -- SOLO VA A PUNTO B SI TIENE CARGA PESADA (LUCKY/BRAINROTS)
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
                                        local MiXActual = root.Position.X
                                        local TargetX = math.clamp(MovePart.Position.X, RielMinX, RielMaxX)
                                        local TargetZ = MovePart.Position.Z
                                        
                                        local PuntoEntradaRiel = CFrame.new(MiXActual, AlturaSegura, RielSeguroZ)
                                        local PuntoDeAtaque = CFrame.new(TargetX, AlturaSegura, RielSeguroZ)

                                        if math.abs(root.Position.Z - RielSeguroZ) > 10 then
                                            BetaFlyTo(PuntoEntradaRiel)
                                        end

                                        BetaFlyTo(PuntoDeAtaque)

                                        -- REACCIÓN INSTANTÁNEA: Revisa ola sin pausas lentas
                                        while BetaConfig.Enabled and not EsSeguroMatematico(TargetX, TargetZ) do
                                            task.wait() 
                                        end

                                        if BetaConfig.Enabled then
                                            BetaFlyTo(MovePart.CFrame)
                                            
                                            -- RECOLECCIÓN BRUTAL (Sin Esperas Largas)
                                            if Prompt then
                                                Prompt.RequiresLineOfSight = false
                                                Prompt.HoldDuration = 0
                                                -- Lo activamos 15 veces en el mismo instante
                                                for i = 1, 15 do 
                                                    fireproximityprompt(Prompt) 
                                                end
                                                task.wait(0.1) -- Pequeño delay para que el server lo procese
                                            end
                                            
                                            Processed[Target] = true
                                            
                                            -- REGRESO INMEDIATO AL RIEL
                                            BetaFlyTo(PuntoDeAtaque)
                                        end
                                        
                                        IsDoingSequence = false
                                    end)
                                end
                            else
                                -- SI NO HAY TARGETS Y NO TIENES LA ESPALDA LLENA: Quedate en el riel donde estás
                                local PosicionDescanso = CFrame.new(root.Position.X, AlturaSegura, RielSeguroZ)
                                if math.abs(root.Position.Z - RielSeguroZ) > 5 then
                                    BetaFlyTo(PosicionDescanso)
                                end
                            end
                        end
                    end)
                    task.wait() -- Ciclo ultra rápido
                end
            end)
            
            RunService:BindToRenderStep("BetaFlyStabilizer", 1, function()
                if BetaConfig.Enabled and LocalPlayer.Character then
                    for _,p in pairs(LocalPlayer.Character:GetDescendants()) do 
                        if p:IsA("BasePart") then p.CanCollide = false end 
                    end
                end
            end)
            
        else
            -- ❌ DESTRUCCIÓN DE TODOS LOS MOTORES Y APAGADO SEGURO
            if BetaTween then BetaTween:Cancel() end
            IsBetaFlying = false
            IsDoingSequence = false
            RunService:UnbindFromRenderStep("BetaFlyStabilizer")
            
            RemoveAntiGravity() -- Quita cualquier BodyVelocity residual
            
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
