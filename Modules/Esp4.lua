--[[
    MODULE: VORTEX ESP - SEASONAL EVENT ADDON (esp4.lua)
    TARGETS: 
    1. Candy Parts (in workspace.CandyEventParts)
    2. Valentine Coins (in workspace.ValentinesCoinParts)
    STYLE: Neon Tech (Seasonal Colors)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- --- [ CONFIGURACIÓN ] ---
local Config = {
    Candy = { Enabled = false, Beams = false },
    Valentines = { Enabled = false, Beams = false }
}

-- --- [ INTERFAZ UI (ESTILO WINDUI) ] ---

-- Creamos la sección visual con el icono de corazón por la fecha
_G.EspTab:Section({ Title = "--[ EVENTOS DE TEMPORADA (ESP) ]--", Icon = "heart" })

-- 1. DULCES (CANDY)
_G.EspTab:Toggle({
    Title = "🍬 ESP Dulces (Candy)",
    Callback = function(s) 
        Config.Candy.Enabled = s 
        if not s then _G.LimpiarTemporal("Candy") end 
    end
})

_G.EspTab:Toggle({
    Title = "Láser Naranja Neón (Candy)",
    Callback = function(s) Config.Candy.Beams = s end
})

-- 2. SAN VALENTÍN
_G.EspTab:Toggle({
    Title = "💖 ESP Monedas San Valentín",
    Callback = function(s) 
        Config.Valentines.Enabled = s 
        if not s then _G.LimpiarTemporal("Valentines") end 
    end
})

_G.EspTab:Toggle({
    Title = "Láser Rosa Neón (San Valentín)",
    Callback = function(s) Config.Valentines.Beams = s end
})


-- --- [ MOTOR VISUAL (Temático) ] ---

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Función global de limpieza
_G.LimpiarTemporal = function(tipo)
    local targetFolder
    if tipo == "Candy" then targetFolder = workspace:FindFirstChild("CandyEventParts") end
    if tipo == "Valentines" then targetFolder = workspace:FindFirstChild("ValentinesCoinParts") end

    if targetFolder then
        for _, item in pairs(targetFolder:GetChildren()) do
            if item:FindFirstChild("S_Esp") then item.S_Esp:Destroy() end
            if item:FindFirstChild("S_Gui") then item.S_Gui:Destroy() end
            
            local part = (item:IsA("Model") and item.PrimaryPart) or (item:IsA("BasePart") and item)
            if part and part:FindFirstChild("S_Beam") then part.S_Beam:Destroy() end
        end
    end
end

local function AplicarVisualesTemporales(model, color, texto)
    local part = (model:IsA("Model") and model.PrimaryPart) or (model:IsA("BasePart") and model)
    if not part then return end

    -- 1. Highlight
    if not model:FindFirstChild("S_Esp") then
        local hl = Instance.new("Highlight")
        hl.Name = "S_Esp"
        hl.Parent = model
        hl.FillColor = color
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
    end

    -- 2. Texto
    if not model:FindFirstChild("S_Gui") then
        local bg = Instance.new("BillboardGui", model)
        bg.Name = "S_Gui"; bg.Size = UDim2.new(0, 120, 0, 40); bg.AlwaysOnTop = true
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

local function ManejarBeamTemporal(model, color, enabled)
    local part = (model:IsA("Model") and model.PrimaryPart) or (model:IsA("BasePart") and model)
    local myRoot = GetRoot()
    if not part or not myRoot then return end

    local beam = part:FindFirstChild("S_Beam")
    
    if enabled then
        local attP = myRoot:FindFirstChild("S_Att") or Instance.new("Attachment", myRoot)
        attP.Name = "S_Att"
        
        local attT = part:FindFirstChild("S_Att") or Instance.new("Attachment", part)
        attT.Name = "S_Att"

        if not beam then
            beam = Instance.new("Beam", part)
            beam.Name = "S_Beam"
            beam.Attachment0 = attP; beam.Attachment1 = attT
            beam.Color = ColorSequence.new(color)
            beam.Width0 = 0.1; beam.Width1 = 0.1
            beam.FaceCamera = true
            beam.LightEmission = 1
            beam.Texture = "rbxassetid://446111271"
            beam.TextureSpeed = 2
        else
            beam.Attachment0 = attP
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
            
            -- A) LÓGICA CANDY
            if Config.Candy.Enabled then
                local folder = workspace:FindFirstChild("CandyEventParts")
                if folder then
                    for _, item in pairs(folder:GetChildren()) do
                        if item:IsA("Model") or item:IsA("BasePart") then
                            -- Color NARANJA DULCE
                            local CandyColor = Color3.fromRGB(255, 150, 0) 
                            AplicarVisualesTemporales(item, CandyColor, "🍬 Dulce")
                            ManejarBeamTemporal(item, CandyColor, Config.Candy.Beams)
                        end
                    end
                end
            end

            -- B) LÓGICA SAN VALENTÍN
            if Config.Valentines.Enabled then
                local folder = workspace:FindFirstChild("ValentinesCoinParts")
                if folder then
                    for _, item in pairs(folder:GetChildren()) do
                        if item:IsA("Model") or item:IsA("BasePart") then
                            -- Color ROSA NEÓN
                            local ValColor = Color3.fromRGB(255, 50, 150) 
                            AplicarVisualesTemporales(item, ValColor, "💖 Moneda V.")
                            ManejarBeamTemporal(item, ValColor, Config.Valentines.Beams)
                        end
                    end
                end
            end

        end
        task.wait(0.2) 
    end
end)
