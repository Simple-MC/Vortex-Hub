--[[
    MODULE: VORTEX ESP - OPTIMIZED & SAFE EDITION
    FIXES:
    1. Removed WalkSpeed (Anti-Cheat Safe)
    2. Cleaned Dropdown Lists (Only Models, no parts)
    3. Multi-Instance Beams (Shows all targets simultaneously)
]]

local EspTab = _G.EspTab
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- --- [ CONFIGURACIÓN ] ---
local Config = {
    Brainrots = { Enabled = false, Beams = false, Targets = {} },
    LuckyBlocks = { Enabled = false, Beams = false, Targets = {} }
}

-- --- [ FUNCIONES DE UTILIDAD (LISTAS LIMPIAS) ] ---
local function GetAllAssets(folderName)
    local uniqueNames = {}
    local folder = ReplicatedStorage.Assets:FindFirstChild(folderName)
    
    if folder then
        -- Usamos una función recursiva para buscar SOLO Modelos dentro de carpetas
        local function ScanFolder(dir)
            for _, item in pairs(dir:GetChildren()) do
                if item:IsA("Model") then
                    if not table.find(uniqueNames, item.Name) then
                        table.insert(uniqueNames, item.Name)
                    end
                elseif item:IsA("Folder") then
                    -- Si hay carpetas dentro (ej: Rarity), buscamos adentro
                    ScanFolder(item)
                end
            end
        end
        ScanFolder(folder)
    end
    
    table.sort(uniqueNames)
    return uniqueNames
end

-- --- [ INTERFAZ (UI) ] ---

-- SECCIÓN 1: BRAINROTS
local SectionBR = EspTab:Section({ Title = "👽 ESP Brainrots" })

SectionBR:Toggle({
    Title = "Activar Visuales (Brainrots)",
    Callback = function(s) Config.Brainrots.Enabled = s end
})

SectionBR:Toggle({
    Title = "Activar Láser Rojo (Beams)",
    Callback = function(s) Config.Brainrots.Beams = s end
})

local DropdownBR = SectionBR:Dropdown({
    Title = "Seleccionar Objetivos",
    Multi = true,
    Values = GetAllAssets("Brainrots"),
    Callback = function(v) Config.Brainrots.Targets = v end
})

-- SECCIÓN 2: LUCKY BLOCKS
local SectionLB = EspTab:Section({ Title = "🍀 ESP Lucky Blocks" })

SectionLB:Toggle({
    Title = "Activar Visuales (Lucky Blocks)",
    Callback = function(s) Config.LuckyBlocks.Enabled = s end
})

SectionLB:Toggle({
    Title = "Activar Láser Amarillo (Beams)",
    Callback = function(s) Config.LuckyBlocks.Beams = s end
})

local DropdownLB = SectionLB:Dropdown({
    Title = "Seleccionar Objetivos",
    Multi = true,
    Values = GetAllAssets("LuckyBlocks"),
    Callback = function(v) Config.LuckyBlocks.Targets = v end
})

SectionLB:Button({
    Title = "🔄 Refrescar Listas Limpias",
    Callback = function()
        DropdownBR:Refresh(GetAllAssets("Brainrots"), Config.Brainrots.Targets)
        DropdownLB:Refresh(GetAllAssets("LuckyBlocks"), Config.LuckyBlocks.Targets)
    end
})

-- --- [ MOTOR VISUAL (CORE OPTIMIZADO) ] ---

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function CrearBeam(rootPlayer, targetPart, color)
    -- 1. Attachment en el Jugador (Solo uno necesario)
    local attPlayer = rootPlayer:FindFirstChild("ESP_Att_Player")
    if not attPlayer then
        attPlayer = Instance.new("Attachment", rootPlayer)
        attPlayer.Name = "ESP_Att_Player"
    end

    -- 2. Attachment en el Enemigo
    local attTarget = targetPart:FindFirstChild("ESP_Att_Target")
    if not attTarget then
        attTarget = Instance.new("Attachment", targetPart)
        attTarget.Name = "ESP_Att_Target"
    end

    -- 3. EL BEAM (Ahora va dentro del Target, no del jugador)
    -- Esto permite tener múltiples Beams del mismo tipo de monstruo
    local beam = targetPart:FindFirstChild("ESP_Beam")
    if not beam then
        beam = Instance.new("Beam", targetPart)
        beam.Name = "ESP_Beam"
        beam.Attachment0 = attPlayer
        beam.Attachment1 = attTarget
        beam.Color = ColorSequence.new(color)
        beam.Width0 = 0.1
        beam.Width1 = 0.1
        beam.FaceCamera = true
        beam.Texture = "rbxassetid://446111271" -- Textura suave de láser
        beam.TextureSpeed = 2
        beam.Transparency = NumberSequence.new(0.2)
    else
        -- Actualizar conexión si reviviste
        if beam.Attachment0 ~= attPlayer then
            beam.Attachment0 = attPlayer
        end
    end
