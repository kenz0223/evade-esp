--[[
	Fixed Combined Script: Custom Timer + Player Box ESP + Downed Tracers + Nextbot ESP
	- Nextbot ESP: Identical to player ESP (red, see-through boxes, name + distance)
	- INSERT: Toggle Player Box ESP
	- DELETE: Toggle Downed Tracers + Nextbot ESP ****NEXTBOX ESP NOT WORKING****
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

-- ====================== ALLOWED GAMES ======================
local allowedGames = {
    [9872472334] = true,   -- Evade
    [10324346056] = true,  -- Big Teams
    [10324347967] = true,  -- Social Space
    [10662542523] = true,  -- Casual
    [10808838353] = true,  -- VC Only
    [11353528705] = true,  -- Pro
    [96537472072550] = true,   -- Legacy
    [99214917572799] = true,   -- Custom Servers
    [121271605799901] = true   -- Player Nextbots
}

if not allowedGames[game.PlaceId] then
    print("This Script Only Works In Evade-related Games!")
    return
end

-- ====================== CUSTOM EVADE TIMER (UNCHANGED) ======================
local existingTimer = PlayerGui:FindFirstChild("CustomEvadeTimer")
if existingTimer then existingTimer:Destroy() end

-- Timer settings
local TIMER_POSITION = UDim2.new(0.5, 0, 0.025, 0)
local TIMER_SIZE = UDim2.new(0.09, 0, 0.1, -10)
local BG_COLOR = Color3.fromRGB(20, 20, 20)
local BG_TRANSPARENCY = 0.5
local CORNER_RADIUS = UDim.new(0, 10)
local BORDER_GLOW = true
local BORDER_THICKNESS = 2.5
local GLOW_ROUND_BRIGHT = Color3.fromRGB(255, 80, 80)
local GLOW_ROUND_DARK = Color3.fromRGB(130, 40, 40)
local GLOW_SAFE_BRIGHT = Color3.fromRGB(100, 255, 100)
local GLOW_SAFE_DARK = Color3.fromRGB(50, 130, 50)
local GLOW_SPEED = 1
local STATUS_ROUND_TEXT = "Survive"
local STATUS_INTERMISSION_TEXT = "Safe"
local STATUS_ROUND_COLOR = Color3.fromRGB(250, 100, 100)
local STATUS_INTERMISSION_COLOR = Color3.fromRGB(100, 250, 100)
local NORMAL_TIMER_COLOR = Color3.fromRGB(255, 255, 255)
local LOW_TIME_COLOR = Color3.fromRGB(250, 100, 100)
local SAFE_TIMER_COLOR = Color3.fromRGB(100, 250, 100)
local LOW_TIME_THRESHOLD = 15
local LOW_TIME_PULSE = true
local LOW_TIME_PULSE_SPEED = 0.4
local LOW_TIME_PULSE_SCALE = 1.15
local TEXT_FONT = Enum.Font.GothamBold
local TEXT_STROKE_COLOR = Color3.fromRGB(50, 50, 50)
local TEXT_STROKE_THICKNESS = 2.5
local TEXT_STROKE_TRANSPARENCY = 0.6

local function CreateTimerGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomEvadeTimer"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Parent = ScreenGui
    Container.AnchorPoint = Vector2.new(0.5, 0)
    Container.Position = TIMER_POSITION
    Container.Size = TIMER_SIZE
    Container.BackgroundColor3 = BG_COLOR
    Container.BackgroundTransparency = BG_TRANSPARENCY
    Container.BorderSizePixel = 0

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = CORNER_RADIUS
    Corner.Parent = Container

    local Border = Instance.new("UIStroke")
    Border.Thickness = BORDER_THICKNESS
    Border.Color = Color3.fromRGB(0, 0, 0)
    Border.Transparency = 0.5
    Border.Parent = Container

    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Parent = Container
    Status.Position = UDim2.new(0.5, 0, 0.2, 0)
    Status.AnchorPoint = Vector2.new(0.5, 0.3)
    Status.Size = UDim2.new(0.95, 0, 0.45, 0)
    Status.BackgroundTransparency = 1
    Status.Font = TEXT_FONT
    Status.Text = "LOADING..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 255)
    Status.TextScaled = true

    local Timer = Instance.new("TextLabel")
    Timer.Name = "Timer"
    Timer.Parent = Container
    Timer.Position = UDim2.new(0.5, 0, 0.75, 0)
    Timer.AnchorPoint = Vector2.new(0.5, 0.7)
    Timer.Size = UDim2.new(0.95, 0, 0.45, 0)
    Timer.BackgroundTransparency = 1
    Timer.Font = TEXT_FONT
    Timer.Text = "0:00"
    Timer.TextColor3 = NORMAL_TIMER_COLOR
    Timer.TextScaled = true

    local StatusStroke = Instance.new("UIStroke")
    StatusStroke.Parent = Status
    StatusStroke.Color = TEXT_STROKE_COLOR
    StatusStroke.Thickness = TEXT_STROKE_THICKNESS
    StatusStroke.Transparency = TEXT_STROKE_TRANSPARENCY

    local TimerStroke = Instance.new("UIStroke")
    TimerStroke.Parent = Timer
    TimerStroke.Color = TEXT_STROKE_COLOR
    TimerStroke.Thickness = TEXT_STROKE_THICKNESS
    TimerStroke.Transparency = TEXT_STROKE_TRANSPARENCY

    return ScreenGui, Timer, Status, Border
end

local TimerGui, TimerLabel, StatusLabel, BorderStroke = CreateTimerGUI()

local function formatTime(sec)
    sec = math.floor(tonumber(sec) or 0)
    return sec <= 0 and "0:00" or string.format("%d:%02d", math.floor(sec/60), sec%60)
end

local TimerConnection
local function UpdateTimer()
    local StatsFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Stats")
    if not StatsFolder then
        TimerLabel.Text = "0:00"
        StatusLabel.Text = "WAITING..."
        return
    end

    if TimerConnection then TimerConnection:Disconnect() end

    TimerConnection = StatsFolder:GetAttributeChangedSignal("Timer"):Connect(function()
        local timeLeft = StatsFolder:GetAttribute("Timer")
        local roundActive = StatsFolder:GetAttribute("RoundStarted")

        TimerLabel.Text = formatTime(timeLeft)
        StatusLabel.Text = roundActive and STATUS_ROUND_TEXT or STATUS_INTERMISSION_TEXT
        StatusLabel.TextColor3 = roundActive and STATUS_ROUND_COLOR or STATUS_INTERMISSION_COLOR
        
        if roundActive then
            TimerLabel.TextColor3 = (timeLeft <= LOW_TIME_THRESHOLD) and LOW_TIME_COLOR or NORMAL_TIMER_COLOR
        else
            TimerLabel.TextColor3 = SAFE_TIMER_COLOR
        end
    end)
    
    StatsFolder:SetAttribute("Timer", StatsFolder:GetAttribute("Timer"))
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Game" then
        task.wait(0.6)
        UpdateTimer()
    end
end)
UpdateTimer()

-- Border glow
if BORDER_GLOW then
    task.spawn(function()
        while TimerGui and TimerGui.Parent do
            local StatsFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Stats")
            local roundActive = StatsFolder and StatsFolder:GetAttribute("RoundStarted")
            
            local brightColor = roundActive and GLOW_ROUND_BRIGHT or GLOW_SAFE_BRIGHT
            local darkColor = roundActive and GLOW_ROUND_DARK or GLOW_SAFE_DARK
            
            local tweenToBright = TweenService:Create(BorderStroke, TweenInfo.new(GLOW_SPEED, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Color = brightColor})
            tweenToBright:Play()
            tweenToBright.Completed:Wait()
            
            local tweenToDark = TweenService:Create(BorderStroke, TweenInfo.new(GLOW_SPEED, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Color = darkColor})
            tweenToDark:Play()
            tweenToDark.Completed:Wait()
        end
    end)
end

-- Hide original timers
task.spawn(function()
    while TimerGui and TimerGui.Parent do
        pcall(function()
            local round = PlayerGui:FindFirstChild("Shared") 
                and PlayerGui.Shared.HUD
                and PlayerGui.Shared.HUD.Overlay
                and PlayerGui.Shared.HUD.Overlay.Default
                and PlayerGui.Shared.HUD.Overlay.Default.RoundOverlay
                and PlayerGui.Shared.HUD.Overlay.Default.RoundOverlay.Round
            if round then
                if not round:FindFirstChild("RoundTimer") then
                    local dummy = Instance.new("TextLabel")
                    dummy.Name = "RoundTimer"
                    dummy.Parent = round
                    dummy.Visible = false
                end
                round.Visible = false
            end
        end)
        pcall(function()
            local inter = PlayerGui:FindFirstChild("Menu") and PlayerGui.Menu:FindFirstChild("IntermissionTimer")
            if inter then
                if not inter:FindFirstChild("RoundTimer") then
                    local dummy = Instance.new("TextLabel")
                    dummy.Name = "RoundTimer"
                    dummy.Parent = inter
                    dummy.Visible = false
                end
                inter.Visible = false
            end
        end)
        task.wait(0.5)
    end
end)

print("✓ Custom Evade Timer Loaded")

-- ====================== ESP + TRACERS + NEXTBOT ESP ======================

local PlayerBoxESPEnabled = true
local MiscESPEnabled = true  -- Controls downed tracers + nextbot ESP

local PlayerBoxESPObjects = {}
local DownedTracerCache = {}
local NextbotESPObjects = {}

-- Shared ESP Settings (same for players and nextbots)
local ESPSettings = {
    BoxColor = Color3.fromRGB(255, 0, 0),  -- Red
    BoxTransparency = 0.5,  -- See-through
    OutlineTransparency = 0,
    TextTransparency = 0.7,
    TextSize = 16,
    TextColor = Color3.fromRGB(255, 255, 255),
    WidthRatio = 0.5,
    HeightMultiplier = 1.0,
    TextOutline = true,
    TeamCheck = false  -- Only applies to players
}

local Colors = {
    Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255),
    Color3.fromRGB(255,255,0), Color3.fromRGB(0,255,255), Color3.fromRGB(255,0,255),
    Color3.fromRGB(255,255,255), Color3.fromRGB(128,128,128)
}
local ColorNames = {"Red","Lime","Blue","Yellow","Cyan","Magenta","White","Gray"}
local ColorIndex = 1

