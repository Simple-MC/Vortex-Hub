-- Main.lua
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "VORTEX HUB",
    Icon = "lucide-zap", 
    Author = "Simple-MC & Gemini",
    Folder = "VortexConfig"
})

-- Función para cargar módulos desde tu repositorio
local function LoadModule(name)
    local url = "https://raw.githubusercontent.com/Simple-MC/Vortex-Hub/main/Modules/" .. name .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        warn("Error cargando módulo: " .. name .. " | " .. result)
    end
end

-- DEFINICIÓN DE TABS GLOBALES (Deben llamarse igual en los módulos)
_G.MainTab = Window:Tab({ Title = "Principal", Icon = "lucide-home" }) -- Aquí va el AutoFarm
_G.EspTab = Window:Tab({ Title = "Visuales", Icon = "lucide-eye" })    -- Aquí va el ESP Dinámico
_G.UtilitiesTab = Window:Tab({ Title = "Utilidades", Icon = "lucide-settings" }) -- Aquí va VIP e Instant Prompt
_G.CombatTab = Window:Tab({ Title = "Combate", Icon = "lucide-swords" }) -- Aquí va el Anti-Kill

-- CARGA DE MÓDULOS (Asegúrate de que los nombres de los archivos en GitHub sean idénticos)
LoadModule("Visuals")   -- Temporizadores
LoadModule("Esp")        -- ESP de Brainrots con Dropdowns
LoadModule("Utilities")  -- VIP Free e Instant Prompt
LoadModule("Combat")     -- Anti-Kill y protección

WindUI:Notify({
    Title = "VORTEX HUB",
    Content = "Módulos cargados correctamente. ¡A farmear!",
    Duration = 5
})
