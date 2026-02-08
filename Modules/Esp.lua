--[[
    MODULE: ULTRA PRECISION ESP & BEAM SYSTEM
    FEATURES: 3D Beams, Attachment Tracking, 0.1s Scan, Fixed Slider
]]

local Section = _G.EspTab:Section({ Title = "Rastreador de Élite (Beam System)" })
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumRoot = Character:WaitForChild("HumanoidRootPart")

local Settings = {
    Enabled = false,
    Beams = false,
    MinLevel = 0,
    RefreshRate = 0.1 -- Velocidad máxima de escaneo
}

local SelectedModels = {}
local Assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Brainrots")

-- --- [ FUNCIONES DE LIMPIEZA ] ---
local function LimpiarTodo(br)
    if br:FindFirstChild("VVisual") then br.VVisual:Destroy() end
    if br:FindFirstChild("VInfo") then br.VInfo:Destroy() end
    if br:FindFirstChild("VAttach") then br.VAttach:Destroy() end
    local oldBeam = HumRoot:FindFirstChild("Beam_" .. br.Name)
    if oldBeam then oldBeam:Destroy() end
end

-- --- [ INTERFAZ DE USUARIO ] ---
Section:Toggle({
    Title = "Activar ESP",
    Callback = function(s) Settings.Enabled = s end
})

Section:Toggle({
    Title = "Activar Beams Rojos (Láser)",
    Callback = function(s) 
        Settings.Beams = s 
        if not s then
            for _, v in pairs(HumRoot:GetChildren()) do
                if v.Name:find("Beam_") then v:Destroy() end
            end
        end
    end
})

Section:Slider({
    Title = "Nivel Mínimo",
    Min = 0, Max = 1000, Default = 0,
    Callback = function(v) 
        Settings.MinLevel = math.floor(v) -- Corregido para que deslice bien
    end
})

local BrainrotDropdown
local function ActualizarDB()
    local Todos = {}
    for _, f in pairs(Assets:GetChildren()) do
        for _, m in pairs(f:GetChildren()) do table.insert(Todos, m.Name) end
    end
    if BrainrotDropdown then BrainrotDropdown:Refresh(Todos, {}) end
end

BrainrotDropdown = Section:Dropdown({
    Title = "Objetivos Seleccionados",
    Multi = true,
    Values = {},
    Callback = function(val) SelectedModels = val end
})

Section:Button({ Title = "Refrescar Modelos", Callback = ActualizarDB })
ActualizarDB()

-- --- [ MOTOR LÓGICO DE ALTA VELOCIDAD (0.1s) ] ---
task.spawn(function()
    while true do
        if Settings.Enabled then
            local ActiveFolder = workspace:FindFirstChild("ActiveBrainrots")
            if ActiveFolder then
                for _, rareza in pairs(ActiveFolder:GetChildren()) do
                    local container = rareza:FindFirstChild("RenderedBrainrot") or rareza
                    
                    for _, br in pairs(container:GetChildren()) do
                        if br:IsA("Model") and table.find(SelectedModels, br.Name) then
                            pcall(function()
                                local root = br.PrimaryPart or br:FindFirstChildWhichIsA("BasePart")
                                local stats = br.ModelExtents.StatsGui.Frame
                                local lvl = tonumber(stats.Level.Text:match("%d+")) or 0
                                
                                if lvl >= Settings.MinLevel then
                                    -- 1. Aura Roja
                                    if not br:FindFirstChild("VVisual") then
                                        local hl = Instance.new("Highlight", br)
                                        hl.Name = "VVisual"; hl.FillColor = Color3.new(1,0,0); hl.OutlineColor = Color3.new(1,1,1)
                                    end

                                    -- 2. GUI de Información
                                    if not br:FindFirstChild("VInfo") then
                                        local bg = Instance.new("BillboardGui", br)
                                        bg.Name = "VInfo"; bg.Size = UDim2.new(0,140,0,50); bg.AlwaysOnTop = true; bg.StudsOffset = Vector3.new(0,4,0)
                                        local tl = Instance.new("TextLabel", bg)
                                        tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.new(1,1,1); tl.TextSize = 14; tl.RichText = true
                                    end
                                    br.VInfo.TextLabel.Text = "<b>"..br.Name.."</b>\n<font color='#ff0000'>Lv: "..lvl.."</font>"

                                    -- 3. SISTEMA DE BEAMS (CONEXIÓN AL JUGADOR)
                                    if Settings.Beams then
                                        -- Attachment en el Brainrot
                                        local attBR = br:FindFirstChild("VAttach") or Instance.new("Attachment", root)
                                        attBR.Name = "VAttach"

                                        -- Attachment en el Jugador (si no existe)
                                        local attPlayer = HumRoot:FindFirstChild("PlayerAttach") or Instance.new("Attachment", HumRoot)
                                        attPlayer.Name = "PlayerAttach"

                                        -- Crear/Actualizar el Beam
                                        local beam = HumRoot:FindFirstChild("Beam_" .. br.Name)
                                        if not beam then
                                            beam = Instance.new("Beam", HumRoot)
                                            beam.Name = "Beam_" .. br.Name
                                            beam.Color = ColorSequence.new(Color3.new(1, 0, 0))
                                            beam.Width0 = 0.2
                                            beam.Width1 = 0.2
                                            beam.FaceCamera = true
                                            beam.Attachment0 = attPlayer
                                            beam.Attachment1 = attBR
                                        end
                                    else
                                        local b = HumRoot:FindFirstChild("Beam_" .. br.Name)
                                        if b then b:Destroy() end
                                    end
                                else
                                    LimpiarTodo(br)
                                end
                            end)
                        else
                            LimpiarTodo(br)
                        end
                    end
                end
            end
        else
            -- Apagado total
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "VVisual" or v.Name == "VInfo" or v.Name == "VAttach" then v:Destroy() end
            end
            for _, v in pairs(HumRoot:GetChildren()) do if v.Name:find("Beam_") then v:Destroy() end end
        end
        task.wait(Settings.RefreshRate)
    end
end)
