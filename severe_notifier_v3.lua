--[[
    SEVERE NOTIFIER V3 - CUSTOM UI EDITION
    Desenvolvido para: SEVERE (External Memory Reader)
    Estilo: Custom UI (Inspirado em Death Ball AP / New UI)
    Funcionalidades: Rainbow Title, iOS Toggles, Delete to Hide, Discord Webhook
]]

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configurações Globais
local _G = getgenv and getgenv() or _G
_G.WebhookURL = "https://ptb.discord.com/api/webhooks/1489310598238830803/WshnnHaAobRqes3QBCdhPO_qgRcm5_giwtXwUir4wKCF5jbhrGP7TUAtcroj8UOdo03H"
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
-- CUSTOM UI SYSTEM (Drawing Library)
-- ============================================

local UI = {
    Main = {},
    Toggles = {},
    Buttons = {},
    RainbowElements = {},
    Notifications = {}
}

-- Configurações de Cores e Estilo
local Colors = {
    Background = Color3.fromRGB(15, 15, 20),
    Accent = Color3.fromRGB(80, 255, 80), -- Verde iOS
    Off = Color3.fromRGB(255, 80, 80),    -- Vermelho
    Text = Color3.fromRGB(255, 255, 255),
    SecondaryText = Color3.fromRGB(180, 180, 180),
    Outline = Color3.fromRGB(0, 0, 0)
}

local function CreateRainbowEffect(obj)
    table.insert(UI.RainbowElements, obj)
end

-- Atualizador de Rainbow
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

