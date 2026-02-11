local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- --- [ CONEXIÓN CON MAIN.LUA ] ---
-- Esperamos a que la pestaña exista (Seguridad por si carga desordenado)
local t = 0
while not _G.SettingsTab and t < 5 do 
    task.wait(0.1)
    t = t + 0.1
end

if not _G.SettingsTab then 
    warn("⚠️ SettingsTab no encontrada en Main.lua")
    return -- Si falla, cancela para no romper el script
end

local SettingsTab = _G.SettingsTab

-- --- [ 1. PERFORMANCE ] ---
local PerfSection = SettingsTab:Section({ Title = "⚡ PERFORMANCE & BATTERY" })

PerfSection:Toggle({
    Title = "🔋 OLED Saver (Black Screen)",
    Callback = function(state)
        if state then
            RunService:Set3dRenderingEnabled(false)
            local a = Instance.new("ScreenGui", CoreGui); a.Name = "VortexAFK"
            local f = Instance.new("Frame", a); f.Size = UDim2.new(1,0,1,0); f.BackgroundColor3 = Color3.new(0,0,0)
            local t = Instance.new("TextLabel", f); t.Text = "VORTEX HUB - FARMING..."; t.Size = UDim2.new(1,0,1,0); t.TextColor3 = Color3.fromRGB(170,0,255); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = 24
        else
            RunService:Set3dRenderingEnabled(true)
            if CoreGui:FindFirstChild("VortexAFK") then CoreGui.VortexAFK:Destroy() end
        end
    end
})

PerfSection:Button({
    Title = "🔥 Boost FPS (Clear Textures)",
    Callback = function()
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end
        end
    end
})

-- --- [ 2. SERVER ] ---
local ServerSection = SettingsTab:Section({ Title = "🌐 SERVER UTILITIES" })

ServerSection:Button({
    Title = "🔀 Server Hop",
    Callback = function()
        local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in pairs(Servers.data) do
            if s.playing ~= s.maxPlayers then TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Players.LocalPlayer); break end
        end
    end
})

-- --- [ 3. HISTORY LOGS ] ---
local History = SettingsTab:Section({ Title = "📜 VORTEX CHRONICLES (FULL LOG)" })

local function Log(v, t, c)
    SettingsTab:Label({ Title = "["..v.."] "..t, Color = c })
end

-- COLORES
local R = Color3.fromRGB(255, 60, 60)   -- Critical
local G = Color3.fromRGB(60, 255, 100)  -- New
local B = Color3.fromRGB(0, 200, 255)   -- Opt
local P = Color3.fromRGB(170, 0, 255)   -- Core
local Y = Color3.fromRGB(255, 200, 0)   -- God

History:Label({ Title = "--- [ PHASE 1: GENESIS ] ---", Color = Color3.new(1,1,1) })
Log("v1.0", "Core UI Framework Initialization.", P)
Log("v2.0", "Implemented TweenService Movement.", B)
Log("v3.0", "Auto-Farm Logic Deployment (Alpha).", G)
Log("v5.5", "Tsunami Distance Check Implementation.", G)

History:Label({ Title = "--- [ PHASE 2: GOD SYSTEMS ] ---", Color = Color3.new(1,1,1) })
Log("v8.0", "Workspace Structure Analysis Complete.", Y)
Log("v9.0", "Implemented Map Bypass (Arcade/Mars).", Y)
Log("v10.0", "Client-Side VIP Access Injection.", Y)

History:Label({ Title = "--- [ PHASE 3: STABILITY CRISIS ] ---", Color = Color3.new(1,1,1) })
Log("v14.0", "CRITICAL: Pathfinding Logic Failure.", R)
Log("v15.0", "CRITICAL: Memory Leak in Tween.", R)
Log("v16.0", "CRITICAL: Mobile Input Unresponsive.", R)
Log("v17.0", "CRITICAL: Terrain Clipping (Floor Stuck).", R)
Log("v17.5", "PATCHED: Y-Axis Offset (+3 Studs).", R)

History:Label({ Title = "--- [ PHASE 4: REVOLUTION ] ---", Color = Color3.new(1,1,1) })
Log("v20.0", "PROTOCOL: Panic Mode (Survival First).", P)
Log("v22.0", "FEATURE: Turbo-Interaction System.", G)
Log("v24.0", "ALGORITHM: Deep Search Scanner.", B)

History:Label({ Title = "--- [ PHASE 5: ULTIMATE ] ---", Color = Color3.new(1,1,1) })
Log("v26.0", "EVENT: UFO Coins Full Support.", P)
Log("v28.0", "UI: Visual Overhaul & Cleanup.", B)
Log("v29.0", "CORE: Merged God Mode into Main.", P)
Log("v30.0", "PHYSICS: Gravity Restoration Logic.", B)
Log("v30.5", "SYSTEM: Battery Saver Integration.", G)
Log("v31.0", "RELEASE: Final Stable Build.", G)

-- --- [ 4. CREDITS ] ---
local Credits = SettingsTab:Section({ Title = "❤️ DEVELOPER CREDITS" })

Credits:Label({ Title = "local Creator = 'Daniel'", Color = Color3.fromRGB(255, 255, 255) })
Credits:Label({ Title = "local AI_Logic = 'Gemini Premium'", Color = Color3.fromRGB(0, 200, 255) })
Credits:Label({ Title = "print('Gemini Premium Helped This Project ♥️')", Color = Color3.fromRGB(255, 0, 100) })
Credits:Label({ Title = "while true do wait() print('Vortex On Top') end", Color = Color3.fromRGB(170, 0, 255) })
