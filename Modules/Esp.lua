--[[
    MODULE: VORTEX GOD-MODE ESP
    ENGINE: Gemini Pro Optimized | Zero Latency | Immortal Beams
]]

local Section = _G.EspTab:Section({ Title = "Rastreador Universal (Pro)" })
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- --- [ CONFIGURACIÓN & ESTADO ] ---
local Config = {
    Enabled = false,
    ShowBeams = false,
    MinLevel = 0,
    MaxDistance = 10000, -- Rango infinito practicamente
    RefreshRate = 0.05 -- Ultra rápido (20 veces por segundo)
}

local SelectedTargets = {} 
local ProcessedObjects = {} -- Cache para no procesar lo mismo 2 veces

-- --- [ CARGA DE ASSETS ] ---
local function ObtenerListaGlobal()
    local Lista = {}
    local Assets = ReplicatedStorage:WaitForChild("Assets")
    
    -- 1. Brainrots (Están en subcarpetas de rareza)
    if Assets:FindFirstChild("Brainrots") then
        for _, rareza in pairs(Assets.Brainrots:GetChildren()) do
            for _, model in pairs(rareza:GetChildren()) do
                if not table.find(Lista, model.Name) then table.insert(Lista, model.Name) end
            end
        end
    end
    
    -- 2. Lucky Blocks (Están sueltos o en carpetas)
    if Assets:FindFirstChild("LuckyBlocks") then
        for _, item in pairs(Assets.LuckyBlocks:GetDescendants()) do
            if item:IsA("Model") or item:IsA("BasePart") then
                if not table.find(Lista, item.Name) then table.insert(Lista, item.Name) end
            end
        end
    end
    
    table.sort(Lista) -- Ordenar alfabéticamente para que se vea bonito
    return Lista
end

-- --- [ INTERFAZ DE USUARIO ] ---
Section:Toggle({ Title = "Activar ESP Maestro", Callback = function(s) Config.Enabled = s end })
Section:Toggle({ Title = "Activar Láser Rojo (Beams)", Callback = function(s) Config.ShowBeams = s end })
Section:Slider({ Title = "Nivel Mínimo (Solo Brainrots)", Min = 0, Max = 2000, Default = 0, Callback = function(v) Config.MinLevel = v end })

local MainDropdown = Section:Dropdown({
    Title = "Seleccionar Objetivos",
    Multi = true,
    Values = ObtenerListaGlobal(), -- Carga automática al inicio
    Callback = function(val) 
        SelectedTargets = val 
        table.clear(ProcessedObjects) -- Limpiar cache al cambiar selección
    end
})

Section:Button({ 
    Title = "Actualizar Lista de Objetos", 
    Callback = function() MainDropdown:Refresh(ObtenerListaGlobal(), {}) end 
})

-- --- [ FUNCIONES CORE ] ---
local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function CrearVisuales(model)
    -- 1. Highlight (Aura)
    if not model:FindFirstChild("G_Visual") then
        local hl = Instance.new("Highlight", model)
        hl.Name = "G_Visual"
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
    end

    -- 2. Billboard (Texto)
    if not model:FindFirstChild("G_Info") then
        local bg = Instance.new("BillboardGui", model)
        bg.Name = "G_Info"; bg.Size = UDim2.new(0, 150, 0, 50); bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, 3.5, 0)
        
        local txt = Instance.new("TextLabel", bg)
        txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.new(1,1,1); txt.TextStrokeTransparency = 0
        txt.TextSize = 14; txt.RichText = true
        txt.Font = Enum.Font.GothamBold
    end

    -- 3. Attachment para el Beam (En el objeto)
    local rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if rootPart and not model:FindFirstChild("G_Attach") then
        local att = Instance.new("Attachment", rootPart)
        att.Name = "G_Attach"
    end
end