end

local function AplicarESP(model, settings, colorBase)
    -- Validación básica
    if not model or not model.Parent then return end

    -- Buscar parte principal
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    -- 1. HIGHLIGHT (Aura)
    if not model:FindFirstChild("ESP_Highlight") then
        local hl = Instance.new("Highlight", model)
        hl.Name = "ESP_Highlight"
        hl.FillColor = colorBase
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0
    end

    -- 2. BILLBOARD (Texto)
    if not model:FindFirstChild("ESP_Text") then
        local bg = Instance.new("BillboardGui", model)
        bg.Name = "ESP_Text"; bg.Size = UDim2.new(0,100,0,30); bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, part.Size.Y + 2, 0); bg.Adornee = part
        
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
        lbl.TextColor3 = colorBase; lbl.TextStrokeTransparency = 0
        lbl.TextStrokeColor3 = Color3.new(0,0,0)
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12
        lbl.Text = model.Name
    end

    -- 3. BEAMS (Láser)
    if settings.Beams and GetRoot() then
        CrearBeam(GetRoot(), part, colorBase)
    else
        -- Si desactivas la opción de Beams, quitamos solo el beam
        local oldBeam = part:FindFirstChild("ESP_Beam")
        if oldBeam then oldBeam:Destroy() end
    end
end

local function LimpiarESP(model)
    if model:FindFirstChild("ESP_Highlight") then model.ESP_Highlight:Destroy() end
    if model:FindFirstChild("ESP_Text") then model.ESP_Text:Destroy() end
    if model:FindFirstChildWhichIsA("BasePart") then
        local part = model:FindFirstChildWhichIsA("BasePart")
        if part:FindFirstChild("ESP_Beam") then part.ESP_Beam:Destroy() end
    end
end

-- --- [ LOOP INTELIGENTE ] ---
-- Usamos task.spawn con un loop, pero optimizado para no buscar 'Descendants' a lo loco

task.spawn(function()
    while true do
        local root = GetRoot()
        
        if root then
            -- A) LÓGICA BRAINROTS (Carpetas)
            if Config.Brainrots.Enabled then
                local FolderBR = workspace:FindFirstChild("ActiveBrainrots")
                if FolderBR then
                    -- Buscamos en las carpetas de rareza
                    for _, subFolder in pairs(FolderBR:GetChildren()) do
                        local targetsContainer = subFolder:FindFirstChild("RenderedBrainrot") or subFolder
                        for _, m in pairs(targetsContainer:GetChildren()) do
                            if table.find(Config.Brainrots.Targets, m.Name) then
                                AplicarESP(m, Config.Brainrots, Color3.fromRGB(255, 50, 50)) -- Rojo
                            else
                                LimpiarESP(m)
                            end
                        end
                    end
                end
            end

            -- B) LÓGICA LUCKY BLOCKS
            if Config.LuckyBlocks.Enabled then
                local FolderLB = workspace:FindFirstChild("ActiveLuckyBlocks")
                if FolderLB then
                    -- Usamos GetChildren si es posible, es más rápido que GetDescendants
                    -- Si los luckyblocks están en subcarpetas, usa una función recursiva simple o GetDescendants con cuidado
                    for _, m in pairs(FolderLB:GetDescendants()) do
                        if m:IsA("Model") then
                            if table.find(Config.LuckyBlocks.Targets, m.Name) then
                                AplicarESP(m, Config.LuckyBlocks, Color3.fromRGB(255, 255, 0)) -- Amarillo
                            else
                                LimpiarESP(m)
                            end
                        end
                    end
                end
            end
        end
        
        -- Espera un poco menos para que se sienta más fluido, pero sin laguear
        task.wait(0.15)
    end
end)
