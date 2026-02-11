--[[ MODULE: COMBAT (GOD MODE & BORDERS) ]]

local Section = _G.CombatTab:Section({ Title = "Supervivencia y Mapa" })
local Trash = game:GetService("Lighting") -- Almacén temporal
local SavedParents = {}
local SavedMud = {}
local ActiveBorders = {}

-- Configuración de Bordes (Tus CFrames exactos)
local BorderConfig = {
    {s=Vector3.new(90, 2.7, 2048), c=CFrame.new(1177, 0, -143)},
    {s=Vector3.new(90, 2.7, 2048), c=CFrame.new(1917, 0, -143)},
    {s=Vector3.new(4, 13, 2048), c=CFrame.new(1177, -2, -136)},
    {s=Vector3.new(4, 13, 2048), c=CFrame.new(1917, -2, -136)},
    {s=Vector3.new(4, 13, 2048), c=CFrame.new(1177, -2, 136)},
    {s=Vector3.new(90, 2.7, 2048), c=CFrame.new(1179, 0, 143.5)},
    {s=Vector3.new(4, 13, 2048), c=CFrame.new(1917, -2, 135.5)},
    {s=Vector3.new(90, 2.7, 2048), c=CFrame.new(1917, 0, 144)},
    {s=Vector3.new(6, 90, 284), c=CFrame.new(2938, 0, 0)}
}

local function MoveToTrash(obj)
    if obj and obj.Parent ~= Trash then
        SavedParents[obj] = obj.Parent
        obj.Parent = Trash
    end
end

local function RestoreMap()
    for obj, parent in pairs(SavedParents) do pcall(function() obj.Parent = parent end) end
    for obj, data in pairs(SavedMud) do 
        pcall(function() obj.Size = data.s; obj.CFrame = data.c end) 
    end
    SavedParents, SavedMud = {}, {}
    for _, b in pairs(ActiveBorders) do b:Destroy() end
    ActiveBorders = {}
end

local GodMode = false
Section:Toggle({
    Title = "🛡️ Activar God Mode (Map Bypass)",
    Callback = function(state)
        GodMode = state
        if not state then RestoreMap() return end

        -- 1. CREAR BORDES
        for i, d in ipairs(BorderConfig) do
            local p = Instance.new("Part", workspace)
            p.Name = "VortexBorder_"..i; p.Size = d.s; p.CFrame = d.c
            p.Anchored = true; p.Transparency = 0.5; p.Color = Color3.fromRGB(255, 50, 50)
            p.Material = Enum.Material.Neon
            table.insert(ActiveBorders, p)
        end

        -- 2. BUCLE DE LIMPIEZA
        task.spawn(function()
            while GodMode do
                pcall(function()
                    local W = workspace
                    -- Limpieza General de Mapas
                    MoveToTrash(W:FindFirstChild("ArcadeMap") and W.ArcadeMap:FindFirstChild("RightWalls"))
                    MoveToTrash(W:FindFirstChild("RadioactiveMap") and W.RadioactiveMap:FindFirstChild("RightWalls"))
                    MoveToTrash(W:FindFirstChild("DefaultMap") and W.DefaultMap:FindFirstChild("RightWalls"))
                    
                    if W:FindFirstChild("MarsMap") and W.MarsMap:FindFirstChild("Walls") then
                        MoveToTrash(W.MarsMap.Walls:GetChildren()[7]) -- Pared específica
                    end
                    
                    if W:FindFirstChild("MoneyMap") then
                        MoveToTrash(W.MoneyMap.DefaultStudioMap.Walls)
                        MoveToTrash(W.MoneyMap.DefaultStudioMap.RightWalls)
                    end

                    -- Modificación Especial de Lodo (Mud)
                    local DM = W:FindFirstChild("DefaultMap")
                    if DM and DM:FindFirstChild("Walls") then
                        local walls = DM.Walls:GetChildren()
                        MoveToTrash(DM.Walls:FindFirstChild("wall"))
                        if walls[6] then MoveToTrash(walls[6]) end

                        -- Ajustar Lodos (Mud 3 y 4)
                        local m1, m2 = walls[3] and walls[3]:FindFirstChild("Mud"), walls[4] and walls[4]:FindFirstChild("Mud")
                        
                        if m1 then
                            if not SavedMud[m1] then SavedMud[m1] = {s=m1.Size, c=m1.CFrame} end
                            m1.CFrame = CFrame.new(156, 50, -164) * CFrame.Angles(0, -1.57, -1.57)
                        end
                        if m2 then
                            if not SavedMud[m2] then SavedMud[m2] = {s=m2.Size, c=m2.CFrame} end
                            m2.Size = Vector3.new(100, 33, 6)
                            m2.CFrame = CFrame.new(156, 50, 159.1) * CFrame.Angles(0, -1.57, -1.57)
                        end
                    end
                end)
                task.wait(0.5) -- Revisión cada medio segundo
            end
        end)
    end
})
