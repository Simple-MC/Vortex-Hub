--[[
    MODULE: VORTEX ESP - v6 (FINAL POLISHED)
    FIXES:
    1. "RenderedBrainrot" Fix: Now finds the REAL mob inside the container.
    2. Instant OFF: Visuals clear immediately when you toggle off.
    3. Retains all Rarity/Neon Beam logic from v5.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- --- [ CONFIGURACIÓN ] ---
local Config = {
    Brainrots = { 
        Enabled = false, 
        Beams = false, 
        RarityTargets = {}, 
        ModelTargets = {}   
    },
    LuckyBlocks = { Enabled = false, Beams = false, Targets = {} }
}

-- --- [ FUNCIONES DE UTILIDAD ] ---

-- Función para limpiar visuales INMEDIATAMENTE al desactivar
local function LimpiarTodo(categoria)
    local foldersToClean = {}
    
    if categoria == "Brainrots" then
        table.insert(foldersToClean, workspace:FindFirstChild("ActiveBrainrots"))
    elseif categoria == "LuckyBlocks" then
        table.insert(foldersToClean, workspace:FindFirstChild("ActiveLuckyBlocks"))
    end

    for _, folder in pairs(foldersToClean) do
        if folder then
            for _, item in pairs(folder:GetDescendants()) do
                if item.Name == "ESP_H" or item.Name == "ESP_T" or item.Name == "ESP_B" then
                    item:Destroy()
                end
            end
        end
    end
    
    -- Limpiar attachments del jugador también
    if LocalPlayer.Character then
        for _, item in pairs(LocalPlayer.Character:GetDescendants()) do
            if item.Name == "ESP_Att" then item:Destroy() end
        end
    end
end

-- Funciones de Lista (Igual que v5)
local function GetRarityNames()
    local names = {}
    local folder = ReplicatedStorage.Assets:FindFirstChild("Brainrots")
    if folder then
        for _, item in pairs(folder:GetChildren()) do
            if item:IsA("Folder") then table.insert(names, item.Name) end
        end
    end
    table.sort(names)
    return names
end

local function GetBrainrotModels()
    local names = {}
    local folder = ReplicatedStorage.Assets:FindFirstChild("Brainrots")
    if folder then
        for _, rarityFolder in pairs(folder:GetChildren()) do
            for _, model in pairs(rarityFolder:GetChildren()) do
                if model:IsA("Model") and not table.find(names, model.Name) then
                    table.insert(names, model.Name)
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
        for _, item in pairs(folder:GetChildren()) do table.insert(names, item.Name) end
    end
    table.sort(names)
    return names
end

-- --- [ INTERFAZ UI (ESTILO WINDUI) ] ---

-- [ SECCIÓN BRAINROTS ]
_G.EspTab:Section({ Title = "--[ BRAINROTS (ESP) ]--", Icon = "skull" })

_G.EspTab:Toggle({ 
    Title = "👽 Activar ESP Brainrots", 
    Callback = function(s) 
        Config.Brainrots.Enabled = s 
        if not s then LimpiarTodo("Brainrots") end -- Limpieza Instantánea
    end 
})

_G.EspTab:Toggle({ 
    Title = "Láser Rojo Neón (Brainrots)", 
    Callback = function(s) Config.Brainrots.Beams = s end 
})

_G.EspTab:Dropdown({
    Title = "Seleccionar por RAREZA",
    Multi = true,
    Values = GetRarityNames(),
    Callback = function(v) Config.Brainrots.RarityTargets = v end
})

_G.EspTab:Dropdown({
    Title = "Seleccionar por NOMBRE",
    Multi = true,
    Values = GetBrainrotModels(),
    Callback = function(v) Config.Brainrots.ModelTargets = v end
})


-- [ SECCIÓN LUCKY BLOCKS ]
_G.EspTab:Section({ Title = "--[ LUCKY BLOCKS (ESP) ]--", Icon = "package" })

_G.EspTab:Toggle({ 
    Title = "🍀 Activar ESP Lucky Blocks", 
    Callback = function(s) 
        Config.LuckyBlocks.Enabled = s 
        if not s then LimpiarTodo("LuckyBlocks") end -- Limpieza Instantánea
    end 
})

_G.EspTab:Toggle({ 
    Title = "Láser Amarillo Neón (Lucky Blocks)", 
    Callback = function(s) Config.LuckyBlocks.Beams = s end 
})

_G.EspTab:Dropdown({
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

-- --- [ LOOP INTELIGENTE (CORREGIDO) ] ---

task.spawn(function()
    while true do
        -- 1. BRAINROTS
        local folderBR = workspace:FindFirstChild("ActiveBrainrots")
        if folderBR and Config.Brainrots.Enabled then
            for _, rarityFolder in pairs(folderBR:GetChildren()) do
                
                -- Detectar si hay que entrar a 'RenderedBrainrot'
                -- Primero buscamos dentro de la carpeta de rareza
                local items = rarityFolder:GetChildren()
                
                -- LÓGICA DE DETECCIÓN PROFUNDA
                local finalMobs = {}
                
                for _, item in pairs(items) do
                    -- ARREGLO PARA LA FOTO QUE MANDASTE:
                    if item.Name == "RenderedBrainrot" then
                        -- Si es el contenedor, agarramos lo que tenga adentro
                        for _, realMob in pairs(item:GetChildren()) do
                            if realMob:IsA("Model") then
                                table.insert(finalMobs, realMob)
                            end
                        end
                    elseif item:IsA("Model") then
                        -- Si es un modelo normal, lo agregamos directo
                        table.insert(finalMobs, item)
                    end
                end

                -- AHORA PROCESAMOS LOS MOBS REALES
                for _, m in pairs(finalMobs) do
                    local shouldHighlight = false
                    
                    -- Filtro por Rareza
                    if table.find(Config.Brainrots.RarityTargets, rarityFolder.Name) then
                        shouldHighlight = true
                    end
                    -- Filtro por Nombre
                    if table.find(Config.Brainrots.ModelTargets, m.Name) then
                        shouldHighlight = true
                    end

                    if shouldHighlight then
                        -- Mostrar Nombre Real + Rareza
                        AplicarVisuales(m, Color3.fromRGB(255, 0, 0), m.Name .. "\n["..rarityFolder.Name.."]")
                        ManejarBeam(m, Color3.fromRGB(255, 0, 0), Config.Brainrots.Beams)
                    else
                        Limpiar(m)
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
