-- Hub com interface: Fly + Fling + ESP
-- Atalhos: F = fly | G = fling | T = ESP | Y = anti-fling | RightShift = esconder/mostrar menu

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- evita abrir duas vezes
local GUI_NAME = "HubGui"
pcall(function()
	local old = (gethui and gethui() or CoreGui):FindFirstChild(GUI_NAME)
	if old then old:Destroy() end
end)

local conns = {}
local function track(c) table.insert(conns, c) return c end

local function getParts()
	local char = player.Character
	if not char then return end
	return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local refreshUI = function() end

---------------------------------------------------------------- FLY
local speed = 60
local flying = false
local bv, bg, flyConn

local function stopFly()
	flying = false
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if bv then bv:Destroy() bv = nil end
	if bg then bg:Destroy() bg = nil end
	local _, hum = getParts()
	if hum then hum.PlatformStand = false end
	refreshUI()
end

local function startFly()
	local root, hum = getParts()
	if not root or not hum then return end
	flying = true
	hum.PlatformStand = true

	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = Vector3.zero
	bv.Parent = root

	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bg.P = 1e4
	bg.CFrame = root.CFrame
	bg.Parent = root

	flyConn = RunService.RenderStepped:Connect(function()
		local cf = camera.CFrame
		local dir = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
		bv.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
		bg.CFrame = cf
	end)
	refreshUI()
end

local function toggleFly()
	if flying then stopFly() else startFly() end
end

---------------------------------------------------------------- FLING
local flinging = false
local selected = nil -- Player escolhido na lista

local function nearestPlayer()
	local root = getParts()
	if not root then return end
	local best, bestDist
	for _, p in ipairs(Players:GetPlayers()) do
		local r = p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r then
			local d = (r.Position - root.Position).Magnitude
			if not bestDist or d < bestDist then best, bestDist = p, d end
		end
	end
	return best
end

local function flingPlayer(target)
	if flinging or not target then return end
	local root, hum = getParts()
	local troot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not root or not hum or not troot then return end

	flinging = true
	if flying then stopFly() end
	refreshUI()
	local origin = root.CFrame

	local start = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not troot.Parent or os.clock() - start > 2.5 or troot.AssemblyLinearVelocity.Magnitude > 400 then
			conn:Disconnect()
			return
		end
		root.CFrame = troot.CFrame
		root.AssemblyAngularVelocity = Vector3.new(0, 1e5, 0)
		root.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5)
	end)

	while conn.Connected do task.wait() end

	for _ = 1, 10 do
		root.AssemblyAngularVelocity = Vector3.zero
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = origin
		task.wait()
	end
	flinging = false
	refreshUI()
end

local function doFling()
	task.spawn(flingPlayer, selected or nearestPlayer())
end

---------------------------------------------------------------- ESP
local espOn = false
local espObjects = {}

local function removeESP(p)
	local o = espObjects[p]
	if o then
		if o.highlight then o.highlight:Destroy() end
		if o.billboard then o.billboard:Destroy() end
		espObjects[p] = nil
	end
end

local function createESP(p)
	removeESP(p)
	local char = p.Character
	local head = char and char:FindFirstChild("Head")
	if not char or not head then return end

	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 60, 60)
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.FillTransparency = 0.6
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = char
	hl.Parent = char

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 150, 0, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = head
	bb.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.Text = p.DisplayName
	label.Parent = bb

	espObjects[p] = { highlight = hl, billboard = bb, label = label }
end

local function setESP(on)
	espOn = on
	if on then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then createESP(p) end
		end
	else
		for p in pairs(espObjects) do removeESP(p) end
	end
	refreshUI()
end

local function hookPlayer(p)
	if p == player then return end
	track(p.CharacterAdded:Connect(function()
		if espOn then task.wait(0.5) createESP(p) end
	end))
end

track(RunService.RenderStepped:Connect(function()
	if not espOn then return end
	local root = getParts()
	for p, o in pairs(espObjects) do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r and root then
			o.label.Text = string.format("%s\n[%d studs]", p.DisplayName, (r.Position - root.Position).Magnitude)
		end
	end
end))

