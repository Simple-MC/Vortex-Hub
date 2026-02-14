--[[
    MODULE: VORTEX ESP - ARCADE EVENT ADDON (esp2.lua)
    TARGETS: 
    1. Game Consoles (in workspace.ArcadeEventConsoles)
    2. Event Tickets (in workspace.ArcadeEventTickets)
    STYLE: Same Neon Tech as Main ESP
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- --- [ CONFIGURACIÓN ] ---
local Config = {
    Consoles = { Enabled = false, Beams = false },
    Tickets = { Enabled = false, Beams = false }
}

-- --- [ INTERFAZ UI (ESTILO WINDUI) ] ---

-- Creamos la sección visual con tu estilo y un icono
_G.EspTab:Section({ Title = "--[ EVENTO ARCADE (ESP) ]--", Icon = "gamepad-2" })

-- 1. CONSOLAS (Se conectan a _G.EspTab directamente)
_G.EspTab:Toggle({
    Title = "🎮 ESP Consolas",
    Callback = function(s) 
        Config.Consoles.Enabled = s 
        if not s then _G.LimpiarArcade("Consoles") end -- Limpieza rápida
    end
})

_G.EspTab:Toggle({
    Title = "Láser Azul Neón (Consolas)",
    Callback = function(s) Config.Consoles.Beams = s end
})

-- 2. TICKETS
_G.EspTab:Toggle({
    Title = "🎟️ ESP Tickets",
    Callback = function(s) 
        Config.Tickets.Enabled = s 
        if not s then _G.LimpiarArcade("Tickets") end
    end
})

_G.EspTab:Toggle({
    Title = "Láser Verde Neón (Tickets)",
    Callback = function(s) Config.Tickets.Beams = s end
})


-- --- [ MOTOR VISUAL (Copia optimizada para Arcade) ] ---

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Función global para limpiar (por si quieres llamarla desde otro lado)
_G.LimpiarArcade = function(tipo)
    local targetFolder
    if tipo == "Consoles" then targetFolder = workspace:FindFirstChild("ArcadeEventConsoles") end
    if tipo == "Tickets" then targetFolder = workspace:FindFirstChild("ArcadeEventTickets") end

    if targetFolder then
        for _, item in pairs(targetFolder:GetChildren()) do
            if item:FindFirstChild("A_Esp") then item.A_Esp:Destroy() end -- Highlight
            if item:FindFirstChild("A_Gui") then item.A_Gui:Destroy() end -- Texto
            
            local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
            if part and part:FindFirstChild("A_Beam") then part.A_Beam:Destroy() end
        end
    end
end

local function AplicarVisualesArcade(model, color, texto)
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    -- 1. Highlight (Aura)
    if not model:FindFirstChild("A_Esp") then
        local hl = Instance.new("Highlight", model)
        hl.Name = "A_Esp"
        hl.FillColor = color
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
    end

    -- 2. Texto
    if not model:FindFirstChild("A_Gui") then
        local bg = Instance.new("BillboardGui", model)
        bg.Name = "A_Gui"; bg.Size = UDim2.new(0,120,0,40); bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, part.Size.Y + 2.5, 0); bg.Adornee = part
        
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color; lbl.TextStrokeTransparency = 0.5
        lbl.TextStrokeColor3 = Color3.new(0,0,0)
        lbl.Font = Enum.Font.GothamBlack; lbl.TextSize = 14
        lbl.Text = texto
    end
end

local function ManejarBeamArcade(model, color, enabled)
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    local myRoot = GetRoot()
    if not part or not myRoot then return end

    local beam = part:FindFirstChild("A_Beam")
    if enabled then
        local attP = myRoot:FindFirstChild("A_Att") or Instance.new("Attachment", myRoot)
        attP.Name = "A_Att"
        
        local attT = part:FindFirstChild("A_Att") or Instance.new("Attachment", part)
        attT.Name = "A_Att"

        if not beam then
            beam = Instance.new("Beam", part)
            beam.Name = "A_Beam"
            beam.Attachment0 = attP; beam.Attachment1 = attT
            beam.Color = ColorSequence.new(color)
            beam.Width0 = 0.15; beam.Width1 = 0.15
            beam.FaceCamera = true
            beam.LightEmission = 1 -- Efecto Neón
            beam.Texture = "" -- Sólido
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
            
            -- A) LÓGICA CONSOLAS
            if Config.Consoles.Enabled then
                local folder = workspace:FindFirstChild("ArcadeEventConsoles")
                if folder then
                    for _, item in pairs(folder:GetChildren()) do
                        if item:IsA("Model") then
                            -- Color AZUL CIAN (Cyan) para tecnología
                            AplicarVisualesArcade(item, Color3.fromRGB(0, 255, 255), "🎮 Consola")
                            ManejarBeamArcade(item, Color3.fromRGB(0, 255, 255), Config.Consoles.Beams)
                        end
                    end
                end
            end

            -- B) LÓGICA TICKETS
            if Config.Tickets.Enabled then
                local folder = workspace:FindFirstChild("ArcadeEventTickets")
                if folder then
                    for _, item in pairs(folder:GetChildren()) do
                        -- Detectamos cualquier cosa que sea un modelo o parte
                        if item:IsA("Model") or item:IsA("BasePart") then
                            -- Color VERDE LIMA para items de valor
                            AplicarVisualesArcade(item, Color3.fromRGB(0, 255, 100), "🎟️ Ticket")
                            ManejarBeamArcade(item, Color3.fromRGB(0, 255, 100), Config.Tickets.Beams)
                        end
                    end
                end
            end

        end
        task.wait(0.2) -- Loop relajado
    end
end)
