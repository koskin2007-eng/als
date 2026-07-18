-- Place in StarterPlayer > StarterPlayerScripts.
-- Controlled QA simulation. It refuses to run outside Studio unless the user is allowlisted.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ALLOWED_QA_USERS = {
	-- [123456789] = true,
}

local player = Players.LocalPlayer
if not ALLOWED_QA_USERS[player.UserId] then
	return
end

local state = {
	speed = false,
	jump = false,
	fly = false,
	invisible = false,
	flySpeedIndex = 2,
}

local DEFAULT_WALK_SPEED = 16
local QA_WALK_SPEED = 60
local DEFAULT_JUMP_POWER = 50
local QA_JUMP_POWER = 110
local FLY_SPEEDS = {40, 70, 100, 140}

local function characterParts()
	local character = player.Character or player.CharacterAdded:Wait()
	return character, character:WaitForChild("Humanoid"), character:WaitForChild("HumanoidRootPart")
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SecurityQA"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(1, 0.5)
frame.Position = UDim2.new(1, -20, 0.5, 0)
frame.Size = UDim2.fromOffset(250, 325)
frame.BackgroundColor3 = Color3.fromRGB(10, 28, 58)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 14)
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 9)
layout.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "SECURITY QA"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

local function addToggle(label, key, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(18, 75, 135)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 15
	button.AutoButtonColor = true
	button.Parent = frame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	local function render()
		button.Text = string.format("%s: %s", label, state[key] and "ON" or "OFF")
		button.BackgroundColor3 = state[key]
			and Color3.fromRGB(20, 145, 92)
			or Color3.fromRGB(18, 75, 135)
	end

	button.Activated:Connect(function()
		state[key] = not state[key]
		callback(state[key])
		render()
	end)
	render()
end

local function addAction(label, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(18, 75, 135)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 15
	button.AutoButtonColor = true
	button.Parent = frame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	local function render()
		button.Text = callback(false)
	end

	button.Activated:Connect(function()
		button.Text = callback(true)
	end)
	render()
end

addToggle("Run speed", "speed", function(enabled)
	local _, humanoid = characterParts()
	humanoid.WalkSpeed = enabled and QA_WALK_SPEED or DEFAULT_WALK_SPEED
end)

addToggle("Jump power", "jump", function(enabled)
	local _, humanoid = characterParts()
	humanoid.UseJumpPower = true
	humanoid.JumpPower = enabled and QA_JUMP_POWER or DEFAULT_JUMP_POWER
end)

addToggle("Fly", "fly", function(enabled)
	if not enabled then
		local _, _, root = characterParts()
		root.AssemblyLinearVelocity = Vector3.zero
	end
end)

addAction("Flight speed", function(advance)
	if advance then
		state.flySpeedIndex = state.flySpeedIndex % #FLY_SPEEDS + 1
	end
	return string.format("Flight speed: %d", FLY_SPEEDS[state.flySpeedIndex])
end)

addToggle("Local invisibility", "invisible", function(enabled)
	local character = characterParts()
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = enabled and 1 or 0
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if not state.fly then
		return
	end

	local _, _, root = characterParts()
	local camera = workspace.CurrentCamera
	local direction = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end

	root.AssemblyLinearVelocity = direction.Magnitude > 0
		and direction.Unit * FLY_SPEEDS[state.flySpeedIndex]
		or Vector3.zero
end)

player.CharacterAdded:Connect(function()
	state.speed = false
	state.jump = false
	state.fly = false
	state.invisible = false
end)
