-- Modules/Local.lua
--[[
    MODULE: LOCAL PLAYER
    FEATURES: Speed, Jump, NoClip, Fly, InfJump, FOV, Gravity
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables de estado
local Config = {
    Speed = 16,
    Jump = 50,
    NoClip = false,
    InfJump = false,
    Gravity = 196.2,
    Fov = 70
}

-- --- [ SECCIÓN: JUGADOR LOCAL ] ---
-- Usamos una Section para agrupar todo en el MainTab como pediste
local SectionLocal = _G.MainTab:Section({ 
    Title = "👤 Modificadores de Jugador",
    Icon = "lucide-user-cog"
})

-- 1. VELOCIDAD (WalkSpeed)
SectionLocal:Slider({
    Title = "Velocidad (WalkSpeed)",
    Step = 1,
    Min = 16,
    Max = 300,
    Default = 16,
    Callback = function(v)
        Config.Speed = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})

-- 2. SALTO (JumpPower)
SectionLocal:Slider({
    Title = "Fuerza de Salto",
    Step = 1,
    Min = 50,
    Max = 500,
    Default = 50,
    Callback = function(v)
        Config.Jump = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.UseJumpPower = true
            LocalPlayer.Character.Humanoid.JumpPower = v
        end
    end
})

-- 3. GRAVEDAD (Gravity)
SectionLocal:Slider({
    Title = "Gravedad (Low Gravity)",
    Step = 5,
    Min = 0,
    Max = 196,
    Default = 196,
    Callback = function(v)
        Config.Gravity = v
        workspace.Gravity = v
    end
})

-- 4. FOV (Campo de Visión)
SectionLocal:Slider({
    Title = "Campo de Visión (FOV)",
    Step = 1,
    Min = 70,
    Max = 120,
    Default = 70,
    Callback = function(v)
        Config.Fov = v
        Camera.FieldOfView = v
    end
})

-- 5. NOCLIP (Atravesar Paredes)
SectionLocal:Toggle({
    Title = "🔥 NoClip (Atravesar Muros)",
    Callback = function(state)
        Config.NoClip = state
    end
})

-- 6. INFINITE JUMP (Salto Infinito)
SectionLocal:Toggle({
    Title = "🐇 Infinite Jump (Salto Aéreo)",
    Callback = function(state)
        Config.InfJump = state
    end
})

-- --- [ LÓGICA INTERNA (LOOPS) ] ---

-- Loop Principal (Se ejecuta cada frame)
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")

        -- Mantener Velocidad y Salto (Evita que el juego te lo quite)
        if hum then
            if hum.WalkSpeed ~= Config.Speed then
                hum.WalkSpeed = Config.Speed
            end
            if hum.JumpPower ~= Config.Jump then
                hum.UseJumpPower = true
                hum.JumpPower = Config.Jump
            end
        end

        -- Lógica NoClip
        if Config.NoClip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Lógica Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfJump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Restaurar Gravedad al cerrar (opcional, por si acaso)
game.Players.PlayerRemoving:Connect(function(plr)
    if plr == LocalPlayer then
        workspace.Gravity = 196.2
    end
end)
