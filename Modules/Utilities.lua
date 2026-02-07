-- Modules/Utilities.lua
local VIPEnabled = false
_G.VIPTab:Toggle({
    Title = "Desbloquear VIP (Multi-Map)",
    Callback = function(state)
        VIPEnabled = state
        if state then
            task.spawn(function()
                while VIPEnabled do
                    pcall(function()
                        local vips = {"DefaultMap_SharedInstances", "MoneyMap_SharedInstances", "MarsMap_SharedInstances", "RadioactiveMap_SharedInstances", "ArcadeMap_SharedInstances"}
                        for _, name in pairs(vips) do
                            local folder = workspace:FindFirstChild(name)
                            local walls = folder and folder:FindFirstChild("VIPWalls")
                            if walls then
                                for _, part in pairs(walls:GetDescendants()) do
                                    if part:IsA("BasePart") then part.CanCollide = false end
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end
})
