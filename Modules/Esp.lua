--[[
    MODULE: VORTEX GOD-MODE ESP (v4 - Final Fix)
    FIXES:
    1. Clean Object List (No internal parts)
    2. Independent Beams (Shows ALL targets at once)
    3. Auto-Level Detection
    4. Instant Refresh
]]

local Section = _G.EspTab:Section({ Title = "Rastreador Universal (Pro)" })
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- --- [ CONFIGURACIÓN ] ---
local Config = {
    Enabled = false,
    ShowBeams = false,
    MinLevel = 0,
    SelectedTargets = {}
}

-- --- [ UTILIDADES DE BÚSQUEDA ] ---

-- Función para limpiar la lista y solo obtener NOMBRES DE MODELOS PRINCIPALES
local function ObtenerListaLimpia()
    local Names = {}
    local Assets = ReplicatedStorage:WaitForChild("Assets")
    
    local function ScanFolder(folder)
        for _, item in pairs(folder:GetChildren()) do
            if item:IsA("Model") then
                if not table.find(Names, item.Name) then
                    table.insert(Names, item.Name)
                end
            elseif item:IsA("Folder") then
                ScanFolder(item) -- Búsqueda recursiva para carpetas dentro de carpetas
            end
        end
    end

    -- Escanear Brainrots y LuckyBlocks
    if Assets:FindFirstChild("Brainrots") then ScanFolder(Assets.Brainrots) end
    if Assets:FindFirstChild("LuckyBlocks") then ScanFolder(Assets.LuckyBlocks) end
    
    table.sort(Names)
    return Names
end

-- Función segura para obtener el Nivel
local function GetLevel(model)
    -- Intenta buscar Atributos
    local lvl = model:GetAttribute("Level") or model:GetAttribute("Nivel")
    if lvl then return tonumber(lvl) end

    -- Intenta buscar Valores Int/Number
    local val = model:FindFirstChild("Level") or model:FindFirstChild("Nivel") or model:FindFirstChild("Value")
    if val and (val:IsA("IntValue") or val:IsA("NumberValue")) then
        return val.Value
    end
    
    -- Intenta buscar en GUIs (común en Brainrot Tycoons)
    local head = model:FindFirstChild("Head") or model.PrimaryPart
    if head and head:FindFirstChildWhichIsA("BillboardGui") then
        for _, gui in pairs(head:GetChildren()) do
            if gui:IsA("BillboardGui") then
                local txt = gui:FindFirstChildWhichIsA("TextLabel", true)
                if txt and txt.Text then
                    local num = tonumber(string.match(txt.Text, "%d+"))
                    if num then return num end
                end
            end
        end
    end

    return 0 -- Si no encuentra nada
end

-- --- [ INTERFAZ ] ---

Section:Toggle({ 
    Title = "Activar ESP Maestro", 
    Callback = function(s) Config.Enabled = s end 
})

Section:Toggle({ 
    Title = "Activar Láser Rojo (Beams)", 
    Callback = function(s) Config.ShowBeams = s end 
})

Section:Slider({ 
    Title = "Filtrar por Nivel Mínimo", 
    Min = 0, Max = 1000, Default = 0, 
    Callback = function(v) Config.MinLevel = v end 
})

local MainDropdown = Section:Dropdown({
    Title = "Seleccionar Objetivos",
    Multi = true,
    Values = ObtenerListaLimpia(),
    Callback = function(val) Config.SelectedTargets = val end
})

Section:Button({ 
    Title = "🔄 Refrescar Lista", 
    Callback = function() MainDropdown:Refresh(ObtenerListaLimpia(), Config.SelectedTargets) end 
})

