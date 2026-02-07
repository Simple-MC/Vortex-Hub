-- Modules/Visuals.lua
local CelestialParagraph = _G.MainTab:Paragraph({
    Title = "Buscando Celestial...",
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
local function buscar()
    local m = workspace:FindFirstChild("EventTimers")
    if not m then return end
    for _, p in pairs(m:GetChildren()) do
        local f = p:FindFirstChildOfClass("SurfaceGui") and p.SurfaceGui:FindFirstChildOfClass("Frame")
        if f then
            local t1 = f:FindFirstChild("TextLabel")
            if t1 and string.find(string.upper(t1.Text), "CELESTIAL") then lC = t1 end
            local t2 = f:FindFirstChild("TextLabel2")
            if t2 and t2.Text ~= "" then lD = t2 end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not lC or not lC.Parent then buscar() end
    if lC then CelestialParagraph:SetTitle(lC.Text) end
    if lD then DynamicEventParagraph:SetTitle(lD.Text) end
end)
