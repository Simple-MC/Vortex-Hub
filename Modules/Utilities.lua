--[[
    MODULE: UTILITIES
    FEATURES: VIP Multi-Map & Instant Proximity Prompt
]]

local VIPEnabled = false
local InstantEnabled = false

-- --- [ SECCIÓN VIP ] ---
_G.UtilitiesTab:Toggle({
    Title = "Desbloquear VIP (Multi-Map)",
    Callback = function(state)
        VIPEnabled = state
        if state then
            task.spawn(function()
                while VIPEnabled do
                    pcall(function()
                        local vips = {
                            "DefaultMap_SharedInstances", 
                            "MoneyMap_SharedInstances", 
                            "MarsMap_SharedInstances", 
                            "RadioactiveMap_SharedInstances", 
                            "ArcadeMap_SharedInstances"
                        }
                        for _, name in pairs(vips) do
                            local folder = workspace:FindFirstChild(name)
                            local walls = folder and folder:FindFirstChild("VIPWalls")
                            if walls then
                                for _, part in pairs(walls:GetDescendants()) do
                                    if part:IsA("BasePart") then 
                                        part.CanCollide = false 
                                        -- Opcional: part.Transparency = 0.5 (Para ver que está activo)
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.5) -- 0.5 es suficiente para no dar lag y mantener el bypass
                end
            end)
        end
    end
})

-- --- [ SECCIÓN INSTANT PROMPT ] ---
_G.UtilitiesTab:Toggle({
    Title = "Instant Proximity Prompt",
    Callback = function(state)
        InstantEnabled = state
    end
})

-- Hilo para forzar el tiempo de espera a 0
task.spawn(function()
    while true do
        if InstantEnabled then
            pcall(function()
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        prompt.HoldDuration = 0
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)
