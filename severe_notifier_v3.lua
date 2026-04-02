--[[
    SEVERE NOTIFIER - PORTABILIDADE PERFEITA
    Adaptado para: SEVERE (External Memory Reader)
    Alvos: Sammino_Vermicello, Karker_Spot, Rubrizzio_Fortuna_Mangiatore, Strawberry_Elephant, John_Pork
    Funcionalidades: GUI VaderHax, Webhook Discord, Detecção de Memória, Server Hop
]]

-- Carregar Biblioteca de UI (VaderHax conforme solicitado no txt)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/x8n8x/vader/refs/heads/main/vaderhaxing"))()
local win = Library:Window({ name = "Severe Notifier - Zabuza" })
Library:Watermark({ name = "severe x zabuza" })

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- Configurações Globais
local _G = getgenv and getgenv() or _G
_G.WebhookURL = "https://ptb.discord.com/api/webhooks/1489310598238830803/WshnnHaAobRqes3QBCdhPO_qgRcm5_giwtXwUir4wKCF5jbhrGP7TUAtcroj8UOdo03H"
_G.DetectionEnabled = true
_G.AutoServerHop = false
_G.HopInterval = 300 -- 5 minutos

-- Lista de Alvos (Ordem de Prioridade)
local TARGET_NAMES = {
    "Sammino_Vermicello", -- Prioridade 1
    "Karker_Spot",        -- Prioridade 2
    "Rubrizzio_Fortuna_Mangiatore", -- Prioridade 3
    "Strawberry_Elephant", -- Prioridade 4
    "John_Pork"           -- Prioridade 5
}

local notifiedEntities = {}
local lastHop = tick()

-- Função de Webhook (Adaptada para Severe game:HttpPost)
local function sendWebhook(entityName, position)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com/api/webhooks") then return end
    
    local payload = {
        ["content"] = "@everyone",
        ["embeds"] = {{
            ["title"] = "🚨 ALVO PRIORITÁRIO DETECTADO (SEVERE)!",
            ["description"] = string.format("**Entidade:** %s\n**Localização:** %s\n**Place ID:** %d\n**Job ID:** %s\n**HWID:** %s", 
                entityName, tostring(position), game.PlaceId, game.JobId, game:GetHwid()),
            ["color"] = 16711680,
            ["footer"] = {["text"] = "Severe Notifier - Portabilidade Perfeita"}
        }}
    }
    
    -- No Severe, usamos game:HttpPost para enviar dados
    -- Nota: Precisamos converter a tabela para JSON string. 
    -- Como o Severe não tem HttpService exposto na doc, mas tem game:HttpPost,
    -- assume-se que o usuário pode precisar de uma lib JSON ou o executor faz o wrap.
    -- Se não houver lib JSON, enviaremos como string formatada manualmente para garantir.
    
    local jsonPayload = string.format([[{"content":"@everyone","embeds":[{"title":"🚨 ALVO PRIORITÁRIO DETECTADO (SEVERE)!","description":"**Entidade:** %s\n**Localização:** %s\n**Place ID:** %d\n**Job ID:** %s","color":16711680}]} ]], 
        entityName, tostring(position), game.PlaceId, game.JobId)

    pcall(function()
        game:HttpPost(_G.WebhookURL, jsonPayload)
    end)
end

-- Função de Server Hop (Simplificada para External)
local function serverHop()
    -- Em externos como Severe, o teleporte pode ser instável via script se não houver API de rede completa.
    -- Tentaremos usar o método padrão de busca de servidores via HttpGet.
    pcall(function()
        local servers = {}
        local res = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=50")
        -- Parsing manual simples de JSON se necessário, mas aqui assumimos que o usuário quer a funcionalidade.
        -- Devido às limitações de parsing JSON em ambientes externos puros, 
        -- o ideal é usar uma URL de API que retorne apenas o ID do servidor ou um script de hop universal.
        send_notification("Tentando trocar de servidor...")
        -- Implementação básica de hop
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    end)
end

-- Lógica de Detecção (Aproveitando o ExplorerDex/Mem do Severe)
local function checkEntities()
    if not _G.DetectionEnabled then return end
    
    -- O Severe permite iterar sobre Workspace:GetDescendants() de forma eficiente
    for _, instance in pairs(Workspace:GetDescendants()) do
        -- Filtro de Boss: Ignorar se tiver Humanoid (conforme especificado)
        if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
            continue
        end

        local targetFound = false
        local entityName = instance.Name

        -- Detecção Profunda (Mesma lógica do v2, mas rodando no ambiente Severe)
        for _, target in pairs(TARGET_NAMES) do
            if entityName:lower():find(target:lower(), 1, true) then
                targetFound = true
                break
            end
        end

        if not targetFound then
            for _, child in pairs(instance:GetChildren()) do
                for _, target in pairs(TARGET_NAMES) do
                    if child.Name:lower():find(target:lower(), 1, true) then
                        targetFound = true
                        entityName = child.Name
                        break
                    end
                end
                if targetFound then break end
            end
        end

        if targetFound and not notifiedEntities[instance] then
            local position = "Desconhecida"
            pcall(function()
                if instance:IsA("Model") then
                    position = instance:GetPivot().Position
                elseif instance:IsA("BasePart") then
                    position = instance.Position
                end
            end)

            notifiedEntities[instance] = true
            send_notification("ALVO DETECTADO: " .. entityName)
            Library:AddNotification("Alvo Encontrado", entityName, 5)
            sendWebhook(entityName, position)
        end
    end

    -- Limpeza de cache
    for entity, _ in pairs(notifiedEntities) do
        if not entity or not entity.Parent then
            notifiedEntities[entity] = nil
        end
    end
end

-- Tabs da UI
local main = win:Tab({ name = "Principal" })
local settings = win:Tab({ name = "Configurações" })

local mainSection = main:Section({ name = "Controles", side = "left" })
local webhookSection = settings:Section({ name = "Webhook", side = "left" })

mainSection:Toggle({
    name = "Ativar Detecção",
    flag = "det_enabled",
    default = true,
    callback = function(v)
        _G.DetectionEnabled = v
        Library:AddNotification("Notifier", v and "Ativado" or "Desativado", 2)
    end
})

mainSection:Toggle({
    name = "Auto Server Hop",
    flag = "auto_hop",
    default = false,
    callback = function(v)
        _G.AutoServerHop = v
    end
})

mainSection:Button({
    name = "Server Hop Manual",
    callback = function()
        serverHop()
    end
})

webhookSection:TextBox({
    name = "Discord Webhook URL",
    flag = "webhook_url",
    default = "",
    placeholder = "Cole aqui...",
    callback = function(v)
        _G.WebhookURL = v
    end
})

-- Loop de Execução (Usando task.wait para estabilidade no Severe)
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

send_notification("Severe Notifier Carregado!")
Library:AddNotification("Sucesso", "Script adaptado para Severe carregado com sucesso!", 3)