-- Utility Functions
local function newTracerLine()
    local line = Drawing.new("Line")
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 2
    line.Transparency = 0.8
    line.Visible = false
    return line
end

local function worldToScreen(pos)
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), vec.Z > 0
end

local function destroyTracer(data)
    if data.tracer then data.tracer:Remove() end
end

local function ForceHideESP(esp)
    if esp.Box then esp.Box.Visible = false end
    if esp.Outline then esp.Outline.Visible = false end
    if esp.NameTag then esp.NameTag.Visible = false end
end

-- Player Box ESP
local function CreatePlayerBoxESP(player)
    if player == LocalPlayer or PlayerBoxESPObjects[player] then return end
    local Box = Drawing.new("Square")
    Box.Filled = true
    Box.Thickness = 1.5
    Box.Visible = false
    Box.Transparency = 1

    local Outline = Drawing.new("Square")
    Outline.Filled = false
    Outline.Thickness = 3
    Outline.Color = Color3.fromRGB(0,0,0)
    Outline.Visible = false
    Outline.Transparency = 1

    local NameTag = Drawing.new("Text")
    NameTag.Size = ESPSettings.TextSize
    NameTag.Center = true
    NameTag.Outline = ESPSettings.TextOutline
    NameTag.Font = Drawing.Fonts.UI
    NameTag.Visible = false
    NameTag.Transparency = 1

    PlayerBoxESPObjects[player] = {Box = Box, Outline = Outline, NameTag = NameTag}
