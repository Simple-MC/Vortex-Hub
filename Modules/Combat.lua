-- Modules/Combat.lua
local AlmacenTemporal = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local GodModeEnabled = false
local OriginalParents = {}
local OriginalMudData = {}
local BordesEstructura = {}

-- Función de movimiento seguro (Mueve cosas a Lighting para borrarlas temporalmente)
local function SafeMove(obj, newParent)
    if obj and not OriginalParents[obj] then
        OriginalParents[obj] = obj.Parent
    end
    if obj then obj.Parent = newParent end
end

-- Función para restaurar todo al apagar
local function RestoreAll()
    -- Restaurar padres (objetos movidos)
    for obj, parent in pairs(OriginalParents) do
        pcall(function() if obj then obj.Parent = parent end end)
    end
    OriginalParents = {}
    
    -- Restaurar datos de Mud
    for obj, data in pairs(OriginalMudData) do
        pcall(function()
            if obj then
                obj.Size = data.Size
                obj.CFrame = data.CFrame
            end
        end)
    end
    OriginalMudData = {}

    -- Restaurar VIP y Paredes modificadas (Lógica del VIP Free)
    pcall(function()
        local folders = {
            "DefaultMap_SharedInstances", "MoneyMap_SharedInstances", 
            "MarsMap_SharedInstances", "RadioactiveMap_SharedInstances", 
            "ArcadeMap_SharedInstances"
        }
        for _, folderName in pairs(folders) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, v in pairs(folder:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:find("VIP") or v.Name:find("Wall") or v.Name:find("Mud")) then
                        v.CanCollide = true
                        v.Transparency = 0
                    end
                end
            end
        end
    end)
end

-- Configuración de Bordes (Tus CFrames originales)
local configBordes = {
    {nombre = "B1", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1177, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "B2", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1917, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "B3", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1177, -2, -136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "B4", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1917, -2, -136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde5", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1177, -2, 136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde6", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1179, 0, 144, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde7", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1917, -2, 135.5, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde8", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1917, 0, 144, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde9", size = Vector3.new(6, 90, 284), cf = CFrame.new(2938, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)}
}

-- Toggle principal en la Tab de Combate
_G.AutoFarmTab:Toggle({
    Title = "Activate God Mode Total (+VIP)",
    Callback = function(state)
        GodModeEnabled = state
        
        if GodModeEnabled then
            -- Bucle de mantenimiento (God Mode + VIP + Limpieza)
            task.spawn(function()
                while GodModeEnabled do
                    pcall(function()
                        -- === PARTE 1: LIMPIEZA DE MAPAS (GOD MODE) ===
                        
                        -- Arcade
                        SafeMove(workspace:FindFirstChild("ArcadeMap") and workspace.ArcadeMap:FindFirstChild("RightWalls"), AlmacenTemporal)
                        -- Radioactive
                        SafeMove(workspace:FindFirstChild("RadioactiveMap") and workspace.RadioactiveMap:FindFirstChild("RightWalls"), AlmacenTemporal)
                        
                        -- Mars (AQUÍ ESTÁ LO DE DECO)
                        if workspace:FindFirstChild("MarsMap") then
                            if workspace.MarsMap:FindFirstChild("Walls") then
                                SafeMove(workspace.MarsMap.Walls:GetChildren()[7], AlmacenTemporal)
                            end
                            if workspace.MarsMap:FindFirstChild("Deco") then
                                SafeMove(workspace.MarsMap.Deco, AlmacenTemporal) -- <--- Deco eliminado
                            end
                        end

                        -- Money
                        if workspace:FindFirstChild("MoneyMap") and workspace.MoneyMap:FindFirstChild("DefaultStudioMap") then
                            SafeMove(workspace.MoneyMap.DefaultStudioMap:FindFirstChild("Walls"), AlmacenTemporal)
                            SafeMove(workspace.MoneyMap.DefaultStudioMap:FindFirstChild("RightWalls"), AlmacenTemporal)
                        end
                        -- Default & Shared
                        SafeMove(workspace:FindFirstChild("DefaultMap") and workspace.DefaultMap:FindFirstChild("RightWalls"), AlmacenTemporal)
                        SafeMove(workspace:FindFirstChild("Misc") and workspace.Misc:FindFirstChild("BrickAddition"), AlmacenTemporal)

                        -- Lógica especial para Mud y Walls base
                        local dMap = workspace:FindFirstChild("DefaultMap")
                        if dMap and dMap:FindFirstChild("Walls") then
                            local w = dMap.Walls
                            local c = w:GetChildren()
                            if w:FindFirstChild("wall") then SafeMove(w.wall, AlmacenTemporal) end
                            if c[6] then SafeMove(c[6], AlmacenTemporal) end
                            
                            -- Mud 1
                            if c[3] and c[3]:FindFirstChild("Mud") then
                                local m = c[3].Mud
                                if not OriginalMudData[m] then OriginalMudData[m] = {Size = m.Size, CFrame = m.CFrame} end
                                m.CFrame = CFrame.new(156, 50, -164, 0, 0, 1, -1, 0, 0, 0, -1, 0)
                            end
                            -- Mud 2
                            if c[4] and c[4]:FindFirstChild("Mud") then
                                local m = c[4].Mud
                                if not OriginalMudData[m] then OriginalMudData[m] = {Size = m.Size, CFrame = m.CFrame} end
                                m.Size = Vector3.new(100, 33, 6)
                                m.CFrame = CFrame.new(156, 50, 159.1, 0, 0, 1, -1, 0, 0, 0, -1, 0)
                            end
                        end

                        -- === PARTE 2: FREE VIP & WALL BYPASS ===
                        local vipFolders = {
                            "DefaultMap_SharedInstances", 
                            "MoneyMap_SharedInstances", 
                            "MarsMap_SharedInstances", 
                            "RadioactiveMap_SharedInstances", 
                            "ArcadeMap_SharedInstances"
                        }

                        for _, folderName in pairs(vipFolders) do
                            local folder = workspace:FindFirstChild(folderName)
                            if folder then
                                -- Buscamos modelos o partes llamadas VIP, Wall, o Mud
                                for _, obj in pairs(folder:GetDescendants()) do
                                    if obj:IsA("BasePart") and (obj.Name:find("VIP") or obj.Name:find("Wall") or obj.Name:find("Mud")) then
                                        obj.CanCollide = false
                                        obj.Transparency = 0.5 -- Visual para saber que funcionó
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.5) -- Ejecutar cada medio segundo para no laggear
                end
            end)

            -- Crear los bordes físicos (Tus barreras rojas)
            for _, d in ipairs(configBordes) do
                local p = Instance.new("Part", workspace)
                p.Name = d.nombre; p.Size = d.size; p.CFrame = d.cf; p.Anchored = true; p.CanCollide = true
                p.Color = Color3.fromRGB(255, 60, 60); p.Material = Enum.Material.Neon; p.Transparency = 0.35
                table.insert(BordesEstructura, p)
            end
        else
            -- Restaurar todo al apagar el Toggle
            RestoreAll()
            for _, b in pairs(BordesEstructura) do if b then b:Destroy() end end
            BordesEstructura = {}
        end
    end
})
