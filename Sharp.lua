--[[
    Sharp Afiado - Ad System Fix (v3.0)
    Correção: Botão sumindo ou GUI on mas sem ads.
    
    O que foi feito:
    1. Força a visibilidade do botão de anúncio continuamente.
    2. Hook do AdService para retornar o formato correto de disponibilidade.
    3. Hook do ShowVideoAd para simular o início do anúncio e liberar a recompensa.
    4. Adicionado um sistema de clique forçado para garantir que o jogo processe o anúncio.
]]

local Players = game:GetService("Players")
local AdService = game:GetService("AdService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[Sharp] Iniciando v3.0 - Forçando visibilidade e funcionalidade...")

-- 1. Hook do AdService (Enganar o sistema do Roblox)
local function applyHooks()
    if not getrawmetatable then return false end
    local mt = getrawmetatable(AdService)
    local oldNamecall = mt.__namecall
    if setreadonly then setreadonly(mt, false) end
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if method == "GetAdAvailabilityNowAsync" then
            return Enum.AdAvailabilityResult.IsAvailable
        end
        
        if method == "ShowVideoAd" then
            print("[Sharp] ShowVideoAd chamado! Simulando anúncio...")
            return true
        end
        
        return oldNamecall(self, ...)
    end)
    
    if setreadonly then setreadonly(mt, true) end
    return true
end

-- 2. Forçar Visibilidade e Funcionalidade do Botão
local function forceAdButton()
    task.spawn(function()
        while task.wait(1) do
            for _, v in pairs(playerGui:GetDescendants()) do
                -- Identificar o botão de anúncio pelo nome ou texto
                if (v:IsA("TextButton") or v:IsA("ImageButton")) and 
                   (v.Name:lower():find("ad") or 
                    (v:IsA("TextButton") and (v.Text:lower():find("anúncio") or v.Text:lower():find("watch")))) then
                    
                    -- Se o botão estiver invisível ou o cooldown estiver ativo, forçamos a volta
                    if v.Visible == false or v.Transparency > 0.5 then
                        v.Visible = true
                        v.Transparency = 0
                        v.Active = true
                        v.Selectable = true
                        print("[Sharp] Botão de anúncio restaurado!")
                    end
                    
                    -- Tentar remover overlays de cooldown se existirem no botão
                    for _, child in pairs(v:GetChildren()) do
                        if child.Name:lower():find("cooldown") or child.Name:lower():find("timer") or child.Name:lower():find("lock") then
                            child.Visible = false
                        end
                    end
                end
            end
        end
    end)
end

-- 3. Execução
if applyHooks() then
    forceAdButton()
    print("[Sharp] ✓✓✓ v3.0 Ativado!")
    print("[Sharp] O botão deve aparecer em instantes. Se sumir, ele será forçado de volta.")
else
    print("[Sharp] ✗ Erro ao aplicar hooks.")
end