-- --- [ MOTOR ESP ] ---

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function CrearVisuales(model)
    local rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not rootPart then return end

    -- 1. Highlight (Aura Roja)
    if not model:FindFirstChild("ESP_Highlight") then
        local hl = Instance.new("Highlight", model)
        hl.Name = "ESP_Highlight"
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0
    end

    -- 2. Billboard (Texto Info)
    if not model:FindFirstChild("ESP_Info") then
        local bg = Instance.new("BillboardGui", model)
        bg.Name = "ESP_Info"; bg.Size = UDim2.new(0, 150, 0, 50); bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, rootPart.Size.Y + 3, 0)
        bg.Adornee = rootPart
        
        local txt = Instance.new("TextLabel", bg)
        txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.new(1,1,1); txt.TextStrokeTransparency = 0
        txt.TextSize = 12; txt.RichText = true
        txt.Font = Enum.Font.GothamBold
        txt.Name = "Label"
    end
end

local function ActualizarInfo(model)
    local infoGui = model:FindFirstChild("ESP_Info")
    if infoGui then
        local label = infoGui:FindFirstChild("Label")
        if label then
            local lvl = GetLevel(model)
            if lvl > 0 then
                label.Text = string.format("%s\n<font color='#FFAA00'>Lv: %d</font>", model.Name, lvl)
            else
                label.Text = string.format("%s", model.Name)
            end
        end
    end
end

local function ManejarBeam(model, myRoot)
    local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not targetPart then return end

    -- Crear Attachment en el Enemigo
    local attTarget = targetPart:FindFirstChild("ESP_Att_Target")
    if not attTarget then
        attTarget = Instance.new("Attachment", targetPart)
        attTarget.Name = "ESP_Att_Target"
    end

    -- Crear Attachment en Nosotros (Uno solo)
    local attPlayer = myRoot:FindFirstChild("ESP_Att_Player")
    if not attPlayer then
        attPlayer = Instance.new("Attachment", myRoot)
        attPlayer.Name = "ESP_Att_Player"
    end

    -- Crear el Beam (En el enemigo apuntando a nosotros)
    local beam = targetPart:FindFirstChild("ESP_Beam")
    
    if Config.ShowBeams then
        if not beam then
            beam = Instance.new("Beam", targetPart)
            beam.Name = "ESP_Beam"
            beam.Attachment0 = attPlayer
            beam.Attachment1 = attTarget
            beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0)) -- Rojo Puro
            beam.Width0 = 0.1; beam.Width1 = 0.1
            beam.FaceCamera = true
            beam.Texture = "" -- Sin textura = Neón Sólido
            beam.LightEmission = 1
            beam.LightInfluence = 0
        else
            -- Actualizar referencia si revivimos
            if beam.Attachment0 ~= attPlayer then
                beam.Attachment0 = attPlayer
            end
        end
    else
        if beam then beam:Destroy() end
    end
end

local function Limpiar(model)
    if model:FindFirstChild("ESP_Highlight") then model.ESP_Highlight:Destroy() end
    if model:FindFirstChild("ESP_Info") then model.ESP_Info:Destroy() end
    
    local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if root then
        if root:FindFirstChild("ESP_Beam") then root.ESP_Beam:Destroy() end
    end
end

-- --- [ BUCLE PRINCIPAL ] ---
task.spawn(function()
    while true do
        local MyRoot = GetRoot()
        
        if Config.Enabled and MyRoot then
            local ActiveFolders = {
                workspace:FindFirstChild("ActiveBrainrots"),
                workspace:FindFirstChild("ActiveLuckyBlocks"),
                workspace:FindFirstChild("Drops") -- A veces los items caen aquí
            }

            for _, folder in pairs(ActiveFolders) do
                if folder then
                    -- Usamos GetDescendants con cuidado para encontrar Modelos anidados
                    for _, obj in pairs(folder:GetDescendants()) do
                        if obj:IsA("Model") and table.find(Config.SelectedTargets, obj.Name) then
                            
                            local lvl = GetLevel(obj)
                            -- Filtro de Nivel
                            if lvl >= Config.MinLevel then
                                CrearVisuales(obj)
                                ActualizarInfo(obj)
                                ManejarBeam(obj, MyRoot)
                            else
                                Limpiar(obj)
                            end
                        end
                    end
                end
            end
        else
            -- Si desactivamos, limpiamos todo visual
            -- (Opcional: Implementar limpieza global más eficiente si da lag)
        end
        
        task.wait(0.1) -- 10 veces por segundo es suficiente y ahorra recursos
    end
end)
