--[[
	Fixed Combined Script: Custom Timer + Box ESP + Downed Tracers (WORKING!)
	All features fully functional together
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

-- ====================== CUSTOM EVADE TIMER ======================

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

-- Hide original timers loop
task.spawn(function()
    while TimerGui and TimerGui.Parent do
        pcall(function()
            local round = PlayerGui:FindFirstChild("Shared") 
                and PlayerGui.Shared:FindFirstChild("HUD")
                and PlayerGui.Shared.HUD:FindFirstChild("Overlay")
                and PlayerGui.Shared.HUD.Overlay:FindFirstChild("Default")
                and PlayerGui.Shared.HUD.Overlay.Default:FindFirstChild("RoundOverlay")
                and PlayerGui.Shared.HUD.Overlay.Default.RoundOverlay:FindFirstChild("Round")
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
            local intermissionTimer = PlayerGui:FindFirstChild("Menu") and PlayerGui.Menu:FindFirstChild("IntermissionTimer")
            if intermissionTimer then
                if not intermissionTimer:FindFirstChild("RoundTimer") then
                    local dummy = Instance.new("TextLabel")
                    dummy.Name = "RoundTimer"
                    dummy.Parent = intermissionTimer
                    dummy.Visible = false
                end
                intermissionTimer.Visible = false
            end
        end)
        task.wait(0.5)
    end
end)

print("✓ Custom Evade Timer Loaded")

-- ====================== ESP + TRACERS (SEPARATE ENABLE STATES) ======================

local BoxESPEnabled = true
local TracerEnabled = true

local BoxESPObjects = {}
local TracerCache = {}

-- Box ESP Settings
local BoxSettings = {
    BoxColor = Color3.fromRGB(255, 0, 0),
    BoxTransparency = 0.4,
    OutlineTransparency = 0,
    TextTransparency = 0.7,
    TextSize = 16,
    TextColor = Color3.fromRGB(255, 255, 255),
    WidthRatio = 0.5,
    HeightMultiplier = 1.0,
    TextOutline = true,
    TeamCheck = false
}

local Colors = {
    Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255),
    Color3.fromRGB(255,255,0), Color3.fromRGB(0,255,255), Color3.fromRGB(255,0,255),
    Color3.fromRGB(255,255,255), Color3.fromRGB(128,128,128)
}
local ColorNames = {"Red","Lime","Blue","Yellow","Cyan","Magenta","White","Gray"}
local ColorIndex = 1

-- Tracer functions
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

local function destroyTracerData(data)
    if data.tracer then 
        data.tracer:Remove() 
    end
end

-- Box ESP functions
local function CreateBoxESP(player)
    if player == LocalPlayer then return end
    
    local Box = Drawing.new("Square")
    Box.Filled = true
    Box.Thickness = 1.5
    Box.Visible = false
    
    local Outline = Drawing.new("Square")
    Outline.Filled = false
    Outline.Thickness = 3
    Outline.Color = Color3.fromRGB(0, 0, 0)
    Outline.Visible = false
    
    local NameTag = Drawing.new("Text")
    NameTag.Size = BoxSettings.TextSize
    NameTag.Center = true
    NameTag.Outline = BoxSettings.TextOutline
    NameTag.Font = Drawing.Fonts.UI
    NameTag.Visible = false
    
    BoxESPObjects[player] = {Box = Box, Outline = Outline, NameTag = NameTag}
end

local function RemoveBoxESP(player)
    if BoxESPObjects[player] then
        BoxESPObjects[player].Box:Remove()
        BoxESPObjects[player].Outline:Remove()
        BoxESPObjects[player].NameTag:Remove()
        BoxESPObjects[player] = nil
    end
end

-- Main unified update loop
local function UpdateAllESP()
    local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localHRP then return end
    
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Update Box ESP
    if BoxESPEnabled then
        for player, esp in pairs(BoxESPObjects) do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 and char.Parent then
                local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen and (not BoxSettings.TeamCheck or player.Team ~= LocalPlayer.Team) then
                    -- Apply settings
                    esp.Box.Color = BoxSettings.BoxColor
                    esp.Box.Transparency = BoxSettings.BoxTransparency
                    esp.Outline.Transparency = BoxSettings.OutlineTransparency
                    esp.NameTag.Color = BoxSettings.TextColor
                    esp.NameTag.Transparency = BoxSettings.TextTransparency
                    esp.NameTag.Size = BoxSettings.TextSize
                    
                    -- Calculate box size
                    local headPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 4.5, 0))
                    local footPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 4, 0))
                    local height = math.abs(headPos.Y - footPos.Y) * BoxSettings.HeightMultiplier
                    local width = height * BoxSettings.WidthRatio
                    
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                    esp.Outline.Size = esp.Box.Size
                    esp.Outline.Position = esp.Box.Position
                    
                    -- Name + distance
                    local distance = math.floor((localHRP.Position - hrp.Position).Magnitude)
                    esp.NameTag.Text = string.format("%s\n[%dm]", player.Name, distance)
                    esp.NameTag.Position = Vector2.new(rootPos.X, rootPos.Y - height / 2 - 25)
                    
                    esp.Box.Visible = true
                    esp.Outline.Visible = true
                    esp.NameTag.Visible = true
                else
                    esp.Box.Visible = false
                    esp.Outline.Visible = false
                    esp.NameTag.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.Outline.Visible = false
                esp.NameTag.Visible = false
            end
        end
    else
        -- Hide all box ESP when disabled
        for _, esp in pairs(BoxESPObjects) do
            esp.Box.Visible = false
            esp.Outline.Visible = false
            esp.NameTag.Visible = false
        end
    end
    
    -- Update Tracers (ALWAYS INDEPENDENT)
    if TracerEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
            
            local hrp = char.HumanoidRootPart
            
            -- Check if downed
            if char:GetAttribute("Downed") then
                local data = TracerCache[player.Name]
                if not data then
                    data = {tracer = newTracerLine()}
                    TracerCache[player.Name] = data
                end
                
                local root2D, onScreen = worldToScreen(hrp.Position)
                data.tracer.From = center
                data.tracer.To = root2D
                data.tracer.Visible = onScreen
            else
                if TracerCache[player.Name] then
                    destroyTracerData(TracerCache[player.Name])
                    TracerCache[player.Name] = nil
                end
            end
        end
        
        -- Cleanup removed players
        for name, data in pairs(TracerCache) do
            if not Players:FindFirstChild(name) then
                destroyTracerData(data)
                TracerCache[name] = nil
            end
        end
    else
        -- Hide all tracers when disabled
        for _, data in pairs(TracerCache) do
            if data.tracer then data.tracer.Visible = false end
        end
    end
