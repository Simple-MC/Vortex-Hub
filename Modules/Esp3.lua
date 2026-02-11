--[[
    MODULE: VORTEX ESP - UFO EVENT ADDON (esp3.lua)
    TARGETS: UFO Coins (in workspace.UFOEventParts)
    STYLE: Neon Tech (Alien Purple)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Usamos el mismo Tab global (_G.EspTab)
local SectionUFO = _G.EspTab:Section({ Title = "👽 Evento UFO" })

-- --- [ CONFIGURACIÓN ] ---
local Config = {
    UFO = { Enabled = false, Beams = false }
}

-- --- [ INTERFAZ UI ] ---

SectionUFO:Toggle({
    Title = "🛸 ESP Monedas UFO",
    Callback = function(s) 
        Config.UFO.Enabled = s 
        if not s then _G.LimpiarUFO() end -- Limpieza rápida al apagar
    end
})

SectionUFO:Toggle({
    Title = "Láser Morado Neón (UFO)",
    Callback = function(s) Config.UFO.Beams = s end
})


-- --- [ MOTOR VISUAL (Adaptado para Aliens) ] ---

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Función global de limpieza única para este módulo
_G.LimpiarUFO = function()
    local targetFolder = workspace:FindFirstChild("UFOEventParts")
    if targetFolder then
        for _, item in pairs(targetFolder:GetChildren()) do
            -- Limpiamos Highlights y UI
            if item:FindFirstChild("U_Esp") then item.U_Esp:Destroy() end
            if item:FindFirstChild("U_Gui") then item.U_Gui:Destroy() end
            
            -- Limpiamos Beams
            local part = item:IsA("Model") and item.PrimaryPart or item
            if part and part:FindFirstChild("U_Beam") then part.U_Beam:Destroy() end
        end
    end
end

local function AplicarVisualesUFO(model, color, texto)
    -- Soporte para Modelos o Partes sueltas
    local part = (model:IsA("Model") and model.PrimaryPart) or (model:IsA("BasePart") and model)
    if not part then return end

    -- 1. Highlight (Aura Morada)
    if not model:FindFirstChild("U_Esp") then
        local hl = Instance.new("Highlight")
        hl.Name = "U_Esp"
        hl.Parent = model -- El highlight va en el modelo/parte
        hl.FillColor = color
        hl.OutlineColor = Color3.new(1, 1, 1) -- Borde blanco para resaltar
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
    end

    -- 2. Texto Flotante
    if not model:FindFirstChild("U_Gui") then
        local bg = Instance.new("BillboardGui", model)
        bg.Name = "U_Gui"; bg.Size = UDim2.new(0, 120, 0, 40); bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, 2.5, 0); bg.Adornee = part
        
        local lbl = Instance.new("TextLabel", bg)
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Text = texto
        lbl.TextColor3 = color
        lbl.TextStrokeTransparency = 0.5
        lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = 13
    end
end

local function ManejarBeamUFO(model, color, enabled)
    local part = (model:IsA("Model") and model.PrimaryPart) or (model:IsA("BasePart") and model)
    local myRoot = GetRoot()
    if not part or not myRoot then return end

    local beam = part:FindFirstChild("U_Beam")
    
    if enabled then
        -- Crear Attachments si no existen
        local attP = myRoot:FindFirstChild("U_Att") or Instance.new("Attachment", myRoot)
        attP.Name = "U_Att"
        
        local attT = part:FindFirstChild("U_Att") or Instance.new("Attachment", part)
        attT.Name = "U_Att"

        -- Crear o actualizar Beam
        if not beam then
            beam = Instance.new("Beam", part)
            beam.Name = "U_Beam"
            beam.Attachment0 = attP; beam.Attachment1 = attT
            beam.Color = ColorSequence.new(color)
            beam.Width0 = 0.1; beam.Width1 = 0.1
            beam.FaceCamera = true
            beam.LightEmission = 1
            beam.Texture = "rbxassetid://446111271" -- Textura de rayo láser
            beam.TextureSpeed = 2 -- Movimiento del láser
        else
            beam.Attachment0 = attP -- Actualizar origen si respawneas
        end
    else
        if beam then beam:Destroy() end
    end
end

-- --- [ LOOP DE BÚSQUEDA ] ---

task.spawn(function()
    while true do
        local MyRoot = GetRoot()
        if MyRoot then
            
            -- LÓGICA UFO COINS
            if Config.UFO.Enabled then
                local folder = workspace:FindFirstChild("UFOEventParts")
                if folder then
                    for _, item in pairs(folder:GetChildren()) do
                        -- Aceptamos Modelos y Partes
                        if item:IsA("Model") or item:IsA("BasePart") then
                            -- Color MORADO NEÓN (Alien Purple)
                            local AlienColor = Color3.fromRGB(170, 0, 255) 
                            
                            AplicarVisualesUFO(item, AlienColor, "👽 UFO Coin")
                            ManejarBeamUFO(item, AlienColor, Config.UFO.Beams)
                        end
                    end
                end
            end

        end
        task.wait(0.2) -- Loop optimizado
    end
end)
