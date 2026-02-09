--[[
    MODULE: VORTEX ESP - RARITY LOGIC (v5)
    FIXES:
    1. "Rarity ESP": Detects mobs inside Rarity folders (Common, Legendary, etc.)
    2. "Model ESP": Unpacks folders to show real mob names (Skibidi, etc.)
    3. Works for both Brainrots (Folders) and LuckyBlocks (Spawn Names)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- --- [ UI SECTIONS ] ---
local SectionBR = _G.EspTab:Section({ Title = "👽 Brainrots (Por Rareza y Modelo)" })
local SectionLB = _G.EspTab:Section({ Title = "🍀 Lucky Blocks" })

-- --- [ CONFIGURACIÓN ] ---
local Config = {
    Brainrots = { 
        Enabled = false, 
        Beams = false, 
        RarityTargets = {}, -- Lista de rarezas (Legendary, etc.)
        ModelTargets = {}   -- Lista de nombres (Skibidi, etc.)
    },
    LuckyBlocks = { Enabled = false, Beams = false, Targets = {} }
}

-- --- [ FUNCIONES DE LISTA INTELIGENTE ] ---

-- Opción A: Obtener Nombres de Carpetas (Rarezas)
local function GetRarityNames()
    local names = {}
    local folder = ReplicatedStorage.Assets:FindFirstChild("Brainrots")
    if folder then
        for _, item in pairs(folder:GetChildren()) do
            if item:IsA("Folder") then
                table.insert(names, item.Name)
            end
        end
    end
    table.sort(names)
    return names
end

-- Opción B: Obtener Nombres REALES de Modelos (Entrando a las carpetas)
local function GetBrainrotModels()
    local names = {}
    local folder = ReplicatedStorage.Assets:FindFirstChild("Brainrots")
    if folder then
        -- Entramos a cada carpeta de rareza
        for _, rarityFolder in pairs(folder:GetChildren()) do
            for _, model in pairs(rarityFolder:GetChildren()) do
                if model:IsA("Model") then
                    if not table.find(names, model.Name) then
                        table.insert(names, model.Name)
                    end
                end
            end
        end
    end
    table.sort(names)
    return names
end

local function GetLuckyBlockNames()
    local names = {}
    local folder = ReplicatedStorage.Assets:FindFirstChild("LuckyBlocks")
    if folder then
        for _, item in pairs(folder:GetChildren()) do
            table.insert(names, item.Name)
        end
    end
    table.sort(names)
    return names
end

-- --- [ INTERFAZ - BRAINROTS ] ---

SectionBR:Toggle({ Title = "Activar ESP Brainrots", Callback = function(s) Config.Brainrots.Enabled = s end })
SectionBR:Toggle({ Title = "Láser Rojo Neón", Callback = function(s) Config.Brainrots.Beams = s end })

-- DROPDOWN 1: POR RAREZA (Lo que pediste nuevo)
SectionBR:Dropdown({
    Title = "Seleccionar por RAREZA (Carpetas)",
    Desc = "Marca todos los de esta categoría",
    Multi = true,
    Values = GetRarityNames(),
    Callback = function(v) Config.Brainrots.RarityTargets = v end
})

-- DROPDOWN 2: POR MODELO ESPECÍFICO (Corregido)
SectionBR:Dropdown({
    Title = "Seleccionar por NOMBRE (Específico)",
    Desc = "Marca solo monstruos específicos",
    Multi = true,
    Values = GetBrainrotModels(), -- Ahora sí salen los nombres de los bichos
    Callback = function(v) Config.Brainrots.ModelTargets = v end
})


-- --- [ INTERFAZ - LUCKY BLOCKS ] ---
SectionLB:Toggle({ Title = "Activar ESP Lucky Blocks", Callback = function(s) Config.LuckyBlocks.Enabled = s end })
SectionLB:Toggle({ Title = "Láser Amarillo Neón", Callback = function(s) Config.LuckyBlocks.Beams = s end })

SectionLB:Dropdown({
    Title = "Seleccionar Lucky Blocks",
    Multi = true,
    Values = GetLuckyBlockNames(),
    Callback = function(v) Config.LuckyBlocks.Targets = v end
})

-- --- [ MOTOR VISUAL ] ---

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function AplicarVisuales(model, color, labelText)
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    -- Highlight
    if not model:FindFirstChild("ESP_H") then
        local hl = Instance.new("Highlight", model)
        hl.Name = "ESP_H"; hl.FillColor = color; hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.new(1,1,1)
    end

    -- Texto
    if not model:FindFirstChild("ESP_T") then
        local bg = Instance.new("BillboardGui", model)
        bg.Name = "ESP_T"; bg.Size = UDim2.new(0,120,0,40); bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, part.Size.Y + 3, 0); bg.Adornee = part
        
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color; lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
        lbl.Text = labelText
    end
end

local function ManejarBeam(model, color, enabled)
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    local myRoot = GetRoot()
    if not part or not myRoot then return end

    local beam = part:FindFirstChild("ESP_B")
    if enabled then
        local attP = myRoot:FindFirstChild("ESP_Att") or Instance.new("Attachment", myRoot)
        attP.Name = "ESP_Att"
        local attT = part:FindFirstChild("ESP_Att") or Instance.new("Attachment", part)
        attT.Name = "ESP_Att"

        if not beam then
            beam = Instance.new("Beam", part)
            beam.Name = "ESP_B"
            beam.Attachment0 = attP; beam.Attachment1 = attT
            beam.Color = ColorSequence.new(color)
            beam.Width0 = 0.15; beam.Width1 = 0.15
            beam.LightEmission = 1; beam.Texture = ""; beam.FaceCamera = true
        else
            beam.Attachment0 = attP
        end
    else
        if beam then beam:Destroy() end
    end
end

local function Limpiar(model)
    if model:FindFirstChild("ESP_H") then model.ESP_H:Destroy() end
    if model:FindFirstChild("ESP_T") then model.ESP_T:Destroy() end
    local p = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if p and p:FindFirstChild("ESP_B") then p.ESP_B:Destroy() end
end

-- --- [ LOOP INTELIGENTE (LA MAGIA) ] ---

task.spawn(function()
    while true do
        -- 1. BRAINROTS (Lógica Doble: Rareza Y Nombre)
        local folderBR = workspace:FindFirstChild("ActiveBrainrots")
        if folderBR and Config.Brainrots.Enabled then
            -- Iteramos sobre las carpetas de rareza en Workspace (Ej: workspace.ActiveBrainrots.Legendary)
            for _, rarityFolder in pairs(folderBR:GetChildren()) do
                -- Verificamos si es una carpeta (Rareza) o un modelo suelto
                local items = rarityFolder:IsA("Folder") and rarityFolder:GetChildren() or {rarityFolder}
                
                for _, m in pairs(items) do
                    if m:IsA("Model") then
                        local shouldHighlight = false
                        
                        -- CRITERIO A: ¿Está seleccionada la rareza (Nombre de la carpeta padre)?
                        if table.find(Config.Brainrots.RarityTargets, rarityFolder.Name) then
                            shouldHighlight = true
                        end
                        
                        -- CRITERIO B: ¿Está seleccionado el nombre del monstruo?
                        if table.find(Config.Brainrots.ModelTargets, m.Name) then
                            shouldHighlight = true
                        end

                        if shouldHighlight then
                            AplicarVisuales(m, Color3.fromRGB(255, 0, 0), m.Name .. "\n["..rarityFolder.Name.."]")
                            ManejarBeam(m, Color3.fromRGB(255, 0, 0), Config.Brainrots.Beams)
                        else
                            Limpiar(m)
                        end
                    end
                end
            end
        end

        -- 2. LUCKY BLOCKS
        local folderLB = workspace:FindFirstChild("ActiveLuckyBlocks")
        if folderLB and Config.LuckyBlocks.Enabled then
            for _, m in pairs(folderLB:GetChildren()) do
                if m:IsA("Model") then
                    local isTarget = false
                    for _, t in pairs(Config.LuckyBlocks.Targets) do
                        if m.Name:find(t) then isTarget = true break end
                    end
                    
                    if isTarget then
                        -- Limpiamos el nombre para que se vea bonito
                        local cleanName = m.Name:gsub("NaturalSpawn", ""):gsub("EventSpawn", ""):gsub("LuckyBlock_", ""):gsub("_", "")
                        AplicarVisuales(m, Color3.fromRGB(255, 255, 0), cleanName)
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
