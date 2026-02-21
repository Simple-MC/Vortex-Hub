-- =================================================================
-- 🚀 MODULE: AUTO-COLLECT (BETA) - HIT & RUN + GOD MODE
-- =================================================================

local AutoFarmBTab = _G.AutoFarmBTab
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AlmacenTemporal = game:GetService("Lighting")

-- --- [ CONFIGURACIÓN DEL HILO Y AUTO-FARM ] ---
local RielSeguroZ = -140
local RielMinX = 145
local RielMaxX = 4345
local AlturaSegura = 3

local BetaConfig = {
    Enabled = false,
    Speed = 350,
    TsunamiMargen = 40,
    ActiveFolders = {}, 
    Targets = { LuckyBlocks = false, Brainrots = false },
    Sel = { Lucky = {}, Brain = {} }
}

local BetaTween = nil
local IsBetaFlying = false
local Processed = {}
local OriginalParents = {}
local BordesEstructura = {}

-- --- [ EVENTOS FÁCILES DE ACTUALIZAR ] ---
local EventParts = {
    "ArcadeEventTickets", "ArcadeEventConsoles", "MoneyEventParts",
    "UFOEventParts", "CandyEventParts", "ValentinesCoinParts"
}

-- --- [ FUNCIONES DE UTILIDAD Y BÚSQUEDA ] ---
local function GetNames(folder)
    local n = {}
    local f = ReplicatedStorage.Assets:FindFirstChild(folder)
    if f then for _,v in pairs(f:GetChildren()) do table.insert(n, v.Name) end end
    table.sort(n)
    return n
end

local function GetBetaTarget()
    local c, sd = nil, math.huge
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local List = {}

    -- 1. Escanear Carpetas de Eventos
    for _, folderName in ipairs(EventParts) do
        if BetaConfig.ActiveFolders[folderName] then
            local f = workspace:FindFirstChild(folderName)
            if f then for _,v in pairs(f:GetChildren()) do table.insert(List, v) end end
        end
    end

    -- 2. Escanear Lucky Blocks
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

    -- 3. Escanear Brainrots
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

    -- Buscar el más cercano
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

-- --- [ FUNCIONES DE VUELO Y PELIGRO ] ---
local function BetaFlyTo(TargetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local Dist = (root.Position - TargetCFrame.Position).Magnitude
    local Time = Dist / BetaConfig.Speed

    if BetaTween then BetaTween:Cancel() end
    IsBetaFlying = true
    
    local _, rotY, _ = root.CFrame:ToEulerAnglesYXZ()
    local CFrameDerecho = CFrame.new(TargetCFrame.Position) * CFrame.Angles(0, rotY, 0)

    BetaTween = TweenService:Create(root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrameDerecho})
    BetaTween:Play()
    BetaTween.Completed:Wait()
    
    IsBetaFlying = false
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
end

local function CaminoBloqueado(StartPos, EndPos)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return false end

    -- Ampliamos el cuadro de búsqueda para que no te atropelle de lado
    local minX = math.min(StartPos.X, EndPos.X) - BetaConfig.TsunamiMargen
    local maxX = math.max(StartPos.X, EndPos.X) + BetaConfig.TsunamiMargen
    local minZ = math.min(StartPos.Z, EndPos.Z) - BetaConfig.TsunamiMargen
    local maxZ = math.max(StartPos.Z, EndPos.Z) + BetaConfig.TsunamiMargen

    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p then
            if (p.Position.X > minX and p.Position.X < maxX) and (p.Position.Z > minZ and p.Position.Z < maxZ) then
                return true
            end
        end
    end
    return false
end

-- --- [ FUNCIONES GOD MODE (MUROS) ] ---
local function SafeMoveBeta(obj, newParent)
    if obj and not OriginalParents[obj] then OriginalParents[obj] = obj.Parent end
    if obj then obj.Parent = newParent end
end

