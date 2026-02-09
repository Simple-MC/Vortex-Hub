--[[
    MODULE: VORTEX ESP - FINAL BOSS EDITION
    FIXES:
    1. Removed Level Slider.
    2. Smart Name Matching (NaturalSpawn/EventSpawn).
    3. Exact Asset Paths for Dropdowns.
    4. Independent Neon Beams.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- --- [ SECCIONES DE LA UI ] ---
local SectionBR = _G.EspTab:Section({ Title = "👽 Rastreador de Brainrots" })
local SectionLB = _G.EspTab:Section({ Title = "🍀 Rastreador de Lucky Blocks" })

-- --- [ CONFIGURACIÓN ] ---
local Config = {
    Brainrots = { Enabled = false, Beams = false, Targets = {} },
    LuckyBlocks = { Enabled = false, Beams = false, Targets = {} }
}

-- --- [ FUNCIONES DE LISTA (REPLICATED STORAGE) ] ---

local function GetAssetNames(folderPath)
    local names = {}
    local success, folder = pcall(function() return folderPath end)
    if success and folder then
        for _, item in pairs(folder:GetChildren()) do
            -- Insertamos el nombre de la carpeta de rareza o el modelo
            if not table.find(names, item.Name) then
                table.insert(names, item.Name)
            end
        end
    end
    table.sort(names)
    return names
end

-- --- [ INTERFAZ - BRAINROTS ] ---
SectionBR:Toggle({ Title = "Activar ESP", Callback = function(s) Config.Brainrots.Enabled = s end })
SectionBR:Toggle({ Title = "Láser Rojo Neón", Callback = function(s) Config.Brainrots.Beams = s end })
local DropBR = SectionBR:Dropdown({
    Title = "Seleccionar Brainrots",
    Multi = true,
    Values = GetAssetNames(ReplicatedStorage.Assets.Brainrots),
    Callback = function(v) Config.Brainrots.Targets = v end
})

-- --- [ INTERFAZ - LUCKY BLOCKS ] ---
SectionLB:Toggle({ Title = "Activar ESP", Callback = function(s) Config.LuckyBlocks.Enabled = s end })
SectionLB:Toggle({ Title = "Láser Amarillo Neón", Callback = function(s) Config.LuckyBlocks.Beams = s end })
local DropLB = SectionLB:Dropdown({
    Title = "Seleccionar Rarezas",
    Multi = true,
    Values = GetAssetNames(ReplicatedStorage.Assets.LuckyBlocks),
    Callback = function(v) Config.LuckyBlocks.Targets = v end
})

-- --- [ MOTOR VISUAL ] ---

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function AplicarVisuales(model, color)
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    -- 1. Highlight
    if not model:FindFirstChild("V_Highlight") then
        local hl = Instance.new("Highlight", model)
        hl.Name = "V_Highlight"
        hl.FillColor = color
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.new(1,1,1)
    end

    -- 2. Billboard
    if not model:FindFirstChild("V_Text") then
        local bg = Instance.new("BillboardGui", model)
        bg.Name = "V_Text"; bg.Size = UDim2.new(0,120,0,40); bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, 3, 0); bg.Adornee = part
        
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color; lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
        lbl.Text = model.Name:gsub("NaturalSpawn", ""):gsub("EventSpawn", ""):gsub("_", " ")
    end
end

local function ManejarBeam(model, color, enabled)
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    local myRoot = GetRoot()
    if not part or not myRoot then return end

    local beam = part:FindFirstChild("V_Beam")
    if enabled then
        local attP = myRoot:FindFirstChild("V_Att") or Instance.new("Attachment", myRoot)
        attP.Name = "V_Att"
        
        local attT = part:FindFirstChild("V_Att") or Instance.new("Attachment", part)
        attT.Name = "V_Att"

        if not beam then
            beam = Instance.new("Beam", part)
            beam.Name = "V_Beam"
            beam.Attachment0 = attP
            beam.Attachment1 = attT
            beam.Color = ColorSequence.new(color)
            beam.Width0 = 0.15; beam.Width1 = 0.15
            beam.LightEmission = 1
            beam.FaceCamera = true
        else
            beam.Attachment0 = attP -- Por si mueres
        end
    else
        if beam then beam:Destroy() end
    end
end

local function Limpiar(model)
    if model:FindFirstChild("V_Highlight") then model.V_Highlight:Destroy() end
    if model:FindFirstChild("V_Text") then model.V_Text:Destroy() end
    local p = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if p and p:FindFirstChild("V_Beam") then p.V_Beam:Destroy() end
end

-- --- [ LOOP DE ESCANEO ] ---

task.spawn(function()
    while true do
        -- 1. PROCESAR BRAINROTS
        local folderBR = workspace:FindFirstChild("ActiveBrainrots")
        if folderBR and Config.Brainrots.Enabled then
            for _, m in pairs(folderBR:GetDescendants()) do
                if m:IsA("Model") then
                    local isTarget = false
                    for _, t in pairs(Config.Brainrots.Targets) do
                        if m.Name:find(t) then isTarget = true break end
                    end
                    
                    if isTarget then
                        AplicarVisuales(m, Color3.fromRGB(255, 0, 0))
                        ManejarBeam(m, Color3.fromRGB(255, 0, 0), Config.Brainrots.Beams)
                    else
                        Limpiar(m)
                    end
                end
            end
        end

        -- 2. PROCESAR LUCKY BLOCKS
        local folderLB = workspace:FindFirstChild("ActiveLuckyBlocks")
        if folderLB and Config.LuckyBlocks.Enabled then
            for _, m in pairs(folderLB:GetChildren()) do
                if m:IsA("Model") then
                    local isTarget = false
                    for _, t in pairs(Config.LuckyBlocks.Targets) do
                        -- Esto detecta "NaturalSpawnLuckyBlock_Rareza" si eliges "Rareza"
                        if m.Name:find(t) then isTarget = true break end
                    end

                    if isTarget then
                        AplicarVisuales(m, Color3.fromRGB(255, 255, 0))
                        ManejarBeam(m, Color3.fromRGB(255, 255, 0), Config.LuckyBlocks.Beams)
                    else
                        Limpiar(m)
                    end
                end
            end
        end

        task.wait(0.2)
    end
end)
