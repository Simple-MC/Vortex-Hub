--[[
    MODULE: VORTEX ULTIMATE AUTO-FARM (Arcade & Money)
    METHOD: Fast Walk Logic (No TP)
    TARGETS: Tickets, Consoles and Money Events
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- --- [ CONFIGURACIÓN ] ---
local FarmConfig = {
    TicketsEnabled = false,
    MoneyEnabled = false,
    Walking = false
}

-- --- [ INTERFAZ UI ] ---
local SectionArcade = _G.AutoFarmTab:Section({ Title = "🎟️ Arcade Event Farm" })
local SectionMoney = _G.AutoFarmTab:Section({ Title = "💰 Money Event Farm" })

SectionArcade:Toggle({
    Title = "Auto-Collect Tickets",
    Callback = function(s) FarmConfig.TicketsEnabled = s end
})

SectionMoney:Toggle({
    Title = "Auto-Collect Money Parts",
    Callback = function(s) FarmConfig.MoneyEnabled = s end
})

-- --- [ MOTOR DE BUSQUEDA RÁPIDA ] ---

local function GetClosestTarget()
    local closest = nil
    local shortestDist = math.huge
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not root then return nil end

    -- Lista de carpetas donde buscar
    local folders = {}
    if FarmConfig.TicketsEnabled then 
        table.insert(folders, workspace:FindFirstChild("ArcadeEventTickets")) 
    end
    if FarmConfig.MoneyEnabled then 
        table.insert(folders, workspace:FindFirstChild("MoneyEventParts")) 
    end

    for _, folder in pairs(folders) do
        if folder then
            for _, item in pairs(folder:GetChildren()) do
                local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local dist = (root.Position - part.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

-- --- [ BUCLE DE RECOLECCIÓN VELOZ ] ---

task.spawn(function()
    while true do
        if (FarmConfig.TicketsEnabled or FarmConfig.MoneyEnabled) then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and root then
                local target = GetClosestTarget()
                
                if target then
                    -- Caminar al objetivo más cercano
                    hum:MoveTo(target.Position)
                    
                    -- Lógica de espera rápida: Si el target desaparece o llegamos, buscamos otro
                    local timeout = 0
                    repeat
                        task.wait(0.05) -- Revisión ultra rápida
                        timeout = timeout + 0.05
                    until not target.Parent or (root.Position - target.Position).Magnitude < 4 or timeout > 5 or not (FarmConfig.TicketsEnabled or FarmConfig.MoneyEnabled)
                else
                    task.wait(0.2) -- Si no hay nada, espera un parpadeo
                end
            end
        end
        task.wait(0.1)
    end
end)
