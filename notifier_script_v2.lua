--[[
    BRAINROT NOTIFIER V2 - ULTIMATE EDITION (PRIORITY FOCUS)
    Desenvolvido para: Notificação EXCLUSIVA de Sammino_Vermicello, Karker_Spot, Rubrizzio_Fortuna_Mangiatore, Strawberry_Elephant e John_Pork.
    Funcionalidades: GUI, Auto Server Hop (5 min), Manual Server Hop, Webhook Discord
]]

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "Brainrot Notifier V2 - Priority Focus",
   LoadingTitle = "Carregando Notifier...",
   LoadingSubtitle = "by Manus AI",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "BrainrotNotifier",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "",
      RememberJoins = true
   },
   KeySystem = false
})

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- Variáveis de Configuração
local _G = getgenv and getgenv() or _G
_G.WebhookURL = "https://ptb.discord.com/api/webhooks/1488318065220260102/o9XXB175X8qtZmCmeivz6_PiTfqIGe9qjEYLS0V6HY0RQCqH2Zo0oOxO93oFLvHqyBIW"
_G.AutoServerHop = true
_G.DetectionEnabled = true

-- LISTA DE PRIORIDADES EXCLUSIVAS (Ordem de foco e necessidade)
local TARGET_NAMES = {
    "Sammino_Vermicello", -- Prioridade 1
    "Karker_Spot",        -- Prioridade 2
    "Rubrizzio_Fortuna_Mangiatore", -- Prioridade 3
    "Strawberry_Elephant", -- Prioridade 4
    "John_Pork"           -- Prioridade 5
}

local notifiedEntities = {}
local lastHop = tick()
local hopInterval = 300 -- 5 minutos

-- Função de Webhook
local function sendWebhook(entityName, position, placeId, jobId, accountName)
    if _G.WebhookURL == "" or _G.WebhookURL == "SUA_WEBHOOK_URL_AQUI" then return end
    
    local data = {
        ["content"] = "@everyone",
        ["embeds"] = {{
            ["title"] = "🚨 ALVO PRIORITÁRIO DETECTADO!",
            ["description"] = string.format("**Entidade:** %s\n**Localização:** %s\n**Conta:** %s\n**Place ID:** %d\n**Job ID:** %s", 
                entityName, tostring(position), accountName, placeId, jobId),
            ["color"] = 16711680, -- Vermelho para destaque
            ["footer"] = {["text"] = "Brainrot Notifier V2 - Priority Focus"}
        }}
    }
    
    local success, err = pcall(function()
        local request_func = (syn and syn.request or http_request or http and http.request or HttpService.request or request)
        if request_func then
            request_func({
                Url = _G.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        else
            warn("Executor não suporta requisições HTTP externas.")
        end
    end)
    
    if not success then warn("Erro Webhook: " .. tostring(err)) end
end

-- Função de Server Hop (Client-Side)
local function serverHop()
    local Http = HttpService
    local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
    
    local function GetServers(cursor)
        local url = Api .. (cursor and "&cursor=" .. cursor or "")
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        if success and result then
            return Http:JSONDecode(result)
        end
        return nil
    end
    
    local servers = GetServers()
    if servers and servers.data then
        local availableServers = {}
        for _, server in pairs(servers.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                table.insert(availableServers, server)
            end
        end

        if #availableServers > 0 then
            local randomServer = availableServers[math.random(1, #availableServers)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer.id, Players.LocalPlayer)
            return
        else
            warn("Nenhum servidor disponível encontrado. Tentando novamente...")
        end
    else
        warn("Erro ao obter lista de servidores. Tentando novamente...")
    end
    
    task.wait(5)
    serverHop()
end

-- Lógica de Detecção Aprimorada (Recursiva e com Filtro de Boss)
local function checkEntities()
    if not _G.DetectionEnabled then return end
    
    local currentNotified = {}
    for _, instance in pairs(Workspace:GetDescendants()) do
        -- Filtro de Boss: Ignorar se tiver Humanoid (conforme imagem da Dex)
        if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
            continue
        end

        local targetFound = false
        local entityName = instance.Name
        local entityPosition = nil

        -- 1. Verificar o nome da própria instância (ID dinâmico ou nome real)
        local instanceNameLower = instance.Name:lower()
        for _, target in pairs(TARGET_NAMES) do
            if instanceNameLower:find(target:lower(), 1, true) then
                targetFound = true
                break
            end
        end

        -- 2. Se não encontrou, verificar nos filhos (Detecção Profunda para IDs dinâmicos)
        if not targetFound then
            for _, child in pairs(instance:GetChildren()) do
                local childNameLower = child.Name:lower()
                for _, target in pairs(TARGET_NAMES) do
                    if childNameLower:find(target:lower(), 1, true) then
                        targetFound = true
                        entityName = child.Name
                        break
                    end
                end
                if targetFound then break end
            end
        end

        -- Se encontrou um alvo prioritário
        if targetFound and not notifiedEntities[instance] then
            -- Determinar posição (PrimaryPart ou Position)
            if instance:IsA("Model") then
                entityPosition = instance.PrimaryPart and instance.PrimaryPart.Position or instance:GetPivot().Position
            elseif instance:IsA("BasePart") then
                entityPosition = instance.Position
            end

            if entityPosition then
                notifiedEntities[instance] = true
                currentNotified[instance] = true
                sendWebhook(entityName, entityPosition, game.PlaceId, game.JobId, Players.LocalPlayer.Name)
                Rayfield:Notify({
                    Title = "ALVO PRIORITÁRIO!",
                    Content = "Encontrado: " .. entityName,
                    Duration = 10,
                    Image = 4483362458,
                })
            end
        end
    end

    -- Limpar cache de notificações para entidades removidas
    for entity, _ in pairs(notifiedEntities) do
        if not entity.Parent then
            notifiedEntities[entity] = nil
        end
    end
end

-- Tabs da GUI
local MainTab = Window:CreateTab("Principal", 4483362458)

MainTab:CreateInput({
   Name = "Webhook URL",
   PlaceholderText = "Cole sua Webhook aqui",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      _G.WebhookURL = Text
   end,
})

MainTab:CreateToggle({
   Name = "Ativar Detecção",
   CurrentValue = true,
   Flag = "ToggleDetection",
   Callback = function(Value)
      _G.DetectionEnabled = Value
   end,
})

MainTab:CreateToggle({
   Name = "Auto Server Hop (5 min)",
   CurrentValue = true,
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

-- Loop de Execução
task.spawn(function()
    while true do
        checkEntities()
        
        if _G.AutoServerHop and (tick() - lastHop >= hopInterval) then
            serverHop()
            lastHop = tick()
        end
        
        task.wait(5)
    end
end)

Rayfield:Notify({
   Title = "Notifier Ativo",
   Content = "Focado em alvos prioritários!",
   Duration = 5,
   Image = 4483362458,
})
