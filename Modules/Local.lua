-- Modules/Local.lua
--[[
    MODULE: LOCAL PLAYER
    FIXED BY: Gemini
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
-- Asumimos que _G.MainTab ya fue creado en tu script principal
local SectionLocal = _G.MainTab:Section({ 
    Title = "👤 Modificadores de Jugador",
    Icon = "lucide-user-cog"
})

-- 1. VELOCIDAD (WalkSpeed) - CORREGIDO
SectionLocal:Slider({
    Title = "Velocidad (WalkSpeed)",
    Desc = "Cambia qué tan rápido caminas",
    Step = 1,
    Value = {
        Min = 16,
        Max = 300,
        Default = 16,
    },
    Callback = function(v)
        Config.Speed = v
    end
})

-- 2. SALTO (JumpPower) - CORREGIDO
SectionLocal:Slider({
    Title = "Fuerza de Salto",
    Desc = "Cambia qué tan alto saltas",
    Step = 1,
    Value = {
        Min = 50,
        Max = 500,
        Default = 50,
    },
    Callback = function(v)
        Config.Jump = v
    end
})

-- 3. GRAVEDAD (Gravity) - CORREGIDO
SectionLocal:Slider({
    Title = "Gravedad",
    Desc = "Menor número = Flotas más",
    Step = 5,
    Value = {
        Min = 0,
        Max = 196,
        Default = 196,
    },
    Callback = function(v)
        Config.Gravity = v
        workspace.Gravity = v
    end
})

-- 4. FOV (Campo de Visión) - CORREGIDO
SectionLocal:Slider({
    Title = "Campo de Visión (FOV)",
    Step = 1,
    Value = {
        Min = 70,
        Max = 120,
        Default = 70,
    },
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

-- 6. INFINITE JUMP (Salto Aéreo)
SectionLocal:Toggle({
    Title = "🐇 Infinite Jump",
    Callback = function(state)
        Config.InfJump = state
    end
})


-- --- [ LÓGICA INTERNA (LOOPS) ] ---

-- Loop Principal (Optimizado)
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        
        -- APLICAR VELOCIDAD Y SALTO CONSTANTEMENTE
        -- (Esto evita que el juego te resetee la velocidad)
        if hum then
            if hum.WalkSpeed ~= Config.Speed then
                hum.WalkSpeed = Config.Speed
            end
            
            -- Aseguramos que use JumpPower y no JumpHeight
            if hum.UseJumpPower == false then 
                hum.UseJumpPower = true 
            end
            
            if hum.JumpPower ~= Config.Jump then
                hum.JumpPower = Config.Jump
            end
        end

        -- LÓGICA NOCLIP
        -- Solo ejecutamos el loop de partes si el NoClip está ACTIVO (Ahorra recursos)
        if Config.NoClip then
            for _, part in ipairs(char:GetDescendants()) do
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
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Restaurar Gravedad al salir (Opcional, limpieza)
game.Players.PlayerRemoving:Connect(function(plr)
    if plr == LocalPlayer then
        workspace.Gravity = 196.2
    end
end)
