--[[
    MODULE: ESP (Brainrot Tracking)
    FEATURE: Multi-Select Highlight, Name, Level & Rate
]]

local Section = _G.EspTab:Section({ Title = "Rastreo de Brainrots" })

-- Variables de estado
local SelectedModels = {}
local ESP_Enabled = false
local ReplicatedAssets = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Brainrots")

-- 1. DROPDOWNS DINÁMICOS
local BrainrotDropdown
local RarezasList = {}

-- Obtener las rarezas de ReplicatedStorage
for _, folder in pairs(ReplicatedAssets:GetChildren()) do
    table.insert(RarezasList, folder.Name)
end

-- Dropdown de Rarezas (Maestro)
Section:Dropdown({
    Title = "1. Filtrar por Rareza",
    Multi = true,
    Values = RarezasList,
    Callback = function(selectedRarezas)
        local NuevosModelos = {}
        for _, rarezaName in pairs(selectedRarezas) do
            local folder = ReplicatedAssets:FindFirstChild(rarezaName)
            if folder then
                for _, model in pairs(folder:GetChildren()) do
                    if not table.find(NuevosModelos, model.Name) then
                        table.insert(NuevosModelos, model.Name)
                    end
                end
            end
        end
        -- Refrescar el segundo dropdown
        if BrainrotDropdown then
            BrainrotDropdown:Refresh(NuevosModelos, {})
        end
    end
})

-- Dropdown de Modelos (Dinámico)
BrainrotDropdown = Section:Dropdown({
    Title = "2. Seleccionar Brainrots",
    Multi = true,
    Values = {},
    Callback = function(val)
        SelectedModels = val
    end
})

-- Toggle Principal
Section:Toggle({
    Title = "ACTIVAR ESP (Aura Roja)",
    Callback = function(state)
        ESP_Enabled = state
        if not state then
            -- Limpiar visuales al apagar
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "VortexVisual" or v.Name == "VortexInfo" then
                    v:Destroy()
                end
            end
        end
    end
})

-- 2. BUCLE DE RENDERIZADO (Multi-Target)
task.spawn(function()
    while true do
        if ESP_Enabled then
            local ActiveFolder = workspace:FindFirstChild("ActiveBrainrots")
            if ActiveFolder then
                for _, rarezaGroup in pairs(ActiveFolder:GetChildren()) do
                    -- Detectar dónde están los modelos
                    local targets = rarezaGroup:FindFirstChild("RenderedBrainrot") and rarezaGroup.RenderedBrainrot:GetChildren() or rarezaGroup:GetChildren()

                    for _, brainrot in pairs(targets) do
                        if brainrot:IsA("Model") and table.find(SelectedModels, brainrot.Name) then
                            
                            -- A) Aura Roja (Highlight)
                            if not brainrot:FindFirstChild("VortexVisual") then
                                local hl = Instance.new("Highlight", brainrot)
                                hl.Name = "VortexVisual"
                                hl.FillColor = Color3.fromRGB(255, 0, 0)
                                hl.OutlineColor = Color3.new(1, 1, 1)
                                hl.FillTransparency = 0.5
                            end

                            -- B) Interfaz de Texto (BillboardGui)
                            local info = brainrot:FindFirstChild("VortexInfo")
                            if not info then
                                local head = brainrot:FindFirstChild("Head") or brainrot.PrimaryPart or brainrot:FindFirstChildWhichIsA("BasePart")
                                if head then
                                    info = Instance.new("BillboardGui", brainrot)
                                    info.Name = "VortexInfo"
                                    info.Adornee = head
                                    info.AlwaysOnTop = true
                                    info.Size = UDim2.new(0, 160, 0, 60)
                                    info.StudsOffset = Vector3.new(0, 4, 0)

                                    local label = Instance.new("TextLabel", info)
                                    label.Size = UDim2.new(1, 0, 1, 0)
                                    label.BackgroundTransparency = 1
                                    label.TextColor3 = Color3.new(1, 1, 1)
                                    label.TextStrokeTransparency = 0
                                    label.TextSize = 15
                                    label.RichText = true
                                end
                            end

                            -- C) Actualización de Datos en Vivo
                            if info then
                                pcall(function()
                                    local stats = brainrot.ModelExtents.StatsGui.Frame
                                    local lvl = stats.Level.Text
                                    local money = stats.Rate.Text
                                    
                                    info.TextLabel.Text = string.format(
                                        "<b>%s</b>\n<font color='#ff0000'>Lv: %s</font> | <font color='#00ff00'>$%s</font>",
                                        brainrot.Name, lvl, money
                                    )
                                end)
                            end
                        else
                            -- Si ya no está en la lista o desapareció, borrar visuales
                            if brainrot:FindFirstChild("VortexVisual") then brainrot.VortexVisual:Destroy() end
                            if brainrot:FindFirstChild("VortexInfo") then brainrot.VortexInfo:Destroy() end
                        end
                    end
                end
            end
        end
        task.wait(0.4) -- Frecuencia de escaneo
    end
end)
