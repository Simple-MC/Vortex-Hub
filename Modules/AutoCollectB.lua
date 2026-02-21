-- =================================================================
-- 🚀 MODULE: AUTO-COLLECT (BETA) - TRUE L-SHAPE + 2 SEC SPAM + RESPAWN OPTION
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
    RespawnOnStart = false, -- Nuevo botón de renacer
    Speed = 800,
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

-- --- [ VUELO TÁCTICO (ANTI-CAÍDAS) ] ---
local function BetaFlyTo(TargetCFrame)
    local root = GetRoot()
    if not root then return end

    root.Anchored = true 

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

-- --- [ DETECTOR TSUNAMIS (EN EJE X) ] ---
local function OlaEnCamino(TargetX)
    local folder = workspace:FindFirstChild("ActiveTsunamis")
    if not folder then return false end
    local MargenPeligro = 70 

    for _, wave in pairs(folder:GetChildren()) do
        local p = wave:IsA("BasePart") and wave or wave:FindFirstChildWhichIsA("BasePart", true)
        if p and math.abs(p.Position.X - TargetX) < MargenPeligro then
            return true
        end
    end
    return false
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
    Title = "💀 Renacer al Encender (Llegar más rápido)",
    Callback = function(state)
        BetaConfig.RespawnOnStart = state
    end
})

AutoFarmBTab:Toggle({
    Title = "⚡ Activar Hit & Run Perfecto",
    Callback = function(state)
        BetaConfig.Enabled = state
        
        if state then
            Processed = {} 
            IsDoingSequence = false
            
            -- 🔥 NUEVA LÓGICA DE REINICIO
            if BetaConfig.RespawnOnStart then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.Health = 0 
                    LocalPlayer.CharacterAdded:Wait() 
                    task.wait(1.5) -- Tiempo de gracia para cargar el mapa
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
                                        local MiXActual = root.Position.X
                                        local TargetX = math.clamp(MovePart.Position.X, RielMinX, RielMaxX)
                                        
                                        local PuntoEntradaRiel = CFrame.new(MiXActual, AlturaSegura, RielSeguroZ)
                                        local PuntoDeAtaque = CFrame.new(TargetX, AlturaSegura, RielSeguroZ)

                                        -- 1. VERDADERA FORMA DE L: Si estamos lejos del riel, primero retroceder al riel
                                        if math.abs(root.Position.Z - RielSeguroZ) > 10 then
                                            BetaFlyTo(PuntoEntradaRiel)
                                        end

                                        -- 2. Ahora que estamos en el riel seguro, nos alineamos en X
                                        BetaFlyTo(PuntoDeAtaque)

                                        -- 3. ESPERA TÁCTICA
                                        while BetaConfig.Enabled and OlaEnCamino(TargetX) do
                                            task.wait(0.1) 
                                        end

                                        -- 4. ATAQUE RECTO
                                        if BetaConfig.Enabled then
                                            BetaFlyTo(MovePart.CFrame)
                                            
                                            -- 5. RECOLECCIÓN (2 Segundos Exactos de Spam)
                                            local tiempoSpam = 0
                                            while BetaConfig.Enabled and tiempoSpam < 2 do
                                                if Prompt then
                                                    Prompt.RequiresLineOfSight = false
                                                    Prompt.HoldDuration = 0
                                                    fireproximityprompt(Prompt)
                                                end
                                                task.wait(0.1)
                                                tiempoSpam = tiempoSpam + 0.1
                                            end
                                            
                                            Processed[Target] = true
                                            
                                            -- 6. ESCAPE AL HILO EN LÍNEA RECTA
                                            BetaFlyTo(PuntoDeAtaque)
                                        end
                                        
                                        IsDoingSequence = false
                                    end)
                                end
                            else
                                -- PATRULLAJE
                                if (root.Position - PuntoB.Position).Magnitude > 50 then
                                    BetaFlyTo(PuntoB)
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
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
            if BetaTween then BetaTween:Cancel() end
            IsBetaFlying = false
            IsDoingSequence = false
            RunService:UnbindFromRenderStep("BetaFlyStabilizer")
            
            local root = GetRoot()
            if root then root.Anchored = false end 
            
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
