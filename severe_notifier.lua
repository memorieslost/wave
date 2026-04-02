--[[
    VIOLENT NATIVE EDITION - OVERLAY DRAWING
    Desenvolvido para: SEVERE (External Memory Reader)
    Estilo: Overlay Nativo (Inspirado em Death Ball / New UI)
    Atalho: DELETE para Ocultar/Mostrar
]]

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configurações Globais
local _G = getgenv and getgenv() or _G
_G.WebhookURL = "https://ptb.discord.com/api/webhooks/1489310598238830803/WshnnHaAobRqes3QBCdhPO_qgRcm5_giwtXwUir4wKCF5jbhrGP7TUAtcroj8UOdo03H" -- COLOQUE SUA WEBHOOK AQUI
_G.DetectionEnabled = true
_G.AutoServerHop = false
_G.HopInterval = 300
_G.UIVisible = true

-- Alvos
local TARGET_NAMES = {
    "Sammino_Vermicello",
    "Karker_Spot",
    "Rubrizzio_Fortuna_Mangiatore",
    "Strawberry_Elephant",
    "John_Pork"
}

local notifiedEntities = {}
local lastHop = tick()

-- ============================================
-- NATIVE DRAWING SYSTEM (SEVERE OVERLAY)
-- ============================================

local UI = {
    Main = {},
    Toggles = {},
    RainbowElements = {},
    Notifications = {}
}

-- Cores Estilo New UI
local Colors = {
    Background = Color3.fromRGB(15, 15, 20),
    Accent = Color3.fromRGB(80, 255, 80), -- Verde iOS
    Off = Color3.fromRGB(255, 80, 80),    -- Vermelho
    Text = Color3.fromRGB(255, 255, 255),
    SecondaryText = Color3.fromRGB(180, 180, 180)
}

function UI:Init()
    local cam = workspace.CurrentCamera
    local screenWidth = cam and cam.ViewportSize.X or 1920
    local screenHeight = cam and cam.ViewportSize.Y or 1080
    local basePos = Vector2.new(50, screenHeight * 0.4) -- Lado esquerdo da tela

    -- Container Principal (Fundo Transparente)
    self.Main.Container = Drawing.new("Square")
    self.Main.Container.Size = Vector2.new(200, 140)
    self.Main.Container.Position = basePos
    self.Main.Container.Color = Colors.Background
    self.Main.Container.Filled = true
    self.Main.Container.Opacity = 0.8
    self.Main.Container.Rounding = 10
    self.Main.Container.Visible = true
    self.Main.Container.ZIndex = 1

    -- Título VIOLENT (Rainbow)
    self.Main.Title = Drawing.new("Text")
    self.Main.Title.Text = "VIOLENT"
    self.Main.Title.Size = 24
    self.Main.Title.Position = basePos + Vector2.new(100, 15)
    self.Main.Title.Center = true
    self.Main.Title.Outline = true
    self.Main.Title.Font = 2
    self.Main.Title.Visible = true
    self.Main.Title.ZIndex = 5
    table.insert(self.RainbowElements, self.Main.Title)

    -- Labels de Status
    local function CreateStatusLabel(name, yOffset, flag, default)
        local label = Drawing.new("Text")
        label.Text = name .. ":"
        label.Size = 14
        label.Color = Colors.SecondaryText
        label.Position = basePos + Vector2.new(15, yOffset)
        label.Visible = true
        label.ZIndex = 5

        local status = Drawing.new("Text")
        status.Text = default and "ON" or "OFF"
        status.Size = 14
        status.Color = default and Colors.Accent or Colors.Off
        status.Position = basePos + Vector2.new(150, yOffset)
        status.Visible = true
        status.ZIndex = 5
        
        UI.Toggles[flag] = {label = label, status = status}
    end

    CreateStatusLabel("DETECÇÃO", 55, "Detection", _G.DetectionEnabled)
    CreateStatusLabel("AUTO HOP", 80, "AutoHop", _G.AutoServerHop)

    -- Rodapé Informativo
    self.Main.Footer = Drawing.new("Text")
    self.Main.Footer.Text = "[DEL] OCULTAR | [INSERT] TROCAR HOP"
    self.Main.Footer.Size = 10
    self.Main.Footer.Color = Color3.fromRGB(120, 120, 130)
    self.Main.Footer.Position = basePos + Vector2.new(100, 115)
    self.Main.Footer.Center = true
    self.Main.Footer.Visible = true
    self.Main.Footer.ZIndex = 5
end

function UI:UpdateToggles()
    if self.Toggles.Detection then
        self.Toggles.Detection.status.Text = _G.DetectionEnabled and "ON" or "OFF"
        self.Toggles.Detection.status.Color = _G.DetectionEnabled and Colors.Accent or Colors.Off
    end
    if self.Toggles.AutoHop then
        self.Toggles.AutoHop.status.Text = _G.AutoServerHop and "ON" or "OFF"
        self.Toggles.AutoHop.status.Color = _G.AutoServerHop and Colors.Accent or Colors.Off
    end
end

function UI:ToggleVisibility()
    _G.UIVisible = not _G.UIVisible
    self.Main.Container.Visible = _G.UIVisible
    self.Main.Title.Visible = _G.UIVisible
    self.Main.Footer.Visible = _G.UIVisible
    for _, t in pairs(self.Toggles) do
        t.label.Visible = _G.UIVisible
        t.status.Visible = _G.UIVisible
    end
end

-- ============================================
-- INPUT & RAINBOW
-- ============================================

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        UI:ToggleVisibility()
    elseif input.KeyCode == Enum.KeyCode.Insert then
        _G.AutoServerHop = not _G.AutoServerHop
        UI:UpdateToggles()
        send_notification("AUTO HOP: " .. (_G.AutoServerHop and "LIGADO" or "DESLIGADO"))
    end
end)

task.spawn(function()
    local counter = 0
    while true do
        counter = counter + 0.01
        local rainbowColor = Color3.fromHSV(counter % 1, 0.8, 1)
        for _, obj in pairs(UI.RainbowElements) do
            pcall(function() obj.Color = rainbowColor end)
        end
        task.wait(0.03)
    end
end)

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
            if entityName:lower():find(target:lower(), 1, true) then
                targetFound = true
                break
            end
        end

        if targetFound and not notifiedEntities[instance] then
            notifiedEntities[instance] = true
            local pos = "Desconhecida"
            pcall(function()
                pos = instance:IsA("BasePart") and instance.Position or instance:GetPivot().Position
            end)
            send_notification("VIOLENT: " .. entityName)
            sendWebhook(entityName, pos)
        end
    end
end

-- Inicialização Final
task.spawn(function()
    pcall(function() UI:Init() end)
    send_notification("VIOLENT NATIVE CARREGADO!")
    
    while true do
        pcall(checkEntities)
        if _G.AutoServerHop and (tick() - lastHop >= _G.HopInterval) then
            lastHop = tick()
            send_notification("Iniciando Server Hop...")
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        end
        task.wait(5)
    end
end)
