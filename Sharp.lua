--[[
    ============================================================
    Sharp Afiado - Auto Watch Ad Loop (Remove Cooldown)
    ============================================================
    Funcionalidades:
      1) Clica automaticamente em "Watch Ad" na loja
      2) Espera o anúncio de 7 segundos
      3) Clica em "Skip" ou fecha o anúncio
      4) Volta para a loja e repete infinito
      5) Remove o cooldown efetivamente
    
    Sem cooldown = Infinitos anúncios = Infinitas caixas grátis!
    ============================================================
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== CONFIGURAÇÃO =====
local CONFIG = {
    AutoLoop = true,           -- Ativar loop automático
    DelayEntreAds = 1,         -- Segundos entre cada anúncio
    TempoAnuncio = 7.5,        -- Tempo do anúncio (7 segundos + margem)
    DebugMode = true,          -- Mostrar logs
}
-- ========================

local autoLoopAtivo = CONFIG.AutoLoop
local contadorAds = 0

-- ===== FUNÇÃO DE LOG =====
local function log(msg)
    if CONFIG.DebugMode then
        print("[SharpAd AutoAd] " .. msg)
    end
end

-- ===== ENCONTRAR BOTÃO NA GUI =====
local function encontrarBotao(nomeBotao)
    local function buscarRecursivo(obj)
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            if obj.Name == nomeBotao or (obj:FindFirstChild("TextLabel") and obj:FindFirstChild("TextLabel").Text:find(nomeBotao)) then
                return obj
            end
        end
        
        for _, child in pairs(obj:GetChildren()) do
            local resultado = buscarRecursivo(child)
            if resultado then
                return resultado
            end
        end
        
        return nil
    end
    
    return buscarRecursivo(playerGui)
end

-- ===== CLICAR BOTÃO =====
local function clicarBotao(botao, delay)
    if not botao then
        log("❌ Botão não encontrado!")
        return false
    end
    
    if delay then
        task.wait(delay)
    end
    
    -- Simular clique
    local oldPos = botao.Position
    botao:TweenPosition(oldPos, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true)
    
    -- Disparar evento de clique
    botao.MouseButton1Click:Fire()
    
    log("✓ Clicado: " .. botao.Name)
    return true
end

-- ===== BUSCAR E CLICAR "WATCH AD" =====
local function clicarWatchAd()
    log("🔍 Procurando botão 'Watch Ad'...")
    
    -- Estratégia 1: Buscar por nome
    local botao = encontrarBotao("BuyAd")
    if botao and botao.Visible then
        log("✓ Botão BuyAd encontrado!")
        clicarBotao(botao, 0.5)
        return true
    end
    
    -- Estratégia 2: Buscar por texto
    local function buscarPorTexto(obj, texto)
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local textLabel = obj:FindFirstChildOfClass("TextLabel")
            if textLabel and textLabel.Text:find(texto) then
                return obj
            end
        end
        
        for _, child in pairs(obj:GetChildren()) do
            local resultado = buscarPorTexto(child, texto)
            if resultado then
                return resultado
            end
        end
        
        return nil
    end
    
    botao = buscarPorTexto(playerGui, "Watch")
    if botao and botao.Visible then
        log("✓ Botão 'Watch Ad' encontrado por texto!")
        clicarBotao(botao, 0.5)
        return true
    end
    
    botao = buscarPorTexto(playerGui, "Ad")
    if botao and botao.Visible then
        log("✓ Botão 'Ad' encontrado!")
        clicarBotao(botao, 0.5)
        return true
    end
    
    log("❌ Botão 'Watch Ad' não encontrado!")
    return false
end

-- ===== ESPERAR E FECHAR ANÚNCIO =====
local function esperarEFecharAnuncio()
    log("⏳ Anúncio rodando... Aguardando " .. CONFIG.TempoAnuncio .. " segundos")
    
    task.wait(CONFIG.TempoAnuncio)
    
    log("🔍 Procurando botão 'Skip' ou fechar...")
    
    -- Estratégia 1: Buscar por "Skip"
    local function buscarPorTexto(obj, texto)
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local textLabel = obj:FindFirstChildOfClass("TextLabel")
            if textLabel and textLabel.Text:find(texto) then
                return obj
            end
            if obj.Name:find(texto) then
                return obj
            end
        end
        
        for _, child in pairs(obj:GetChildren()) do
            local resultado = buscarPorTexto(child, texto)
            if resultado then
                return resultado
            end
        end
        
        return nil
    end
    
    local botaoSkip = buscarPorTexto(playerGui, "Skip")
    if botaoSkip and botaoSkip.Visible then
        log("✓ Botão 'Skip' encontrado!")
        clicarBotao(botaoSkip, 0.3)
        return true
    end
    
    -- Estratégia 2: Buscar por "X" (fechar)
    local botaoFechar = buscarPorTexto(playerGui, "X")
    if botaoFechar and botaoFechar.Visible then
        log("✓ Botão 'X' (fechar) encontrado!")
        clicarBotao(botaoFechar, 0.3)
        return true
    end
    
    -- Estratégia 3: Pressionar ESC
    log("⌨️ Tentando pressionar ESC para fechar anúncio...")
    UserInputService:SendKeyEvent(true, Enum.KeyCode.Escape, false)
    task.wait(0.1)
    UserInputService:SendKeyEvent(false, Enum.KeyCode.Escape, false)
    
    return true
