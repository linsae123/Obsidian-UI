--[[
	Obsidian UI Library (single-file)
	Load:
		local Obsidian = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/dist/Obsidian.lua"))()
		local Window = Obsidian:Create({ Title = "OBSIDIAN" })
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local COLORS = {
	window = Color3.fromRGB(9, 9, 12),
	surface = Color3.fromRGB(15, 14, 19),
	panel = Color3.fromRGB(13, 12, 17),
	line = Color3.fromRGB(43, 38, 53),
	purple = Color3.fromRGB(126, 91, 232),
	text = Color3.fromRGB(242, 240, 246),
	muted = Color3.fromRGB(126, 119, 139),
}

local Obsidian = {
	Version = "1.0.0",
	_capturing = false,
}

local function uid(prefix)
	return prefix .. "-" .. string.gsub(HttpService:GenerateGUID(false), "-", "")
end

local function protect(gui)
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, gui)
	elseif gethui then
		gui.Parent = gethui()
		return
	end
	gui.Parent = CoreGui
end

local function tween(obj, props, time)
	TweenService:Create(obj, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

local function stroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.line
	s.Transparency = transparency or 0.35
	s.Thickness = 1
	s.Parent = parent
	return s
end

local function pad(parent, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.Parent = parent
	return p
end

local function list(parent, padding)
	local l = Instance.new("UIListLayout")
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, padding or 8)
	l.Parent = parent
	return l
end

local function label(parent, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.Font = props.Font or Enum.Font.GothamMedium
	t.TextSize = props.TextSize or 12
	t.TextColor3 = props.TextColor3 or COLORS.text
	t.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	t.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
	t.Text = props.Text or ""
	t.Size = props.Size or UDim2.new(1, 0, 0, 18)
	t.Position = props.Position or UDim2.new()
	t.AnchorPoint = props.AnchorPoint or Vector2.new()
	t.TextTruncate = props.TextTruncate or Enum.TextTruncate.None
	t.ZIndex = props.ZIndex or 1
	t.Parent = parent
	return t
end

local function button(parent, props)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.BackgroundColor3 = props.BackgroundColor3 or COLORS.surface
	b.BackgroundTransparency = props.BackgroundTransparency or 0
	b.Text = props.Text or ""
	b.Font = props.Font or Enum.Font.GothamSemibold
	b.TextSize = props.TextSize or 11
	b.TextColor3 = props.TextColor3 or COLORS.text
	b.Size = props.Size or UDim2.new(1, 0, 0, 32)
	b.Position = props.Position or UDim2.new()
	b.AnchorPoint = props.AnchorPoint or Vector2.new()
	b.ZIndex = props.ZIndex or 1
	b.Parent = parent
	return b
end

-- Keybind helpers
local MOUSE = {
	[Enum.UserInputType.MouseButton1] = "Lmb",
	[Enum.UserInputType.MouseButton2] = "Rmb",
	[Enum.UserInputType.MouseButton3] = "Mmb",
	[Enum.UserInputType.MouseButton4] = "X1",
	[Enum.UserInputType.MouseButton5] = "X2",
}

function Obsidian.FormatBind(value)
	if typeof(value) == "EnumItem" then
		if MOUSE[value] then
			return MOUSE[value]
		end
		if value.EnumType == Enum.KeyCode and value ~= Enum.KeyCode.Unknown then
			return value.Name
		end
	end
	return "None"
end

local function bindFromInput(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.Escape then
			return nil, true
		end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			return input.KeyCode, false
		end
	elseif MOUSE[input.UserInputType] then
		return input.UserInputType, false
	end
	return nil, false
end

local function bindsMatch(stored, input)
	if typeof(stored) ~= "EnumItem" then
		return false
	end
	if MOUSE[stored] then
		return input.UserInputType == stored
	end
	return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == stored
end

local function makeToggle(parent, enabled, onChanged, position)
	local track = Instance.new("TextButton")
	track.AutoButtonColor = false
	track.Text = ""
	track.Size = UDim2.fromOffset(38, 20)
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = position or UDim2.new(1, 0, 0.5, 0)
	track.BackgroundColor3 = enabled and COLORS.purple or Color3.fromRGB(43, 40, 50)
	track.BorderSizePixel = 0
	track.ZIndex = 5
	track.Parent = parent
	corner(track, 100)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = enabled and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(245, 243, 248)
	knob.BorderSizePixel = 0
	knob.ZIndex = 6
	knob.Parent = track
	corner(knob, 100)

	local state = enabled
	track.MouseButton1Click:Connect(function()
		state = not state
		tween(track, { BackgroundColor3 = state and COLORS.purple or Color3.fromRGB(43, 40, 50) }, 0.15)
		tween(knob, { Position = state and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0) }, 0.18)
		if onChanged then
			task.spawn(onChanged, state)
		end
	end)

	return {
		Set = function(_, value)
			state = value == true
			track.BackgroundColor3 = state and COLORS.purple or Color3.fromRGB(43, 40, 50)
			knob.Position = state and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)
		end,
		Get = function()
			return state
		end,
	}
end

local function makeKeybind(parent, config)
	local value = config.Default or Enum.KeyCode.Unknown
	local listening = false
	local btn = button(parent, {
		Size = UDim2.fromOffset(config.Width or 96, 28),
		Position = config.Position or UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = config.AnchorPoint or Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(27, 25, 34),
		Text = Obsidian.FormatBind(value),
		TextColor3 = Color3.fromRGB(192, 187, 202),
		ZIndex = 8,
	})
	corner(btn, 9)
	stroke(btn, COLORS.line, 0.3)

	local function setValue(v)
		value = v
		btn.Text = listening and "..." or Obsidian.FormatBind(value)
		if config.OnChanged then
			task.spawn(config.OnChanged, value)
		end
	end

	btn.MouseButton1Click:Connect(function()
		if listening then
			return
		end
		listening = true
		Obsidian._capturing = true
		btn.Text = "..."
		btn.BackgroundColor3 = Color3.fromRGB(53, 39, 80)

		local armed = false
		task.delay(0.12, function()
			armed = true
		end)

		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if not armed then
				return
			end
			local bind, cancelled = bindFromInput(input)
			if cancelled then
				listening = false
				Obsidian._capturing = false
				btn.Text = Obsidian.FormatBind(value)
				btn.BackgroundColor3 = Color3.fromRGB(27, 25, 34)
				conn:Disconnect()
				return
			end
			if bind then
				listening = false
				Obsidian._capturing = false
				btn.BackgroundColor3 = Color3.fromRGB(27, 25, 34)
				setValue(bind)
				conn:Disconnect()
			end
		end)
	end)

	return {
		Get = function()
			return value
		end,
		Set = function(_, v)
			setValue(v)
		end,
		Button = btn,
	}
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------

function Obsidian:Create(config)
	config = config or {}
	local title = config.Title or config.Name or "OBSIDIAN"
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
	local showHotkeys = if config.KeybindList == nil then true else config.KeybindList

	local state = {
		visible = true,
		collapsed = false,
		selectedPage = nil,
		pages = {},
		nav = {},
		keybinds = {},
		toggleKey = toggleKey,
	}

	local holder = Instance.new("ScreenGui")
	holder.Name = config.Name or "ObsidianUI"
	holder.ResetOnSpawn = false
	holder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	holder.IgnoreGuiInset = true
	holder.DisplayOrder = config.DisplayOrder or 200
	protect(holder)

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.52)
	window.Size = UDim2.fromOffset(760, 500)
	window.BackgroundColor3 = COLORS.window
	window.BorderSizePixel = 0
	window.ClipsDescendants = true
	window.Parent = holder
	corner(window, 22)
	stroke(window, Color3.fromRGB(57, 49, 69), 0.15)

	-- Topbar
	local topbar = Instance.new("Frame")
	topbar.Size = UDim2.new(1, 0, 0, 56)
	topbar.BackgroundTransparency = 1
	topbar.Parent = window

	local dragBtn = Instance.new("TextButton")
	dragBtn.Size = UDim2.new(1, -100, 1, 0)
	dragBtn.BackgroundTransparency = 1
	dragBtn.Text = ""
	dragBtn.Parent = topbar

	label(dragBtn, {
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(22, 0),
	})

	local dragging, dragStart, startPos
	dragBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			window.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	local minBtn = button(topbar, {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -68, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "–",
		TextSize = 16,
		BackgroundColor3 = Color3.fromRGB(27, 25, 34),
		TextColor3 = COLORS.muted,
	})
	corner(minBtn, 8)

	local closeBtn = button(topbar, {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -32, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "×",
		TextSize = 16,
		BackgroundColor3 = Color3.fromRGB(27, 25, 34),
		TextColor3 = COLORS.muted,
	})
	corner(closeBtn, 8)

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 1, -1)
	divider.BackgroundColor3 = COLORS.line
	divider.BackgroundTransparency = 0.3
	divider.BorderSizePixel = 0
	divider.Parent = topbar

	-- Sidebar
	local sidebar = Instance.new("Frame")
	sidebar.Position = UDim2.fromOffset(0, 56)
	sidebar.Size = UDim2.new(0, 150, 1, -56)
	sidebar.BackgroundTransparency = 1
	sidebar.Parent = window

	local sideLine = Instance.new("Frame")
	sideLine.Size = UDim2.new(0, 1, 1, 0)
	sideLine.Position = UDim2.new(1, -1, 0, 0)
	sideLine.BackgroundColor3 = COLORS.line
	sideLine.BackgroundTransparency = 0.3
	sideLine.BorderSizePixel = 0
	sideLine.Parent = sidebar

	local navFrame = Instance.new("ScrollingFrame")
	navFrame.Position = UDim2.fromOffset(10, 10)
	navFrame.Size = UDim2.new(1, -20, 1, -20)
	navFrame.BackgroundTransparency = 1
	navFrame.BorderSizePixel = 0
	navFrame.ScrollBarThickness = 2
	navFrame.CanvasSize = UDim2.new()
	navFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	navFrame.Parent = sidebar
	list(navFrame, 4)

	-- Content
	local content = Instance.new("Frame")
	content.Position = UDim2.fromOffset(150, 56)
	content.Size = UDim2.new(1, -150, 1, -56)
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Parent = window

	local pageTitle = label(content, {
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Size = UDim2.new(1, -40, 0, 30),
		Position = UDim2.fromOffset(20, 12),
	})

	local pageHost = Instance.new("Frame")
	pageHost.Position = UDim2.fromOffset(16, 48)
	pageHost.Size = UDim2.new(1, -32, 1, -64)
	pageHost.BackgroundTransparency = 1
	pageHost.ClipsDescendants = false
	pageHost.Parent = content

	local leftCol = Instance.new("ScrollingFrame")
	leftCol.Size = UDim2.new(0.5, -8, 1, 0)
	leftCol.BackgroundTransparency = 1
	leftCol.BorderSizePixel = 0
	leftCol.ScrollBarThickness = 3
	leftCol.CanvasSize = UDim2.new()
	leftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
	leftCol.ClipsDescendants = false
	leftCol.Parent = pageHost
	list(leftCol, 10)
	pad(leftCol, 0, 12, 0, 4)

	local rightCol = Instance.new("ScrollingFrame")
	rightCol.Position = UDim2.new(0.5, 8, 0, 0)
	rightCol.Size = UDim2.new(0.5, -8, 1, 0)
	rightCol.BackgroundTransparency = 1
	rightCol.BorderSizePixel = 0
	rightCol.ScrollBarThickness = 3
	rightCol.CanvasSize = UDim2.new()
	rightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
	rightCol.ClipsDescendants = false
	rightCol.Parent = pageHost
	list(rightCol, 10)
	pad(rightCol, 0, 12, 4, 0)

	-- Hotkeys panel
	local hotkeys
	if showHotkeys then
		hotkeys = Instance.new("Frame")
		hotkeys.Name = "Hotkeys"
		hotkeys.AnchorPoint = Vector2.new(0, 1)
		hotkeys.Position = UDim2.new(0, 18, 1, -18)
		hotkeys.Size = UDim2.fromOffset(210, 0)
		hotkeys.AutomaticSize = Enum.AutomaticSize.Y
		hotkeys.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
		hotkeys.BackgroundTransparency = 0.05
		hotkeys.BorderSizePixel = 0
		hotkeys.ZIndex = 50
		hotkeys.Parent = holder
		corner(hotkeys, 8)
		stroke(hotkeys, COLORS.line, 0.3)

		local hkPad = Instance.new("Frame")
		hkPad.Size = UDim2.new(1, 0, 0, 0)
		hkPad.AutomaticSize = Enum.AutomaticSize.Y
		hkPad.BackgroundTransparency = 1
		hkPad.Parent = hotkeys
		list(hkPad, 6)
		pad(hkPad, 10, 10, 12, 12)

		local hkHeader = Instance.new("TextButton")
		hkHeader.Size = UDim2.new(1, 0, 0, 20)
		hkHeader.BackgroundTransparency = 1
		hkHeader.Text = ""
		hkHeader.LayoutOrder = 0
		hkHeader.ZIndex = 51
		hkHeader.Parent = hkPad
		label(hkHeader, {
			Text = "⌨  Hotkeys",
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 52,
		})

		local hkDragging, hkStart, hkPos
		hkHeader.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				hkDragging = true
				hkStart = input.Position
				hkPos = hotkeys.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if hkDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local d = input.Position - hkStart
				hotkeys.Position = UDim2.new(hkPos.X.Scale, hkPos.X.Offset + d.X, hkPos.Y.Scale, hkPos.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				hkDragging = false
			end
		end)

		state.hotkeyPad = hkPad
	end

	local function refreshHotkeys()
		if not state.hotkeyPad then
			return
		end
		for _, child in state.hotkeyPad:GetChildren() do
			if child:IsA("Frame") and child.Name == "Row" then
				child:Destroy()
			end
		end
		local order = 1
		for _, entry in state.keybinds do
			order += 1
			local row = Instance.new("Frame")
			row.Name = "Row"
			row.Size = UDim2.new(1, 0, 0, 20)
			row.BackgroundTransparency = 1
			row.LayoutOrder = order
			row.Parent = state.hotkeyPad

			label(row, {
				Text = entry.mode or "Toggle",
				TextColor3 = COLORS.muted,
				TextSize = 11,
				Font = Enum.Font.Gotham,
				Size = UDim2.fromOffset(52, 20),
			})
			label(row, {
				Text = entry.name,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				Size = UDim2.new(1, -120, 1, 0),
				Position = UDim2.fromOffset(56, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			label(row, {
				Text = Obsidian.FormatBind(entry.get and entry.get() or entry.value),
				TextColor3 = COLORS.muted,
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				Size = UDim2.fromOffset(56, 20),
				Position = UDim2.new(1, 0, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
			})
		end
	end

	local function selectPage(page)
		state.selectedPage = page
		pageTitle.Text = page.name
		for _, p in state.pages do
			local show = p == page
			p.left.Visible = show
			p.right.Visible = show
			if p.navBtn then
				p.navBtn.BackgroundTransparency = show and 0 or 1
				p.navBtn.BackgroundColor3 = show and Color3.fromRGB(55, 42, 109) or Color3.fromRGB(21, 19, 27)
				p.navLabel.TextColor3 = show and COLORS.text or COLORS.muted
			end
		end
	end

	local function setVisible(v)
		state.visible = v
		window.Visible = v and not state.collapsed
		if state.collapsed then
			window.Visible = v
		end
		holder.Enabled = true
		window.Visible = v
		if hotkeys then
			hotkeys.Visible = v
		end
	end

	local function setCollapsed(v)
		state.collapsed = v
		if v then
			window.Size = UDim2.fromOffset(280, 56)
			sidebar.Visible = false
			content.Visible = false
			minBtn.Text = "□"
		else
			window.Size = UDim2.fromOffset(760, 500)
			sidebar.Visible = true
			content.Visible = true
			minBtn.Text = "–"
		end
	end

	minBtn.MouseButton1Click:Connect(function()
		setCollapsed(not state.collapsed)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		setVisible(false)
	end)

	-- Global keybind runner
	UserInputService.InputBegan:Connect(function(input, gp)
		if Obsidian._capturing then
			return
		end
		if gp then
			return
		end
		if bindsMatch(state.toggleKey, input) then
			setVisible(not state.visible)
			if state.visible then
				setCollapsed(false)
			end
			return
		end
		for _, entry in state.keybinds do
			local val = entry.get and entry.get() or entry.value
			if bindsMatch(val, input) then
				local mode = string.lower(entry.mode or "toggle")
				if mode == "toggle" then
					entry.active = not entry.active
					if entry.callback then
						task.spawn(entry.callback, entry.active)
					end
				elseif mode == "press" or mode == "always" then
					if entry.callback then
						task.spawn(entry.callback, true)
					end
				elseif mode == "hold" then
					entry.active = true
					if entry.callback then
						task.spawn(entry.callback, true)
					end
				end
				refreshHotkeys()
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if Obsidian._capturing then
			return
		end
		for _, entry in state.keybinds do
			local val = entry.get and entry.get() or entry.value
			if bindsMatch(val, input) and string.lower(entry.mode or "") == "hold" then
				entry.active = false
				if entry.callback then
					task.spawn(entry.callback, false)
				end
			end
		end
	end)

	local WindowApi = {}
	WindowApi.__index = WindowApi

	function WindowApi:Notify(text, _icon)
		local toast = Instance.new("Frame")
		toast.AnchorPoint = Vector2.new(1, 0)
		toast.Position = UDim2.new(1, -18, 0, 18)
		toast.Size = UDim2.fromOffset(260, 48)
		toast.BackgroundColor3 = COLORS.surface
		toast.BorderSizePixel = 0
		toast.ZIndex = 100
		toast.Parent = holder
		corner(toast, 12)
		stroke(toast, COLORS.purple, 0.4)
		label(toast, {
			Text = tostring(text),
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.fromOffset(12, 0),
			Font = Enum.Font.GothamSemibold,
			TextSize = 12,
			ZIndex = 101,
		})
		task.delay(2.5, function()
			tween(toast, { BackgroundTransparency = 1 }, 0.2)
			task.wait(0.2)
			toast:Destroy()
		end)
	end

	function WindowApi:SetVisible(v)
		setVisible(v == true)
	end

	function WindowApi:Toggle()
		setVisible(not state.visible)
	end

	function WindowApi:SetToggleKey(key)
		state.toggleKey = key
	end

	function WindowApi:AddSection(name)
		local sec = label(navFrame, {
			Text = string.upper(name),
			TextColor3 = Color3.fromRGB(88, 82, 98),
			TextSize = 9,
			Font = Enum.Font.GothamMedium,
			Size = UDim2.new(1, 0, 0, 20),
		})
		sec.LayoutOrder = #navFrame:GetChildren()
		return self
	end

	local function createControlHost(parentFrame)
		local api = {}

		local function addCard(height)
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, height or 56)
			card.BackgroundColor3 = COLORS.panel
			card.BorderSizePixel = 0
			card.LayoutOrder = #parentFrame:GetChildren()
			card.Parent = parentFrame
			corner(card, 14)
			stroke(card, COLORS.line, 0.55)
			pad(card, 12, 12, 14, 14)
			return card
		end

		function api:AddToggle(cfg)
			cfg = cfg or {}
			local card = addCard(cfg.Description and 58 or 48)
			label(card, {
				Text = cfg.Name or "Toggle",
				Font = Enum.Font.GothamSemibold,
				TextSize = 12,
				Size = UDim2.new(1, -50, 0, 18),
			})
			if cfg.Description then
				label(card, {
					Text = cfg.Description,
					TextColor3 = COLORS.muted,
					TextSize = 9,
					Font = Enum.Font.Gotham,
					Size = UDim2.new(1, -50, 0, 14),
					Position = UDim2.fromOffset(0, 20),
				})
			end
			local t = makeToggle(card, cfg.Default == true, cfg.Callback)
			return t
		end

		function api:AddSlider(cfg)
			cfg = cfg or {}
			local minV, maxV = cfg.Min or 0, cfg.Max or 100
			local value = cfg.Default or minV
			local card = addCard(72)
			label(card, {
				Text = cfg.Name or "Slider",
				Font = Enum.Font.GothamSemibold,
				TextSize = 12,
				Size = UDim2.new(1, -56, 0, 18),
			})
			local box = Instance.new("TextBox")
			box.Size = UDim2.fromOffset(48, 24)
			box.Position = UDim2.new(1, 0, 0, 0)
			box.AnchorPoint = Vector2.new(1, 0)
			box.BackgroundColor3 = Color3.fromRGB(25, 23, 32)
			box.BorderSizePixel = 0
			box.Text = tostring(value)
			box.Font = Enum.Font.GothamSemibold
			box.TextSize = 10
			box.TextColor3 = COLORS.purple
			box.Parent = card
			corner(box, 8)

			local track = Instance.new("Frame")
			track.Position = UDim2.fromOffset(0, 36)
			track.Size = UDim2.new(1, 0, 0, 5)
			track.BackgroundColor3 = Color3.fromRGB(48, 45, 57)
			track.BorderSizePixel = 0
			track.Parent = card
			corner(track, 100)

			local fill = Instance.new("Frame")
			fill.Size = UDim2.fromScale((value - minV) / math.max(maxV - minV, 1), 1)
			fill.BackgroundColor3 = COLORS.purple
			fill.BorderSizePixel = 0
			fill.Parent = track
			corner(fill, 100)

			local knob = Instance.new("Frame")
			knob.Size = UDim2.fromOffset(14, 14)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Position = UDim2.fromScale((value - minV) / math.max(maxV - minV, 1), 0.5)
			knob.BackgroundColor3 = Color3.fromRGB(242, 240, 247)
			knob.BorderSizePixel = 0
			knob.ZIndex = 3
			knob.Parent = track
			corner(knob, 100)
			stroke(knob, COLORS.purple, 0)

			local function set(v)
				value = math.clamp(math.round(v), minV, maxV)
				local a = (value - minV) / math.max(maxV - minV, 1)
				fill.Size = UDim2.fromScale(a, 1)
				knob.Position = UDim2.fromScale(a, 0.5)
				box.Text = tostring(value)
				if cfg.Callback then
					task.spawn(cfg.Callback, value)
				end
			end

			local sliding = false
			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					sliding = true
					local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
					set(minV + (maxV - minV) * a)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
					local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
					set(minV + (maxV - minV) * a)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					sliding = false
				end
			end)
			box.FocusLost:Connect(function()
				local n = tonumber(box.Text)
				if n then
					set(n)
				else
					box.Text = tostring(value)
				end
			end)

			return { Set = set, Get = function() return value end }
		end

		function api:AddDropdown(cfg)
			cfg = cfg or {}
			local options = cfg.Options or { "Option 1" }
			local value = cfg.Default or options[1]
			local card = addCard(70)
			label(card, {
				Text = cfg.Name or "Dropdown",
				Font = Enum.Font.GothamSemibold,
				TextSize = 12,
				Size = UDim2.new(1, 0, 0, 18),
			})
			local open = false
			local main = button(card, {
				Size = UDim2.new(1, 0, 0, 32),
				Position = UDim2.fromOffset(0, 24),
				Text = "  " .. tostring(value),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundColor3 = Color3.fromRGB(27, 25, 34),
				TextColor3 = Color3.fromRGB(191, 186, 201),
				ZIndex = 5,
			})
			main.TextXAlignment = Enum.TextXAlignment.Left
			corner(main, 10)
			stroke(main, COLORS.line, 0.4)

			local menu = Instance.new("Frame")
			menu.Visible = false
			menu.Position = UDim2.fromOffset(0, 60)
			menu.Size = UDim2.new(1, 0, 0, #options * 30 + 8)
			menu.BackgroundColor3 = Color3.fromRGB(18, 17, 24)
			menu.BorderSizePixel = 0
			menu.ZIndex = 40
			menu.Parent = card
			corner(menu, 10)
			stroke(menu, COLORS.line, 0.25)
			list(menu, 2)
			pad(menu, 4, 4, 4, 4)

			local function set(v)
				value = v
				main.Text = "  " .. tostring(value)
				menu.Visible = false
				open = false
				if cfg.Callback then
					task.spawn(cfg.Callback, value)
				end
			end

			for i, opt in options do
				local optBtn = button(menu, {
					Size = UDim2.new(1, 0, 0, 28),
					Text = opt,
					BackgroundColor3 = opt == value and Color3.fromRGB(47, 35, 72) or Color3.fromRGB(23, 22, 30),
					BackgroundTransparency = opt == value and 0 or 1,
					TextColor3 = opt == value and Color3.fromRGB(178, 143, 252) or Color3.fromRGB(190, 186, 199),
					ZIndex = 41,
				})
				optBtn.LayoutOrder = i
				corner(optBtn, 8)
				optBtn.MouseButton1Click:Connect(function()
					set(opt)
				end)
			end

			main.MouseButton1Click:Connect(function()
				open = not open
				menu.Visible = open
			end)

			return { Set = set, Get = function() return value end }
		end

		function api:AddKeybind(cfg)
			cfg = cfg or {}
			local card = addCard(48)
			label(card, {
				Text = cfg.Name or "Keybind",
				Font = Enum.Font.GothamSemibold,
				TextSize = 12,
				Size = UDim2.new(1, -110, 1, 0),
			})
			local kb = makeKeybind(card, {
				Default = cfg.Default,
				OnChanged = function(v)
					refreshHotkeys()
					if cfg.OnChanged then
						cfg.OnChanged(v)
					end
				end,
			})
			local entry = {
				name = cfg.Name or "Keybind",
				mode = cfg.Mode or "Toggle",
				callback = cfg.Callback,
				active = cfg.DefaultActive == true,
				get = function()
					return kb.Get()
				end,
				value = cfg.Default,
			}
			table.insert(state.keybinds, entry)
			refreshHotkeys()
			return kb
		end

		function api:AddColorPicker(cfg)
			cfg = cfg or {}
			local color = cfg.Default or COLORS.purple
			local card = addCard(48)
			label(card, {
				Text = cfg.Name or "Color",
				Font = Enum.Font.GothamSemibold,
				TextSize = 12,
				Size = UDim2.new(1, -40, 1, 0),
			})
			local swatch = button(card, {
				Size = UDim2.fromOffset(28, 28),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Text = "",
				BackgroundColor3 = color,
			})
			corner(swatch, 8)
			local presets = {
				Color3.fromRGB(255, 70, 70),
				Color3.fromRGB(255, 146, 48),
				Color3.fromRGB(88, 214, 112),
				Color3.fromRGB(64, 168, 255),
				Color3.fromRGB(139, 83, 246),
				Color3.fromRGB(255, 255, 255),
			}
			local idx = 1
			swatch.MouseButton1Click:Connect(function()
				idx = (idx % #presets) + 1
				color = presets[idx]
				swatch.BackgroundColor3 = color
				if cfg.Callback then
					task.spawn(cfg.Callback, color)
				end
			end)
			return {
				Get = function()
					return color
				end,
				Set = function(_, c)
					color = c
					swatch.BackgroundColor3 = c
				end,
			}
		end

		function api:AddButton(cfg)
			cfg = cfg or {}
			local card = addCard(cfg.Description and 78 or 56)
			if cfg.Description then
				label(card, {
					Text = cfg.Name or "Button",
					Font = Enum.Font.GothamSemibold,
					TextSize = 12,
					Size = UDim2.new(1, 0, 0, 16),
				})
				label(card, {
					Text = cfg.Description,
					TextColor3 = COLORS.muted,
					TextSize = 9,
					Size = UDim2.new(1, 0, 0, 14),
					Position = UDim2.fromOffset(0, 18),
				})
			end
			local b = button(card, {
				Size = UDim2.new(1, 0, 0, 34),
				Position = UDim2.fromOffset(0, cfg.Description and 36 or 4),
				Text = cfg.Name or "Button",
				BackgroundColor3 = COLORS.purple,
				TextColor3 = Color3.new(1, 1, 1),
			})
			corner(b, 12)
			b.MouseButton1Click:Connect(function()
				if cfg.Callback then
					cfg.Callback()
				end
			end)
			return b
		end

		function api:AddParagraph(cfg)
			cfg = cfg or {}
			local card = addCard(84)
			label(card, {
				Text = cfg.Title or cfg.Name or "Info",
				Font = Enum.Font.GothamSemibold,
				TextSize = 12,
			})
			label(card, {
				Text = cfg.Content or cfg.Description or "",
				TextColor3 = COLORS.muted,
				TextSize = 10,
				Font = Enum.Font.Gotham,
				Size = UDim2.new(1, 0, 0, 44),
				Position = UDim2.fromOffset(0, 22),
				TextYAlignment = Enum.TextYAlignment.Top,
			})
		end

		function api:AddGroup(cfg)
			cfg = cfg or {}
			local group = Instance.new("Frame")
			group.Size = UDim2.new(1, 0, 0, 0)
			group.AutomaticSize = Enum.AutomaticSize.Y
			group.BackgroundColor3 = COLORS.panel
			group.BorderSizePixel = 0
			group.LayoutOrder = #parentFrame:GetChildren()
			group.Parent = parentFrame
			corner(group, 14)
			stroke(group, COLORS.line, 0.45)
			list(group, 0)

			local headerH = cfg.Description and 54 or 42
			local header = Instance.new("Frame")
			header.Size = UDim2.new(1, 0, 0, headerH)
			header.BackgroundTransparency = 1
			header.LayoutOrder = 0
			header.Parent = group

			label(header, {
				Text = cfg.Name or "Group",
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				Size = UDim2.new(1, cfg.Default ~= nil and -60 or -20, 0, 18),
				Position = UDim2.fromOffset(14, cfg.Description and 10 or 12),
			})
			if cfg.Description then
				label(header, {
					Text = cfg.Description,
					TextColor3 = COLORS.muted,
					TextSize = 9,
					Font = Enum.Font.Gotham,
					Size = UDim2.new(1, -60, 0, 14),
					Position = UDim2.fromOffset(14, 30),
				})
			end

			local groupEnabled = if cfg.Default == nil then true else cfg.Default
			if cfg.Default ~= nil or cfg.Callback then
				makeToggle(header, groupEnabled, function(v)
					groupEnabled = v
					if cfg.Callback then
						cfg.Callback(v)
					end
				end, UDim2.new(1, -14, 0.5, 0))
			end

			local body = Instance.new("Frame")
			body.Size = UDim2.new(1, 0, 0, 0)
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.BackgroundTransparency = 1
			body.LayoutOrder = 1
			body.Parent = group
			list(body, 0)

			local groupApi = createControlHost(body)
			-- wrap adds to use dividers look: transparent cards
			local oldToggle = groupApi.AddToggle
			function groupApi:AddToggle(c)
				local card = Instance.new("Frame")
				card.Size = UDim2.new(1, 0, 0, c and c.Description and 56 or 46)
				card.BackgroundTransparency = 1
				card.LayoutOrder = #body:GetChildren()
				card.Parent = body
				pad(card, 10, 10, 14, 14)
				label(card, {
					Text = (c and c.Name) or "Toggle",
					Font = Enum.Font.GothamSemibold,
					TextSize = 12,
					Size = UDim2.new(1, -50, 0, 18),
				})
				if c and c.Description then
					label(card, {
						Text = c.Description,
						TextColor3 = COLORS.muted,
						TextSize = 9,
						Size = UDim2.new(1, -50, 0, 14),
						Position = UDim2.fromOffset(0, 20),
					})
				end
				local line = Instance.new("Frame")
				line.Size = UDim2.new(1, -28, 0, 1)
				line.Position = UDim2.new(0, 14, 1, 0)
				line.AnchorPoint = Vector2.new(0, 1)
				line.BackgroundColor3 = COLORS.line
				line.BackgroundTransparency = 0.55
				line.BorderSizePixel = 0
				line.Parent = card
				return makeToggle(card, c and c.Default == true, c and c.Callback)
			end

			-- For other controls, use normal card style inside body via parentFrame swap
			local inner = createControlHost(body)
			groupApi.AddSlider = inner.AddSlider
			groupApi.AddDropdown = inner.AddDropdown
			groupApi.AddKeybind = inner.AddKeybind
			groupApi.AddColorPicker = inner.AddColorPicker
			groupApi.AddButton = inner.AddButton
			groupApi.AddParagraph = inner.AddParagraph
			groupApi.AddToggle = groupApi.AddToggle

			return groupApi
		end

		return api
	end

	function WindowApi:AddPage(cfg)
		cfg = cfg or {}
		local page = {
			name = cfg.Name or "Page",
			icon = cfg.Icon,
			left = Instance.new("Frame"),
			right = Instance.new("Frame"),
		}
		page.left.Size = UDim2.new(1, 0, 0, 0)
		page.left.AutomaticSize = Enum.AutomaticSize.Y
		page.left.BackgroundTransparency = 1
		page.left.Visible = false
		page.left.Parent = leftCol
		list(page.left, 10)

		page.right.Size = UDim2.new(1, 0, 0, 0)
		page.right.AutomaticSize = Enum.AutomaticSize.Y
		page.right.BackgroundTransparency = 1
		page.right.Visible = false
		page.right.Parent = rightCol
		list(page.right, 10)

		local navBtn = button(navFrame, {
			Size = UDim2.new(1, 0, 0, 34),
			Text = "",
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(55, 42, 109),
		})
		navBtn.LayoutOrder = #navFrame:GetChildren()
		corner(navBtn, 12)
		local navLabel = label(navBtn, {
			Text = page.name,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.fromOffset(12, 0),
			TextColor3 = COLORS.muted,
		})
		page.navBtn = navBtn
		page.navLabel = navLabel
		navBtn.MouseButton1Click:Connect(function()
			selectPage(page)
		end)

		table.insert(state.pages, page)
		if not state.selectedPage then
			selectPage(page)
		end

		local pageApi = {}
		pageApi.__index = pageApi

		function pageApi:Left()
			return createControlHost(page.left)
		end
		function pageApi:Right()
			return createControlHost(page.right)
		end
		function pageApi:AddColumn(side)
			if string.lower(tostring(side)) == "right" then
				return self:Right()
			end
			return self:Left()
		end

		-- Direct adds go left by default with auto balance
		local leftApi = createControlHost(page.left)
		local rightApi = createControlHost(page.right)
		local leftCount, rightCount = 0, 0
		local function pick()
			if leftCount <= rightCount then
				leftCount += 1
				return leftApi
			end
			rightCount += 1
			return rightApi
		end

		for _, name in { "AddToggle", "AddSlider", "AddDropdown", "AddKeybind", "AddColorPicker", "AddButton", "AddParagraph", "AddGroup" } do
			pageApi[name] = function(_, cfg2)
				cfg2 = cfg2 or {}
				local side = cfg2.Side and string.lower(tostring(cfg2.Side))
				local host
				if side == "right" then
					rightCount += 1
					host = rightApi
				elseif side == "left" then
					leftCount += 1
					host = leftApi
				else
					host = pick()
				end
				return host[name](host, cfg2)
			end
		end

		return setmetatable(pageApi, pageApi)
	end

	function WindowApi:Destroy()
		holder:Destroy()
	end

	-- register UI toggle in hotkeys
	table.insert(state.keybinds, {
		name = "UI Toggle",
		mode = "Toggle",
		get = function()
			return state.toggleKey
		end,
		value = state.toggleKey,
		callback = function()
			setVisible(not state.visible)
		end,
	})
	refreshHotkeys()

	return setmetatable({}, WindowApi)
end

function Obsidian.createWindow(config)
	return Obsidian:Create(config)
end

Obsidian.CreateWindow = Obsidian.Create

----------------------------------------------------------------------
-- Built-in feature helpers (ESP / Player / Combat)
----------------------------------------------------------------------

local Feature = {}

function Feature.ESP()
	local settings = {
		enabled = false,
		box = true,
		health = true,
		name = true,
		distance = true,
		tracer = false,
		teamCheck = false,
		maxDistance = 1000,
		boxColor = Color3.fromRGB(64, 168, 255),
		healthColor = Color3.fromRGB(80, 220, 120),
		nameColor = Color3.fromRGB(255, 255, 255),
	}
	local gui
	local drawings = {}
	local conn

	local function rootOf(char)
		return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
	end

	local function ensure()
		if gui and gui.Parent then
			return gui
		end
		gui = Instance.new("ScreenGui")
		gui.Name = "ObsidianESP"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 50
		protect(gui)
		return gui
	end

	local function clear(char)
		local d = drawings[char]
		if not d then
			return
		end
		for _, x in d do
			if typeof(x) == "Instance" then
				x:Destroy()
			end
		end
		drawings[char] = nil
	end

	local function create(char, player)
		local root = rootOf(char)
		if not root then
			return
		end
		local host = ensure()
		local hl = Instance.new("Highlight")
		hl.FillTransparency = 0.85
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = char
		hl.Parent = host

		local bb = Instance.new("BillboardGui")
		bb.AlwaysOnTop = true
		bb.Size = UDim2.fromOffset(140, 48)
		bb.StudsOffset = Vector3.new(0, 3.4, 0)
		bb.Adornee = root
		bb.Parent = host

		local nameL = Instance.new("TextLabel")
		nameL.BackgroundTransparency = 1
		nameL.Size = UDim2.new(1, 0, 0, 14)
		nameL.Font = Enum.Font.GothamBold
		nameL.TextSize = 12
		nameL.TextStrokeTransparency = 0.4
		nameL.Parent = bb

		local hpBg = Instance.new("Frame")
		hpBg.Position = UDim2.fromOffset(0, 18)
		hpBg.Size = UDim2.new(1, 0, 0, 5)
		hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
		hpBg.BorderSizePixel = 0
		hpBg.Parent = bb
		Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

		local hp = Instance.new("Frame")
		hp.Size = UDim2.fromScale(1, 1)
		hp.BorderSizePixel = 0
		hp.Parent = hpBg
		Instance.new("UICorner", hp).CornerRadius = UDim.new(1, 0)

		local distL = Instance.new("TextLabel")
		distL.BackgroundTransparency = 1
		distL.Position = UDim2.fromOffset(0, 28)
		distL.Size = UDim2.new(1, 0, 0, 14)
		distL.Font = Enum.Font.Gotham
		distL.TextSize = 11
		distL.TextColor3 = Color3.fromRGB(190, 190, 198)
		distL.TextStrokeTransparency = 0.5
		distL.Parent = bb

		local tracer = Instance.new("Frame")
		tracer.AnchorPoint = Vector2.new(0.5, 0)
		tracer.BackgroundTransparency = 0.2
		tracer.BorderSizePixel = 0
		tracer.Visible = false
		tracer.Parent = host
		Instance.new("UICorner", tracer).CornerRadius = UDim.new(1, 0)

		drawings[char] = {
			hl = hl,
			bb = bb,
			nameL = nameL,
			hpBg = hpBg,
			hp = hp,
			distL = distL,
			tracer = tracer,
			player = player,
		}
	end

	local function step()
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local myRoot = rootOf(LocalPlayer.Character)
		local seen = {}
		if settings.enabled then
			for _, plr in Players:GetPlayers() do
				if plr ~= LocalPlayer then
					local skip = settings.teamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team
					local char = plr.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local root = rootOf(char)
					if not skip and char and hum and root and hum.Health > 0 then
						local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
						if dist <= settings.maxDistance then
							seen[char] = true
							if not drawings[char] then
								create(char, plr)
							end
							local d = drawings[char]
							if d then
								d.hl.Enabled = settings.box
								d.hl.OutlineColor = settings.boxColor
								d.hl.FillColor = settings.boxColor
								d.bb.Enabled = settings.name or settings.health or settings.distance
								d.nameL.Visible = settings.name
								d.nameL.Text = plr.DisplayName
								d.nameL.TextColor3 = settings.nameColor
								d.hpBg.Visible = settings.health
								local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
								d.hp.Size = UDim2.fromScale(ratio, 1)
								d.hp.BackgroundColor3 = settings.healthColor
								d.distL.Visible = settings.distance
								d.distL.Text = string.format("%dm", math.floor(dist))
								if settings.tracer then
									local sp, on = cam:WorldToViewportPoint(root.Position)
									if on then
										local origin = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y)
										local target = Vector2.new(sp.X, sp.Y)
										local delta = target - origin
										d.tracer.Visible = true
										d.tracer.Size = UDim2.fromOffset(2, delta.Magnitude)
										d.tracer.Position = UDim2.fromOffset(origin.X, origin.Y)
										d.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X)) - 90
										d.tracer.BackgroundColor3 = settings.boxColor
									else
										d.tracer.Visible = false
									end
								else
									d.tracer.Visible = false
								end
							end
						end
					end
				end
			end
		end
		for char in drawings do
			if not seen[char] or not settings.enabled then
				clear(char)
			end
		end
	end

	return {
		Set = function(_, patch)
			for k, v in patch do
				settings[k] = v
			end
		end,
		Get = function()
			return settings
		end,
		Start = function()
			if conn then
				return
			end
			ensure()
			conn = RunService.RenderStepped:Connect(step)
		end,
		Stop = function()
			if conn then
				conn:Disconnect()
				conn = nil
			end
			for char in drawings do
				clear(char)
			end
			if gui then
				gui:Destroy()
				gui = nil
			end
		end,
	}
end

function Feature.Player()
	local settings = {
		speedEnabled = false,
		speed = 32,
		jumpEnabled = false,
		jumpPower = 75,
		infiniteJump = false,
		noclip = false,
	}
	local defaults = { walk = 16, jump = 50 }
	local conns = {}
	local noclipParts = {}

	local function hum()
		return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	end
	local function root()
		return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	end

	local function apply()
		local h = hum()
		if not h then
			return
		end
		h.WalkSpeed = settings.speedEnabled and settings.speed or defaults.walk
		h.UseJumpPower = true
		h.JumpPower = settings.jumpEnabled and settings.jumpPower or defaults.jump
	end

	local function setNoclip(on)
		local char = LocalPlayer.Character
		if not char then
			return
		end
		if on then
			for _, p in char:GetDescendants() do
				if p:IsA("BasePart") then
					noclipParts[p] = p.CanCollide
					p.CanCollide = false
				end
			end
		else
			for p, was in noclipParts do
				if p.Parent then
					p.CanCollide = was
				end
			end
			table.clear(noclipParts)
		end
	end

	return {
		Set = function(_, patch)
			for k, v in patch do
				settings[k] = v
			end
			if patch.noclip ~= nil then
				setNoclip(patch.noclip)
			end
			apply()
		end,
		Get = function()
			return settings
		end,
		Start = function()
			if #conns > 0 then
				return
			end
			if LocalPlayer.Character then
				local h = hum()
				if h then
					defaults.walk = h.WalkSpeed
					defaults.jump = h.JumpPower
				end
				apply()
			end
			table.insert(conns, LocalPlayer.CharacterAdded:Connect(function(char)
				table.clear(noclipParts)
				task.defer(function()
					local h = char:WaitForChild("Humanoid", 5)
					if h then
						defaults.walk = h.WalkSpeed
						defaults.jump = h.JumpPower
					end
					apply()
					if settings.noclip then
						setNoclip(true)
					end
				end)
			end))
			table.insert(conns, RunService.Heartbeat:Connect(function()
				apply()
				if settings.noclip and LocalPlayer.Character then
					for _, p in LocalPlayer.Character:GetDescendants() do
						if p:IsA("BasePart") then
							p.CanCollide = false
						end
					end
				end
			end))
			table.insert(conns, UserInputService.JumpRequest:Connect(function()
				if not settings.infiniteJump then
					return
				end
				local h, r = hum(), root()
				if h and r and h.Health > 0 then
					r.AssemblyLinearVelocity = Vector3.new(
						r.AssemblyLinearVelocity.X,
						math.max(settings.jumpPower, 50),
						r.AssemblyLinearVelocity.Z
					)
				end
			end))
		end,
		Stop = function()
			for _, c in conns do
				c:Disconnect()
			end
			table.clear(conns)
			setNoclip(false)
			local h = hum()
			if h then
				h.WalkSpeed = defaults.walk
				h.JumpPower = defaults.jump
			end
		end,
	}
end

Obsidian.Feature = Feature

return Obsidian
