-- Modules/Visuals.lua
local CelestialParagraph = _G.MainTab:Paragraph({
    Title = "Buscando Evento Principal...",
    Content = "Esperando datos...",
    Icon = "timer"
})
local DynamicEventParagraph = _G.MainTab:Paragraph({
    Title = "Buscando Evento...",
    Content = "Esperando datos...",
    Icon = "clock"
})

local RunService = game:GetService("RunService")
local lC, lD

-- Función para quitar las etiquetas <font> y que se vea limpio en tu Hub
local function LimpiarTexto(texto)
    return string.gsub(texto, "<[^>]+>", "")
end

local function buscar()
    local gameObjects = workspace:FindFirstChild("GameObjects")
    if not gameObjects then return end
    
    local placeSpecific = gameObjects:FindFirstChild("PlaceSpecific")
    if not placeSpecific then return end
    
    local root = placeSpecific:FindFirstChild("root")
    if not root then return end
    
    local eventTimers = root:FindFirstChild("EventTimers")
    if not eventTimers then return end
    
    for _, p in pairs(eventTimers:GetChildren()) do
        local sGui = p:FindFirstChildOfClass("SurfaceGui")
        local frame = sGui and sGui:FindFirstChildOfClass("Frame")
        
        if frame then
            local t1 = frame:FindFirstChild("TextLabel")
            if t1 then
                local texto = string.upper(t1.Text)
                if string.find(texto, "CELESTIAL") or string.find(texto, "BRAINROT") then 
                    lC = t1 
                end
            end
            
            local t2 = frame:FindFirstChild("TextLabel2")
            if t2 and t2.Text ~= "" then 
                lD = t2 
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not lC or not lC.Parent then buscar() end
    
    -- Usamos LimpiarTexto para que no salgan los códigos de colores en el Hub
    if lC then 
        CelestialParagraph:SetTitle(LimpiarTexto(lC.Text)) 
    end
    if lD then 
        DynamicEventParagraph:SetTitle(LimpiarTexto(lD.Text)) 
    end
end)