end

local function RemovePlayerBoxESP(player)
    local esp = PlayerBoxESPObjects[player]
    if esp then
        pcall(function()
            esp.Box:Remove()
            esp.Outline:Remove()
            esp.NameTag:Remove()
        end)
        PlayerBoxESPObjects[player] = nil
    end
end

-- Nextbot ESP
local function CreateNextbotESP(nextbot)
    if NextbotESPObjects[nextbot] then return end
    local Box = Drawing.new("Square")
    Box.Filled = true
    Box.Thickness = 1.5
    Box.Visible = false
    Box.Transparency = 1

    local Outline = Drawing.new("Square")
    Outline.Filled = false
    Outline.Thickness = 3
    Outline.Color = Color3.fromRGB(0,0,0)
    Outline.Visible = false
    Outline.Transparency = 1

    local NameTag = Drawing.new("Text")
    NameTag.Size = ESPSettings.TextSize
    NameTag.Center = true
    NameTag.Outline = ESPSettings.TextOutline
    NameTag.Font = Drawing.Fonts.UI
    NameTag.Visible = false
    NameTag.Transparency = 1

    NextbotESPObjects[nextbot] = {Box = Box, Outline = Outline, NameTag = NameTag}
end

local function RemoveNextbotESP(nextbot)
    local esp = NextbotESPObjects[nextbot]
    if esp then
        pcall(function()
            esp.Box:Remove()
            esp.Outline:Remove()
            esp.NameTag:Remove()
        end)
        NextbotESPObjects[nextbot] = nil
    end
end

