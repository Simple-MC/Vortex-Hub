--[[ MODULE: COMBAT (GOD MODE & BORDERS) ]]

local Section = _G.CombatTab:Section({ Title = "Supervivencia y Mapas" })

local AlmacenTemporal = game:GetService("Lighting")
local GodModeEnabled = false
local OriginalParents = {}
local OriginalMudData = {}
local ActiveBorders = {} -- Lista para guardar las partes creadas

-- Configuración EXACTA de tus bordes (No toqué ni un número)
local configBordes = {
    {nombre = "B1", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1177, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "B2", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1917, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "B3", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1177, -2, -136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "B4", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1917, -2, -136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde5", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1177, -2, 136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde6", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1179, 0, 143.5, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde7", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1917, -2, 135.5, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde8", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1917, 0, 144, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde9", size = Vector3.new(6, 90, 284), cf = CFrame.new(2938, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)}
}

-- Función segura para mover objetos
local function SafeMove(obj, newParent)
    if obj and obj.Parent ~= newParent then
        if not OriginalParents[obj] then
            OriginalParents[obj] = obj.Parent
        end
        obj.Parent = newParent
    end
end

-- Función para restaurar todo
local function RestoreAll()
    -- Restaurar padres
    for obj, parent in pairs(OriginalParents) do
        pcall(function()
            if obj then obj.Parent = parent end
        end)
    end
    OriginalParents = {}
    
    -- Restaurar Lodo
    for obj, data in pairs(OriginalMudData) do
        pcall(function()
            if obj then
                obj.Size = data.Size
                obj.CFrame = data.CFrame
            end
        end)
    end
    OriginalMudData = {}

    -- Destruir Bordes
    for _, part in pairs(ActiveBorders) do
        if part then part:Destroy() end
    end
    ActiveBorders = {}
end

Section:Toggle({
    Title = "🛡️ Activar God Mode (Bordes + Clean)",
    Callback = function(state)
        GodModeEnabled = state
        
        if state then
            -- 1. CREAR BORDES INMEDIATAMENTE
            for _, d in ipairs(configBordes) do
                local p = Instance.new("Part", workspace)
                p.Name = d.nombre
                p.Size = d.size
                p.CFrame = d.cf
                p.Anchored = true
                p.CanCollide = true
                p.Color = Color3.fromRGB(255, 0, 0)
                p.Material = Enum.Material.Neon
                p.Transparency = 0.5
                table.insert(ActiveBorders, p) -- Guardar en lista para borrar luego
            end

            -- 2. BUCLE PARA MOVER COSAS (Clean Map)
            task.spawn(function()
                while GodModeEnabled do
                    pcall(function()
                        local W = workspace
                        
                        -- Arcade Map
                        if W:FindFirstChild("ArcadeMap") then
                            SafeMove(W.ArcadeMap:FindFirstChild("RightWalls"), AlmacenTemporal)
                        end
                        
                        -- Radioactive Map
                        if W:FindFirstChild("RadioactiveMap") then
                            SafeMove(W.RadioactiveMap:FindFirstChild("RightWalls"), AlmacenTemporal)
                        end
                        
                        -- Mars Map
                        if W:FindFirstChild("MarsMap") and W.MarsMap:FindFirstChild("Walls") then
                            -- Usa el índice 7 como pediste
                            local children = W.MarsMap.Walls:GetChildren()
                            if children[7] then SafeMove(children[7], AlmacenTemporal) end
                        end
                        
                        -- Money Map
                        if W:FindFirstChild("MoneyMap") and W.MoneyMap:FindFirstChild("DefaultStudioMap") then
                            SafeMove(W.MoneyMap.DefaultStudioMap:FindFirstChild("Walls"), AlmacenTemporal)
                            SafeMove(W.MoneyMap.DefaultStudioMap:FindFirstChild("RightWalls"), AlmacenTemporal)
                        end
                        
                        -- Default Map & Misc
                        if W:FindFirstChild("DefaultMap") then
                            SafeMove(W.DefaultMap:FindFirstChild("RightWalls"), AlmacenTemporal)
                        end
                        if W:FindFirstChild("Misc") then
                            SafeMove(W.Misc:FindFirstChild("BrickAddition"), AlmacenTemporal)
                        end

                        -- Lógica del Lodo (Mud) y Muros extra
                        local dMap = W:FindFirstChild("DefaultMap")
                        if dMap and dMap:FindFirstChild("Walls") then
                            local w = dMap.Walls
                            local c = w:GetChildren()
                            
                            if w:FindFirstChild("wall") then SafeMove(w.wall, AlmacenTemporal) end
                            if c[6] then SafeMove(c[6], AlmacenTemporal) end

                            -- Mud 1 (c[3])
                            if c[3] and c[3]:FindFirstChild("Mud") then
                                local m = c[3].Mud
                                if not OriginalMudData[m] then OriginalMudData[m] = {Size = m.Size, CFrame = m.CFrame} end
                                m.CFrame = CFrame.new(156, 50, -164) * CFrame.Angles(0, -1.57, -1.57)
                            end
                            
                            -- Mud 2 (c[4])
                            if c[4] and c[4]:FindFirstChild("Mud") then
                                local m = c[4].Mud
                                if not OriginalMudData[m] then OriginalMudData[m] = {Size = m.Size, CFrame = m.CFrame} end
                                m.Size = Vector3.new(100, 33, 6)
                                m.CFrame = CFrame.new(156, 50, 159.1) * CFrame.Angles(0, -1.57, -1.57)
                            end
                        end
                    end)
                    task.wait(0.5)
                end
            end)
        else
            RestoreAll()
        end
    end
})
