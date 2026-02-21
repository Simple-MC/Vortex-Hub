-- =================================================================
-- 🚀 MODULE: AUTO-COLLECT (BETA) - HIT & RUN ESTRICTO (L-SHAPE)
-- =================================================================

local AutoFarmBTab = _G.AutoFarmBTab
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AlmacenTemporal = game:GetService("Lighting")

-- --- [ CONFIGURACIÓN DEL HILO ] ---
local RielSeguroZ = -140
local RielMinX = 145
local RielMaxX = 4345
local AlturaSegura = 3

local BetaConfig = {
    Enabled = false,
    Speed = 400, -- Aumenté un poco la velocidad para el escape rápido
    ActiveFolders = {}, 
    Targets = { LuckyBlocks = false, Brainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

local BetaTween = nil
local IsBetaFlying = false
local IsDoingSequence = false -- ESTO ES VITAL: Evita que corte camino en diagonal
local Processed = {}
local OriginalParents = {}
local BordesEstructura = {}

local EventParts = {
    "ArcadeEventTickets", "ArcadeEventConsoles", "MoneyEventParts",
    "UFOEventParts", "CandyEventParts", "ValentinesCoinParts"
}

-- --- [ UTILIDADES ] ---
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

-- --- [ MOTOR DE VUELO ESTRICTO ] ---
local function BetaFlyTo(TargetCFrame)
    local root = GetRoot()
    if not root then return end

    local Dist = (root.Position - TargetCFrame.Position).Magnitude
    local Time = Dist / BetaConfig.Speed
    if Time < 0.05 then Time = 0.05 end -- Tiempo mínimo para no glitchear

    if BetaTween then BetaTween:Cancel() end
    IsBetaFlying = true
    
    BetaTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(TargetCFrame.Position)})
    BetaTween:Play()
    
    -- Espera inteligente (se cancela si te mueres o apagas el hack)
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
    if GetRoot() then
        GetRoot().Velocity = Vector3.zero
        GetRoot().RotVelocity = Vector3.zero
    end
end

-- --- [ DETECTOR DE TSUNAMIS MEJORADO ] ---
local function OlaEnCamino(TargetX)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return false end

    local MargenPeligro = 70 -- Distancia de peligro a los lados de tu pasillo de ataque

    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p then
            -- Si la ola está cruzando por tu coordenada X objetivo, es peligroso entrar
            if math.abs(p.Position.X - TargetX) < MargenPeligro then
                return true
            end
        end
    end
    return false
end

-- --- [ ESCÁNER DE OBJETIVOS ] ---
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

-- --- [ GOD MODE INTEGRADO ] ---
local function SafeMoveBeta(obj, newParent)
    if obj and not OriginalParents[obj] then OriginalParents[obj] = obj.Parent end
    if obj then obj.Parent = newParent end
end

