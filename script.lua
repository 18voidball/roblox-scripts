-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Settings
local Settings = {
    SilentAim = true,
    WallCheck = true,
    FOV = 150,
    ShowFOV = true,
    ShowSnapLine = true,
    InfiniteAmmo = true,
    InstantFire = true,
    FullAutoSemi = true
}

-- UI Toggle Key
local Keybind = Enum.KeyCode.K
local UIVisible = false

-- Drawing Objects (UI)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
FOVCircle.Radius = Settings.FOV
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = false

local SnapLine = Drawing.new("Line")
SnapLine.Visible = false
SnapLine.Color = Color3.fromRGB(255, 0, 0)

-- UI Toggle Function
local function ToggleUI()
    UIVisible = not UIVisible
    FOVCircle.Visible = UIVisible and Settings.ShowFOV
    SnapLine.Visible = UIVisible and Settings.ShowSnapLine
end

-- Wall Check Function
local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = Workspace:Raycast(origin, direction, raycastParams)
    return result and result.Instance:IsDescendantOf(targetPart.Parent)
end

-- Target Logic
local function getClosestPlayer()
    local closestPlayer, shortestDistance = nil, Settings.FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local targetPart = player.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)

            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                
                if distance < shortestDistance and isVisible(targetPart) then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

-- Infinite Ammo & Instant Fire Hack
local oldFireServer
oldFireServer = hookfunction(LocalPlayer.Character.Gun.Shoot, function(self, ...)
    if Settings.InfiniteAmmo and Settings.InstantFire then
        if Settings.FullAutoSemi and LocalPlayer.Character.Gun:FindFirstChild("Auto") then
            LocalPlayer.Character.Gun.Auto.Value = true
        end
        return oldFireServer(self, ...)
    end
    return oldFireServer(self, ...)
end)

-- Silent Aim Hook
local oldRaycast
oldRaycast = hookfunction(workspace.Raycast, function(self, origin, direction, params)
    if Settings.SilentAim then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetPart = target.Character.Head
            local newDirection = (targetPart.Position - origin).Unit * direction.Magnitude
            return oldRaycast(self, origin, newDirection, params)
        end
    end
    return oldRaycast(self, origin, direction, params)
end)

-- UI Controls
local function CreateUI()
    -- Simplified UI (Drawing API)
    local TextLabel = Drawing.new("Text")
    TextLabel.Text = "Press K to Toggle Settings"
    TextLabel.Position = Vector2.new(50, 50)
    TextLabel.Color = Color3.new(1, 1, 1)
    TextLabel.Size = 20
    TextLabel.Visible = true

    -- Toggle UI on key press
    UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode == Keybind and not processed then
            ToggleUI()
        end
    end)
end

-- Main Update Loop
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = Settings.FOV

    -- Update Snap Line
    local target = getClosestPlayer()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local screenPos = Camera:WorldToViewportPoint(target.Character.Head.Position)
        SnapLine.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        SnapLine.To = Vector2.new(screenPos.X, screenPos.Y)
        SnapLine.Visible = UIVisible and Settings.ShowSnapLine
    else
        SnapLine.Visible = false
    end
end)

-- Initialize
CreateUI()

print("✅ Silent Aim Loaded | Press K to Toggle UI")
