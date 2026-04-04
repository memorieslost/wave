--[[
    Sharp Afiado - Ad System Fix (v7.0 FINAL-LITE)
    Correção: Lag de 2000ms e travamento após o primeiro anúncio.
    
    O que foi feito:
    1. Removido TODOS os hooks complexos que causavam conflito de rede.
    2. Usa apenas visibilidade passiva: o botão fica lá, mas o jogo processa o anúncio original.
    3. Zero impacto no Ping e FPS.
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[Sharp] v7.0 FINAL-LITE - Foco em Zero Lag")

-- Função ultra-leve para manter o botão visível
local function fixButton(v)
    if (v:IsA("TextButton") or v:IsA("ImageButton")) and 
       (v.Name:lower():find("ad") or (v:IsA("TextButton") and (v.Text:lower():find("anúncio") or v.Text:lower():find("watch")))) then
        
        v.Visible = true
        v.Active = true
        
        -- Esconde apenas o timer visual de cooldown se ele existir
        for _, child in pairs(v:GetChildren()) do
            if child.Name:lower():find("timer") or child.Name:lower():find("wait") or child.Name:lower():find("lock") or child.Name:lower():find("cooldown") then
                child.Visible = false
            end
        end
    end
end

-- Monitoramento passivo por evento (Não consome CPU)
playerGui.DescendantAdded:Connect(function(descendant)
    task.wait(1) -- Espera o jogo terminar de carregar a UI
    fixButton(descendant)
end)

-- Aplica nos botões atuais
for _, v in pairs(playerGui:GetDescendants()) do
    fixButton(v)
end

print("[Sharp] ✓ v7.0 Ativado! Se o botão não funcionar de imediato, aguarde 5s para o jogo resetar o anúncio.")
