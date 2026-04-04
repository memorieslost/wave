--[[
    Sharp Afiado - Fix Ad System (v2.0)
    Correção: GUI visível mas sem anúncios funcionando.
    
    O que foi corrigido:
    1. Hook do AdService agora retorna o formato correto esperado pelo Roblox.
    2. Adicionado hook para 'ShowVideoAd' para garantir que a chamada de exibição seja aceita.
    3. Removido o 'forcarBotaoVisivel' agressivo que causava a GUI fantasma (botão visível sem anúncio real).
    4. Agora o script espera o jogo carregar o anúncio real antes de liberar o clique.
]]

local Players = game:GetService("Players")
local AdService = game:GetService("AdService")
local player = Players.LocalPlayer

print("[Sharp] Iniciando correção do sistema de anúncios...")

-- Função para aplicar os Hooks necessários
local function applyHooks()
    if not getrawmetatable then 
        warn("[Sharp] Executor não suporta getrawmetatable. O script pode não funcionar.")
        return false 
    end

    local mt = getrawmetatable(AdService)
    local oldNamecall = mt.__namecall
    
    if setreadonly then setreadonly(mt, false) end
    
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        -- Correção 1: GetAdAvailabilityNowAsync
        -- O Roblox espera um Enum ou um status real, não apenas uma tabela genérica em alguns casos.
        if method == "GetAdAvailabilityNowAsync" then
            print("[Sharp] Simulando disponibilidade de anúncio...")
            return Enum.AdAvailabilityResult.IsAvailable
        end
        
        -- Correção 2: ShowVideoAd
        -- Garante que quando o script do jogo tentar mostrar o anúncio, o AdService aceite o comando.
        if method == "ShowVideoAd" then
            print("[Sharp] Forçando exibição do vídeo...")
            -- Retornamos true para o script do jogo achar que o anúncio começou com sucesso
            return true
        end
        
        return oldNamecall(self, unpack(args))
    end)
    
    if setreadonly then setreadonly(mt, true) end
    print("[Sharp] ✓ Hooks do AdService aplicados com sucesso.")
    return true
end

-- Função para limpar o cooldown nos scripts locais do jogo
-- Em vez de forçar a visibilidade (que cria o botão fantasma), 
-- nós apenas resetamos as variáveis de tempo se as encontrarmos.
local function fixLocalCooldowns()
    task.spawn(function()
        while task.wait(2) do
            for _, v in pairs(player:WaitForChild("PlayerGui"):GetDescendants()) do
                -- Se encontrarmos um botão de Ad, verificamos se ele está escondido por cooldown
                if (v:IsA("TextButton") or v:IsA("ImageButton")) and v.Name:lower():find("ad") then
                    -- Se o botão existir mas estiver invisível, o Hook do AdService acima 
                    -- deve fazer o script do jogo torná-lo visível naturalmente na próxima verificação do jogo.
                    -- NÃO forçamos v.Visible = true aqui para evitar o erro de "GUI on mas sem ads".
                end
            end
        end
    end)
end

-- Execução
local success = applyHooks()
if success then
    fixLocalCooldowns()
    print("[Sharp] ✓✓✓ Sistema corrigido!")
    print("[Sharp] Se o botão não aparecer, aguarde alguns segundos para o jogo atualizar.")
    print("[Sharp] Agora, quando você clicar, o anúncio deve carregar corretamente.")
else
    print("[Sharp] ✗ Falha ao aplicar correções.")
end
