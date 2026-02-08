--[[
    MODULE: VORTEX ESP - SEPARATED EDITION
    FEATURES: Brainrots & Lucky Blocks Sections | Guaranteed Beams | No Level Slider
]]

local EspTab = _G.EspTab
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- --- [ CONFIGURACIÓN ] ---
local Config = {
    Brainrots = { Enabled = false, Beams = false, Targets = {} },
    LuckyBlocks = { Enabled = false, Beams = false, Targets = {} }
}

-- --- [ FUNCIONES DE UTILIDAD ] ---
local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function GetAllAssets(folderName)
    local names = {}
    local folder = ReplicatedStorage.Assets:FindFirstChild(folderName)
    if folder then
        for _, item in pairs(folder:GetDescendants()) do
            if item:IsA("Model") or item:IsA("BasePart") then
                if not table.find(names, item.Name) then
                    table.insert(names, item.Name)
                end
            end
        end
    end
    table.sort(names)
    return names
end

-- --- [ SECCIÓN 1: BRAINROTS ] ---
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
    Title = "Seleccionar Brainrots",
    Multi = true,
    Values = GetAllAssets("Brainrots"),
    Callback = function(v) Config.Brainrots.Targets = v end
})

-- --- [ SECCIÓN 2: LUCKY BLOCKS ] ---
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
    Title = "Seleccionar Lucky Blocks",
    Multi = true,
    Values = GetAllAssets("LuckyBlocks"),
    Callback = function(v) Config.LuckyBlocks.Targets = v end
})

SectionLB:Button({
    Title = "🔄 Refrescar Ambas Listas",
    Callback = function()
        DropdownBR:Refresh(GetAllAssets("Brainrots"), Config.Brainrots.Targets)
        DropdownLB:Refresh(GetAllAssets("LuckyBlocks"), Config.LuckyBlocks.Targets)
    end
})

-- --- [ MOTOR VISUAL (CORE) ] ---
local function CrearBeam(rootPlayer, targetPart, color)
    local attPlayer = rootPlayer:FindFirstChild("ESP_Att")
    if not attPlayer then
        attPlayer = Instance.new("Attachment", rootPlayer)
        attPlayer.Name = "ESP_Att"
    end

    local attTarget = targetPart:FindFirstChild("ESP_Target")
    if not attTarget then
        attTarget = Instance.new("Attachment", targetPart)
        attTarget.Name = "ESP_Target"
    end

    local beamName = "Beam_" .. targetPart.Parent.Name
    local beam = rootPlayer:FindFirstChild(beamName)
    
    if not beam then
        beam = Instance.new("Beam", rootPlayer)
        beam.Name = beamName
        beam.Attachment0 = attPlayer
        beam.Attachment1 = attTarget
        beam.Color = ColorSequence.new(color)
        beam.Width0 = 0.15; beam.Width1 = 0.15
        beam.FaceCamera = true
    elseif beam.Attachment0 ~= attPlayer then
        beam.Attachment0 = attPlayer -- Reconectar si moriste
    end
end

local function ProcesarObjeto(model, settings, color)
    pcall(function()
        -- 1. Buscar una parte válida (Esto arregla que falten beams)
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") or model:FindFirstChild("Head")
        
        if part then
            -- Highlight (Aura)
            if not model:FindFirstChild("G_Visual") then
                local hl = Instance.new("Highlight", model)
                hl.Name = "G_Visual"
                hl.FillColor = color
                hl.OutlineColor = Color3.new(1,1,1)
                hl.FillTransparency = 0.5
            end

            -- Billboard (Texto)
            if not model:FindFirstChild("G_Info") then
                local bg = Instance.new("BillboardGui", model)
                bg.Name = "G_Info"; bg.Size = UDim2.new(0,140,0,40); bg.AlwaysOnTop = true
                bg.StudsOffset = Vector3.new(0,3,0); bg.Adornee = part
                
                local lbl = Instance.new("TextLabel", bg)
                lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(1,1,1); lbl.TextStrokeTransparency = 0
                lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
                lbl.Text = model.Name
            end

            -- Beams (Láser)
            if settings.Beams and GetRoot() then
                CrearBeam(GetRoot(), part, color)
            else
                -- Si desactivaste beams, borrarlos
                if GetRoot() then
                    local b = GetRoot():FindFirstChild("Beam_" .. model.Name)
                    if b then b:Destroy() end
                end
            end
        end
    end)
end

local function Limpiar(model)
    if model:FindFirstChild("G_Visual") then model.G_Visual:Destroy() end
    if model:FindFirstChild("G_Info") then model.G_Info:Destroy() end
    -- Borrar beam del jugador
    local root = GetRoot()
    if root then
        local b = root:FindFirstChild("Beam_" .. model.Name)
        if b then b:Destroy() end
    end
end

-- --- [ BUCLE PRINCIPAL ] ---
task.spawn(function()
    while true do
        local root = GetRoot()
        
        -- Si el jugador está vivo
        if root then
            -- 1. PROCESAR BRAINROTS
            local FolderBR = workspace:FindFirstChild("ActiveBrainrots")
            if FolderBR and Config.Brainrots.Enabled then
                for _, sub in pairs(FolderBR:GetChildren()) do -- Entrar a carpetas de rareza
                    local container = sub:FindFirstChild("RenderedBrainrot") or sub
                    for _, m in pairs(container:GetChildren()) do
                        if table.find(Config.Brainrots.Targets, m.Name) then
                            ProcesarObjeto(m, Config.Brainrots, Color3.new(1, 0, 0)) -- ROJO
                        else
                            Limpiar(m)
                        end
                    end
                end
            end

            -- 2. PROCESAR LUCKY BLOCKS
            local FolderLB = workspace:FindFirstChild("ActiveLuckyBlocks")
            if FolderLB and Config.LuckyBlocks.Enabled then
                for _, m in pairs(FolderLB:GetDescendants()) do -- Usar Descendants por si hay subcarpetas
                    if m:IsA("Model") and table.find(Config.LuckyBlocks.Targets, m.Name) then
                        ProcesarObjeto(m, Config.LuckyBlocks, Color3.new(1, 1, 0)) -- AMARILLO
                    elseif m:IsA("Model") then
                        Limpiar(m)
                    end
                end
            end
        end
        
        task.wait(0.1) -- Rápido y furioso
    end
end)
