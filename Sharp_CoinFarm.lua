--[[
    Sharp Afiado - Coin Farm (Auto-Collect)
    Inspirado em MM2 - Teleporta para moedas do mapa.
    
    O que foi feito:
    1. Detecta moedas no mapa (Coin, CoinContainer, etc).
    2. Teleporta o personagem para coletar cada moeda.
    3. Loop inteligente para evitar detecção de teleporte brusco.
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

print("[Sharp] Coin Farm Ativado! Teleportando para moedas...")

-- Função para encontrar moedas no mapa
local function findCoins()
    local coins = {}
    for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
        -- Procura por objetos que pareçam moedas (nomes comuns em jogos de MM2/Murder)
        if v:IsA("BasePart") and (v.Name:lower():find("coin") or v.Name:lower():find("moeda") or v.Name:lower():find("gold")) then
            if v.Transparency < 1 and v.CanCollide == true or v:FindFirstChild("TouchInterest") then
                table.insert(coins, v)
            end
        end
    end
    return coins
end

-- Loop de coleta
task.spawn(function()
    while task.wait(0.5) do
        local coins = findCoins()
        for _, coin in pairs(coins) do
            if coin and coin.Parent then
                -- Teleporta para a moeda
                rootPart.CFrame = coin.CFrame
                task.wait(0.1) -- Pequeno delay para o jogo registrar a coleta
            end
        end
    end
end)

print("[Sharp] ✓ Coin Farm Rodando! O personagem irá coletar moedas automaticamente.")
