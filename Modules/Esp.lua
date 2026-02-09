--[[
    MODULE: VORTEX ESP - NEON EDITION (v3)
    FIXES:
    1. SUPER VISIBLE NEON BEAMS (No texture, pure light)
    2. INSTANT ESP (No switching delay)
    3. DEEP SEARCH for Lucky Blocks lists
    4. LEVEL DISPLAY RESTORED (Auto-detect)
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

-- --- [ FUNCIONES DE UTILIDAD ] ---

-- Buscador mejorado para las listas (Lucky Blocks / Brainrots)
local function GetAllAssets(folderName)
    local uniqueNames = {}
    -- Buscamos en Assets primero
    local folder = ReplicatedStorage:FindFirstChild("Assets") 
    
    -- Si no está en Assets, buscamos en todo ReplicatedStorage (búsqueda profunda)
    if not folder then folder = ReplicatedStorage end
    
    local targetFolder = folder:FindFirstChild(folderName) or folder:FindFirstChild(folderName, true)

    if targetFolder then
        local function Scan(dir)
            for _, item in pairs(dir:GetChildren()) do
                if item:IsA("Model") then
                    if not table.find(uniqueNames, item.Name) then
                        table.insert(uniqueNames, item.Name)
                    end
                elseif item:IsA("Folder") then
                    Scan(item)
                end
            end
        end
        Scan(targetFolder)
    else
        warn("⚠ No se encontró la carpeta: " .. folderName)
    end
    
    table.sort(uniqueNames)
    return uniqueNames
end

-- Intentar obtener el nivel del objeto (Si existe)
local function GetLevel(model)
    -- Intenta buscar Atributos, Valores o Configuración
    local level = model:GetAttribute("Level") or model:GetAttribute("Nivel")
    
    if not level then
        local val = model:FindFirstChild("Level") or model:FindFirstChild("Value") or model:FindFirstChild("Nivel")
        if val and val:IsA("IntValue") or val:IsA("NumberValue") then
            level = val.Value
        end
    end
    
    return level -- Puede ser nil si no tiene nivel
end

-- --- [ INTERFAZ (UI) ] ---

-- SECCIÓN 1: BRAINROTS
local SectionBR = EspTab:Section({ Title = "👽 ESP Brainrots" })

SectionBR:Toggle({
    Title = "Activar Visuales",
    Callback = function(s) Config.Brainrots.Enabled = s end
})

SectionBR:Toggle({
    Title = "Láser ROJO NEÓN (Beams)",
    Callback = function(s) Config.Brainrots.Beams = s end
})

local DropdownBR = SectionBR:Dropdown({
    Title = "Seleccionar Brainrots",
    Multi = true,
    Values = GetAllAssets("Brainrots"),
    Callback = function(v) Config.Brainrots.Targets = v end
})

-- SECCIÓN 2: LUCKY BLOCKS
local SectionLB = EspTab:Section({ Title = "🍀 ESP Lucky Blocks" })

SectionLB:Toggle({
    Title = "Activar Visuales",
    Callback = function(s) Config.LuckyBlocks.Enabled = s end
})

SectionLB:Toggle({
    Title = "Láser AMARILLO NEÓN (Beams)",
    Callback = function(s) Config.LuckyBlocks.Beams = s end
})

local DropdownLB = SectionLB:Dropdown({
    Title = "Seleccionar Lucky Blocks",
    Multi = true,
    Values = GetAllAssets("LuckyBlocks"),
    Callback = function(v) Config.LuckyBlocks.Targets = v end
})

SectionLB:Button({
    Title = "🔄 Refrescar Listas (Debug)",
    Callback = function()
        -- Imprimimos en consola (F9) para ver si encuentra algo
        local brList = GetAllAssets("Brainrots")
        local lbList = GetAllAssets("LuckyBlocks")
        print("Brainrots encontrados:", #brList)
        print("LuckyBlocks encontrados:", #lbList)
        
        DropdownBR:Refresh(brList, Config.Brainrots.Targets)
        DropdownLB:Refresh(lbList, Config.LuckyBlocks.Targets)
    end
})

-- --- [ MOTOR VISUAL (CORE NEÓN) ] ---

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function CrearBeamNeon(rootPlayer, targetPart, color)
    -- Attachments
    local attPlayer = rootPlayer:FindFirstChild("ESP_Att_Player")
    if not attPlayer then
        attPlayer = Instance.new("Attachment", rootPlayer)
        attPlayer.Name = "ESP_Att_Player"
    end

    local attTarget = targetPart:FindFirstChild("ESP_Att_Target")
    if not attTarget then
        attTarget = Instance.new("Attachment", targetPart)
        attTarget.Name = "ESP_Att_Target"
    end

    local beam = targetPart:FindFirstChild("ESP_Beam")
    if not beam then
        beam = Instance.new("Beam", targetPart)
        beam.Name = "ESP_Beam"
        beam.Attachment0 = attPlayer
        beam.Attachment1 = attTarget
        
        -- CONFIGURACIÓN NEÓN (SÚPER VISIBLE)
        beam.Color = ColorSequence.new(color)
        beam.Width0 = 0.2 -- Un poco más grueso
        beam.Width1 = 0.2
        beam.FaceCamera = true
        
        -- Sin textura + LightEmission = NEÓN PURO
        beam.Texture = "" 
        beam.Transparency = NumberSequence.new(0) -- Totalmente sólido
        beam.LightEmission = 1 -- Brilla en la oscuridad
        beam.LightInfluence = 0 -- Ignora sombras
    else
        if beam.Attachment0 ~= attPlayer then
            beam.Attachment0 = attPlayer
        end
    end
end

local function AplicarESP(model, settings, colorBase)
    if not model or not model.Parent then return end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    -- 1. HIGHLIGHT (Aura Sólida)
    if not model:FindFirstChild("ESP_Highlight") then
        local hl = Instance.new("Highlight", model)
        hl.Name = "ESP_Highlight"
        hl.FillColor = colorBase
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.4 -- Más visible
        hl.OutlineTransparency = 0
    end

    -- 2. BILLBOARD (Texto con Nivel)
    if not model:FindFirstChild("ESP_Text") then
        local bg = Instance.new("BillboardGui", model)
        bg.Name = "ESP_Text"; bg.Size = UDim2.new(0,100,0,40); bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, part.Size.Y + 2.5, 0); bg.Adornee = part
        
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
        lbl.TextColor3 = colorBase; lbl.TextStrokeTransparency = 0
        lbl.TextStrokeColor3 = Color3.new(0,0,0)
        lbl.Font = Enum.Font.GothamBlack; lbl.TextSize = 14 -- Fuente más gruesa
        
        -- Recuperar Nivel
        local lvl = GetLevel(model)
        if lvl then
            lbl.Text = model.Name .. " [Nv. " .. tostring(lvl) .. "]"
        else
            lbl.Text = model.Name
        end
    end

    -- 3. BEAMS (Láser Neón)
    if settings.Beams and GetRoot() then
        CrearBeamNeon(GetRoot(), part, colorBase)
    else
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

-- --- [ LOOP RÁPIDO ] ---
-- Usamos 'ipairs' donde sea posible y no usamos 'else Limpiar' agresivo para evitar parpadeos

task.spawn(function()
    while true do
        local root = GetRoot()
        
        if root then
            -- A) BRAINROTS
            if Config.Brainrots.Enabled then
                local FolderBR = workspace:FindFirstChild("ActiveBrainrots")
                if FolderBR then
                    for _, sub in pairs(FolderBR:GetChildren()) do
                        -- Algunos juegos usan carpetas de "Rarity", otros no. Revisamos todo.
                        local items = sub:IsA("Folder") and sub:GetChildren() or {sub}
                        
                        -- Si la carpeta tiene una subcarpeta "Rendered...", usar esa
                        if sub:FindFirstChild("RenderedBrainrot") then
                            items = sub.RenderedBrainrot:GetChildren()
                        end

                        for _, m in pairs(items) do
                            if m:IsA("Model") and table.find(Config.Brainrots.Targets, m.Name) then
                                AplicarESP(m, Config.Brainrots, Color3.fromRGB(255, 0, 0)) -- ROJO NEÓN
                            elseif m:IsA("Model") then
                                -- Solo limpiamos si NO está en la lista pero tiene ESP (cambio de target)
                                if m:FindFirstChild("ESP_Highlight") then LimpiarESP(m) end
                            end
                        end
                    end
                end
            end

            -- B) LUCKY BLOCKS
            if Config.LuckyBlocks.Enabled then
                local FolderLB = workspace:FindFirstChild("ActiveLuckyBlocks")
                if FolderLB then
                    -- Usamos GetDescendants con filtro para asegurar encontrar todo
                    for _, m in pairs(FolderLB:GetDescendants()) do
                        if m:IsA("Model") then
                            if table.find(Config.LuckyBlocks.Targets, m.Name) then
                                AplicarESP(m, Config.LuckyBlocks, Color3.fromRGB(255, 230, 0)) -- AMARILLO NEÓN
                            else
                                if m:FindFirstChild("ESP_Highlight") then LimpiarESP(m) end
                            end
                        end
                    end
                end
            end
        end
        
        task.wait(0.1) -- Actualización rápida
    end
end)