---------------------------------------------------------------- ANTI FLING
local antiOn = false
local antiConns = {}
local lastSafe = nil
local MAX_LINEAR, MAX_ANGULAR = 600, 100

local function setAntiFling(on)
	antiOn = on
	for _, c in ipairs(antiConns) do c:Disconnect() end
	table.clear(antiConns)
	lastSafe = nil

	if on then
		-- desliga colisao dos outros jogadores (eles nao conseguem te empurrar)
		table.insert(antiConns, RunService.Stepped:Connect(function()
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					for _, part in ipairs(p.Character:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end
		end))

		-- se sua velocidade explodir, zera e volta pra ultima posicao segura
		table.insert(antiConns, RunService.Heartbeat:Connect(function()
			if flinging then return end
			local root = getParts()
			if not root then return end
			local lin = root.AssemblyLinearVelocity.Magnitude
			local ang = root.AssemblyAngularVelocity.Magnitude
			if lin > MAX_LINEAR or ang > MAX_ANGULAR then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				if lastSafe then root.CFrame = lastSafe end
			else
				lastSafe = root.CFrame
			end
		end))
	end
	refreshUI()
end

---------------------------------------------------------------- UI
local COLOR_BG = Color3.fromRGB(24, 24, 28)
local COLOR_BTN = Color3.fromRGB(50, 50, 58)
local COLOR_ON = Color3.fromRGB(46, 160, 90)
local COLOR_SEL = Color3.fromRGB(70, 110, 200)

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end

local function corner(parent, r)
	new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, parent)
end

local function button(text, parent, order)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = COLOR_BTN,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		Text = text,
		AutoButtonColor = true,
		LayoutOrder = order or 0,
	}, parent)
	corner(b)
	return b
end

local okGui, gui = pcall(function()
	return new("ScreenGui", { Name = GUI_NAME, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling },
		(gethui and gethui()) or CoreGui)
end)
if not okGui then
	gui = new("ScreenGui", { Name = GUI_NAME, ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))
end

local FULL_H, MIN_H = 428, 34
local main = new("Frame", {
	Size = UDim2.new(0, 250, 0, FULL_H),
	Position = UDim2.new(0, 40, 0.5, -FULL_H / 2),
	BackgroundColor3 = COLOR_BG,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
corner(main, 8)

-- barra de titulo
local title = new("Frame", { Size = UDim2.new(1, 0, 0, MIN_H), BackgroundColor3 = Color3.fromRGB(34, 34, 40), BorderSizePixel = 0 }, main)
new("TextLabel", {
	Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1, Text = "Hub", TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 15,
}, title)

local btnMin = new("TextButton", {
	Size = UDim2.new(0, 26, 0, 22), Position = UDim2.new(1, -60, 0.5, -11),
	BackgroundColor3 = COLOR_BTN, Text = "-", TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold, TextSize = 16,
}, title)
corner(btnMin, 5)

local btnClose = new("TextButton", {
	Size = UDim2.new(0, 26, 0, 22), Position = UDim2.new(1, -30, 0.5, -11),
	BackgroundColor3 = Color3.fromRGB(180, 60, 60), Text = "X", TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold, TextSize = 13,
}, title)
corner(btnClose, 5)

-- conteudo
local content = new("Frame", {
	Size = UDim2.new(1, 0, 1, -MIN_H), Position = UDim2.new(0, 0, 0, MIN_H), BackgroundTransparency = 1,
}, main)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, content)
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, content)

local flyBtn = button("Fly: OFF  [F]", content, 1)

-- velocidade
local speedRow = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 2 }, content)
local speedMinus = new("TextButton", { Size = UDim2.new(0, 40, 1, 0), BackgroundColor3 = COLOR_BTN, Text = "-", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18 }, speedRow)
local speedPlus = new("TextButton", { Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0), BackgroundColor3 = COLOR_BTN, Text = "+", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18 }, speedRow)
local speedLabel = new("TextLabel", { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 45, 0, 0), BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 14 }, speedRow)
corner(speedMinus) corner(speedPlus)