local function ActualizarBeam(model, playerRoot)
    if not Config.ShowBeams or not playerRoot then 
        -- Si beams apagados, borrar si existe
        local b = playerRoot:FindFirstChild("Beam_"..model.Name)
        if b then b:Destroy() end
        return 
    end

    -- Asegurar Attachment en Jugador (INDISPENSABLE PARA QUE NO FALLE AL MORIR)
    local playerAtt = playerRoot:FindFirstChild("ESP_PlayerAtt")
    if not playerAtt then
        playerAtt = Instance.new("Attachment", playerRoot)
        playerAtt.Name = "ESP_PlayerAtt"
    end

    -- Buscar Attachment en Objeto
    local objAtt = model:FindFirstChild("G_Attach", true)
    if not objAtt then return end

    -- Crear o Actualizar Beam
    local beam = playerRoot:FindFirstChild("Beam_"..model.Name)
    if not beam then
        beam = Instance.new("Beam", playerRoot)
        beam.Name = "Beam_"..model.Name
        beam.Color = ColorSequence.new(Color3.new(1, 0, 0)) -- ROJO PURO
        beam.Width0 = 0.15; beam.Width1 = 0.15
        beam.FaceCamera = true
        beam.Attachment0 = playerAtt
        beam.Attachment1 = objAtt
    elseif beam.Attachment0 ~= playerAtt then
        -- RECONEXIÓN AUTOMÁTICA SI MUERES
        beam.Attachment0 = playerAtt
    end
end

-- --- [ BUCLE DE ALTO RENDIMIENTO ] ---
task.spawn(function()
    while true do
        local MyRoot = GetRoot()
        
        if Config.Enabled and MyRoot then
            -- Carpetas a escanear (Expandible)
            local Targets = {}
            local Folders = {workspace:FindFirstChild("ActiveBrainrots"), workspace:FindFirstChild("ActiveLuckyBlocks")}
            
            -- Recolección rápida de objetos
            for _, folder in pairs(Folders) do
                if folder then
                    for _, obj in pairs(folder:GetDescendants()) do
                        if obj:IsA("Model") and table.find(SelectedTargets, obj.Name) then
                            table.insert(Targets, obj)
                        end
                    end
                end
            end

            -- Procesamiento
            for _, model in pairs(Targets) do
                pcall(function()
                    local shouldShow = true
                    
                    -- Filtro de Nivel (Solo si tiene StatsGui)
                    local stats = model:FindFirstChild("ModelExtents") and model.ModelExtents:FindFirstChild("StatsGui")
                    if stats then
                        local lvlText = stats.Frame.Level.Text
                        local lvl = tonumber(string.match(lvlText, "%d+")) or 0
                        if lvl < Config.MinLevel then shouldShow = false end
                        
                        -- Actualizar Texto con Datos Reales
                        if model:FindFirstChild("G_Info") then
                            model.G_Info.TextLabel.Text = string.format("<b>%s</b>\n<font color='#ff4444'>Lv: %d</font>", model.Name, lvl)
                        end
                    else
                        -- Es un Lucky Block u otra cosa sin nivel
                        if model:FindFirstChild("G_Info") then
                            model.G_Info.TextLabel.Text = "<b>"..model.Name.."</b>\n<font color='#FFFF00'>🍀 LUCKY</font>"
                        end
                    end

                    if shouldShow then
                        CrearVisuales(model)
                        ActualizarBeam(model, MyRoot)
                    else
                        -- Si no pasa el filtro (nivel bajo), limpiar
                        if model:FindFirstChild("G_Visual") then model.G_Visual:Destroy() end
                        if model:FindFirstChild("G_Info") then model.G_Info:Destroy() end
                        local b = MyRoot:FindFirstChild("Beam_"..model.Name)
                        if b then b:Destroy() end
                    end
                end)
            end
        else
            -- Limpieza Total si se apaga
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "G_Visual" or v.Name == "G_Info" or v.Name == "G_Attach" then v:Destroy() end
            end
            if MyRoot then
                for _, v in pairs(MyRoot:GetChildren()) do
                    if string.find(v.Name, "Beam_") then v:Destroy() end
                end
            end
        end
        
        task.wait(Config.RefreshRate) -- 0.05s = Actualización casi instantánea
    end
end)
