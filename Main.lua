-- Main.lua
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "VORTEX HUB",
    Icon = "lucide-zap", 
    Author = "Gemini AI",
    Folder = "VortexConfig"
})

-- Función para cargar módulos desde TU GitHub (Cambia 'TuUsuario' por el tuyo)
local function LoadModule(name)
    local url = "https://raw.githubusercontent.com/Simple-MC/Vortex-Hub/main/Modules/" .. name .. ".lua"
    return loadstring(game:HttpGet(url))()
end

-- Definición de Tabs globales para que los módulos las usen
_G.MainTab = Window:Tab({ Title = "Principal", Icon = "lucide-home" })
_G.VIPTab = Window:Tab({ Title = "VIP Free", Icon = "lucide-gem" })
_G.CombatTab = Window:Tab({ Title = "Combate", Icon = "lucide-shield" })

-- Carga de Módulos
LoadModule("Visuals")
LoadModule("Utilities")
LoadModule("Combat")
