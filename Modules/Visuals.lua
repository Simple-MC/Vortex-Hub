-- Modules/Visuals.lua
local CelestialParagraph = _G.MainTab:Paragraph({
    Title = "Buscando Evento Principal...",
    Content = "Esperando datos...",
    Icon = "lucide-timer"
})
local DynamicEventParagraph = _G.MainTab:Paragraph({
    Title = "Buscando Evento...",
    Content = "Esperando datos...",
    Icon = "lucide-clock"
})

local RunService = game:GetService("RunService")
local lC, lD

-- Función para quitar las etiquetas <font> y que se vea limpio en tu Hub
local function LimpiarTexto(texto)
    return string.gsub(texto, "<[^>]+>", "")
end

local function buscar()
    local m = workspace:FindFirstChild("EventTimers")
    if not m then return end
    
    for _, p in pairs(m:GetChildren()) do
        local f = p:FindFirstChildOfClass("SurfaceGui") and p.SurfaceGui:FindFirstChildOfClass("Frame")
        if f then
            local t1 = f:FindFirstChild("TextLabel")
            -- Buscamos BRAINROT o CELESTIAL por si el evento cambia
            if t1 then
                local textoMayusculas = string.upper(t1.Text)
                if string.find(textoMayusculas, "CELESTIAL") or string.find(textoMayusculas, "BRAINROT") then 
                    lC = t1 
                end
            end
            
            local t2 = f:FindFirstChild("TextLabel2")
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
