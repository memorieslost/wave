--[[
    ============================================================
    Sharp Afiado - Ad Cooldown Bypass & Free Box Opener
    ============================================================
    Funcionalidades:
      1) Remove o cooldown do anúncio (botão "Ver Anúncio" sempre visível)
      2) Tenta pular o anúncio de 6 segundos (dispara o RemoteEvent direto)
      3) Loop automático opcional para abrir caixas infinitas por anúncio
    
    Caixas disponíveis: ToyBox, BlacksmithBox, FoodBox
    
    Compatível com: Delta, Synapse, Fluxus, etc.
    ============================================================
]]

-- ===================== CONFIGURAÇÃO =====================
local CONFIG = {
    AutoFarm = false,          -- Mude para true para abrir caixas automaticamente em loop
    BoxName = "ToyBox",        -- Qual caixa abrir: "ToyBox", "BlacksmithBox" ou "FoodBox"
    DelayEntreAberturas = 2,   -- Segundos entre cada abertura automática
}
-- ========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdService = game:GetService("AdService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== Encontrar o RemoteEvent AdBoxBuy =====
local remoteFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remote"):WaitForChild("RemoteEvents")
local adBoxBuyRemote = remoteFolder:WaitForChild("AdBoxBuy")

print("[SharpAd] RemoteEvent AdBoxBuy encontrado!")

-- ===== MÉTODO 1: Disparar o RemoteEvent diretamente (pula o anúncio) =====
local function abrirCaixaGratis(boxName)
    local clientToken = math.random()
    adBoxBuyRemote:FireServer(boxName or CONFIG.BoxName, clientToken)
    print("[SharpAd] FireServer enviado para: " .. (boxName or CONFIG.BoxName) .. " | Token: " .. tostring(clientToken))
end

-- ===== MÉTODO 2: Forçar o botão de anúncio sempre visível =====
local function forcarBotaoVisivel()
    -- Hookear o AdService para sempre retornar que o anúncio está disponível
    -- Isso faz o jogo pensar que sempre tem anúncio pronto
    local mt = getrawmetatable(AdService)
    if mt and setreadonly then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "GetAdAvailabilityNowAsync" then
                -- Retorna um objeto fake dizendo que o anúncio está disponível
                -- Isso remove o cooldown visual do botão
                return {AdAvailabilityResult = Enum.AdAvailabilityResult.IsAvailable}
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        print("[SharpAd] AdService hookado - cooldown removido!")
    else
        print("[SharpAd] Hook do metatable não suportado, usando método alternativo...")
    end
end

-- ===== MÉTODO 3: Buscar e forçar o botão BuyAd na GUI =====
local function buscarEForcarBotao()
    task.spawn(function()
        while true do
            -- Procurar o botão BuyAd em toda a PlayerGui
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                    -- Procurar botões relacionados ao anúncio
                    local parent = gui.Parent
                    if parent and parent.Name == "BuyAd" then
                        gui.Visible = true
                    end
                    -- Também verificar pelo nome direto
                    if gui.Name == "BuyAd" then
                        gui.Visible = true
                    end
                end
                -- Forçar frames chamados BuyAd visíveis
                if gui.Name == "BuyAd" and gui:IsA("GuiObject") then
                    gui.Visible = true
                end
            end
            task.wait(0.5)
        end
    end)
    print("[SharpAd] Loop de forçar botão visível ativo!")
end

-- ===== MÉTODO 4: Auto-farm de caixas por anúncio =====
local function autoFarmCaixas()
    if not CONFIG.AutoFarm then return end
    print("[SharpAd] Auto-farm ATIVADO! Caixa: " .. CONFIG.BoxName)
    print("[SharpAd] Abrindo caixas a cada " .. CONFIG.DelayEntreAberturas .. " segundos...")
    
    task.spawn(function()
        local contador = 0
        while CONFIG.AutoFarm do
            contador = contador + 1
            abrirCaixaGratis(CONFIG.BoxName)
            print("[SharpAd] Caixa #" .. contador .. " aberta!")
            task.wait(CONFIG.DelayEntreAberturas)
        end
    end)
end

-- ===== CRIAR GUI DE CONTROLE =====
local function criarGUI()
    -- Remover GUI antiga se existir
    local oldGui = playerGui:FindFirstChild("SharpAdGUI")
    if oldGui then oldGui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SharpAdGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 220, 0, 280)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -140)
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
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "SHARP AD BYPASS"
    title.TextColor3 = Color3.fromRGB(255, 200, 0)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Função para criar botões
    local function criarBotao(texto, posY, cor, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 32)
        btn.Position = UDim2.new(0.05, 0, 0, posY)
        btn.BackgroundColor3 = cor
        btn.Text = texto
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = mainFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Botão: Abrir Caixa de Brinquedos
    criarBotao("Abrir Caixa de Brinquedos", 42, Color3.fromRGB(50, 120, 200), function()
        abrirCaixaGratis("ToyBox")
    end)
    
    -- Botão: Abrir Caixa de Ferreiro
    criarBotao("Abrir Caixa de Ferreiro", 80, Color3.fromRGB(180, 80, 30), function()
        abrirCaixaGratis("BlacksmithBox")
    end)
    
    -- Botão: Abrir Caixa de Comida
    criarBotao("Abrir Caixa de Comida", 118, Color3.fromRGB(40, 160, 60), function()
        abrirCaixaGratis("FoodBox")
    end)
    
    -- Separador
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(0.8, 0, 0, 1)
    sep.Position = UDim2.new(0.1, 0, 0, 158)
    sep.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    sep.BorderSizePixel = 0
    sep.Parent = mainFrame
    
    -- Botão: Auto-farm Toggle
    local autoFarmBtn = criarBotao("Auto-Farm: OFF", 166, Color3.fromRGB(120, 30, 30), function() end)
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
    
    -- Seletor de caixa para auto-farm
    local boxNames = {"ToyBox", "BlacksmithBox", "FoodBox"}
    local boxDisplayNames = {"Brinquedos", "Ferreiro", "Comida"}
    local currentBoxIndex = 1
    
    local boxSelector = criarBotao("Auto: Brinquedos", 204, Color3.fromRGB(80, 80, 120), function() end)
    boxSelector.MouseButton1Click:Connect(function()
        currentBoxIndex = currentBoxIndex % 3 + 1
        CONFIG.BoxName = boxNames[currentBoxIndex]
        boxSelector.Text = "Auto: " .. boxDisplayNames[currentBoxIndex]
    end)
    
    -- Botão minimizar
    local minimized = false
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
    
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            mainFrame.Size = UDim2.new(0, 220, 0, 35)
            minBtn.Text = "+"
        else
            mainFrame.Size = UDim2.new(0, 220, 0, 280)
            minBtn.Text = "-"
        end
    end)
    
    -- Tornar arrastável
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
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0, 245)
    status.BackgroundTransparency = 1
    status.Text = "Clique para abrir grátis!"
    status.TextColor3 = Color3.fromRGB(180, 180, 180)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.TextWrapped = true
    status.Parent = mainFrame
    
    print("[SharpAd] GUI criada com sucesso!")
end

-- ===== INICIALIZAÇÃO =====
print("=============================================")
print("  Sharp Afiado - Ad Bypass Script")
print("  Removendo cooldown de anúncio...")
print("=============================================")

-- Executar tudo
pcall(forcarBotaoVisivel)
buscarEForcarBotao()
criarGUI()

-- Se auto-farm estiver ativo na config
if CONFIG.AutoFarm then
    autoFarmCaixas()
end

print("[SharpAd] Script carregado com sucesso!")
print("[SharpAd] Use a GUI na tela para abrir caixas grátis!")
