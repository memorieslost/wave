--[[
    VIOLENT NOTIFIER V4.1 - FIXED SERVER HOP (TOGGLES)
    Base: VaderHax (Garantida no Severe)
    Correção: Server Hop Real via API do Roblox
    Atalho: DELETE para Ocultar/Mostrar
]]

-- Carregar Biblioteca VaderHax
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/x8n8x/vader/refs/heads/main/vaderhaxing"))()

-- Configuração da Janela
local win = Library:Window({ 
    name = "VIOLENT",
    size = Vector2.new(280, 220)
})

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Configurações Globais
local _G = getgenv and getgenv() or _G
_G.WebhookURL = "https://ptb.discord.com/api/webhooks/1488318065220260102/o9XXB175X8qtZmCmeivz6_PiTfqIGe9qjEYLS0V6HY0RQCqH2Zo0oOxO93oFLvHqyBIW" -- COLOQUE SUA WEBHOOK AQUI
_G.DetectionEnabled = true
_G.AutoServerHop = false
_G.HopInterval = 300 -- 5 Minutos
_G.LastHopTime = tick()

-- Alvos
local TARGET_NAMES = {"Sammino_Vermicello", "Karker_Spot", "Rubrizzio_Fortuna_Mangiatore", "Strawberry_Elephant", "John_Pork"}
local notifiedEntities = {}

-- ============================================
-- SISTEMA DE SERVER HOP ROBUSTO (API ROBLOX)
-- ============================================
local function robustServerHop()
    Library:AddNotification("VIOLENT", "Buscando novo servidor...", 5)
    send_notification("VIOLENT: Buscando servidor...")
    
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        local response = game:HttpGet(url)
        -- O Severe tem suporte a HttpService:JSONDecode se for Luau padrão, caso contrário usamos parsing simples
        local data = HttpService:JSONDecode(response)
        
        for _, server in pairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Players.LocalPlayer)
                return true
            end
        end
    end)
    
    if not success or not result then
        -- Fallback se a API falhar: Teleporte padrão
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    end
end

-- ============================================
-- LOGIC
-- ============================================
local function sendWebhook(entityName, position)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("http") then return end
    local jsonPayload = string.format([[{"content":"@everyone","embeds":[{"title":"🚨 VIOLENT: ALVO DETECTADO!","description":"**Entidade:** %s\n**Localização:** %s","color":16711680}]} ]], 
        entityName, tostring(position))
    pcall(function() game:HttpPost(_G.WebhookURL, jsonPayload) end)
end

local function checkEntities()
    if not _G.DetectionEnabled then return end
    for _, instance in pairs(Workspace:GetDescendants()) do
        if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then continue end
        local targetFound = false
        local entityName = instance.Name
        for _, target in pairs(TARGET_NAMES) do
            if entityName:lower():find(target:lower(), 1, true) then targetFound = true; break end
        end
        if targetFound and not notifiedEntities[instance] then
            notifiedEntities[instance] = true
            local pos = "Desconhecida"
            pcall(function() pos = instance:IsA("BasePart") and instance.Position or instance:GetPivot().Position end)
            send_notification("VIOLENT: " .. entityName)
            Library:AddNotification("ALVO DETECTADO", entityName, 5)
            sendWebhook(entityName, pos)
        end
    end
end

-- ============================================
-- INTERFACE
-- ============================================
local main = win:Tab({ name = "VIOLENT" })
local section = main:Section({ name = "Controles", side = "left" })

section:Toggle({
    name = "Detecção Ativa",
    default = true,
    callback = function(v) _G.DetectionEnabled = v end
})

section:Toggle({
    name = "Auto Server Hop (5m)",
    default = false,
    callback = function(v) 
        _G.AutoServerHop = v 
        if v then _G.LastHopTime = tick() end
    end
})

section:Button({
    name = "Server Hop Manual",
    callback = function() robustServerHop() end
})

section:TextBox({
    name = "Webhook URL",
    placeholder = "Cole aqui...",
    callback = function(v) _G.WebhookURL = v end
})

-- ============================================
-- ATALHO DELETE & LOOP
-- ============================================
local visible = true
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        visible = not visible
        pcall(function() win:SetVisible(visible) end)
    end
end)

task.spawn(function()
    while true do
        pcall(checkEntities)
        
        -- Lógica de Auto Hop Corrigida
        if _G.AutoServerHop then
            local elapsed = tick() - _G.LastHopTime
            if elapsed >= _G.HopInterval then
                robustServerHop()
                _G.LastHopTime = tick() -- Reseta o timer se falhar o teleporte
            end
        end
        
        task.wait(5)
    end
end)

Library:AddNotification("VIOLENT", "Sistema Corrigido!", 3)
send_notification("VIOLENT: Hop Corrigido!")