end

-- ===== LOOP AUTOMÁTICO =====
local function loopAutomatico()
    log("🚀 Iniciando loop automático de anúncios!")
    
    task.spawn(function()
        while autoLoopAtivo do
            contadorAds = contadorAds + 1
            log("📺 Anúncio #" .. contadorAds .. " iniciando...")
            
            -- Clicar em Watch Ad
            if clicarWatchAd() then
                -- Esperar e fechar anúncio
                esperarEFecharAnuncio()
                
                -- Aguardar antes do próximo
                log("⏱️ Aguardando " .. CONFIG.DelayEntreAds .. " segundo(s) antes do próximo anúncio...")
                task.wait(CONFIG.DelayEntreAds)
            else
                log("⚠️ Falha ao clicar em Watch Ad, tentando novamente em 2 segundos...")
                task.wait(2)
            end
        end
    end)
end

-- ===== CRIAR GUI DE CONTROLE =====
local function criarGUI()
    local oldGui = playerGui:FindFirstChild("SharpAdAutoGUI")
    if oldGui then oldGui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SharpAdAutoGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 220)
    mainFrame.Position = UDim2.new(1, -270, 0.5, -110)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 100)
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "AUTO WATCH AD"
    title.TextColor3 = Color3.fromRGB(0, 255, 100)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local contadorLabel = Instance.new("TextLabel")
    contadorLabel.Size = UDim2.new(0.9, 0, 0, 25)
    contadorLabel.Position = UDim2.new(0.05, 0, 0, 38)
    contadorLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    contadorLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    contadorLabel.TextSize = 12
    contadorLabel.Font = Enum.Font.Gotham
    contadorLabel.BorderSizePixel = 0
    contadorLabel.Text = "Ads: 0"
    contadorLabel.Parent = mainFrame
    
    local contadorCorner = Instance.new("UICorner")
    contadorCorner.CornerRadius = UDim.new(0, 4)
    contadorCorner.Parent = contadorLabel
    
    -- Atualizar contador
    task.spawn(function()
        while true do
            contadorLabel.Text = "Ads: " .. contadorAds
            task.wait(0.5)
        end
    end)
    
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
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    local toggleBtn = criarBotao("Loop: ON", 68, Color3.fromRGB(0, 180, 80), function() end)
    toggleBtn.MouseButton1Click:Connect(function()
        autoLoopAtivo = not autoLoopAtivo
        if autoLoopAtivo then
            toggleBtn.Text = "Loop: ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
            loopAutomatico()
        else
            toggleBtn.Text = "Loop: OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        end
    end)
    
    criarBotao("Clicar Watch Ad", 108, Color3.fromRGB(50, 120, 200), function()
        clicarWatchAd()
    end)
    
    criarBotao("Fechar Anúncio", 148, Color3.fromRGB(180, 80, 30), function()
        esperarEFecharAnuncio()
    end)
    
    criarBotao("Resetar Contador", 188, Color3.fromRGB(100, 100, 100), function()
        contadorAds = 0
        log("Contador resetado!")
    end)
    
    log("GUI criada com sucesso!")
end

-- ===== INICIALIZAÇÃO =====
print("\n=============================================")
print("  Sharp Afiado - Auto Watch Ad Loop")
print("  Remove cooldown com auto-clicker!")
print("=============================================\n")

criarGUI()

if CONFIG.AutoLoop then
    loopAutomatico()
    log("✓ Loop automático iniciado!")
else
    log("Loop automático desativado. Use a GUI para controlar.")
end

log("Script carregado com sucesso!")
print("=============================================\n")

-- Atalho de teclado para pausar/retomar
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F7 then
        autoLoopAtivo = not autoLoopAtivo
        if autoLoopAtivo then
            log("✓ Loop retomado!")
            loopAutomatico()
        else
            log("⏸️ Loop pausado!")
        end
    end
end)

log("Pressione F7 para pausar/retomar o loop!")
