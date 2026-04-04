--[[
    Sharp Afiado - Remove Cooldown (Minimalista)
    Apenas remove o cooldown do botão "Ver Anúncio"
    Sem GUI, sem auto-clicker, sem complicação
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[Sharp] Removendo cooldown do botão Ver Anúncio...")

-- Encontrar o módulo BoxBuy que controla a loja
local function encontrarBoxBuyModule()
    local function buscar(obj)
        if obj:IsA("ModuleScript") and obj.Name == "BoxBuy" then
            return obj
        end
        for _, child in pairs(obj:GetChildren()) do
            local resultado = buscar(child)
            if resultado then
                return resultado
            end
        end
        return nil
    end
    return buscar(ReplicatedStorage)
end

-- Estratégia: Hookear o método que controla a visibilidade do botão
local function removerCooldown()
    local AdService = game:GetService("AdService")
    
    -- Hook 1: Fazer GetAdAvailabilityNowAsync sempre retornar disponível
    if getrawmetatable then
        local mt = getrawmetatable(AdService)
        if mt then
            local oldNamecall = mt.__namecall
            
            if setreadonly then setreadonly(mt, false) end
            
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                
                if method == "GetAdAvailabilityNowAsync" then
                    -- Retornar que o anúncio está sempre disponível
                    return {
                        AdAvailabilityResult = Enum.AdAvailabilityResult.IsAvailable
                    }
                end
                
                return oldNamecall(self, ...)
            end)
            
            if setreadonly then setreadonly(mt, true) end
            
            print("[Sharp] ✓ Hook do AdService ativado - Cooldown removido!")
            return true
        end
    end
    
    return false
end

-- Estratégia 2: Monitorar e forçar o botão visível
local function forcarBotaoVisivel()
    task.spawn(function()
        while true do
            task.wait(0.1)
            
            -- Procurar por qualquer botão chamado BuyAd ou similar
            for _, obj in pairs(playerGui:GetDescendants()) do
                if obj:IsA("GuiObject") and obj.Name == "BuyAd" then
                    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                        obj.Visible = true
                    elseif obj:IsA("Frame") then
                        -- Se for um frame, procurar o botão dentro
                        local btn = obj:FindFirstChildOfClass("TextButton") or obj:FindFirstChildOfClass("ImageButton")
                        if btn then
                            btn.Visible = true
                        end
                    end
                end
            end
        end
    end)
    
    print("[Sharp] ✓ Loop de forçar botão visível ativado!")
end

-- Estratégia 3: Hookear a função que define a visibilidade
local function hookearVisibilidade()
    local function buscarEHookear(obj)
        if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            -- Tentar encontrar scripts que controlam a loja
            if obj.Name:find("Box") or obj.Name:find("Gacha") or obj.Name:find("Shop") then
                print("[Sharp] Encontrado script: " .. obj.Name)
            end
        end
        
        for _, child in pairs(obj:GetChildren()) do
            buscarEHookear(child)
        end
    end
    
    buscarEHookear(playerGui)
end

-- Executar tudo
print("[Sharp] Iniciando remoção de cooldown...")

removerCooldown()
forcarBotaoVisivel()

print("[Sharp] ✓✓✓ Script ativado!")
print("[Sharp] O botão 'Ver Anúncio' agora não tem cooldown!")
print("[Sharp] Clique manual, assista 7s, clique de novo SEM esperar!")
