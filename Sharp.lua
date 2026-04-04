--[[
    ============================================================
    Sharp Afiado - Ad Cooldown Bypass VERSÃO CORRIGIDA
    ============================================================
    Funcionalidades:
      1) Remove o cooldown do anúncio (botão "Ver Anúncio" sempre visível)
      2) Dispara o RemoteEvent AdBoxBuy corretamente
      3) Loop automático opcional para abrir caixas infinitas
    
    Caixas disponíveis: ToyBox, BlacksmithBox, FoodBox
    ============================================================
]]

-- ===================== CONFIGURAÇÃO =====================
local CONFIG = {
    AutoFarm = false,
    BoxName = "ToyBox",
    DelayEntreAberturas = 1,
}
-- ========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== VARIÁVEIS GLOBAIS =====
local adBoxBuyRemote = nil
local remoteFound = false
local debugMode = true

-- ===== FUNÇÃO DE LOG =====
local function log(msg, isError)
    local prefix = isError and "[❌ ERRO]" or "[✓ INFO]"
    print(prefix .. " " .. msg)
end

-- ===== ESTRATÉGIA 1: Buscar RemoteEvent no caminho padrão =====
local function buscarRemoteEstrategia1()
    log("Estratégia 1: Buscando em ReplicatedStorage.Shared.Remote.RemoteEvents...")
    
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if not shared then
        log("Shared não encontrado", true)
        return nil
    end
    
    local remote = shared:FindFirstChild("Remote")
    if not remote then
        log("Remote não encontrado", true)
        return nil
    end
    
    local remoteEvents = remote:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        log("RemoteEvents não encontrado", true)
        return nil
    end
    
    local adBoxBuy = remoteEvents:FindFirstChild("AdBoxBuy")
    if adBoxBuy then
        log("✓ AdBoxBuy encontrado em ReplicatedStorage.Shared.Remote.RemoteEvents!")
        return adBoxBuy
    end
    
    log("AdBoxBuy não encontrado neste caminho", true)
    return nil
end

-- ===== ESTRATÉGIA 2: Buscar recursivamente em toda ReplicatedStorage =====
local function buscarRemoteEstrategia2()
    log("Estratégia 2: Buscando AdBoxBuy recursivamente em ReplicatedStorage...")
    
    local function buscarRecursivo(obj)
        if obj:IsA("RemoteEvent") and obj.Name == "AdBoxBuy" then
            return obj
        end
        
        for _, child in pairs(obj:GetChildren()) do
            local resultado = buscarRecursivo(child)
            if resultado then
                return resultado
            end
        end
        
        return nil
    end
    
    local resultado = buscarRecursivo(ReplicatedStorage)
    if resultado then
        log("✓ AdBoxBuy encontrado recursivamente em: " .. resultado:GetFullName())
        return resultado
    end
    
    log("AdBoxBuy não encontrado recursivamente", true)
    return nil
end

-- ===== ESTRATÉGIA 3: Buscar em toda a hierarquia do jogo =====
local function buscarRemoteEstrategia3()
    log("Estratégia 3: Buscando AdBoxBuy em toda a hierarquia...")
    
    local function buscarRecursivoGlobal(obj, depth)
        depth = depth or 0
        if depth > 10 then return nil end
        
        if obj:IsA("RemoteEvent") and obj.Name == "AdBoxBuy" then
            return obj
        end
        
        for _, child in pairs(obj:GetChildren()) do
            local resultado = buscarRecursivoGlobal(child, depth + 1)
            if resultado then
                return resultado
            end
        end
        
        return nil
    end
    
    local resultado = buscarRecursivoGlobal(game)
    if resultado then
        log("✓ AdBoxBuy encontrado em: " .. resultado:GetFullName())
        return resultado
    end
    
    log("AdBoxBuy não encontrado em nenhum lugar", true)
    return nil
end

-- ===== ESTRATÉGIA 4: Esperar pelo RemoteEvent ser criado =====
local function buscarRemoteEstrategia4()
    log("Estratégia 4: Aguardando RemoteEvent ser criado...")
    
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if shared then
        local remote = shared:FindFirstChild("Remote")
        if remote then
            local remoteEvents = remote:FindFirstChild("RemoteEvents")
            if remoteEvents then
                local adBoxBuy = remoteEvents:WaitForChild("AdBoxBuy", 5)
                if adBoxBuy then
                    log("✓ AdBoxBuy criado e encontrado!")
                    return adBoxBuy
                end
            end
        end
    end
    
    log("Timeout esperando AdBoxBuy", true)
    return nil
end

-- ===== ENCONTRAR O REMOTE EVENT =====
local function encontrarRemote()
    log("Iniciando busca pelo RemoteEvent AdBoxBuy...")
    
    -- Tentar todas as estratégias
    local remote = buscarRemoteEstrategia1()
    if remote then return remote end
    
    task.wait(0.5)
    remote = buscarRemoteEstrategia2()
    if remote then return remote end
    
    task.wait(0.5)
    remote = buscarRemoteEstrategia3()
    if remote then return remote end
    
    task.wait(0.5)
    remote = buscarRemoteEstrategia4()
    if remote then return remote end
    
    log("FALHA: Não foi possível encontrar o RemoteEvent AdBoxBuy!", true)
    return nil
