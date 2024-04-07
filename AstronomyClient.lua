local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local starGui = playerGui:WaitForChild("StarGui")

local starAdornee = workspace:WaitForChild("StarAdornee")

local starLabelGui = Instance.new("BillboardGui")
starLabelGui.Size = UDim2.new(0, 200, 0, 30)
starLabelGui.AlwaysOnTop = true
starLabelGui.MaxDistance = math.huge
starLabelGui.Adornee = starAdornee
starLabelGui.ExtentsOffset = Vector3.zero
starLabelGui.ExtentsOffsetWorldSpace = Vector3.zero
starLabelGui.StudsOffset = Vector3.yAxis * 100
starLabelGui.Parent = starGui

local starNameLabel = Instance.new("TextLabel")
starNameLabel.Size = UDim2.new(1, 0, 1, 0)
starNameLabel.TextColor3 = Color3.new(1, 1, 1)
starNameLabel.BackgroundTransparency = 1
starNameLabel.Parent = starLabelGui

local function clearStarLabel()
    starLabelGui.StudsOffsetWorldSpace = Vector3.zero
end

local starChildren = starAdornee:GetChildren()

for starChildIndex = 1, #starChildren do
    
    local starChild = starChildren[starChildIndex]
    starChild.Parent = starGui
    
    starChild.MouseEnter:Connect(function()
        starNameLabel.Text = starChild.Name
        starLabelGui.StudsOffsetWorldSpace = starChild.CFrame.Position
    end)

    -- starChild.MouseLeave:Connect(clearStarLabel)
end

local function rotateAdornee()
    starAdornee.CFrame = starAdornee.CFrame*CFrame.Angles(.0001, 0.0001, 0.0001)
end

game:GetService("RunService"):BindToRenderStep("SkyRotate", 1, rotateAdornee)
