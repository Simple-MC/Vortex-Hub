--[[
    MODULE: VISUALS (ESP)
    FEATURE: Multi-Target Tracking & High Performance
]]

local Section = _G.EspTab:Section({ Title = "Rastreo de Brainrots" })

local SelectedModels = {}
local ESP_Enabled = false
local ReplicatedAssets = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Brainrots")

-- Dropdowns Dinámicos
local BrainrotDropdown
local ListaRarezas = {}
for _, folder in pairs(ReplicatedAssets:GetChildren()) do table.insert(ListaRarezas, folder.Name) end

Section:Dropdown({
    Title = "1. Filtrar por Rareza",
    Multi = true,
    Values = ListaRarezas,
    Callback = function(val)
        local NuevosModelos = {}
        for _, rareza in pairs(val) do
            local f = ReplicatedAssets:FindFirstChild(rareza)
            if f then for _, m in pairs(f:GetChildren()) do table.insert(NuevosModelos, m.Name) end end
        end
        if BrainrotDropdown then BrainrotDropdown:Refresh(NuevosModelos, {}) end
    end
})

BrainrotDropdown = Section:Dropdown({
    Title = "2. Seleccionar Brainrots",
    Multi = true,
    Values = {},
    Callback = function(val) SelectedModels = val end
})

Section:Toggle({
    Title = "Activar ESP Total",
    Callback = function(state) 
        ESP_Enabled = state 
        if not state then
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "VortexVisual" or v.Name == "VortexInfo" then v:Destroy() end
            end
        end
    end
})

-- BUCLE OPTIMIZADO: Muestra TODOS los seleccionados
task.spawn(function()
    while true do
        if ESP_Enabled then
            local ActiveFolder = workspace:FindFirstChild("ActiveBrainrots")
            if ActiveFolder then
                -- Escaneamos todas las carpetas de rarezas en Workspace
                for _, rarezaGroup in pairs(ActiveFolder:GetChildren()) do
                    local container = rarezaGroup:FindFirstChild("RenderedBrainrot") or rarezaGroup
                    
                    for _, brainrot in pairs(container:GetChildren()) do
                        if brainrot:IsA("Model") and table.find(SelectedModels, brainrot.Name) then
                            -- Crear Highlight si no existe
                            if not brainrot:FindFirstChild("VortexVisual") then
                                local hl = Instance.new("Highlight", brainrot)
                                hl.Name = "VortexVisual"
                                hl.FillColor = Color3.fromRGB(255, 0, 0)
                                hl.OutlineColor = Color3.new(1, 1, 1)
                                hl.FillTransparency = 0.4
                            end

                            -- Crear/Actualizar Billboard
                            local ui = brainrot:FindFirstChild("VortexInfo")
                            if not ui then
                                local head = brainrot:FindFirstChild("Head") or brainrot.PrimaryPart or brainrot:FindFirstChildWhichIsA("BasePart")
                                if head then
                                    ui = Instance.new("BillboardGui", brainrot)
                                    ui.Name = "VortexInfo"; ui.Adornee = head; ui.AlwaysOnTop = true
                                    ui.Size = UDim2.new(0, 200, 0, 100); ui.StudsOffset = Vector3.new(0, 4, 0)
                                    local l = Instance.new("TextLabel", ui)
                                    l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1; l.TextColor3 = Color3.new(1,1,1)
                                    l.TextStrokeTransparency = 0; l.RichText = true; l.TextSize = 14
                                end
                            end

                            -- Actualizar Stats en tiempo real
                            if ui then
                                pcall(function()
                                    local ext = brainrot:FindFirstChild("ModelExtents")
                                    local s = ext and ext.StatsGui.Frame
                                    local t = ext and ext.TimerGui.TimeLeft
                                    ui.TextLabel.Text = string.format("<b>%s</b>\n<font color='#ff0000'>Lvl: %s</font> | <font color='#00ff00'>$ %s</font>\n⏳ %s", 
                                    brainrot.Name, s.Level.Text, s.Rate.Text, t.TimeLeft.Text)
                                end)
                            end
                        else
                            -- Limpiar si ya no está seleccionado
                            if brainrot:FindFirstChild("VortexVisual") then brainrot.VortexVisual:Destroy() end
                            if brainrot:FindFirstChild("VortexInfo") then brainrot.VortexInfo:Destroy() end
                        end
                    end
                end
            end
        end
        task.wait(0.3) -- Escaneo rápido para no perderse nada
    end
end)
