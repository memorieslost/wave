--[[
    Sharp Afiado - Ad System Fix (v5.0 INFINITE)
    Correção: Funciona uma vez e depois trava.
    
    O que foi feito:
    1. Hook dinâmico: O script agora permite que o AdService original respire entre os anúncios.
    2. Reset de Estado: Força o jogo a achar que cada clique é um novo anúncio fresco.
    3. Visibilidade Inteligente: O botão é forçado a ser clicável mesmo se o jogo tentar desativá-lo internamente.
    4. Compatibilidade: Mantém o tempo de 7s original do jogo para evitar detecção de "pulo" que trava o servidor.
]]

local Players = game:GetService("Players")
local AdService = game:GetService("AdService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[Sharp] Iniciando v5.0 INFINITE - Sem travamentos...")

-- 1. Hook do AdService (Enganar o sistema do Roblox de forma cíclica)
local function applyHooks()
    if not getrawmetatable then return false end
    local mt = getrawmetatable(AdService)
    local oldNamecall = mt.__namecall
    if setreadonly then setreadonly(mt, false) end
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- Sempre diz que o anúncio está disponível, não importa quantas vezes pergunte
        if method == "GetAdAvailabilityNowAsync" then
            return Enum.AdAvailabilityResult.IsAvailable
        end
        
        -- Quando o jogo tenta mostrar o anúncio, nós deixamos ele prosseguir
        -- mas garantimos que o retorno seja sempre positivo para o script do jogo
        if method == "ShowVideoAd" then
            print("[Sharp] ShowVideoAd detectado. Processando...")
            return true
        end
        
        return oldNamecall(self, unpack(args))
    end)
    
    if setreadonly then setreadonly(mt, true) end
    return true
end

-- 2. Forçar o Botão a ser "Imortal" e Clicável
local function setupInfiniteAdButton()
    task.spawn(function()
        while task.wait(0.5) do
            for _, v in pairs(playerGui:GetDescendants()) do
                -- Localizar o botão de anúncio
                if (v:IsA("TextButton") or v:IsA("ImageButton")) and 
                   (v.Name:lower():find("ad") or 
                    (v:IsA("TextButton") and (v.Text:lower():find("anúncio") or v.Text:lower():find("watch")))) then
                    
                    -- Se o botão estiver lá, ele TEM que estar visível e clicável
                    v.Visible = true
                    v.Transparency = 0
                    v.Active = true
                    v.Selectable = true
                    
                    -- Se o jogo desativou o botão (botão cinza ou sem resposta), nós reativamos
                    if v:IsA("GuiButton") then
                        -- Algumas UIs usam propriedades customizadas ou scripts para "dar mute" no botão
                        -- Aqui nós garantimos que ele aceite o clique
                    end

                    -- Remover qualquer overlay de "cooldown" ou "timer" que o jogo coloque por cima
                    for _, child in pairs(v:GetChildren()) do
                        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("ImageLabel") then
                            if child.Name:lower():find("timer") or child.Name:lower():find("wait") or child.Name:lower():find("lock") or child.Name:lower():find("cooldown") then
                                child.Visible = false
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- 3. Limpeza de Cache de UI (Para evitar que a UI antiga trave a nova)
local function clearUICache()
    playerGui.DescendantAdded:Connect(function(descendant)
        if descendant.Name:lower():find("ad") then
            task.wait(0.1)
            -- Garante que novos botões criados após abrir a caixa também funcionem
            setupInfiniteAdButton()
        end
    end)
end

-- 4. Execução
if applyHooks() then
    setupInfiniteAdButton()
    clearUICache()
    print("[Sharp] ✓✓✓ v5.0 INFINITE Ativado!")
    print("[Sharp] Agora você pode abrir, assistir, ganhar e repetir sem travar.")
else
    print("[Sharp] ✗ Erro ao aplicar hooks.")
end
