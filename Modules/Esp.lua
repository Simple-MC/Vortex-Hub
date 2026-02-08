--[[
    MODULE: ELITE ESP SYSTEM
    FEATURES: Tracers, Highlights, Distance, Live Stats, Advanced Filtering
]]

local Section = _G.EspTab:Section({ Title = "Rastreador Avanzado de Brainrots" })
local Settings = {
    Enabled = false,
    Tracers = false,
    MinLevel = 0,
    MinRate = 0,
    RefreshRate = 0.3,
    MaxDistance = 5000
}

local SelectedModels = {}
local ActiveObjects = {}
local Assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Brainrots")
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- --- [ UTILIDADES ] ---
local function LimpiarVisuales(br)
    if br:FindFirstChild("VVisual") then br.VVisual:Destroy() end
    if br:FindFirstChild("VInfo") then br.VInfo:Destroy() end
    if br:FindFirstChild("VTracer") then br.VTracer:Destroy() end
end

-- --- [ UI DE CONTROL ] ---
Section:Toggle({
    Title = "Activar Sistema ESP",
    Callback = function(s) Settings.Enabled = s end
})

Section:Toggle({
    Title = "Mostrar Tracers (Líneas)",
    Callback = function(s) Settings.Tracers = s end
})

Section:Slider({
    Title = "Nivel Mínimo",
    Min = 0, Max = 1000, Default = 0,
    Callback = function(v) Settings.MinLevel = v end
})

local BrainrotDropdown
local function ActualizarLista()
    local Rarezas = {}
    local TodosLosModelos = {}
    for _, f in pairs(Assets:GetChildren()) do
        for _, m in pairs(f:GetChildren()) do table.insert(TodosLosModelos, m.Name) end
    end
    if BrainrotDropdown then BrainrotDropdown:Refresh(TodosLosModelos, {}) end
end

BrainrotDropdown = Section:Dropdown({
    Title = "Seleccionar Objetivos",
    Multi = true,
    Values = {},
    Callback = function(val) SelectedModels = val end
})

Section:Button({ Title = "Refrescar Base de Datos", Callback = ActualizarLista })
ActualizarLista() -- Carga inicial

-- --- [ MOTOR LÓGICO (100% POWER) ] ---
task.spawn(function()
    while true do
        if Settings.Enabled then
            local ActiveFolder = workspace:FindFirstChild("ActiveBrainrots")
            if ActiveFolder then
                for _, group in pairs(ActiveFolder:GetChildren()) do
                    local container = group:FindFirstChild("RenderedBrainrot") or group
                    
                    for _, br in pairs(container:GetChildren()) do
                        if br:IsA("Model") and table.find(SelectedModels, br.Name) then
                            pcall(function()
                                local root = br.PrimaryPart or br:FindFirstChildWhichIsA("BasePart")
                                local stats = br.ModelExtents.StatsGui.Frame
                                local lvl = tonumber(stats.Level.Text:match("%d+")) or 0
                                local rate = tonumber(stats.Rate.Text:match("%d+")) or 0
                                local dist = math.floor((Player.Character.HumanoidRootPart.Position - root.Position).Magnitude)

                                -- Filtros Avanzados
                                if lvl >= Settings.MinLevel and dist <= Settings.MaxDistance then
                                    -- 1. Aura (Highlight)
                                    if not br:FindFirstChild("VVisual") then
                                        local hl = Instance.new("Highlight", br)
                                        hl.Name = "VVisual"
                                        hl.FillColor = (lvl > 100) and Color3.new(1, 0.5, 0) or Color3.new(1, 0, 0)
                                        hl.OutlineColor = Color3.new(1, 1, 1)
                                    end

                                    -- 2. Billboard de Información
                                    if not br:FindFirstChild("VInfo") then
                                        local bg = Instance.new("BillboardGui", br)
                                        bg.Name = "VInfo"; bg.Size = UDim2.new(0,180,0,70); bg.AlwaysOnTop = true
                                        bg.StudsOffset = Vector3.new(0, 4, 0)
                                        local tl = Instance.new("TextLabel", bg)
                                        tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.new(1,1,1)
                                        tl.TextStrokeTransparency = 0; tl.RichText = true; tl.TextSize = 14
                                    end
                                    br.VInfo.TextLabel.Text = string.format("<b>%s</b>\n<font color='#ffaa00'>Lv: %s</font> | <font color='#00ff00'>$%s</font>\n📍 %s studs", br.Name, lvl, rate, dist)

                                    -- 3. Tracers (Líneas de Seguimiento)
                                    if Settings.Tracers then
                                        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                                        if onScreen then
                                            local tracer = br:FindFirstChild("VTracer") or Instance.new("Frame", game.CoreGui:FindFirstChildWhichIsA("ScreenGui"))
                                            if not br:FindFirstChild("VTracer") then
                                                tracer.Name = "VTracer"; tracer.AnchorPoint = Vector2.new(0.5, 0.5)
                                                tracer.BackgroundColor3 = Color3.new(1, 0, 0); tracer.BorderSizePixel = 0
                                                local folder = Instance.new("ObjectValue", br); folder.Name = "VTracer"; folder.Value = tracer
                                            end
                                            local startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                            local endPos = Vector2.new(screenPos.X, screenPos.Y)
                                            local distance = (endPos - startPos).Magnitude
                                            tracer.Position = UDim2.new(0, (startPos.X + endPos.X) / 2, 0, (startPos.Y + endPos.Y) / 2)
                                            tracer.Size = UDim2.new(0, distance, 0, 1.5)
                                            tracer.Rotation = math.deg(math.atan2(endPos.Y - startPos.Y, endPos.X - startPos.X))
                                            tracer.Visible = true
                                        end
                                    else
                                        if br:FindFirstChild("VTracer") then br.VTracer.Value.Visible = false end
                                    end
                                else
                                    LimpiarVisuales(br)
                                end
                            end)
                        else
                            LimpiarVisuales(br)
                        end
                    end
                end
            end
        else
            for _, v in pairs(workspace:GetDescendants()) do if v.Name == "VVisual" or v.Name == "VInfo" then v:Destroy() end end
        end
        task.wait(Settings.RefreshRate)
    end
end)
