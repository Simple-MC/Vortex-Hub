-- Main.lua
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "VORTEX HUB",
    Icon = "rbxassetid://114764180805798", 
    Author = "Simple-MC",
    Folder = "VortexConfig",      
    BackgroundImageTransparency = 0.42,
    Background = "rbxassetid://107940860934147"
})

local function LoadModule(name)
    local url = "https://raw.githubusercontent.com/Simple-MC/Vortex-Hub/main/Modules/" .. name .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then warn("Fallo al cargar " .. name .. ": " .. tostring(result)) end
end

-- DEFINICIÓN DE TABS
_G.MainTab = Window:Tab({ Title = "Main", Icon = "house" }) -- Timers, Local Player
_G.EspTab = Window:Tab({ Title = "Visuals", Icon = "eye" })    -- ESP Brainrots/LuckyBlocks
_G.UtilitiesTab = Window:Tab({ Title = "Utilities", Icon = "code-xml" }) -- VIP, Prompts
_G.AutoFarmTab = Window:Tab({ Title = "Auto Farm", Icon = "zap" }) -- AUTO FARM 
_G.SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" }) -- AUTO FARM 


-- CARGA DE MÓDULOS
LoadModule("Local")      -- (Velocidad, Salto, Fly)
LoadModule("Visuals")    -- Temporizadores del mapa
LoadModule("Combat")     -- God Mode y Anti-Muros
LoadModule("Esp")        -- El ESP
LoadModule("Esp2")        -- El ESP avanzado (Brainrots y LuckyBlocks)
LoadModule("Esp3")        -- El ESP avanzado enfocado en UFO Coins 
LoadModule("Esp4")
LoadModule("Utilities")  -- VIP y Prompts
LoadModule("AutoCollect")
LoadModule("Settings")
LoadModule("Sectionex") 

local Keybind = _G.MainTab:Keybind({
    Title = "Keybind",
    Desc = "Keybind to open ui",
    Value = "G",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

Window:EditOpenButton({
    Title = "Vortex Hub",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

WindUI:Notify({
    Title = "VORTEX HUB",
    Content = "Sistema cargado. ¡A farmear!",
    Duration = 5
})
