--[[
    MODULE: VORTEX GOD MODE & WALL BYPASS (Combat.lua)
    FEATURES: Dynamic Folder Cleaning, VIP/Wall Bypass, Custom Borders
]]

local AlmacenTemporal = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local GodModeEnabled = false
local OriginalParents = {}
local OriginalMudData = {}
local BordesEstructura = {}

-- ==========================================
-- 🛠️ LISTA DINÁMICA DE COSAS QUE ESTORBAN
-- ==========================================
-- Al ponerlo como función, escanea el mapa en tiempo real por si el mapa cambia de la nada.
local function ObtenerCosasQueEstorban()
    return {
        workspace:FindFirstChild("ArcadeMap") and workspace.ArcadeMap:FindFirstChild("RightWalls"),
        workspace:FindFirstChild("RadioactiveMap") and workspace.RadioactiveMap:FindFirstChild("RightWalls"),
        workspace:FindFirstChild("MarsMap") and workspace.MarsMap:FindFirstChild("Walls") and workspace.MarsMap.Walls:GetChildren()[7],
        workspace:FindFirstChild("MarsMap") and workspace.MarsMap:FindFirstChild("Deco"),
        workspace:FindFirstChild("MoneyMap") and workspace.MoneyMap:FindFirstChild("DefaultStudioMap") and workspace.MoneyMap.DefaultStudioMap:FindFirstChild("Walls"),
        workspace:FindFirstChild("MoneyMap") and workspace.MoneyMap:FindFirstChild("DefaultStudioMap") and workspace.MoneyMap.DefaultStudioMap:FindFirstChild("RightWalls"),
        workspace:FindFirstChild("DefaultMap") and workspace.DefaultMap:FindFirstChild("RightWalls"),
        workspace:FindFirstChild("Misc") and workspace.Misc:FindFirstChild("BrickAddition"),
        workspace:FindFirstChild("DefaultMap") and workspace.DefaultMap:FindFirstChild("Walls"),
        
        -- 🔥 UPDATE SAN VALENTÍN 🔥
        workspace:FindFirstChild("ValentinesMap") and workspace.ValentinesMap:FindFirstChild("RightWalls"),
        workspace:FindFirstChild("ValentinesMap") and workspace.ValentinesMap:FindFirstChild("Walls")
    }
end

-- ==========================================

-- Funcion de movimiento seguro
local function SafeMove(obj, newParent)
    if obj and not OriginalParents[obj] then
        OriginalParents[obj] = obj.Parent
    end
    if obj then obj.Parent = newParent end
end

-- Funcion para restaurar todo al apagar
local function RestoreAll()
    for obj, parent in pairs(OriginalParents) do
        pcall(function() if obj then obj.Parent = parent end end)
    end
    OriginalParents = {}
    
    for obj, data in pairs(OriginalMudData) do
        pcall(function()
            if obj then
                obj.Size = data.Size
                obj.CFrame = data.CFrame
            end
        end)
    end
    OriginalMudData = {}

    pcall(function()
        -- Agregamos ValentinesMap_SharedInstances a la lista de restauración
        local folders = {
            "DefaultMap_SharedInstances", "MoneyMap_SharedInstances", 
            "MarsMap_SharedInstances", "RadioactiveMap_SharedInstances", 
            "ArcadeMap_SharedInstances", "ValentinesMap_SharedInstances"
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

-- Configuracion de Bordes (Con la expansion del mapa v31)
local configBordes = {
    {nombre = "B1", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1177, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "B2", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1917, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "B3", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1177, -2, -136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "B4", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1917, -2, -136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde5", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1177, -2, 136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde6", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1179, 0, 144, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde7", size = Vector3.new(4, 13, 2048), cf = CFrame.new(1917, -2, 135.5, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde8", size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1917, 0, 144, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde9", size = Vector3.new(4, 13, 1409.5), cf = CFrame.new(3645.5, -2, -136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde10", size = Vector3.new(90, 2.700000047683716, 1409.5), cf = CFrame.new(3645.5, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde11", size = Vector3.new(4, 13, 1409.5), cf = CFrame.new(3645.5, -2, 136, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde12", size = Vector3.new(90, 2.700000047683716, 1409.5), cf = CFrame.new(3645.5, 0, 142.5, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    {nombre = "Borde13", size = Vector3.new(6, 90, 284), cf = CFrame.new(4353, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)}
}

-- Creamos la sección visual en WindUI (Asegúrate de que _G.AutoFarmTab exista en tu Main.lua)
_G.AutoFarmTab:Section({ Title = "--[ GOD MODE & PROTECCIÓN ]--", Icon = "shield" })

-- Toggle principal
_G.AutoFarmTab:Toggle({
    Title = "🔥 Activate God Mode Total (+VIP)",
    Callback = function(state)
        GodModeEnabled = state
        
        if GodModeEnabled then
            task.spawn(function()
                while GodModeEnabled do
                    pcall(function()
                        
                        -- === LIMPIEZA DINÁMICA DE MAPAS ===
                        local listaBasura = ObtenerCosasQueEstorban()
                        for _, objetoEnMedio in pairs(listaBasura) do
                            if objetoEnMedio then
                                SafeMove(objetoEnMedio, AlmacenTemporal)
                            end
                        end

                        -- === FREE VIP & WALL BYPASS ===
                        -- Agregamos ValentinesMap_SharedInstances a la lista
                        local vipFolders = {
                            "DefaultMap_SharedInstances", 
                            "MoneyMap_SharedInstances", 
                            "MarsMap_SharedInstances", 
                            "RadioactiveMap_SharedInstances", 
                            "ArcadeMap_SharedInstances",
                            "ValentinesMap_SharedInstances"
                        }

                        for _, folderName in pairs(vipFolders) do
                            local folder = workspace:FindFirstChild(folderName)
                            if folder then
                                for _, obj in pairs(folder:GetDescendants()) do
                                    if obj:IsA("BasePart") and (obj.Name:find("VIP") or obj.Name:find("Wall") or obj.Name:find("Mud")) then
                                        obj.CanCollide = false
                                        obj.Transparency = 0.5
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.5) -- Revisa cada medio segundo
                end
            end)

            -- Crear bordes rojos de protección
            for _, d in ipairs(configBordes) do
                local p = Instance.new("Part", workspace)
                p.Name = d.nombre; p.Size = d.size; p.CFrame = d.cf; p.Anchored = true; p.CanCollide = true
                p.Color = Color3.fromRGB(255, 60, 60); p.Material = Enum.Material.Neon; p.Transparency = 0.35
                table.insert(BordesEstructura, p)
            end
            
        else
            -- Restaurar todo a la normalidad
            RestoreAll()
            for _, b in pairs(BordesEstructura) do if b then b:Destroy() end end
            BordesEstructura = {}
        end
    end
})
