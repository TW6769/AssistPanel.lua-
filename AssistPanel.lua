
-- Roblox Studio：玩家輔助面板
-- 深色直式風格
-- 玩家選擇｜高度調整｜測試傳送
-- 頭部視角｜追蹤｜拾取狀態
-- 支援手機觸控

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 設定
local Height = 5
local SelectedPlayer = nil

local TrackingEnabled = false
local AimEnabled = false
local AutoSelectEnabled = false
local AutoLootEnabled = false

local MIN_HEIGHT = -10
local MAX_HEIGHT = 30

-- 清除舊面板
local oldGui = PlayerGui:FindFirstChild("AssistPanel")
if oldGui then
    oldGui:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AssistPanel"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.fromOffset(250, 380)
frame.Position = UDim2.new(0, 25, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(24, 25, 32)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(75, 85, 110)
stroke.Thickness = 1
stroke.Parent = frame

-- 標題
local title = Instance.new("TextButton")
title.Size = UDim2.new(1, 0, 0, 42)
title.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
title.Text = "玩家輔助面板"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = frame

-- 拖曳
local dragging = false
local dragStart
local startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- 狀態
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 27)
status.Position = UDim2.fromOffset(10, 45)
status.BackgroundTransparency = 1
status.Text = "目標：搜尋中"
status.TextColor3 = Color3.fromRGB(130, 195, 255)
status.TextSize = 13
status.Font = Enum.Font.Gotham
status.Parent = frame

local heightLabel = Instance.new("TextLabel")
heightLabel.Size = UDim2.new(1, -20, 0, 24)
heightLabel.Position = UDim2.fromOffset(10, 72)
heightLabel.BackgroundTransparency = 1
heightLabel.TextColor3 = Color3.new(1, 1, 1)
heightLabel.TextSize = 13
heightLabel.Font = Enum.Font.Gotham
heightLabel.Text = "高度：5"
heightLabel.Parent = frame

-- 滑動區域
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -108)
scroll.Position = UDim2.fromOffset(8, 104)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.Active = true
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

-- 角色檢查
local function getCharacter(player)
    if not player then return nil end

    local character = player.Character
    if not character then return nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")

    if not humanoid or humanoid.Health <= 0
    or not root or not head then
        return nil
    end

    return character, root, head
end

-- 狀態更新
local function updateStatus()
    if SelectedPlayer then
        status.Text = "目標：" .. SelectedPlayer.DisplayName
    else
        status.Text = "目標：沒有玩家"
    end

    heightLabel.Text = "高度：" .. Height
end

-- 按鈕建立
local function makeButton(text, callback)
    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, -5, 0, 34)
    button.BackgroundColor3 = Color3.fromRGB(55, 65, 85)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Parent = scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = button

    button.Activated:Connect(callback)

    return button
end

-- 玩家搜尋
local function getNearestPlayer()
    local _, myRoot = getCharacter(LocalPlayer)
    if not myRoot then return nil end

    local nearest = nil
    local shortest = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local _, root = getCharacter(player)

            if root then
                local distance =
                    (myRoot.Position - root.Position).Magnitude

                if distance < shortest then
                    shortest = distance
                    nearest = player
                end
            end
        end
    end

    return nearest
end

local function selectNearest()
    SelectedPlayer = getNearestPlayer()
    updateStatus()
end

local function getPlayerList()
    local list = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getCharacter(player) then
            table.insert(list, player)
        end
    end

    table.sort(list, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    return list
end

local function cyclePlayer()
    local list = getPlayerList()

    if #list == 0 then
        SelectedPlayer = nil
    else
        local index = table.find(list, SelectedPlayer) or 0
        SelectedPlayer = list[index % #list + 1]
    end

    updateStatus()
end

-- 按鈕
local autoButton
local trackingButton
local aimButton
local lootButton

autoButton = makeButton("自動選擇玩家：關閉", function()
    AutoSelectEnabled = not AutoSelectEnabled

    autoButton.Text =
        "自動選擇玩家：" ..
        (AutoSelectEnabled and "開啟" or "關閉")

    if AutoSelectEnabled then
        selectNearest()
    end
end)

makeButton("切換下一位玩家", function()
    AutoSelectEnabled = false
    autoButton.Text = "自動選擇玩家：關閉"
    cyclePlayer()
end)

makeButton("高度 + 5", function()
    Height = math.clamp(Height + 5, MIN_HEIGHT, MAX_HEIGHT)
    updateStatus()
end)

makeButton("高度 - 5", function()
    Height = math.clamp(Height - 5, MIN_HEIGHT, MAX_HEIGHT)
    updateStatus()
end)

makeButton("測試傳送", function()
    local _, targetRoot = getCharacter(SelectedPlayer)
    local myChar = LocalPlayer.Character

    if targetRoot and myChar then
        myChar:PivotTo(
            CFrame.new(targetRoot.Position + Vector3.new(0, Height, 0))
        )
    end
end)

trackingButton = makeButton("持續追蹤：關閉", function()
    TrackingEnabled = not TrackingEnabled

    trackingButton.Text =
        "持續追蹤：" ..
        (TrackingEnabled and "開啟" or "關閉")
end)

aimButton = makeButton("頭部視角：關閉", function()
    AimEnabled = not AimEnabled

    aimButton.Text =
        "頭部視角：" ..
        (AimEnabled and "開啟" or "關閉")

    if not AimEnabled then
        local humanoid = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            Workspace.CurrentCamera.CameraSubject = humanoid
        end
    end
end)

lootButton = makeButton("拾取狀態：關閉", function()
    AutoLootEnabled = not AutoLootEnabled

    lootButton.Text =
        "拾取狀態：" ..
        (AutoLootEnabled and "開啟" or "關閉")
end)

makeButton("重新搜尋玩家", function()
    selectNearest()
end)

-- 主更新
RunService.RenderStepped:Connect(function()
    if AutoSelectEnabled then
        if not SelectedPlayer or not getCharacter(SelectedPlayer) then
            selectNearest()
        end
    end

    if TrackingEnabled and SelectedPlayer then
        local _, targetRoot = getCharacter(SelectedPlayer)
        local myChar = LocalPlayer.Character

        if targetRoot and myChar then
            local destination =
                targetRoot.Position + Vector3.new(0, Height, 0)

            -- 僅供自己的 Studio 測試環境使用
            myChar:PivotTo(CFrame.new(destination))
        end
    end

    if AimEnabled and SelectedPlayer then
        local _, _, targetHead = getCharacter(SelectedPlayer)

        if targetHead then
            Workspace.CurrentCamera.CFrame =
                CFrame.lookAt(
                    Workspace.CurrentCamera.CFrame.Position,
                    targetHead.Position
                )
        end
    end
end)

-- 玩家離開時清除目標
Players.PlayerRemoving:Connect(function(player)
    if SelectedPlayer == player then
        SelectedPlayer = nil
        updateStatus()
    end
end)

-- 初始狀態
updateStatus()
print("玩家輔助面板已成功載入")
