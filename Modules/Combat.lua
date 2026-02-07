-- Modules/Combat.lua
local GodModeEnabled = false
local OriginalParents = {}
local Almacen = game:GetService("Lighting")
local Bordes = {}

local configBordes = {
    {size = Vector3.new(90, 2.7, 2048), cf = CFrame.new(1177, 0, -143, -4.37113883e-08, 0, 1, 1, -4.37113883e-08, 4.37113883e-08, 4.37113883e-08, 1, 1.91068547e-15)},
    -- [Agrega aquí todos los demás CFrames que tienes en tu lista original]
}

_G.CombatTab:Toggle({
    Title = "Activar God Mode Total",
    Callback = function(state)
        GodModeEnabled = state
        if state then
            task.spawn(function()
                while GodModeEnabled do
                    -- Limpieza agresiva de muros de todos los mapas
                    pcall(function() workspace.ArcadeMap.RightWalls.Parent = Almacen end)
                    pcall(function() workspace.RadioactiveMap.RightWalls.Parent = Almacen end)
                    pcall(function() workspace.DefaultMap.RightWalls.Parent = Almacen end)
                    -- [Agrega aquí las demás líneas de borrado]
                    task.wait(0.1)
                end
            end)
            -- Crear Bordes
            for _, d in pairs(configBordes) do
                local p = Instance.new("Part", workspace)
                p.Size = d.size; p.CFrame = d.cf; p.Anchored = true; p.Color = Color3.fromRGB(255,0,0); p.Transparency = 0.5
                table.insert(Bordes, p)
            end
        else
            -- Lógica para restaurar y borrar bordes
            for _, b in pairs(Bordes) do b:Destroy() end
            Bordes = {}
        end
    end
})