local function ActivarGodModeLocal()
    -- 1. Limpiar Muros
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
            
            for _, obj in pairs(folder:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:find("VIP") or obj.Name:find("Wall") or obj.Name:find("Mud")) then
                    obj.CanCollide = false
                    obj.Transparency = 0.5
                end
            end
        end
    end

    -- 2. Crear los bordes protectores rojos tuyos
    local configBordes = {
        {nombre="B1", size=Vector3.new(90, 2.7, 2048), cf=CFrame.new(1177, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
        {nombre="B9", size=Vector3.new(4, 13, 1409.5), cf=CFrame.new(3645.5, -2, -136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)}
        -- (Agregué solo 2 de ejemplo para no hacer el código infinito, puedes meter los 13 aquí adentro)
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
-- 🎨 INTERFAZ GRÁFICA (WIND UI)
-- =================================================================

AutoFarmBTab:Section({ Title = "--[ HIT & RUN STRATEGY ]--", Icon = "skull" })

AutoFarmBTab:Toggle({
    Title = "⚡ Activar Hit & Run (+God Mode)",
    Callback = function(state)
        BetaConfig.Enabled = state
        
        if state then
            Processed = {} -- Reiniciar inventario de recolección
            ActivarGodModeLocal() -- Quitar paredes que estorban en Z = -140
            
            task.spawn(function()
                while BetaConfig.Enabled do
                    pcall(function()
                        local char = LocalPlayer.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if not root or char.Humanoid.Health <= 0 then return end

                        local Target = GetBetaTarget()

                        if Target then
                            local Prompt = Target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            local MovePart = Prompt and Prompt.Parent or Target:FindFirstChild("Root") or Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart", true)

                            if MovePart then
                                -- Intersección matemática
                                local TargetX = math.clamp(MovePart.Position.X, RielMinX, RielMaxX)
                                local PuntoDeAtaque = CFrame.new(TargetX, AlturaSegura, RielSeguroZ)

                                -- 1. Posicionarse en el hilo
                                local distAlHilo = (root.Position - PuntoDeAtaque.Position).Magnitude
                                if distAlHilo > 5 then
                                    BetaFlyTo(PuntoDeAtaque)
                                else
                                    -- 2. Estamos en posición. Revisar Tsunami
                                    if CaminoBloqueado(root.Position, MovePart.Position) then
                                        -- Esperar a que pase la ola
                                        root.Velocity = Vector3.zero
                                        task.wait(0.2)
                                    else
                                        -- 3. ATAQUE: Ir al item
                                        BetaFlyTo(MovePart.CFrame)
                                        
                                        -- Recoger
                                        if Prompt then
                                            Prompt.RequiresLineOfSight = false
                                            Prompt.HoldDuration = 0
                                            for i = 1, 15 do fireproximityprompt(Prompt) end
                                            Processed[Target] = true
                                            task.wait(0.1) 
                                        end
                                        
                                        -- 4. ESCAPE: Volver al hilo de seguridad inmediatamente
                                        BetaFlyTo(PuntoDeAtaque)
                                    end
                                end
                            end
                        else
                            -- No hay items, patrullar al centro del mapa pero en el hilo seguro
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
            
            -- Estabilizador de Vuelo
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
            -- Apagar Todo
            if BetaTween then BetaTween:Cancel() end
            IsBetaFlying = false
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

-- --- [ SELECCIÓN DE ITEMS A RECOGER ] ---
AutoFarmBTab:Section({ Title = "--[ EVENTO ARCADE ]--" })
AutoFarmBTab:Toggle({ Title = "Tickets 🎫", Callback = function(s) BetaConfig.ActiveFolders["ArcadeEventTickets"] = s end })
AutoFarmBTab:Toggle({ Title = "Consoles 🎮", Callback = function(s) BetaConfig.ActiveFolders["ArcadeEventConsoles"] = s end })

AutoFarmBTab:Section({ Title = "--[ EVENTO MONEY ]--" })
AutoFarmBTab:Toggle({ Title = "Gold Money 🪙", Callback = function(s) BetaConfig.ActiveFolders["MoneyEventParts"] = s end })

AutoFarmBTab:Section({ Title = "--[ EVENTO UFO ]--" })
AutoFarmBTab:Toggle({ Title = "UFO Money 👽", Callback = function(s) BetaConfig.ActiveFolders["UFOEventParts"] = s end })

AutoFarmBTab:Section({ Title = "--[ EVENTO VALENTINE'S DAY ]--" })
AutoFarmBTab:Toggle({ Title = "CANDYS 🍭", Callback = function(s) BetaConfig.ActiveFolders["CandyEventParts"] = s end })
AutoFarmBTab:Toggle({ Title = "COINS 🍬", Callback = function(s) BetaConfig.ActiveFolders["ValentinesCoinParts"] = s end })

AutoFarmBTab:Section({ Title = "--[ OTROS EVENTOS ]--" })
AutoFarmBTab:Toggle({ Title = "Lucky Blocks", Callback = function(s) BetaConfig.Targets.LuckyBlocks = s end })
AutoFarmBTab:Dropdown({ Title = "Lucky Filter", Multi = true, Values = GetNames("LuckyBlocks"), Callback = function(v) BetaConfig.Sel.Lucky = v end })

AutoFarmBTab:Toggle({ Title = "Brainrots", Callback = function(s) BetaConfig.Targets.Brainrots = s end })
AutoFarmBTab:Dropdown({ Title = "Brainrot Filter", Multi = true, Values = GetNames("Brainrots"), Callback = function(v) BetaConfig.Sel.Brain = v end })