end

-- ===== FUNÇÃO PARA ABRIR CAIXA =====
local function abrirCaixaGratis(boxName)
    if not adBoxBuyRemote then
        log("RemoteEvent não está disponível!", true)
        return false
    end
    
    local clientToken = math.random()
    
    log("Disparando: " .. boxName .. " | Token: " .. tostring(clientToken))
    
    local sucesso, erro = pcall(function()
        adBoxBuyRemote:FireServer(boxName, clientToken)
    end)
    
    if sucesso then
        log("✓ FireServer enviado com sucesso!")
        return true
    else
        log("Erro ao disparar: " .. tostring(erro), true)
        return false
    end
end

-- ===== CRIAR GUI =====
local function criarGUI()
    local oldGui = playerGui:FindFirstChild("SharpAdGUI")
    if oldGui then oldGui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SharpAdGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 240, 0, 300)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 200, 0)
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "SHARP AD BYPASS"
    title.TextColor3 = Color3.fromRGB(255, 200, 0)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.9, 0, 0, 25)
    statusLabel.Position = UDim2.new(0.05, 0, 0, 38)
    statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    statusLabel.TextColor3 = remoteFound and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.BorderSizePixel = 0
    statusLabel.Text = remoteFound and "✓ Conectado" or "✗ Desconectado"
    statusLabel.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 4)
    statusCorner.Parent = statusLabel
    
    local function criarBotao(texto, posY, cor, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 35)
        btn.Position = UDim2.new(0.05, 0, 0, posY)
        btn.BackgroundColor3 = cor
        btn.Text = texto
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = mainFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if remoteFound then
                callback()
            else
                log("Remote não conectado!", true)
            end
        end)
        
        return btn
    end
    
    criarBotao("🎁 Brinquedos", 70, Color3.fromRGB(50, 120, 200), function()
        abrirCaixaGratis("ToyBox")
    end)
    
    criarBotao("⚒️ Ferreiro", 110, Color3.fromRGB(180, 80, 30), function()
        abrirCaixaGratis("BlacksmithBox")
    end)
    
    criarBotao("🍔 Comida", 150, Color3.fromRGB(40, 160, 60), function()
        abrirCaixaGratis("FoodBox")
    end)
    
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(0.8, 0, 0, 1)
    sep.Position = UDim2.new(0.1, 0, 0, 190)
    sep.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    sep.BorderSizePixel = 0
    sep.Parent = mainFrame
    
    local autoFarmBtn = criarBotao("Auto-Farm: OFF", 200, Color3.fromRGB(120, 30, 30), function() end)
    autoFarmBtn.MouseButton1Click:Connect(function()
        CONFIG.AutoFarm = not CONFIG.AutoFarm
        if CONFIG.AutoFarm then
            autoFarmBtn.Text = "Auto-Farm: ON"
            autoFarmBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 30)
            autoFarmCaixas()
        else
            autoFarmBtn.Text = "Auto-Farm: OFF"
            autoFarmBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
        end
    end)
    
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 25, 0, 25)
    minBtn.Position = UDim2.new(1, -30, 0, 5)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextSize = 18
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = mainFrame
    minBtn.ZIndex = 10
    
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            mainFrame.Size = UDim2.new(0, 240, 0, 35)
            minBtn.Text = "+"
        else
            mainFrame.Size = UDim2.new(0, 240, 0, 300)
            minBtn.Text = "-"
        end
    end)
    
    local dragging, dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    log("GUI criada com sucesso!")
end

-- ===== AUTO-FARM =====
local function autoFarmCaixas()
    if not CONFIG.AutoFarm then return end
    log("Auto-Farm iniciado! Caixa: " .. CONFIG.BoxName)
    
    task.spawn(function()
        local contador = 0
        while CONFIG.AutoFarm do
            contador = contador + 1
            abrirCaixaGratis(CONFIG.BoxName)
            task.wait(CONFIG.DelayEntreAberturas)
        end
    end)
end

-- ===== INICIALIZAÇÃO =====
print("\n=============================================")
print("  Sharp Afiado - Ad Bypass VERSÃO CORRIGIDA")
print("=============================================\n")

-- Encontrar o remote
adBoxBuyRemote = encontrarRemote()
remoteFound = adBoxBuyRemote ~= nil

if remoteFound then
    log("✓✓✓ SUCESSO! RemoteEvent encontrado e pronto para usar!")
else
    log("✗✗✗ FALHA! Não foi possível encontrar o RemoteEvent", true)
    log("Tente reexecutar o script ou verifique se está no jogo correto", true)
end

-- Criar GUI
criarGUI()

print("\n=============================================")
print("  Script carregado! Use a GUI para abrir caixas")
print("=============================================\n")

-- Monitorar se o remote foi encontrado depois
task.spawn(function()
    while not remoteFound do
        task.wait(1)
        if not adBoxBuyRemote then
            adBoxBuyRemote = encontrarRemote()
            if adBoxBuyRemote then
                remoteFound = true
                log("✓ RemoteEvent encontrado após espera!")
            end
        end
    end
end)