local function ActivarGodModeLocal()
    local vipFolders = {
        "DefaultMap_SharedInstances", "MoneyMap_SharedInstances", 
        "MarsMap_SharedInstances", "RadioactiveMap_SharedInstances", 
        "ArcadeMap_SharedInstances", "ValentinesMap_SharedInstances"
    }
    for _, folderName in pairs(vipFolders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            local vipWalls = folder:FindFirstChild("VIPWalls")
            if vipWalls then SafeMoveBeta(vipWalls, AlmacenTemporal) end
        end
    end

    -- Crea los 13 bordes protectores aquí
    local configBordes = {
        {nombre="B1", size=Vector3.new(90, 2.7, 2048), cf=CFrame.new(1177, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
        {nombre="B9", size=Vector3.new(4, 13, 1409.5), cf=CFrame.new(3645.5, -2, -136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)}
        -- PON EL RESTO DE TUS BORDES AQUÍ
    }
    for _, d in ipairs(configBordes) do
        local p = Instance.new("Part", workspace)
        p.Name = d.nombre; p.Size = d.size; p.CFrame = d.cf; p.Anchored = true; p.CanCollide = true
        p.Color = Color3.fromRGB(255, 60, 60); p.Material = Enum.Material.Neon; p.Transparency = 0.35
        table.insert(BordesEstructura, p)
    end
end

local function DesactivarGodModeLocal()
    for obj, parent in pairs(OriginalParents) do
        pcall(function() if obj then obj.Parent = parent end end)
    end
    OriginalParents = {}
    for _, b in pairs(BordesEstructura) do if b then b:Destroy() end end
    BordesEstructura = {}
end

-- =================================================================
-- 🎨 INTERFAZ GRÁFICA Y BUCLE PRINCIPAL
-- =================================================================

AutoFarmBTab:Section({ Title = "--[ L-SHAPE HIT & RUN ]--", Icon = "skull" })

AutoFarmBTab:Toggle({
    Title = "⚡ Activar Hit & Run Perfecto",
    Callback = function(state)
        BetaConfig.Enabled = state
        
        if state then
            Processed = {} 
            IsDoingSequence = false
            ActivarGodModeLocal() 
            
            task.spawn(function()
                while BetaConfig.Enabled do
                    pcall(function()
                        -- Solo buscar un nuevo target si NO estamos a mitad de un escape
                        if not IsDoingSequence then
                            local root = GetRoot()
                            if not root or LocalPlayer.Character.Humanoid.Health <= 0 then return end

                            local Target = GetBetaTarget()

                            if Target then
                                local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                                local MovePart = Prompt and Prompt.Parent or Target:FindFirstChild("Root") or Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart", true)

                                if MovePart then
                                    IsDoingSequence = true -- Bloqueamos el escáner para no crear líneas diagonales
                                    
                                    task.spawn(function()
                                        local TargetX = math.clamp(MovePart.Position.X, RielMinX, RielMaxX)
                                        local PuntoDeAtaque = CFrame.new(TargetX, AlturaSegura, RielSeguroZ)

                                        -- 1. ALINEACIÓN: Moverse por el hilo seguro (Movimiento SOLO en X)
                                        BetaFlyTo(PuntoDeAtaque)

                                        -- 2. ESPERA: Revisar si pasa una ola justo frente a nosotros
                                        while BetaConfig.Enabled and OlaEnCamino(TargetX) do
                                            if GetRoot() then GetRoot().Velocity = Vector3.zero end
                                            task.wait(0.1) -- Quedarse parado en el riel
                                        end

                                        -- 3. ATAQUE: Ir directo al ítem (Movimiento SOLO en Z)
                                        if BetaConfig.Enabled then
                                            BetaFlyTo(MovePart.CFrame)
                                            
                                            -- SPAM para agarrar
                                            if Prompt then
                                                Prompt.RequiresLineOfSight = false
                                                Prompt.HoldDuration = 0
                                                for i = 1, 15 do fireproximityprompt(Prompt) end
                                                Processed[Target] = true
                                                task.wait(0.15) 
                                            end
                                            
                                            -- 4. RETIRADA: Volver inmediatamente a la misma X del hilo seguro
                                            BetaFlyTo(PuntoDeAtaque)
                                        end
                                        
                                        -- Desbloqueamos el escáner para buscar el siguiente
                                        IsDoingSequence = false
                                    end)
                                end
                            else
                                -- Si no hay nada, quédate parado en el riel para estar a salvo
                                root.Velocity = Vector3.zero
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
            
            -- Estabilizador para volar sin fricción
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
            -- Apagar TODO
            if BetaTween then BetaTween:Cancel() end
            IsBetaFlying = false
            IsDoingSequence = false
            RunService:UnbindFromRenderStep("BetaFlyStabilizer")
            DesactivarGodModeLocal()
            
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
AutoFarmBTab:Section({ Title = "--[ FILTROS ]--" })
AutoFarmBTab:Toggle({ Title = "Tickets 🎫", Callback = function(s) BetaConfig.ActiveFolders["ArcadeEventTickets"] = s end })
AutoFarmBTab:Toggle({ Title = "Consoles 🎮", Callback = function(s) BetaConfig.ActiveFolders["ArcadeEventConsoles"] = s end })
AutoFarmBTab:Toggle({ Title = "Gold Money 🪙", Callback = function(s) BetaConfig.ActiveFolders["MoneyEventParts"] = s end })
AutoFarmBTab:Toggle({ Title = "UFO Money 👽", Callback = function(s) BetaConfig.ActiveFolders["UFOEventParts"] = s end })
AutoFarmBTab:Toggle({ Title = "CANDYS 🍭", Callback = function(s) BetaConfig.ActiveFolders["CandyEventParts"] = s end })
AutoFarmBTab:Toggle({ Title = "COINS 🍬", Callback = function(s) BetaConfig.ActiveFolders["ValentinesCoinParts"] = s end })
AutoFarmBTab:Toggle({ Title = "Lucky Blocks", Callback = function(s) BetaConfig.Targets.LuckyBlocks = s end })
AutoFarmBTab:Dropdown({ Title = "Lucky Filter", Multi = true, Values = GetNames("LuckyBlocks"), Callback = function(v) BetaConfig.Sel.Lucky = v end })
AutoFarmBTab:Toggle({ Title = "Brainrots", Callback = function(s) BetaConfig.Targets.Brainrots = s end })
AutoFarmBTab:Dropdown({ Title = "Brainrot Filter", Multi = true, Values = GetNames("Brainrots"), Callback = function(v) BetaConfig.Sel.Brain = v end })