-- Main Update Loop
local function UpdateAllESP()
    local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localHRP then 
        for _, esp in pairs(PlayerBoxESPObjects) do ForceHideESP(esp) end
        for _, esp in pairs(NextbotESPObjects) do ForceHideESP(esp) end
        return 
    end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- PLAYER BOX ESP
    for player, esp in pairs(PlayerBoxESPObjects) do ForceHideESP(esp) end
    if PlayerBoxESPEnabled then
        for player, esp in pairs(PlayerBoxESPObjects) do
            if player ~= LocalPlayer then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")

                if hrp and hum and hum.Health > 0 and char.Parent and (not ESPSettings.TeamCheck or player.Team ~= LocalPlayer.Team) then
                    local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        esp.Box.Color = ESPSettings.BoxColor
                        esp.Box.Transparency = ESPSettings.BoxTransparency
                        esp.Outline.Transparency = ESPSettings.OutlineTransparency
                        esp.NameTag.Color = ESPSettings.TextColor
                        esp.NameTag.Transparency = ESPSettings.TextTransparency
                        esp.NameTag.Size = ESPSettings.TextSize

                        local headPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 4.5, 0))
                        local footPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 4, 0))
                        local height = math.abs(headPos.Y - footPos.Y) * ESPSettings.HeightMultiplier
                        local width = height * ESPSettings.WidthRatio

                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                        esp.Outline.Size = esp.Box.Size
                        esp.Outline.Position = esp.Box.Position

                        local distance = math.floor((localHRP.Position - hrp.Position).Magnitude)
                        esp.NameTag.Text = string.format("%s\n[%dm]", player.Name, distance)
                        esp.NameTag.Position = Vector2.new(rootPos.X, rootPos.Y - height / 2 - 25)

                        esp.Box.Visible = true
                        esp.Outline.Visible = true
                        esp.NameTag.Visible = true
                    end
                end
            end
        end
    end

    -- DOWNED TRACERS & NEXTBOT ESP
    if MiscESPEnabled then
        -- Downed Tracers
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if hrp and char:GetAttribute("Downed") then
                    local data = DownedTracerCache[player.Name]
                    if not data then
                        data = {tracer = newTracerLine()}
                        DownedTracerCache[player.Name] = data
                    end

                    local root2D, onScreen = worldToScreen(hrp.Position)
                    data.tracer.From = center
                    data.tracer.To = root2D
                    data.tracer.Visible = onScreen
                else
                    if DownedTracerCache[player.Name] then
                        destroyTracer(DownedTracerCache[player.Name])
                        DownedTracerCache[player.Name] = nil
                    end
                end
            end
        end

        -- Nextbot ESP
        for _, esp in pairs(NextbotESPObjects) do ForceHideESP(esp) end
        local nextbotsFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Nextbots")
        if nextbotsFolder then
            for _, nextbot in pairs(nextbotsFolder:GetChildren()) do
                if nextbot:IsA("Model") then
                    local rootPart = nextbot:FindFirstChild("HumanoidRootPart") or nextbot:FindFirstChildWhichIsA("BasePart")
                    if rootPart and nextbot.Parent then
                        if not NextbotESPObjects[nextbot] then CreateNextbotESP(nextbot) end
                        local esp = NextbotESPObjects[nextbot]
                        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                        if onScreen then
                            esp.Box.Color = ESPSettings.BoxColor
                            esp.Box.Transparency = ESPSettings.BoxTransparency
                            esp.Outline.Transparency = ESPSettings.OutlineTransparency
                            esp.NameTag.Color = ESPSettings.TextColor
                            esp.NameTag.Transparency = ESPSettings.TextTransparency
                            esp.NameTag.Size = ESPSettings.TextSize

                            local headPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 4.5, 0))
                            local footPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 4, 0))
                            local height = math.abs(headPos.Y - footPos.Y) * ESPSettings.HeightMultiplier
                            local width = height * ESPSettings.WidthRatio

                            esp.Box.Size = Vector2.new(width, height)
                            esp.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                            esp.Outline.Size = esp.Box.Size
                            esp.Outline.Position = esp.Box.Position

                            local distance = math.floor((localHRP.Position - rootPart.Position).Magnitude)
                            esp.NameTag.Text = string.format("%s\n[%dm]", nextbot.Name, distance)
                            esp.NameTag.Position = Vector2.new(rootPos.X, rootPos.Y - height / 2 - 25)

                            esp.Box.Visible = true
                            esp.Outline.Visible = true
                            esp.NameTag.Visible = true
                        end
                    end
                end
            end
        end
    else
        for _, data in pairs(DownedTracerCache) do if data.tracer then data.tracer.Visible = false end end
        for _, esp in pairs(NextbotESPObjects) do ForceHideESP(esp) end
    end

    -- Cleanup
    for name, data in pairs(DownedTracerCache) do
        if not Players:FindFirstChild(name) then
            destroyTracer(data)
            DownedTracerCache[name] = nil
        end
    end
    for nextbot, _ in pairs(NextbotESPObjects) do
        local rootPart = nextbot:IsA("Model") and (nextbot:FindFirstChild("HumanoidRootPart") or nextbot:FindFirstChildWhichIsA("BasePart"))
        if not nextbot.Parent or not rootPart then
            RemoveNextbotESP(nextbot)
        end
    end