-- Função para Criar Notificação Temporária
local function ShowLog(text, color)
    local log = Drawing.new("Text")
    log.Text = "[LOG] " .. text
    log.Size = 14
    log.Color = color or Colors.Text
    log.Outline = true
    log.Center = false
    log.Visible = _G.UIVisible
    
    -- Posição dinâmica baseada na UI
    local basePos = UI.Main.Container.Position
    log.Position = Vector2.new(basePos.X + UI.Main.Container.Size.X + 10, basePos.Y + (#UI.Notifications * 18))
    
    table.insert(UI.Notifications, log)
    
    task.delay(2, function()
        log.Visible = false
        log:Remove()
        for i, v in ipairs(UI.Notifications) do
            if v == log then
                table.remove(UI.Notifications, i)
                break
            end
        end
    end)
end

function UI:Init()
    local screenWidth = workspace.CurrentCamera.ViewportSize.X
    local screenHeight = workspace.CurrentCamera.ViewportSize.Y
    local basePos = Vector2.new(50, screenHeight * 0.3)

    -- Container Principal (Fundo Transparente/Blur Style)
    self.Main.Container = Drawing.new("Square")
    self.Main.Container.Size = Vector2.new(220, 180)
    self.Main.Container.Position = basePos
    self.Main.Container.Color = Colors.Background
    self.Main.Container.Filled = true
    self.Main.Container.Opacity = 0.8
    self.Main.Container.Rounding = 12
    self.Main.Container.Visible = true
    self.Main.Container.ZIndex = 1

    -- Título Rainbow
    self.Main.Title = Drawing.new("Text")
    self.Main.Title.Text = "VIOLENT"
    self.Main.Title.Size = 18
    self.Main.Title.Position = basePos + Vector2.new(110, 15)
    self.Main.Title.Center = true
    self.Main.Title.Outline = true
    self.Main.Title.Font = 2 -- Bold
    self.Main.Title.Visible = true
    self.Main.Title.ZIndex = 2
    CreateRainbowEffect(self.Main.Title)

    -- Linha Divisória
    self.Main.Line = Drawing.new("Line")
    self.Main.Line.From = basePos + Vector2.new(15, 40)
    self.Main.Line.To = basePos + Vector2.new(205, 40)
    self.Main.Line.Color = Color3.fromRGB(50, 50, 60)
    self.Main.Line.Thickness = 1
    self.Main.Line.Visible = true

    -- Labels e Toggles (Estilo iOS)
    local function CreateToggle(name, yOffset, flag, default)
        local label = Drawing.new("Text")
        label.Text = name
        label.Size = 14
        label.Color = Colors.SecondaryText
        label.Position = basePos + Vector2.new(15, yOffset)
        label.Visible = true
        label.ZIndex = 2

        local status = Drawing.new("Text")
        status.Text = default and "ON" or "OFF"
        status.Size = 14
        status.Color = default and Colors.Accent or Colors.Off
        status.Position = basePos + Vector2.new(170, yOffset)
        status.Visible = true
        status.ZIndex = 2
        
        UI.Toggles[flag] = {label = label, status = status, value = default}
    end

    CreateToggle("Detecção Ativa", 60, "Detection", _G.DetectionEnabled)
    CreateToggle("Auto Server Hop", 90, "AutoHop", _G.AutoServerHop)

    -- Botão Server Hop Manual
    self.Main.HopBtn = Drawing.new("Square")
    self.Main.HopBtn.Size = Vector2.new(190, 30)
    self.Main.HopBtn.Position = basePos + Vector2.new(15, 130)
    self.Main.HopBtn.Color = Color3.fromRGB(40, 40, 50)
    self.Main.HopBtn.Filled = true
    self.Main.HopBtn.Rounding = 6
    self.Main.HopBtn.Visible = true
    self.Main.HopBtn.ZIndex = 2

    self.Main.HopText = Drawing.new("Text")
    self.Main.HopText.Text = "SERVER HOP MANUAL"
    self.Main.HopText.Size = 13
    self.Main.HopText.Color = Colors.Text
    self.Main.HopText.Position = self.Main.HopBtn.Position + Vector2.new(95, 7)
    self.Main.HopText.Center = true
    self.Main.HopText.Visible = true
    self.Main.HopText.ZIndex = 3

    -- Footer
    self.Main.Footer = Drawing.new("Text")
    self.Main.Footer.Text = "[DEL] OCULTAR PAINEL"
    self.Main.Footer.Size = 10
    self.Main.Footer.Color = Color3.fromRGB(100, 100, 110)
    self.Main.Footer.Position = basePos + Vector2.new(110, 165)
    self.Main.Footer.Center = true
    self.Main.Footer.Visible = true
end

function UI:ToggleVisibility()
    _G.UIVisible = not _G.UIVisible
    self.Main.Container.Visible = _G.UIVisible
    self.Main.Title.Visible = _G.UIVisible
    self.Main.Line.Visible = _G.UIVisible
    self.Main.HopBtn.Visible = _G.UIVisible
    self.Main.HopText.Visible = _G.UIVisible
    self.Main.Footer.Visible = _G.UIVisible
    
    for _, t in pairs(self.Toggles) do
        t.label.Visible = _G.UIVisible
        t.status.Visible = _G.UIVisible
    end
end

-- ============================================
-- LOGIC & INPUT
-- ============================================

-- Atalho DELETE
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        UI:ToggleVisibility()
    end
end)

-- Simulação de Click (Como é external, o usuário clica e nós checamos a posição do mouse)
-- Nota: Para simplificar no Severe, vamos usar comandos ou apenas atualizar via Loop se houver interação
-- Mas aqui vamos focar na funcionalidade de detecção.

local function sendWebhook(entityName, position)
    if _G.WebhookURL == "" then return end
    local jsonPayload = string.format([[{"content":"@everyone","embeds":[{"title":"🚨 ALVO DETECTADO!","description":"**Entidade:** %s\n**Localização:** %s","color":16711680}]} ]], 
        entityName, tostring(position))
    pcall(function() game:HttpPost(_G.WebhookURL, jsonPayload) end)
end

local function serverHop()
    ShowLog("Iniciando Server Hop...", Colors.Accent)
    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
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
            local pos = instance:IsA("BasePart") and instance.Position or instance:GetPivot().Position
            send_notification("ALVO: " .. entityName)
            ShowLog("Detectado: " .. entityName, Colors.Accent)
            sendWebhook(entityName, pos)
        end
    end
end

-- Loop Principal
task.spawn(function()
    UI:Init()
    while true do
        pcall(checkEntities)
        if _G.AutoServerHop and (tick() - lastHop >= _G.HopInterval) then
            lastHop = tick()
            serverHop()
        end
        task.wait(5)
    end
end)

send_notification("VIOLENT Notifier Carregado!")
ShowLog("Sistema Inicializado", Colors.Accent)
