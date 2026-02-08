--[[
    MODULE: ULTRA PRECISION ESP & BEAM SYSTEM (V2)
    FEATURES: Persistent Attachments, Auto-Rebuild on Death, 0.1s Scan
]]

local Section = _G.EspTab:Section({ Title = "Rastreador de Élite (Beam System)" })
local Player = game.Players.LocalPlayer

local Settings = {
    Enabled = false,
    Beams = false,
    MinLevel = 0,
    RefreshRate = 0.1
}

local SelectedModels = {}
local Assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Brainrots")

-- --- [ FUNCIONES DE UTILIDAD ] ---
local function GetPlayerRoot()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function LimpiarVisuales(br)
    if br:FindFirstChild("VVisual") then br.VVisual:Destroy() end
    if br:FindFirstChild("VInfo") then br.VInfo:Destroy() end
    if br:FindFirstChild("VAttach") then br.VAttach:Destroy() end
    
    local root = GetPlayerRoot()
    if root then
        local beam = root:FindFirstChild("Beam_" .. br.Name)
        if beam then beam:Destroy() end
    end
end

-- --- [ INTERFAZ ] ---
Section:Toggle({
    Title = "Activar ESP",
    Callback = function(s) Settings.Enabled = s end
})

Section:Toggle({
    Title = "Activar Beams Rojos",
    Callback = function(s) 
        Settings.Beams = s 
        if not s then
            local root = GetPlayerRoot()
            if root then
                for _, v in pairs(root:GetChildren()) do
                    if v.Name:find("Beam_") or v.Name == "ESP" then v:Destroy() end
                end
            end
        end
    end
})

Section:Slider({
    Title = "Nivel Mínimo",
    Min = 0, Max = 1000, Default = 0,
    Callback = function(v) Settings.MinLevel = math.floor(v) end
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
    Title = "Objetivos",
    Multi = true,
    Values = {},
    Callback = function(val) SelectedModels = val end
})

Section:Button({ Title = "Refrescar Modelos", Callback = ActualizarDB })
ActualizarDB()

-- --- [ MOTOR LÓGICO DE ALTA VELOCIDAD ] ---
task.spawn(function()
    while true do
        local root = GetPlayerRoot()
        
        if Settings.Enabled and root then
            -- 1. Gestión del Attachment del Jugador (Persistencia)
            local attPlayer = root:FindFirstChild("ESP")
            if Settings.Beams and not attPlayer then
                attPlayer = Instance.new("Attachment", root)
                attPlayer.Name = "ESP"
            end

            local ActiveFolder = workspace:FindFirstChild("ActiveBrainrots")
            if ActiveFolder then
                for _, rareza in pairs(ActiveFolder:GetChildren()) do
                    local container = rareza:FindFirstChild("RenderedBrainrot") or rareza
                    
                    for _, br in pairs(container:GetChildren()) do
                        if br:IsA("Model") and table.find(SelectedModels, br.Name) then
                            pcall(function()
                                local brRoot = br.PrimaryPart or br:FindFirstChildWhichIsA("BasePart")
                                local stats = br.ModelExtents.StatsGui.Frame
                                local lvl = tonumber(stats.Level.Text:match("%d+")) or 0
                                
                                if lvl >= Settings.MinLevel then
                                    -- Highlight
                                    if not br:FindFirstChild("VVisual") then
                                        local hl = Instance.new("Highlight", br)
                                        hl.Name = "VVisual"; hl.FillColor = Color3.new(1,0,0)
                                    end

                                    -- Billboard
                                    if not br:FindFirstChild("VInfo") then
                                        local bg = Instance.new("BillboardGui", br)
                                        bg.Name = "VInfo"; bg.Size = UDim2.new(0,140,0,50); bg.AlwaysOnTop = true; bg.StudsOffset = Vector3.new(0,4,0)
                                        local tl = Instance.new("TextLabel", bg)
                                        tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.new(1,1,1); tl.RichText = true
                                    end
                                    br.VInfo.TextLabel.Text = "<b>"..br.Name.."</b>\n<font color='#ff0000'>Lv: "..lvl.."</font>"

                                    -- Sistema de Beams con Re-conexión
                                    if Settings.Beams and attPlayer then
                                        local attBR = br:FindFirstChild("VAttach") or Instance.new("Attachment", brRoot)
                                        attBR.Name = "VAttach"

                                        local beam = root:FindFirstChild("Beam_" .. br.Name)
                                        if not beam then
                                            beam = Instance.new("Beam", root)
                                            beam.Name = "Beam_" .. br.Name
                                            beam.Color = ColorSequence.new(Color3.new(1, 0, 0))
                                            beam.Width0, beam.Width1 = 0.2, 0.2
                                            beam.FaceCamera = true
                                            beam.Attachment0 = attPlayer
                                            beam.Attachment1 = attBR
                                        elseif beam.Attachment0 ~= attPlayer then
                                            -- Si el attachment cambió (por muerte), re-conectar
                                            beam.Attachment0 = attPlayer
                                        end
                                    else
                                        local b = root:FindFirstChild("Beam_" .. br.Name)
                                        if b then b:Destroy() end
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
        elseif not Settings.Enabled then
            -- Limpieza total si se apaga el ESP
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "VVisual" or v.Name == "VInfo" or v.Name == "VAttach" then v:Destroy() end
            end
            if root then
                for _, v in pairs(root:GetChildren()) do
                    if v.Name:find("Beam_") or v.Name == "ESP" then v:Destroy() end
                end
            end
        end
        task.wait(Settings.RefreshRate)
    end
end)