end

-- Initialize
for _, player in pairs(Players:GetPlayers()) do
    CreatePlayerBoxESP(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        CreatePlayerBoxESP(player)
    end)
end

Players.PlayerAdded:Connect(function(player)
    CreatePlayerBoxESP(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        CreatePlayerBoxESP(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemovePlayerBoxESP(player)
    if DownedTracerCache[player.Name] then
        destroyTracer(DownedTracerCache[player.Name])
        DownedTracerCache[player.Name] = nil
    end
end)

-- Monitor Nextbots
local function setupNextbotMonitoring()
    local nextbotsFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Nextbots")
    if nextbotsFolder then
        for _, nextbot in pairs(nextbotsFolder:GetChildren()) do
            if nextbot:IsA("Model") then CreateNextbotESP(nextbot) end
        end
        nextbotsFolder.ChildAdded:Connect(function(nextbot)
            if nextbot:IsA("Model") then CreateNextbotESP(nextbot) end
        end)
        nextbotsFolder.ChildRemoved:Connect(function(nextbot)
            RemoveNextbotESP(nextbot)
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Game" then
        task.wait(0.6)
        setupNextbotMonitoring()
    end
end)
setupNextbotMonitoring()

RunService.RenderStepped:Connect(UpdateAllESP)

-- ====================== KEYBINDS ======================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        PlayerBoxESPEnabled = not PlayerBoxESPEnabled
        print("Player Box ESP:", PlayerBoxESPEnabled and "ON" or "OFF")
        
    elseif input.KeyCode == Enum.KeyCode.Delete then
        MiscESPEnabled = not MiscESPEnabled
        print("Tracers + Nextbot ESP:", MiscESPEnabled and "ON" or "OFF")
        
    elseif input.KeyCode == Enum.KeyCode.C then
        ColorIndex = (ColorIndex % #Colors) + 1
        ESPSettings.BoxColor = Colors[ColorIndex]
        print("Box Color:", ColorNames[ColorIndex])
        
    elseif input.KeyCode == Enum.KeyCode.LeftBracket then
        ESPSettings.BoxTransparency = math.max(0, ESPSettings.BoxTransparency - 0.05)
        print("Box Trans:", string.format("%.2f", ESPSettings.BoxTransparency))
        
    elseif input.KeyCode == Enum.KeyCode.RightBracket then
        ESPSettings.BoxTransparency = math.min(1, ESPSettings.BoxTransparency + 0.05)
        print("Box Trans:", string.format("%.2f", ESPSettings.BoxTransparency))
        
    elseif input.KeyCode == Enum.KeyCode.Comma then
        ESPSettings.WidthRatio = math.max(0.1, ESPSettings.WidthRatio - 0.05)
        print("Width:", string.format("%.2f", ESPSettings.WidthRatio))
        
    elseif input.KeyCode == Enum.KeyCode.Period then
        ESPSettings.WidthRatio = math.min(2, ESPSettings.WidthRatio + 0.05)
        print("Width:", string.format("%.2f", ESPSettings.WidthRatio))
        
    elseif input.KeyCode == Enum.KeyCode.Slash then
        ESPSettings.HeightMultiplier = math.max(0.5, ESPSettings.HeightMultiplier - 0.05)
        print("Height:", string.format("%.2f", ESPSettings.HeightMultiplier))
        
    elseif input.KeyCode == Enum.KeyCode.Quote then
        ESPSettings.HeightMultiplier = math.min(2, ESPSettings.HeightMultiplier + 0.05)
        print("Height:", string.format("%.2f", ESPSettings.HeightMultiplier))
        
    elseif input.KeyCode == Enum.KeyCode.X then
        ESPSettings.TeamCheck = not ESPSettings.TeamCheck
        print("TeamCheck:", ESPSettings.TeamCheck)
    end
end)

print("=== ALL FEATURES LOADED SUCCESSFULLY! ===")
print("INSERT = Player Box ESP | DELETE = Tracers + Nextbot ESP | C = Colors | [ ] = Trans | ,. = Width | /' = Height | T = Team")
print("✓ Timer | ✓ Player Box ESP (Red, See-Through) | ✓ Downed Tracers | ✓ Nextbot ESP (Red, See-Through)")
