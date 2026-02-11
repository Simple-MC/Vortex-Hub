local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- --- [ CONEXIÓN SEGURA ] ---
local t = 0
while not _G.SettingsTab and t < 5 do 
    task.wait(0.1)
    t = t + 0.1
end

if not _G.SettingsTab then return end
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
local History = SettingsTab:Section({ Title = "📜 VORTEX CHRONICLES" })

-- Función Helper para crear Párrafos rápidos
local function Log(ver, desc)
    History:Paragraph({
        Title = "["..ver.."] Update",
        Content = desc
    })
end

-- PHASE 1
History:Paragraph({ Title = "--- [ PHASE 1: GENESIS ] ---", Content = "The Beginning of Vortex" })
Log("v1.0", "Core UI Framework Initialization")
Log("v2.0", "Implemented TweenService Movement")
Log("v5.5", "Tsunami Distance Check Logic")

-- PHASE 2
History:Paragraph({ Title = "--- [ PHASE 2: GOD SYSTEMS ] ---", Content = "Breaking the Game Limits" })
Log("v8.0", "Workspace Structure Analysis")
Log("v9.0", "Map Bypass Implementation")
Log("v10.0", "Client-Side VIP Access Injection")

-- PHASE 3
History:Paragraph({ Title = "--- [ PHASE 3: STABILITY ] ---", Content = "Fixing Critical Bugs" })
Log("CRITICAL", "Fixed Pathfinding Logic Failure")
Log("CRITICAL", "Fixed Mobile Input Unresponsive")
Log("PATCHED", "Terrain Clipping (+3 Studs)")

-- PHASE 4
History:Paragraph({ Title = "--- [ PHASE 4: REVOLUTION ] ---", Content = "Smart Features" })
Log("NEW", "Panic Mode (Survival First Protocol)")
Log("NEW", "Turbo-Interaction System")
Log("NEW", "Deep Search Scanner Algorithm")

-- PHASE 5
History:Paragraph({ Title = "--- [ PHASE 5: ULTIMATE ] ---", Content = "Current Version" })
Log("EVENT", "UFO Coins Full Support")
Log("CORE", "Merged God Mode into Main Core")
Log("RELEASE", "Final Stable Build v31")

-- --- [ 4. CREDITS ] ---
local Credits = SettingsTab:Section({ Title = "❤️ CREDITS" })

Credits:Paragraph({ Title = "👑 Creator", Content = "Daniel" })
Credits:Paragraph({ Title = "🧠 AI Logic", Content = "Gemini Premium" })
Credits:Paragraph({ Title = "SPECIAL THANKS", Content = "Gemini Premium Helped This Project ♥️" })
Credits:Paragraph({ Title = "MOTTO", Content = "Vortex On Top 🚀" })
