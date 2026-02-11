local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- --- [ CONEXIÓN ] ---
local t = 0
while not _G.SettingsTab and t < 5 do 
    task.wait(0.1)
    t = t + 0.1
end

if not _G.SettingsTab then return end
local SettingsTab = _G.SettingsTab

-- --- [ 1. PERFORMANCE ] ---
-- Usamos "Section" para crear el separador visual como en la foto
local PerfSection = SettingsTab:Section({ Title = "- [ PERFORMANCE & BATTERY ] -" })

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
local ServerSection = SettingsTab:Section({ Title = "- [ SERVER UTILITIES ] -" })

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
-- CAMBIO IMPORTANTE: Usamos Section para el título principal
local History = SettingsTab:Section({ Title = "📜 VORTEX CHRONICLES" })

-- Función corregida: Usa 'Paragraph' en lugar de 'Label'
local function Log(v, t)
    -- Paragraph requiere Title y Content
    SettingsTab:Paragraph({ 
        Title = "["..v.."] Update:", 
        Content = t 
    })
end

-- Títulos de Fase usando Section para dividir bonito
SettingsTab:Section({ Title = "- [ PHASE 1: GENESIS ] -" })
Log("v1.0", "Core UI Framework Initialization.")
Log("v2.0", "Implemented TweenService Movement.")
Log("v5.5", "Tsunami Distance Check Implementation.")

SettingsTab:Section({ Title = "- [ PHASE 2: GOD SYSTEMS ] -" })
Log("v8.0", "Workspace Structure Analysis Complete.")
Log("v9.0", "Implemented Map Bypass (Arcade/Mars).")
Log("v10.0", "Client-Side VIP Access Injection.")

SettingsTab:Section({ Title = "- [ PHASE 3: STABILITY ] -" })
Log("v14.0", "CRITICAL: Pathfinding Logic Failure Fixed.")
Log("v16.0", "CRITICAL: Mobile Input Unresponsive Fixed.")
Log("v17.5", "PATCHED: Y-Axis Offset (+3 Studs).")

SettingsTab:Section({ Title = "- [ PHASE 4: REVOLUTION ] -" })
Log("v20.0", "PROTOCOL: Panic Mode (Survival First).")
Log("v22.0", "FEATURE: Turbo-Interaction System.")
Log("v24.0", "ALGORITHM: Deep Search Scanner.")

SettingsTab:Section({ Title = "- [ PHASE 5: ULTIMATE ] -" })
Log("v26.0", "EVENT: UFO Coins Full Support.")
Log("v29.0", "CORE: Merged God Mode into Main.")
Log("v31.0", "RELEASE: Final Stable Build.")

-- --- [ 4. CREDITS ] ---
local Credits = SettingsTab:Section({ Title = "❤️ DEVELOPER CREDITS" })

-- Usamos Paragraph para los créditos también
SettingsTab:Paragraph({ Title = "👑 Creator", Content = "Daniel" })
SettingsTab:Paragraph({ Title = "🧠 AI Logic", Content = "Gemini Premium" })
SettingsTab:Paragraph({ Title = "SPECIAL THANKS", Content = "Gemini Premium Helped This Project ♥️" })
SettingsTab:Paragraph({ Title = "MOTTO", Content = "Vortex On Top 🚀" })
