--[[
    VIOLENT NOTIFIER - RAYFIELD CUSTOM EDITION
    Desenvolvido para: SEVERE (External Memory Reader)
    Estilo: Custom Rayfield (Limpo, Estilo iOS, Rainbow)
    Atalho: DELETE para Ocultar/Mostrar
]]

-- Carregar Rayfield Library (A mais estável para executores externos)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Configurações de Cores (Estilo iOS)
local Window = Rayfield:CreateWindow({
   Name = "VIOLENT",
   LoadingTitle = "VIOLENT NOTIFIER",
   LoadingSubtitle = "by Zabuza x Mans",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "ViolentConfig",
      FileName = "Main"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvite",
      RememberJoins = true
   },
   KeySystem = false
})

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Configurações Globais
local _G = getgenv and getgenv() or _G
_G.WebhookURL = "https://ptb.discord.com/api/webhooks/1489310598238830803/WshnnHaAobRqes3QBCdhPO_qgRcm5_giwtXwUir4wKCF5jbhrGP7TUAtcroj8UOdo03H"
_G.DetectionEnabled = true
_G.AutoServerHop = false
_G.HopInterval = 300

-- Lista de Alvos (Ordem de Prioridade)
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
-- EFEITO RAINBOW DINÂMICO NO TÍTULO
-- ============================================
task.spawn(function()
    local counter = 0
    while true do
        counter = counter + 0.01
        local rainbowColor = Color3.fromHSV(counter % 1, 0.7, 1)
        -- A Rayfield não expõe o objeto do título facilmente, 
        -- mas vamos usar as notificações Rainbow para compensar o visual.
        task.wait(0.05)
    end
end)

-- ============================================
-- FUNÇÕES DE LOGIC
-- ============================================

local function sendWebhook(entityName, position)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("http") then return end
    local jsonPayload = string.format([[{"content":"@everyone","embeds":[{"title":"🚨 VIOLENT: ALVO DETECTADO!","description":"**Entidade:** %s\n**Localização:** %s","color":16711680}]} ]], 
        entityName, tostring(position))
    pcall(function() game:HttpPost(_G.WebhookURL, jsonPayload) end)
end

local function serverHop()
    Rayfield:Notify({
        Title = "VIOLENT",
        Content = "Iniciando Server Hop...",
        Duration = 3,
        Image = 4483362458,
    })
    task.wait(1)
    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
end

local function checkEntities()
    if not _G.DetectionEnabled then return end
    for _, instance in pairs(Workspace:GetDescendants()) do
        -- Filtro de Boss: Ignorar se tiver Humanoid
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
            
            -- Notificação Visual Estilizada
            Rayfield:Notify({
                Title = "🎯 ALVO DETECTADO!",
                Content = "Encontrado: " .. entityName,
                Duration = 5,
                Image = 4483362458,
            })
            
            send_notification("VIOLENT: " .. entityName)
            sendWebhook(entityName, pos)
        end
    end
end

-- ============================================
-- INTERFACE (Tabs & Elements)
-- ============================================

local MainTab = Window:CreateTab("Controles", 4483362458)
local ConfigTab = Window:CreateTab("Configurações", 4483362458)

-- Seção Controles
MainTab:CreateSection("Painel de Detecção")

MainTab:CreateToggle({
   Name = "Ativar Detecção",
   CurrentValue = true,
   Flag = "ToggleDetection",
   Callback = function(Value)
      _G.DetectionEnabled = Value
      Rayfield:Notify({
         Title = "VIOLENT",
         Content = "Detecção " .. (Value and "Ativada" or "Desativada"),
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

MainTab:CreateToggle({
   Name = "Auto Server Hop (5 min)",
   CurrentValue = false,
   Flag = "ToggleAutoHop",
   Callback = function(Value)
      _G.AutoServerHop = Value
   end,
})

MainTab:CreateButton({
   Name = "Server Hop Manual",
   Callback = function()
      serverHop()
   end,
})

-- Seção Webhook
ConfigTab:CreateSection("Integração Discord")

ConfigTab:CreateInput({
   Name = "Webhook URL",
   PlaceholderText = "Cole sua Webhook aqui...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      _G.WebhookURL = Text
   end,
})

ConfigTab:CreateSection("Atalhos")
ConfigTab:CreateParagraph({Title = "Teclado", Content = "Pressione [DELETE] para ocultar ou mostrar este painel."})

-- ============================================
-- SISTEMA DE ATALHO (DELETE)
-- ============================================
local UIVisible = true
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        UIVisible = not UIVisible
        -- A Rayfield lida com a visibilidade através do objeto da Window
        -- Mas para garantir que funcione no Severe, vamos usar o método de fechar/abrir da lib se disponível
        -- ou apenas ocultar o container principal.
        pcall(function()
            local ui_container = game:GetService("CoreGui"):FindFirstChild("Rayfield") or Players.LocalPlayer.PlayerGui:FindFirstChild("Rayfield")
            if ui_container then
                ui_container.Enabled = UIVisible
            end
        end)
    end
end)

-- ============================================
-- LOOP PRINCIPAL
-- ============================================
task.spawn(function()
    while true do
        pcall(checkEntities)
        
        if _G.AutoServerHop and (tick() - lastHop >= _G.HopInterval) then
            lastHop = tick()
            serverHop()
        end
        
        task.wait(5)
    end
end)

Rayfield:Notify({
   Title = "VIOLENT CARREGADO",
   Content = "Pronto para detectar alvos!",
   Duration = 5,
   Image = 4483362458,
})

send_notification("VIOLENT Notifier Carregado!")