local espBtn = button("ESP: OFF  [T]", content, 3)
local antiBtn = button("Anti-Fling: OFF  [Y]", content, 4)

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 5,
	Text = "Fling - escolha um jogador", TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(180, 180, 190), Font = Enum.Font.Gotham, TextSize = 12,
}, content)

local list = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = Color3.fromRGB(32, 32, 38), BorderSizePixel = 0,
	ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 6,
}, content)
corner(list)
new("UIListLayout", { Padding = UDim.new(0, 3) }, list)
new("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3) }, list)

local flingBtn = button("Fling (mais proximo)  [G]", content, 7)

local hint = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 8,
	Text = "RightShift esconde o menu\nClique no jogador de novo p/ desmarcar",
	TextColor3 = Color3.fromRGB(130, 130, 140), Font = Enum.Font.Gotham, TextSize = 11,
}, content)

-- lista de jogadores
local function refreshList()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local b = new("TextButton", {
				Size = UDim2.new(1, -6, 0, 24),
				BackgroundColor3 = (selected == p) and COLOR_SEL or COLOR_BTN,
				Text = p.DisplayName .. " (@" .. p.Name .. ")",
				TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, list)
			corner(b, 4)
			b.MouseButton1Click:Connect(function()
				selected = (selected == p) and nil or p
				refreshUI()
				refreshList()
			end)
		end
	end
end

refreshUI = function()
	flyBtn.Text = "Fly: " .. (flying and "ON" or "OFF") .. "  [F]"
	flyBtn.BackgroundColor3 = flying and COLOR_ON or COLOR_BTN
	espBtn.Text = "ESP: " .. (espOn and "ON" or "OFF") .. "  [T]"
	espBtn.BackgroundColor3 = espOn and COLOR_ON or COLOR_BTN
	antiBtn.Text = "Anti-Fling: " .. (antiOn and "ON" or "OFF") .. "  [Y]"
	antiBtn.BackgroundColor3 = antiOn and COLOR_ON or COLOR_BTN
	speedLabel.Text = "Velocidade: " .. speed
	if flinging then
		flingBtn.Text = "Flingando..."
	elseif selected then
		flingBtn.Text = "Fling em " .. selected.DisplayName .. "  [G]"
	else
		flingBtn.Text = "Fling (mais proximo)  [G]"
	end
end

-- eventos da UI
flyBtn.MouseButton1Click:Connect(toggleFly)
espBtn.MouseButton1Click:Connect(function() setESP(not espOn) end)
antiBtn.MouseButton1Click:Connect(function() setAntiFling(not antiOn) end)
flingBtn.MouseButton1Click:Connect(doFling)
speedMinus.MouseButton1Click:Connect(function() speed = math.max(speed - 10, 10) refreshUI() end)
speedPlus.MouseButton1Click:Connect(function() speed = math.min(speed + 10, 300) refreshUI() end)

local minimized = false
btnMin.MouseButton1Click:Connect(function()
	minimized = not minimized
	main.Size = UDim2.new(0, 250, 0, minimized and MIN_H or FULL_H)
	btnMin.Text = minimized and "+" or "-"
end)

btnClose.MouseButton1Click:Connect(function()
	stopFly()
	setESP(false)
	setAntiFling(false)
	for _, c in ipairs(conns) do c:Disconnect() end
	gui:Destroy()
end)

-- arrastar
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, i.Position, main.Position
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
track(UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end))

-- atalhos
track(UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.F then toggleFly()
	elseif k == Enum.KeyCode.G then doFling()
	elseif k == Enum.KeyCode.T then setESP(not espOn)
	elseif k == Enum.KeyCode.Y then setAntiFling(not antiOn)
	elseif k == Enum.KeyCode.RightShift then main.Visible = not main.Visible
	end
end))

-- jogadores entrando/saindo
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
track(Players.PlayerAdded:Connect(function(p)
	hookPlayer(p)
	refreshList()
end))
track(Players.PlayerRemoving:Connect(function(p)
	removeESP(p)
	if selected == p then selected = nil end
	refreshList()
	refreshUI()
end))

track(player.CharacterAdded:Connect(function()
	stopFly()
	flinging = false
	lastSafe = nil
	refreshUI()
end))

refreshList()
refreshUI()
