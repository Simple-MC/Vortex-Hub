--[[
    MODULE: ESP BRAINROTS
    FEATURE: Auto-Update Dropdowns, Highlights, Stats Display
]]

local Section = _G.EspTab:Section({ Title = "Configuración ESP" })

-- Variables de Estado
local SelectedRarezas = {}
local SelectedModels = {}
local ESP_Enabled = false

-- Referencias
local ReplicatedAssets = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Brainrots")

-- 1. Obtener Lista de Rarezas
local ListaRarezas = {}
for _, folder in pairs(ReplicatedAssets:GetChildren()) do
    table.insert(ListaRarezas, folder.Name)
end

local BrainrotDropdown -- Declaración anticipada

-- 2. Dropdown de Rarezas (Controlador)
Section:Dropdown({
    Title = "1. Filtrar por Rareza",
    Multi = true,
    Values = ListaRarezas,
    Callback = function(val)
        SelectedRarezas = val
        
        -- Buscar modelos en las rarezas seleccionadas
        local NuevosModelos = {}
        for _, rarezaName in pairs(SelectedRarezas) do
            local folder = ReplicatedAssets:FindFirstChild(rarezaName)
            if folder then
                for _, model in pairs(folder:GetChildren()) do
                    if not table.find(NuevosModelos, model.Name) then
                        table.insert(NuevosModelos, model.Name)
                    end
                end
            end
        end
        
        -- Refrescar el segundo menú automáticamente
        if BrainrotDropdown then
            BrainrotDropdown:Refresh(NuevosModelos, {})
        end
    end
})

-- 3. Dropdown de Modelos (Dinámico)
BrainrotDropdown = Section:Dropdown({
    Title = "2. Seleccionar Brainrots",
    Multi = true,
    Values = {}, -- Inicia vacío
    Callback = function(val)
        SelectedModels = val
    end
})

-- Toggle Activador
Section:Toggle({
    Title = "ACTIVAR ESP (Speed Hub Style)",
    Callback = function(state)
        ESP_Enabled = state
        if not state then
            -- Limpieza al desactivar
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "VortexVisual" or v.Name == "VortexInfo" then v:Destroy() end
            end
        end
    end
})

-- 4. Bucle Visual (Highlight + BillboardGui)
task.spawn(function()
    while true do
        if ESP_Enabled then
            local ActiveFolder = workspace:FindFirstChild("ActiveBrainrots")
            if ActiveFolder then
                for _, rarezaGroup in pairs(ActiveFolder:GetChildren()) do
                    -- Detectar dónde están los modelos (carpeta directa o RenderedBrainrot)
                    local targets = {}
                    if rarezaGroup:FindFirstChild("RenderedBrainrot") then
                        targets = rarezaGroup.RenderedBrainrot:GetChildren()
                    else
                        targets = rarezaGroup:GetChildren()
                    end

                    for _, brainrot in pairs(targets) do
                        if brainrot:IsA("Model") and table.find(SelectedModels, brainrot.Name) then
                            
                            -- A) HIGHLIGHT (Aura Roja)
                            if not brainrot:FindFirstChild("VortexVisual") then
                                local hl = Instance.new("Highlight", brainrot)
                                hl.Name = "VortexVisual"
                                hl.FillColor = Color3.fromRGB(255, 0, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.5
                                hl.OutlineTransparency = 0
                            end

                            -- B) INFO GUI (Stats Flotantes)
                            if not brainrot:FindFirstChild("VortexInfo") then
                                local head = brainrot:FindFirstChild("Head") or brainrot.PrimaryPart or brainrot:FindFirstChildWhichIsA("BasePart")
                                if head then
                                    local bgui = Instance.new("BillboardGui", brainrot)
                                    bgui.Name = "VortexInfo"
                                    bgui.Adornee = head
                                    bgui.Size = UDim2.new(0, 200, 0, 100)
                                    bgui.StudsOffset = Vector3.new(0, 4.5, 0)
                                    bgui.AlwaysOnTop = true

                                    local label = Instance.new("TextLabel", bgui)
                                    label.Size = UDim2.new(1, 0, 1, 0)
                                    label.BackgroundTransparency = 1
                                    label.TextColor3 = Color3.new(1, 1, 1)
                                    label.TextStrokeTransparency = 0
                                    label.TextSize = 14
                                    label.RichText = true
                                    label.Text = "..."
                                end
                            end

                            -- C) ACTUALIZAR DATOS
                            local ui = brainrot:FindFirstChild("VortexInfo")
                            if ui and ui:FindFirstChild("TextLabel") then
                                pcall(function()
                                    local extents = brainrot:FindFirstChild("ModelExtents")
                                    local stats = extents and extents:FindFirstChild("StatsGui") and extents.StatsGui.Frame
                                    local timer = extents and extents:FindFirstChild("TimerGui") and extents.TimerGui.TimeLeft

                                    local lvl = stats and stats:FindFirstChild("Level") and stats.Level.Text or "?"
                                    local rate = stats and stats:FindFirstChild("Rate") and stats.Rate.Text or "?"
                                    local time = timer and timer:FindFirstChild("TimeLeft") and timer.TimeLeft.Text or "∞"

                                    ui.TextLabel.Text = string.format(
                                        '<font size="18"><b>%s</b></font>\n<font color="#FF0000">LVL: %s</font> | <font color="#00FF00">$ %s</font>\n⏳ %s',
                                        brainrot.Name, lvl, rate, time
                                    )
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)