end

-- Initialize ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    CreateBoxESP(player)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        CreateBoxESP(player)
    end)
    CreateBoxESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveBoxESP(player)
    if TracerCache[player.Name] then
        destroyTracerData(TracerCache[player.Name])
        TracerCache[player.Name] = nil
    end
end)

-- Main render loop
RunService.RenderStepped:Connect(UpdateAllESP)

-- ====================== KEYBINDS ======================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        BoxESPEnabled = not BoxESPEnabled
        print("Box ESP:", BoxESPEnabled and "ON" or "OFF")
        
    elseif input.KeyCode == Enum.KeyCode.Delete then
        TracerEnabled = not TracerEnabled
        print("Tracers:", TracerEnabled and "ON" or "OFF")
        
    elseif input.KeyCode == Enum.KeyCode.C then
        ColorIndex = (ColorIndex % #Colors) + 1
        BoxSettings.BoxColor = Colors[ColorIndex]
        print("Box Color:", ColorNames[ColorIndex])
        
    elseif input.KeyCode == Enum.KeyCode.LeftBracket then -- [
        BoxSettings.BoxTransparency = math.max(0, BoxSettings.BoxTransparency - 0.05)
        print("Box Trans:", string.format("%.2f", BoxSettings.BoxTransparency))
        
    elseif input.KeyCode == Enum.KeyCode.RightBracket then -- ]
        BoxSettings.BoxTransparency = math.min(1, BoxSettings.BoxTransparency + 0.05)
        print("Box Trans:", string.format("%.2f", BoxSettings.BoxTransparency))
        
    elseif input.KeyCode == Enum.KeyCode.Comma then -- ,
        BoxSettings.WidthRatio = math.max(0.1, BoxSettings.WidthRatio - 0.05)
        print("Width:", string.format("%.2f", BoxSettings.WidthRatio))
        
    elseif input.KeyCode == Enum.KeyCode.Period then -- .
        BoxSettings.WidthRatio = math.min(2, BoxSettings.WidthRatio + 0.05)
        print("Width:", string.format("%.2f", BoxSettings.WidthRatio))
        
    elseif input.KeyCode == Enum.KeyCode.Slash then -- /
        BoxSettings.HeightMultiplier = math.max(0.5, BoxSettings.HeightMultiplier - 0.05)
        print("Height:", string.format("%.2f", BoxSettings.HeightMultiplier))
        
    elseif input.KeyCode == Enum.KeyCode.Quote then -- '
        BoxSettings.HeightMultiplier = math.min(2, BoxSettings.HeightMultiplier + 0.05)
        print("Height:", string.format("%.2f", BoxSettings.HeightMultiplier))
        
    elseif input.KeyCode == Enum.KeyCode.T then
        BoxSettings.TeamCheck = not BoxSettings.TeamCheck
        print("TeamCheck:", BoxSettings.TeamCheck)
    end
end)

print("=== ALL FEATURES LOADED SUCCESSFULLY! ===")
print("INSERT = Box ESP | DELETE = Tracers | C = Colors | [ ] = Trans | ,. = Width | /' = Height | T = Team")
print("✓ Timer | ✓ Box ESP | ✓ Downed Tracers - ALL WORKING!")