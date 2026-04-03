--[[
    BRAINROT NOTIFIER V2 - ULTIMATE EDITION (PRIORITY FOCUS)
    CORRIGIDO: Filtro de Bases, Coordenadas Amigáveis e Detecção de ZONAS
    Desenvolvido para: Notificação EXCLUSIVA de Sammino_Vermicello, Karker_Spot, Rubrizzio_Fortuna_Mangiatore, Strawberry_Elephant e John_Pork.
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
_G.WebhookURL = "https://ptb.discord.com/api/webhooks/1489310598238830803/WshnnHaAobRqes3QBCdhPO_qgRcm5_giwtXwUir4wKCF5jbhrGP7TUAtcroj8UOdo03H"
_G.AutoServerHop = true
_G.DetectionEnabled = true

-- LISTA DE PRIORIDADES EXCLUSIVAS
local TARGET_NAMES = {
    "Sammino_Vermicello", 
    "Karker_Spot",        
    "Rubrizzio_Fortuna_Mangiatore", 
    "Strawberry_Elephant", 
    "John_Pork"           
}

local notifiedEntities = {}
local lastHop = tick()
local hopInterval = 300 -- 5 minutos

-- Função para formatar coordenadas de forma legível
local function formatCoords(pos)
    if not pos then return "N/A" end
    return string.format("X: %.0f, Y: %.0f, Z: %.0f", pos.X, pos.Y, pos.Z)
end

-- Função para detectar a ZONA onde o item está
local function getZoneName(instance)
    -- Tenta encontrar o nome da Zona subindo na hierarquia do objeto
    -- Geralmente os itens ficam dentro de pastas como Workspace.Zones["Rare Zone"].Items
    local p = instance.Parent
    while p and p ~= Workspace do
        local name = p.Name:lower()
        if name:find("zone") or name:find("area") or name:find("map") then
            return p.Name
        end
        p = p.Parent
    end
    
    -- Se não achou pelo pai, tenta verificar se o objeto está dentro de alguma parte de detecção de zona (Region3/Touch)
    -- Ou retorna "Desconhecida" se não houver estrutura clara
    return "Zona Desconhecida"
end

-- Função para verificar se o objeto está na base de alguém
local function isInPlayerBase(instance)
    local p = instance.Parent
    while p and p ~= Workspace do
        local name = p.Name:lower()
        -- Filtra bases de Tycoon/Simulator comuns
        if name:find("base") or name:find("plot") or name:find("house") or name:find("owned") or name:find("player") then
            return true
        end
        -- Se o pai for o nome de um jogador atual
        if Players:FindFirstChild(p.Name) then
            return true
        end
        p = p.Parent
    end
    return false
end

-- Função de Webhook
local function sendWebhook(entityName, position, zoneName, placeId, jobId, accountName)
    if _G.WebhookURL == "" or _G.WebhookURL == "SUA_WEBHOOK_URL_AQUI" then return end
    
    local formattedPos = formatCoords(position)
    local data = {
        ["content"] = "@everyone",
        ["embeds"] = {{
            ["title"] = "🚨 ALVO PRIORITÁRIO DETECTADO!",
            ["description"] = string.format("**Entidade:** %s\n**Zona:** %s\n**Localização:** %s\n**Conta:** %s\n**Place ID:** %d\n**Job ID:** %s", 
                entityName, zoneName, formattedPos, accountName, placeId, jobId),
            ["color"] = 16711680,
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
        end
    end)
end

-- Função de Server Hop
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
        end
    end
end

-- Lógica de Detecção Aprimorada
local function checkEntities()
    if not _G.DetectionEnabled then return end
    
    for _, instance in pairs(Workspace:GetDescendants()) do
        -- Filtro de Boss/NPC: Ignorar se tiver Humanoid
        if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
            continue
        end

        -- NOVO FILTRO: Ignorar se estiver em uma base de jogador
        if isInPlayerBase(instance) then
            continue
        end

        local targetFound = false
        local entityName = instance.Name
        local entityPosition = nil

        local instanceNameLower = instance.Name:lower()
        for _, target in pairs(TARGET_NAMES) do
            if instanceNameLower:find(target:lower(), 1, true) then
                targetFound = true
                break
            end
        end

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

        if targetFound and not notifiedEntities[instance] then
            if instance:IsA("Model") then
                entityPosition = instance.PrimaryPart and instance.PrimaryPart.Position or instance:GetPivot().Position
            elseif instance:IsA("BasePart") then
                entityPosition = instance.Position
            end

            if entityPosition then
                local zoneName = getZoneName(instance)
                notifiedEntities[instance] = true
                sendWebhook(entityName, entityPosition, zoneName, game.PlaceId, game.JobId, Players.LocalPlayer.Name)
                Rayfield:Notify({
                    Title = "ALVO PRIORITÁRIO!",
                    Content = "Encontrado: " .. entityName .. " na " .. zoneName,
                    Duration = 10,
                    Image = 4483362458,
                })
            end
        end
    end

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
   Content = "Corrigido: Filtro de bases e Detecção de Zonas!",
   Duration = 5,
   Image = 4483362458,
})
