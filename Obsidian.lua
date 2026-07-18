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

local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")

local Obsidian = {
	Version = "2.0.0",
	_capturing = false,
	SourceUrl = nil,
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

-- Embedded Lucide atlas icons (48px sheet)
local LUCIDE = {
	keyboard = { id = 16898613509, rect = Vector2.new(453, 820), size = Vector2.new(48, 48) },
	bell = { id = 16898612819, rect = Vector2.new(820, 257), size = Vector2.new(48, 48) },
	sparkles = { id = 16898613777, rect = Vector2.new(918, 49), size = Vector2.new(48, 48) },
	["layout-dashboard"] = { id = 16898613509, rect = Vector2.new(967, 355), size = Vector2.new(48, 48) },
	["layout-grid"] = { id = 16898613509, rect = Vector2.new(918, 404), size = Vector2.new(48, 48) },
	home = { id = 16898613509, rect = Vector2.new(820, 147), size = Vector2.new(48, 48) },
	eye = { id = 16898613353, rect = Vector2.new(771, 563), size = Vector2.new(48, 48) },
	user = { id = 16898613869, rect = Vector2.new(661, 869), size = Vector2.new(48, 48) },
	settings = { id = 16898613777, rect = Vector2.new(771, 257), size = Vector2.new(48, 48) },
	plus = { id = 16898613699, rect = Vector2.new(257, 918), size = Vector2.new(48, 48) },
	pencil = { id = 16898613699, rect = Vector2.new(820, 257), size = Vector2.new(48, 48) },
	zap = { id = 16898613869, rect = Vector2.new(918, 906), size = Vector2.new(48, 48) },
	activity = { id = 16898612629, rect = Vector2.new(514, 771), size = Vector2.new(48, 48) },
	box = { id = 16898612819, rect = Vector2.new(771, 196), size = Vector2.new(48, 48) },
	gauge = { id = 16898613353, rect = Vector2.new(771, 955), size = Vector2.new(48, 48) },
	["sliders-horizontal"] = { id = 16898613777, rect = Vector2.new(820, 355), size = Vector2.new(48, 48) },
	["refresh-cw"] = { id = 16898613699, rect = Vector2.new(404, 869), size = Vector2.new(48, 48) },
	["gamepad-2"] = { id = 16898613353, rect = Vector2.new(710, 967), size = Vector2.new(48, 48) },
	rocket = { id = 16898613699, rect = Vector2.new(918, 147), size = Vector2.new(48, 48) },
	monitor = { id = 16898613613, rect = Vector2.new(404, 820), size = Vector2.new(48, 48) },
	layers = { id = 16898613509, rect = Vector2.new(98, 967), size = Vector2.new(48, 48) },
	search = { id = 16898613699, rect = Vector2.new(918, 857), size = Vector2.new(48, 48) },
}

local function lucideIcon(parent, name, size, color, position, anchor)
	local asset = LUCIDE[name] or LUCIDE.bell
	local img = Instance.new("ImageLabel")
	img.Name = name
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Size = UDim2.fromOffset(size or 14, size or 14)
	img.Position = position or UDim2.new()
	img.AnchorPoint = anchor or Vector2.new()
	img.Image = "rbxassetid://" .. tostring(asset.id)
	img.ImageRectOffset = asset.rect
	img.ImageRectSize = asset.size
	img.ImageColor3 = color or COLORS.text
	img.ScaleType = Enum.ScaleType.Fit
	img.ZIndex = 60
	img.Parent = parent
	return img
end

local function tween(obj, props, time, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
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
	t.Name = props.Name or "Label"
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
}
-- MouseButton4/5 are not in standard Roblox Enum (some executors add them)
do
	local ok4, mb4 = pcall(function()
		return (Enum.UserInputType :: any).MouseButton4
	end)
	local ok5, mb5 = pcall(function()
		return (Enum.UserInputType :: any).MouseButton5
	end)
	if ok4 and mb4 then
		MOUSE[mb4] = "X1"
	end
	if ok5 and mb5 then
		MOUSE[mb5] = "X2"
	end
end

function Obsidian.FormatBind(value)
	if typeof(value) == "EnumItem" then
		if MOUSE[value] then
			return MOUSE[value]
		end
		if value.EnumType == Enum.KeyCode and value ~= Enum.KeyCode.Unknown then
			local short = {
				RightControl = "RCTRL",
				LeftControl = "LCTRL",
				RightShift = "RSHIFT",
				LeftShift = "LSHIFT",
				RightAlt = "RALT",
				LeftAlt = "LALT",
				RightSuper = "RWIN",
				LeftSuper = "LWIN",
				Return = "ENTER",
				Backspace = "BKSP",
				Delete = "DEL",
				Insert = "INS",
				PageUp = "PGUP",
				PageDown = "PGDN",
				CapsLock = "CAPS",
				NumLock = "NUM",
				ScrollLock = "SCRL",
				Print = "PRTSC",
				Space = "SPACE",
				Escape = "ESC",
				Tab = "TAB",
				Unknown = "—",
			}
			return short[value.Name] or value.Name
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
	track.Position = position or UDim2.new(1, 0, 0.5, -3)
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
		Size = UDim2.fromOffset(config.Width or 72, 28),
		Position = config.Position or UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = config.AnchorPoint or Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(27, 25, 34),
		BackgroundTransparency = 1,
		Text = Obsidian.FormatBind(value),
		TextColor3 = Color3.fromRGB(192, 187, 202),
		TextSize = config.TextSize or 11,
		ZIndex = config.ZIndex or 8,
	})
	btn.Font = Enum.Font.GothamBold
	-- no box / stroke — plain key text

	local function setValue(v, silent)
		value = v
		btn.Text = listening and "..." or Obsidian.FormatBind(value)
		if not silent and config.OnChanged then
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
		btn.TextColor3 = COLORS.purple

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
				btn.TextColor3 = Color3.fromRGB(192, 187, 202)
				conn:Disconnect()
				return
			end
			if bind then
				listening = false
				Obsidian._capturing = false
				btn.TextColor3 = Color3.fromRGB(192, 187, 202)
				setValue(bind, false)
				conn:Disconnect()
			end
		end)
	end)

	return {
		Get = function()
			return value
		end,
		Set = function(_, v, silent)
			setValue(v, silent == true)
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

	local dropLayer = Instance.new("Frame")
	dropLayer.Name = "DropLayer"
	dropLayer.Size = UDim2.fromScale(1, 1)
	dropLayer.BackgroundTransparency = 1
	dropLayer.BorderSizePixel = 0
	dropLayer.ZIndex = 500
	dropLayer.Parent = holder

	local activeDropdown = nil
	local function closeDropdown()
		if activeDropdown then
			activeDropdown.Visible = false
			activeDropdown = nil
		end
	end
	local function openDropdown(menu, anchor)
		closeDropdown()
		local absPos = anchor.AbsolutePosition
		local absSize = anchor.AbsoluteSize
		menu.Parent = dropLayer
		menu.Size = UDim2.fromOffset(math.max(absSize.X, 120), menu.Size.Y.Offset)
		menu.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
		menu.ZIndex = 510
		menu.Visible = true
		activeDropdown = menu
	end

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
		TextSize = 18,
		Size = UDim2.new(1, -24, 0, 22),
		Position = UDim2.fromOffset(22, 10),
		Name = "TitleLabel",
	})

	local subtitleText = tostring(config.Subtitle or config.SubTitle or "")
	local subtitleLabel = label(dragBtn, {
		Text = subtitleText,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = COLORS.muted,
		Size = UDim2.new(1, -24, 0, 16),
		Position = UDim2.fromOffset(22, 30),
		Name = "SubtitleLabel",
	})
	subtitleLabel.Visible = subtitleText ~= ""

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
		Position = UDim2.new(1, -92, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "–",
		TextSize = 16,
		BackgroundColor3 = Color3.fromRGB(27, 25, 34),
		TextColor3 = COLORS.muted,
	})
	corner(minBtn, 8)

	local closeBtn = button(topbar, {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -56, 0.5, 0),
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
	navFrame.ScrollBarThickness = 0
	navFrame.ScrollBarImageTransparency = 1
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
		Size = UDim2.new(1, -200, 0, 30),
		Position = UDim2.fromOffset(20, 12),
	})

	local searchWrap = Instance.new("Frame")
	searchWrap.Name = "Search"
	searchWrap.AnchorPoint = Vector2.new(1, 0)
	searchWrap.Position = UDim2.new(1, -20, 0, 10)
	searchWrap.Size = UDim2.fromOffset(178, 28)
	searchWrap.BackgroundColor3 = Color3.fromRGB(22, 20, 28)
	searchWrap.BorderSizePixel = 0
	searchWrap.Parent = content
	corner(searchWrap, 9)
	stroke(searchWrap, COLORS.line, 0.4)

	local searchIcon = lucideIcon(
		searchWrap,
		"search",
		14,
		COLORS.muted,
		UDim2.new(0, 9, 0.5, 0),
		Vector2.new(0, 0.5)
	)
	searchIcon.ZIndex = 40

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchInput"
	searchBox.Position = UDim2.fromOffset(28, 0)
	searchBox.Size = UDim2.new(1, -32, 1, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.BorderSizePixel = 0
	searchBox.ClearTextOnFocus = false
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 12
	searchBox.TextColor3 = COLORS.text
	searchBox.PlaceholderText = "Search..."
	searchBox.PlaceholderColor3 = COLORS.muted
	searchBox.Text = ""
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ZIndex = 41
	searchBox.Parent = searchWrap
	pad(searchBox, 0, 0, 0, 6)

	state.searchables = {}
	state.searchQuery = ""

	local function applySearch(query)
		query = string.lower(tostring(query or ""))
		state.searchQuery = query
		local pageHits = {}
		for _, entry in ipairs(state.searchables) do
			if entry.inst and entry.inst.Parent then
				local show = query == "" or string.find(entry.text, query, 1, true) ~= nil
				entry.inst.Visible = show
				if show then
					if entry.page then
						pageHits[entry.page] = true
					end
					-- reveal parent group / column frames
					local p = entry.inst.Parent
					local guard = 0
					while p and guard < 8 do
						if p:IsA("GuiObject") then
							p.Visible = true
						end
						if p.Name == "Window" or p:IsA("ScreenGui") then
							break
						end
						p = p.Parent
						guard = guard + 1
					end
				end
			end
		end
		for _, p in ipairs(state.pages) do
			if p.navBtn then
				local hit = query == "" or pageHits[p] == true or string.find(string.lower(p.name), query, 1, true) ~= nil
				p.navBtn.Visible = hit
			end
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		applySearch(searchBox.Text)
	end)

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
	leftCol.ScrollBarThickness = 0
	leftCol.ScrollBarImageTransparency = 1
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
	rightCol.ScrollBarThickness = 0
	rightCol.ScrollBarImageTransparency = 1
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
		hkHeader.Size = UDim2.new(1, 0, 0, 22)
		hkHeader.BackgroundTransparency = 1
		hkHeader.Text = ""
		hkHeader.LayoutOrder = 0
		hkHeader.ZIndex = 51
		hkHeader.Parent = hkPad

		lucideIcon(
			hkHeader,
			"keyboard",
			14,
			Color3.fromRGB(210, 210, 216),
			UDim2.new(0, 0, 0.5, 0),
			Vector2.new(0, 0.5)
		)
		label(hkHeader, {
			Text = "Hotkeys",
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Size = UDim2.new(1, -22, 1, 0),
			Position = UDim2.fromOffset(20, 0),
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

	-- Top-center notification stack (original style)
	local notifyHost = Instance.new("Frame")
	notifyHost.Name = "NotificationHost"
	notifyHost.AnchorPoint = Vector2.new(0.5, 0)
	notifyHost.Position = UDim2.new(0.5, 0, 0, 72)
	notifyHost.Size = UDim2.fromOffset(0, 0)
	notifyHost.AutomaticSize = Enum.AutomaticSize.XY
	notifyHost.BackgroundTransparency = 1
	notifyHost.BorderSizePixel = 0
	notifyHost.ZIndex = 200
	notifyHost.Parent = holder
	local notifyList = list(notifyHost, 8)
	notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	notifyList.VerticalAlignment = Enum.VerticalAlignment.Top

	local function isListed(entry)
		if entry.getListed then
			return entry.getListed() ~= false
		end
		return entry.listed ~= false
	end

	local function refreshHotkeys()
		if not state.hotkeyPad then
			return
		end
		for _, child in ipairs(state.hotkeyPad:GetChildren()) do
			if child:IsA("Frame") and child.Name == "Row" then
				child:Destroy()
			end
		end
		local order = 1
		for _, entry in ipairs(state.keybinds) do
			local hideFeature = entry.name ~= "UI Toggle" and entry.requireActive and not entry.active
			if isListed(entry) and not hideFeature then
				order = order + 1
				local row = Instance.new("Frame")
				row.Name = "Row"
				row.Size = UDim2.new(1, 0, 0, 22)
				row.BackgroundTransparency = 1
				row.LayoutOrder = order
				row.ZIndex = 55
				row.Parent = state.hotkeyPad

				label(row, {
					Text = entry.mode or "Toggle",
					TextColor3 = COLORS.muted,
					TextSize = 11,
					Font = Enum.Font.Gotham,
					Size = UDim2.fromOffset(52, 22),
					ZIndex = 56,
				})
				label(row, {
					Text = entry.name,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					Size = UDim2.new(1, -120, 1, 0),
					Position = UDim2.fromOffset(56, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 56,
				})

				local current = entry.get and entry.get() or entry.value
				makeKeybind(row, {
					Default = current,
					Width = 58,
					TextSize = 10,
					ZIndex = 57,
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					OnChanged = function(v)
						if entry.apply then
							entry.apply(v)
						elseif entry.kb then
							entry.kb:Set(v, true)
							entry.value = v
							if entry.onChanged then
								task.spawn(entry.onChanged, v)
							end
						else
							entry.value = v
						end
						refreshHotkeys()
					end,
				})
			end
		end
	end

	local function selectPage(page)
		state.selectedPage = page
		pageTitle.Text = page.name
		local hideTitle = page.fullWidth or page.hideTitle
		pageTitle.Visible = not hideTitle
		searchWrap.Visible = true
		if hideTitle then
			pageHost.Position = UDim2.fromOffset(16, 44)
			pageHost.Size = UDim2.new(1, -32, 1, -54)
		else
			pageTitle.TextTransparency = 1
			tween(pageTitle, { TextTransparency = 0 }, 0.22)
			pageHost.Position = UDim2.fromOffset(16, 48)
			pageHost.Size = UDim2.new(1, -32, 1, -64)
		end

		if page.fullWidth then
			leftCol.Size = UDim2.new(1, 0, 1, 0)
			rightCol.Visible = false
		else
			leftCol.Size = UDim2.new(0.5, -8, 1, 0)
			rightCol.Visible = true
			rightCol.Position = UDim2.new(0.5, 8, 0, 0)
			rightCol.Size = UDim2.new(0.5, -8, 1, 0)
		end

		for _, p in ipairs(state.pages) do
			local show = p == page
			p.left.Visible = show
			p.right.Visible = show and not p.fullWidth
			if p.navBtn then
				tween(p.navBtn, {
					BackgroundTransparency = show and 0 or 1,
				}, 0.16)
				p.navBtn.BackgroundColor3 = show and Color3.fromRGB(55, 42, 109) or Color3.fromRGB(21, 19, 27)
				tween(p.navLabel, {
					TextColor3 = show and COLORS.text or COLORS.muted,
				}, 0.16)
				if p.navIcon then
					tween(p.navIcon, {
						ImageColor3 = show and COLORS.text or COLORS.muted,
					}, 0.16)
				end
			end
		end
		if not hideTitle then
			pageHost.Position = UDim2.fromOffset(16, 56)
			tween(pageHost, { Position = UDim2.fromOffset(16, 48) }, 0.22)
		end
	end

	local function setVisible(v)
		state.visible = v
		holder.Enabled = true
		if v then
			window.Visible = true
			window.BackgroundTransparency = 1
			tween(window, { BackgroundTransparency = 0 }, 0.2)
			if hotkeys then
				hotkeys.Visible = true
				hotkeys.BackgroundTransparency = 1
				tween(hotkeys, { BackgroundTransparency = 0.05 }, 0.2)
			end
		else
			tween(window, { BackgroundTransparency = 1 }, 0.16)
			if hotkeys then
				tween(hotkeys, { BackgroundTransparency = 1 }, 0.16)
			end
			task.delay(0.16, function()
				if not state.visible then
					window.Visible = false
					if hotkeys then
						hotkeys.Visible = false
					end
				end
			end)
		end
	end

	local function setCollapsed(v)
		state.collapsed = v
		if v then
			sidebar.Visible = false
			content.Visible = false
			minBtn.Text = "□"
			tween(window, { Size = UDim2.fromOffset(280, 56) }, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		else
			minBtn.Text = "–"
			tween(window, { Size = UDim2.fromOffset(760, 500) }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			task.delay(0.12, function()
				if not state.collapsed then
					sidebar.Visible = true
					content.Visible = true
					content.BackgroundTransparency = 1
				end
			end)
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
		for _, entry in ipairs(state.keybinds) do
			local skip = entry.listed == false
			if not skip and entry.getListed and entry.getListed() == false then
				skip = true
			end
			if not skip then
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
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if Obsidian._capturing then
			return
		end
		for _, entry in ipairs(state.keybinds) do
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

	function WindowApi:Notify(text, iconName)
		local toast = Instance.new("CanvasGroup")
		toast.Size = UDim2.fromOffset(0, 46)
		toast.AutomaticSize = Enum.AutomaticSize.X
		toast.BackgroundTransparency = 1
		toast.BorderSizePixel = 0
		toast.GroupTransparency = 1
		toast.ZIndex = 201
		toast.LayoutOrder = #notifyHost:GetChildren() + 1
		toast.Parent = notifyHost

		local scale = Instance.new("UIScale")
		scale.Scale = 0.88
		scale.Parent = toast

		local body = Instance.new("Frame")
		body.Size = UDim2.fromScale(1, 1)
		body.AutomaticSize = Enum.AutomaticSize.X
		body.Position = UDim2.fromOffset(0, -12)
		body.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
		body.BackgroundTransparency = 0.05
		body.BorderSizePixel = 0
		body.ZIndex = 202
		body.Parent = toast
		corner(body, 16)
		stroke(body, Color3.fromRGB(157, 105, 255), 0.7)

		local padFrame = Instance.new("UIPadding")
		padFrame.PaddingLeft = UDim.new(0, 12)
		padFrame.PaddingRight = UDim.new(0, 14)
		padFrame.Parent = body

		lucideIcon(
			body,
			iconName or "bell",
			15,
			Color3.fromRGB(186, 151, 255),
			UDim2.new(0, 0, 0.5, 0),
			Vector2.new(0, 0.5)
		)

		local textLabel = Instance.new("TextLabel")
		textLabel.BackgroundTransparency = 1
		textLabel.Position = UDim2.fromOffset(22, 0)
		textLabel.Size = UDim2.fromOffset(0, 46)
		textLabel.AutomaticSize = Enum.AutomaticSize.X
		textLabel.Font = Enum.Font.GothamSemibold
		textLabel.TextSize = 12
		textLabel.TextColor3 = COLORS.text
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Text = tostring(text)
		textLabel.ZIndex = 203
		textLabel.Parent = body

		tween(toast, { GroupTransparency = 0 }, 0.28)
		tween(body, { Position = UDim2.fromOffset(0, 0) }, 0.28)
		tween(scale, { Scale = 1 }, 0.28)

		task.delay(2.6, function()
			tween(toast, { GroupTransparency = 1 }, 0.22)
			tween(body, { Position = UDim2.fromOffset(0, -10) }, 0.22)
			tween(scale, { Scale = 0.9 }, 0.22)
			task.wait(0.24)
			toast:Destroy()
		end)
	end

	function WindowApi:SetVisible(v)
		setVisible(v == true)
	end

	function WindowApi:SetCollapsed(v)
		setCollapsed(v == true)
	end

	function WindowApi:Toggle()
		setVisible(not state.visible)
	end

	function WindowApi:SetToggleKey(key)
		state.toggleKey = key
		refreshHotkeys()
	end

	function WindowApi:SetTitle(text)
		local titleLabel = dragBtn:FindFirstChild("TitleLabel")
		if titleLabel and titleLabel:IsA("TextLabel") then
			titleLabel.Text = tostring(text or "")
		end
	end

	function WindowApi:SetSubtitle(text)
		text = tostring(text or "")
		local sub = dragBtn:FindFirstChild("SubtitleLabel")
		if sub and sub:IsA("TextLabel") then
			sub.Text = text
			sub.Visible = text ~= ""
		end
	end

	function WindowApi:GetSubtitle()
		local sub = dragBtn:FindFirstChild("SubtitleLabel")
		if sub and sub:IsA("TextLabel") then
			return sub.Text
		end
		return ""
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

	local function createControlHost(parentFrame, pageRef)
		local api = {}

		local function registerSearch(inst, text)
			if not inst then
				return
			end
			local key = string.lower(tostring(text or ""))
			inst:SetAttribute("ObsidianSearch", tostring(text or ""))
			table.insert(state.searchables, {
				inst = inst,
				text = key,
				page = pageRef,
			})
		end

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
			registerSearch(card, (cfg.Name or "Toggle") .. " " .. (cfg.Description or ""))
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
			registerSearch(card, cfg.Name or "Slider")
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
			registerSearch(card, cfg.Name or "Dropdown")
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
			menu.Size = UDim2.fromOffset(180, #options * 30 + 8)
			menu.BackgroundColor3 = Color3.fromRGB(18, 17, 24)
			menu.BorderSizePixel = 0
			menu.ZIndex = 510
			menu.Parent = dropLayer
			corner(menu, 10)
			stroke(menu, COLORS.line, 0.25)
			list(menu, 2)
			pad(menu, 4, 4, 4, 4)

			local function set(v)
				value = v
				main.Text = "  " .. tostring(value)
				closeDropdown()
				open = false
				if cfg.Callback then
					task.spawn(cfg.Callback, value)
				end
			end

			for i, opt in ipairs(options) do
				local optBtn = button(menu, {
					Size = UDim2.new(1, 0, 0, 28),
					Text = opt,
					BackgroundColor3 = opt == value and Color3.fromRGB(47, 35, 72) or Color3.fromRGB(23, 22, 30),
					BackgroundTransparency = opt == value and 0 or 1,
					TextColor3 = opt == value and Color3.fromRGB(178, 143, 252) or Color3.fromRGB(190, 186, 199),
					ZIndex = 511,
				})
				optBtn.LayoutOrder = i
				corner(optBtn, 8)
				optBtn.MouseButton1Click:Connect(function()
					set(opt)
				end)
			end

			main.MouseButton1Click:Connect(function()
				open = not open
				if open then
					openDropdown(menu, main)
				else
					closeDropdown()
				end
			end)

			return { Set = set, Get = function() return value end }
		end

		function api:AddKeybind(cfg)
			cfg = cfg or {}
			local card = addCard(48)
			registerSearch(card, cfg.Name or "Keybind")
			label(card, {
				Text = cfg.Name or "Keybind",
				Font = Enum.Font.GothamSemibold,
				TextSize = 12,
				Size = UDim2.new(1, -110, 1, 0),
			})

			local entry
			local kb = makeKeybind(card, {
				Default = cfg.Default,
				OnChanged = function(v)
					if entry then
						entry.value = v
					end
					refreshHotkeys()
					if cfg.OnChanged then
						cfg.OnChanged(v)
					end
				end,
			})

			entry = {
				name = cfg.Name or "Keybind",
				mode = cfg.Mode or "Toggle",
				callback = cfg.Callback,
				onChanged = cfg.OnChanged,
				active = cfg.DefaultActive == true,
				listed = cfg.Listed ~= false,
				requireActive = cfg.RequireActive == true,
				kb = kb,
				value = cfg.Default,
				get = function()
					return kb.Get()
				end,
				getListed = function()
					return entry.listed ~= false
				end,
				apply = function(v)
					kb:Set(v, true)
					entry.value = v
					if cfg.OnChanged then
						task.spawn(cfg.OnChanged, v)
					end
				end,
			}
			table.insert(state.keybinds, entry)
			refreshHotkeys()

			return {
				Get = kb.Get,
				Set = kb.Set,
				Button = kb.Button,
				SetActive = function(_, v)
					entry.active = v == true
					refreshHotkeys()
				end,
				GetActive = function()
					return entry.active == true
				end,
				SetListed = function(_, v)
					entry.listed = v ~= false
					refreshHotkeys()
				end,
				GetListed = function()
					return entry.listed ~= false
				end,
			}
		end

		function api:AddColorPicker(cfg)
			cfg = cfg or {}
			local color = cfg.Default or COLORS.purple
			local card = addCard(48)
			registerSearch(card, cfg.Name or "Color")
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
			registerSearch(card, (cfg.Name or "Button") .. " " .. (cfg.Description or ""))
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
			registerSearch(card, (cfg.Title or cfg.Name or "Info") .. " " .. (cfg.Content or cfg.Description or ""))
			label(card, {
				Text = cfg.Title or cfg.Name or "Info",
				Font = Enum.Font.GothamSemibold,
				TextSize = 12,
			})
			local body = label(card, {
				Text = cfg.Content or cfg.Description or "",
				TextColor3 = COLORS.muted,
				TextSize = 10,
				Font = Enum.Font.Gotham,
				Size = UDim2.new(1, 0, 0, 44),
				Position = UDim2.fromOffset(0, 22),
				TextYAlignment = Enum.TextYAlignment.Top,
			})
			body.TextWrapped = true
		end

		function api:AddWelcomeBanner(cfg)
			cfg = cfg or {}
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, cfg.Height or 210)
			registerSearch(card, (cfg.Title or "Welcome") .. " " .. (cfg.Subtitle or "Dashboard"))
			card.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
			card.BorderSizePixel = 0
			card.ClipsDescendants = true
			card.LayoutOrder = #parentFrame:GetChildren()
			card.Parent = parentFrame
			corner(card, 16)
			stroke(card, COLORS.line, 0.45)

			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Size = UDim2.fromScale(1, 1)
			img.ScaleType = Enum.ScaleType.Crop
			img.ImageTransparency = 0.05
			img.ZIndex = 1
			img.Parent = card

			local function httpGet(url)
				local ok, body = pcall(function()
					return game:HttpGet(url)
				end)
				if ok and type(body) == "string" and #body > 2 then
					return body
				end
				local reqFns = {}
				pcall(function()
					table.insert(reqFns, request)
				end)
				pcall(function()
					table.insert(reqFns, http_request)
				end)
				pcall(function()
					if syn and syn.request then
						table.insert(reqFns, syn.request)
					end
				end)
				pcall(function()
					if http and http.request then
						table.insert(reqFns, http.request)
					end
				end)
				for _, req in ipairs(reqFns) do
					if typeof(req) == "function" then
						local ok2, res = pcall(req, { Url = url, Method = "GET" })
						if ok2 and typeof(res) == "table" then
							local b = res.Body or res.body
							if type(b) == "string" and #b > 2 then
								return b
							end
						end
					end
				end
				return nil
			end

			local function pickImageUrl(payload)
				if typeof(payload) ~= "table" or typeof(payload.data) ~= "table" then
					return nil
				end
				for _, entry in ipairs(payload.data) do
					if typeof(entry) == "table" then
						if type(entry.imageUrl) == "string" and entry.imageUrl ~= "" and entry.state ~= "Error" then
							return entry.imageUrl
						end
						if typeof(entry.thumbnails) == "table" then
							for _, thumb in ipairs(entry.thumbnails) do
								if typeof(thumb) == "table"
									and type(thumb.imageUrl) == "string"
									and thumb.imageUrl ~= ""
									and thumb.state ~= "Error"
								then
									return thumb.imageUrl
								end
							end
						end
					end
				end
				return nil
			end

			local function setBanner(content)
				if img.Parent and type(content) == "string" and content ~= "" then
					img.Image = content
				end
			end

			-- CDN https often fails on ImageLabel in executors → download + getcustomasset
			local function applyDownloadedImage(imageUrl, placeId)
				if type(imageUrl) ~= "string" or imageUrl == "" then
					return false
				end
				setBanner(imageUrl)

				local bytes = httpGet(imageUrl)
				if not bytes or #bytes < 64 then
					return false
				end

				local folder = "Obsidian"
				pcall(function()
					if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
						if not isfolder(folder) then
							makefolder(folder)
						end
					end
				end)

				local path = folder .. "/banner_" .. tostring(placeId) .. ".png"
				local wrote = false
				pcall(function()
					if typeof(writefile) == "function" then
						writefile(path, bytes)
						wrote = true
					end
				end)
				if not wrote then
					path = "ObsidianBanner_" .. tostring(placeId) .. ".png"
					pcall(function()
						if typeof(writefile) == "function" then
							writefile(path, bytes)
							wrote = true
						end
					end)
				end
				if not wrote then
					return false
				end

				local asset = nil
				pcall(function()
					if typeof(getcustomasset) == "function" then
						asset = getcustomasset(path)
					end
				end)
				pcall(function()
					if not asset and typeof(getsynasset) == "function" then
						asset = getsynasset(path)
					end
				end)
				pcall(function()
					if not asset and syn and typeof(syn.getcustomasset) == "function" then
						asset = syn.getcustomasset(path)
					end
				end)

				if type(asset) == "string" and asset ~= "" then
					setBanner(asset)
					return true
				end
				return false
			end

			if cfg.Image then
				if string.find(cfg.Image, "https://", 1, true) or string.find(cfg.Image, "http://", 1, true) then
					task.spawn(function()
						applyDownloadedImage(cfg.Image, game.PlaceId)
					end)
				else
					setBanner(cfg.Image)
				end
			else
				local placeId = tonumber(cfg.PlaceId) or game.PlaceId
				local universeId = tonumber(cfg.UniverseId) or game.GameId
				setBanner("rbxthumb://type=GameThumbnail&id=" .. tostring(placeId) .. "&w=768&h=432")

				task.spawn(function()
					local endpoints = {
						string.format(
							"https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=%s&countPerUniverse=1&size=768x432&format=Png&isCircular=false",
							tostring(universeId)
						),
						string.format(
							"https://thumbnails.roblox.com/v1/places/gameicons?placeIds=%s&returnPolicy=PlaceHolder&size=512x512&format=Png",
							tostring(placeId)
						),
						string.format(
							"https://thumbnails.roblox.com/v1/games/icons?universeIds=%s&returnPolicy=PlaceHolder&size=512x512&format=Png",
							tostring(universeId)
						),
					}

					for _, endpoint in ipairs(endpoints) do
						local raw = httpGet(endpoint)
						if raw then
							local ok, decoded = pcall(function()
								return HttpService:JSONDecode(raw)
							end)
							if ok then
								local imageUrl = pickImageUrl(decoded)
								if imageUrl and applyDownloadedImage(imageUrl, placeId) then
									return
								end
								if imageUrl then
									setBanner(imageUrl)
									return
								end
							end
						end
					end

					setBanner("rbxthumb://type=PlaceIcon&id=" .. tostring(placeId) .. "&w=512&h=512")
					task.wait(0.15)
					setBanner("rbxthumb://type=GameIcon&id=" .. tostring(universeId) .. "&w=512&h=512")
				end)
			end

			local shade = Instance.new("Frame")
			shade.Size = UDim2.fromScale(1, 1)
			shade.BackgroundColor3 = Color3.fromRGB(8, 6, 14)
			shade.BackgroundTransparency = 0.35
			shade.BorderSizePixel = 0
			shade.ZIndex = 2
			shade.Parent = card
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 16, 28)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 6, 12)),
			})
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55),
				NumberSequenceKeypoint.new(0.45, 0.25),
				NumberSequenceKeypoint.new(1, 0.05),
			})
			g.Parent = shade

			local welcome = cfg.Title
				or ("Welcome, " .. (LocalPlayer.DisplayName or LocalPlayer.Name or "Player"))
			local playing = cfg.Subtitle
			if not playing then
				local placeName = tostring(game.PlaceId)
				pcall(function()
					local data = MarketplaceService:GetProductInfo(game.PlaceId)
					if data and data.Name then
						placeName = data.Name
					end
				end)
				playing = "You are currently playing, " .. placeName
			end

			label(card, {
				Text = welcome,
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				Size = UDim2.new(1, -28, 0, 30),
				Position = UDim2.new(0, 18, 1, -62),
				ZIndex = 5,
			})
			label(card, {
				Text = playing,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Color3.fromRGB(200, 194, 214),
				Size = UDim2.new(1, -28, 0, 20),
				Position = UDim2.new(0, 18, 1, -28),
				ZIndex = 5,
			})
			return card
		end

function api:AddChangelog(cfg)
			cfg = cfg or {}
			local items = cfg.Items or cfg.Entries or {}
			local wrap = Instance.new("Frame")
			wrap.Size = UDim2.new(1, 0, 0, 0)
			wrap.AutomaticSize = Enum.AutomaticSize.Y
			wrap.BackgroundTransparency = 1
			wrap.LayoutOrder = #parentFrame:GetChildren()
			wrap.Parent = parentFrame
			list(wrap, 8)

			if cfg.Title or cfg.Version then
				local head = Instance.new("Frame")
				head.Size = UDim2.new(1, 0, 0, 22)
				head.BackgroundTransparency = 1
				head.LayoutOrder = 0
				head.Parent = wrap
				label(head, {
					Text = cfg.Title or cfg.Version or "Updates",
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					TextColor3 = COLORS.muted,
				})
			end

			for i, item in ipairs(items) do
				local kind = string.lower(tostring(item.Kind or item.Type or "add"))
				local accent = item.Color
					or (kind == "edit" or kind == "change") and Color3.fromRGB(230, 190, 70)
					or Color3.fromRGB(88, 214, 112)
				local iconName = item.Icon or ((kind == "edit" or kind == "change") and "pencil" or "plus")

				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 40)
				row.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
				row.BorderSizePixel = 0
				row.LayoutOrder = i
				row.Parent = wrap
				corner(row, 10)
				stroke(row, COLORS.line, 0.55)

				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(0, 3, 1, -12)
				bar.Position = UDim2.fromOffset(8, 6)
				bar.BackgroundColor3 = accent
				bar.BorderSizePixel = 0
				bar.Parent = row
				corner(bar, 2)

				lucideIcon(
					row,
					iconName,
					14,
					accent,
					UDim2.new(0, 22, 0.5, 0),
					Vector2.new(0, 0.5)
				)
				label(row, {
					Text = item.Text or item.Title or "",
					Font = Enum.Font.GothamMedium,
					TextSize = 12,
					Size = UDim2.new(1, -52, 1, 0),
					Position = UDim2.fromOffset(44, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
				})
			end
			return wrap
		end

		function api:AddGroup(cfg)
			cfg = cfg or {}
			local group = Instance.new("Frame")
			group.Size = UDim2.new(1, 0, 0, 0)
			group.AutomaticSize = Enum.AutomaticSize.Y
			group.BackgroundColor3 = COLORS.panel
			group.BorderSizePixel = 0
			group.LayoutOrder = #parentFrame:GetChildren()
			group.ClipsDescendants = false
			group.Parent = parentFrame
			corner(group, 14)
			stroke(group, COLORS.line, 0.45)
			list(group, 0)
			registerSearch(group, (cfg.Name or "Group") .. " " .. (cfg.Description or ""))

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

			local groupToggle
			local groupEnabled = if cfg.Default == nil then true else cfg.Default
			if cfg.Default ~= nil or cfg.Callback then
				groupToggle = makeToggle(header, groupEnabled, function(v)
					groupEnabled = v
					if cfg.Callback then
						cfg.Callback(v)
					end
				end, UDim2.new(1, -14, 0.5, -3))
			end

			local body = Instance.new("Frame")
			body.Size = UDim2.new(1, 0, 0, 0)
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.BackgroundTransparency = 1
			body.LayoutOrder = 1
			body.Parent = group
			list(body, 0)

			local function addDivider(parent)
				local line = Instance.new("Frame")
				line.Size = UDim2.new(1, -28, 0, 1)
				line.Position = UDim2.new(0, 14, 1, 0)
				line.AnchorPoint = Vector2.new(0, 1)
				line.BackgroundColor3 = COLORS.line
				line.BackgroundTransparency = 0.55
				line.BorderSizePixel = 0
				line.Parent = parent
			end

			local function row(height)
				local card = Instance.new("Frame")
				card.Size = UDim2.new(1, 0, 0, height)
				card.BackgroundTransparency = 1
				card.BorderSizePixel = 0
				card.LayoutOrder = #body:GetChildren()
				card.Parent = body
				pad(card, 6, 8, 14, 14)
				addDivider(card)
				return card
			end

			local groupApi = {}

			function groupApi:AddToggle(c)
				c = c or {}
				local card = row(c.Description and 52 or 40)
				registerSearch(card, (c.Name or "Toggle") .. " " .. (c.Description or ""))
				label(card, {
					Text = c.Name or "Toggle",
					Font = Enum.Font.GothamSemibold,
					TextSize = 12,
					Size = UDim2.new(1, -50, 0, 18),
				})
				if c.Description then
					label(card, {
						Text = c.Description,
						TextColor3 = COLORS.muted,
						TextSize = 9,
						Size = UDim2.new(1, -50, 0, 14),
						Position = UDim2.fromOffset(0, 20),
					})
				end
				return makeToggle(card, c.Default == true, c.Callback)
			end

			function groupApi:AddSlider(c)
				c = c or {}
				local minV, maxV = c.Min or 0, c.Max or 100
				local value = c.Default or minV
				local card = row(68)
				registerSearch(card, c.Name or "Slider")
				label(card, {
					Text = c.Name or "Slider",
					Font = Enum.Font.GothamSemibold,
					TextSize = 12,
					Size = UDim2.new(1, -56, 0, 18),
				})
				local box = Instance.new("TextBox")
				box.Size = UDim2.fromOffset(48, 22)
				box.Position = UDim2.new(1, 0, 0, 0)
				box.AnchorPoint = Vector2.new(1, 0)
				box.BackgroundColor3 = Color3.fromRGB(22, 20, 28)
				box.BorderSizePixel = 0
				box.Text = tostring(value)
				box.Font = Enum.Font.GothamSemibold
				box.TextSize = 10
				box.TextColor3 = COLORS.purple
				box.Parent = card
				corner(box, 7)

				local track = Instance.new("Frame")
				track.Position = UDim2.fromOffset(0, 32)
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
				knob.Size = UDim2.fromOffset(12, 12)
				knob.AnchorPoint = Vector2.new(0.5, 0.5)
				knob.Position = UDim2.fromScale((value - minV) / math.max(maxV - minV, 1), 0.5)
				knob.BackgroundColor3 = Color3.fromRGB(242, 240, 247)
				knob.BorderSizePixel = 0
				knob.ZIndex = 3
				knob.Parent = track
				corner(knob, 100)

				local function set(v)
					value = math.clamp(math.round(v), minV, maxV)
					local a = (value - minV) / math.max(maxV - minV, 1)
					fill.Size = UDim2.fromScale(a, 1)
					knob.Position = UDim2.fromScale(a, 0.5)
					box.Text = tostring(value)
					if c.Callback then
						task.spawn(c.Callback, value)
					end
				end

				local sliding = false
				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						sliding = true
						local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
						set(minV + (maxV - minV) * a)
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
						local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
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

			function groupApi:AddKeybind(c)
				c = c or {}
				local card = row(46)
				registerSearch(card, c.Name or "Keybind")
				label(card, {
					Text = c.Name or "Keybind",
					Font = Enum.Font.GothamSemibold,
					TextSize = 12,
					Size = UDim2.new(1, -110, 1, 0),
				})
				local entry
				local kb = makeKeybind(card, {
					Default = c.Default,
					OnChanged = function(v)
						if entry then
							entry.value = v
						end
						refreshHotkeys()
						if c.OnChanged then
							c.OnChanged(v)
						end
					end,
				})
				entry = {
					name = c.Name or "Keybind",
					mode = c.Mode or "Toggle",
					callback = c.Callback,
					onChanged = c.OnChanged,
					active = c.DefaultActive == true,
					listed = c.Listed ~= false,
					requireActive = c.RequireActive == true,
					kb = kb,
					value = c.Default,
					get = function()
						return kb.Get()
					end,
					getListed = function()
						return entry.listed ~= false
					end,
					apply = function(v)
						kb:Set(v, true)
						entry.value = v
						if c.OnChanged then
							task.spawn(c.OnChanged, v)
						end
					end,
				}
				table.insert(state.keybinds, entry)
				refreshHotkeys()
				return {
					Get = kb.Get,
					Set = kb.Set,
					Button = kb.Button,
					SetActive = function(_, v)
						entry.active = v == true
						refreshHotkeys()
					end,
					GetActive = function()
						return entry.active == true
					end,
					SetListed = function(_, v)
						entry.listed = v ~= false
						refreshHotkeys()
					end,
					GetListed = function()
						return entry.listed ~= false
					end,
				}
			end

			function groupApi:AddDropdown(c)
				c = c or {}
				local options = c.Options or { "Option 1" }
				local value = c.Default or options[1]
				local card = row(64)
				registerSearch(card, c.Name or "Dropdown")
				label(card, {
					Text = c.Name or "Dropdown",
					Font = Enum.Font.GothamSemibold,
					TextSize = 12,
					Size = UDim2.new(1, 0, 0, 16),
				})
				local open = false
				local main = button(card, {
					Size = UDim2.new(1, 0, 0, 28),
					Position = UDim2.fromOffset(0, 20),
					Text = "  " .. tostring(value),
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundColor3 = Color3.fromRGB(27, 25, 34),
					TextColor3 = Color3.fromRGB(191, 186, 201),
					ZIndex = 5,
				})
				corner(main, 9)
				stroke(main, COLORS.line, 0.4)

				local menu = Instance.new("Frame")
				menu.Visible = false
				menu.Size = UDim2.fromOffset(180, #options * 28 + 8)
				menu.BackgroundColor3 = Color3.fromRGB(18, 17, 24)
				menu.BorderSizePixel = 0
				menu.ZIndex = 510
				menu.Parent = dropLayer
				corner(menu, 9)
				stroke(menu, COLORS.line, 0.25)
				list(menu, 2)
				pad(menu, 4, 4, 4, 4)

				local function set(v)
					value = v
					main.Text = "  " .. tostring(value)
					closeDropdown()
					open = false
					if c.Callback then
						task.spawn(c.Callback, value)
					end
				end

				for i, opt in ipairs(options) do
					local optBtn = button(menu, {
						Size = UDim2.new(1, 0, 0, 26),
						Text = opt,
						BackgroundColor3 = opt == value and Color3.fromRGB(47, 35, 72) or Color3.fromRGB(23, 22, 30),
						BackgroundTransparency = opt == value and 0 or 1,
						TextColor3 = opt == value and Color3.fromRGB(178, 143, 252) or Color3.fromRGB(190, 186, 199),
						ZIndex = 511,
					})
					optBtn.LayoutOrder = i
					corner(optBtn, 7)
					optBtn.MouseButton1Click:Connect(function()
						set(opt)
					end)
				end

				main.MouseButton1Click:Connect(function()
					open = not open
					if open then
						openDropdown(menu, main)
					else
						closeDropdown()
					end
				end)
				return { Set = set, Get = function() return value end }
			end

			function groupApi:AddButton(c)
				c = c or {}
				local card = row(c.Description and 72 or 52)
				if c.Description then
					label(card, {
						Text = c.Name or "Button",
						Font = Enum.Font.GothamSemibold,
						TextSize = 12,
						Size = UDim2.new(1, 0, 0, 14),
					})
					label(card, {
						Text = c.Description,
						TextColor3 = COLORS.muted,
						TextSize = 9,
						Size = UDim2.new(1, 0, 0, 12),
						Position = UDim2.fromOffset(0, 16),
					})
				end
				local b = button(card, {
					Size = UDim2.new(1, 0, 0, 30),
					Position = UDim2.fromOffset(0, c.Description and 32 or 4),
					Text = c.Name or "Button",
					BackgroundColor3 = COLORS.purple,
					TextColor3 = Color3.new(1, 1, 1),
				})
				corner(b, 10)
				b.MouseButton1Click:Connect(function()
					if c.Callback then
						c.Callback()
					end
				end)
				return b
			end

			function groupApi:AddParagraph(c)
				c = c or {}
				local card = row(96)
				label(card, {
					Text = c.Title or c.Name or "Info",
					Font = Enum.Font.GothamSemibold,
					TextSize = 12,
				})
				local body = label(card, {
					Text = c.Content or c.Description or "",
					TextColor3 = COLORS.muted,
					TextSize = 10,
					Font = Enum.Font.Gotham,
					Size = UDim2.new(1, 0, 0, 56),
					Position = UDim2.fromOffset(0, 20),
					TextYAlignment = Enum.TextYAlignment.Top,
				})
				body.TextWrapped = true
			end

			function groupApi:AddColorPicker(c)
				c = c or {}
				local color = c.Default or COLORS.purple
				local card = row(46)
				label(card, {
					Text = c.Name or "Color",
					Font = Enum.Font.GothamSemibold,
					TextSize = 12,
					Size = UDim2.new(1, -40, 1, 0),
				})
				local swatch = button(card, {
					Size = UDim2.fromOffset(26, 26),
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
					if c.Callback then
						task.spawn(c.Callback, color)
					end
				end)
				return {
					Get = function()
						return color
					end,
					Set = function(_, col)
						color = col
						swatch.BackgroundColor3 = col
					end,
				}
			end

			groupApi.Toggle = groupToggle
			groupApi.SetEnabled = function(_, v)
				groupEnabled = v == true
				if groupToggle then
					groupToggle:Set(groupEnabled)
				end
			end
			groupApi.GetEnabled = function()
				return groupEnabled
			end

			return groupApi
		end

		return api
	end

	function WindowApi:AddPage(cfg)
		cfg = cfg or {}
		local page = {
			name = cfg.Name or "Page",
			icon = cfg.Icon,
			fullWidth = cfg.FullWidth == true,
			hideTitle = cfg.HideTitle == true or cfg.FullWidth == true,
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

		local iconName = cfg.Icon or "sparkles"
		local navIcon = lucideIcon(
			navBtn,
			iconName,
			14,
			COLORS.muted,
			UDim2.new(0, 10, 0.5, 0),
			Vector2.new(0, 0.5)
		)
		navIcon.ZIndex = 3

		local navLabel = label(navBtn, {
			Text = page.name,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			Size = UDim2.new(1, -36, 1, 0),
			Position = UDim2.fromOffset(30, 0),
			TextColor3 = COLORS.muted,
		})
		page.navBtn = navBtn
		page.navLabel = navLabel
		page.navIcon = navIcon
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
			return createControlHost(page.left, page)
		end
		function pageApi:Right()
			return createControlHost(page.right, page)
		end
		function pageApi:AddColumn(side)
			if string.lower(tostring(side)) == "right" then
				return self:Right()
			end
			return self:Left()
		end

		local leftApi = createControlHost(page.left, page)
		local rightApi = createControlHost(page.right, page)
		local leftCount, rightCount = 0, 0
		local function pick()
			if page.fullWidth then
				return leftApi
			end
			if leftCount <= rightCount then
				leftCount = leftCount + 1
				return leftApi
			end
			rightCount = rightCount + 1
			return rightApi
		end

		for _, name in {
			"AddToggle",
			"AddSlider",
			"AddDropdown",
			"AddKeybind",
			"AddColorPicker",
			"AddButton",
			"AddParagraph",
			"AddGroup",
			"AddWelcomeBanner",
			"AddChangelog",
		} do
			pageApi[name] = function(_, cfg2)
				cfg2 = cfg2 or {}
				local side = cfg2.Side and string.lower(tostring(cfg2.Side))
				local host
				if page.fullWidth or side == "left" then
					leftCount = leftCount + 1
					host = leftApi
				elseif side == "right" then
					rightCount = rightCount + 1
					host = rightApi
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
		apply = function(v)
			state.toggleKey = v
		end,
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
-- Built-in feature helpers (ESP / Player / Game)
----------------------------------------------------------------------

local Feature = {}

local R15_BONES = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
}

local R6_BONES = {
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

local function makeLine(parent, z)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 0
	f.Visible = false
	f.ZIndex = z or 120
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
	return f
end

local function placeLine(line, a, b, color, thickness)
	if typeof(line) == "table" and line.kind == "drawing" then
		local obj = line.obj
		obj.From = a
		obj.To = b
		obj.Color = color
		obj.Thickness = thickness or 1.5
		obj.Transparency = 0.15
		obj.Visible = true
		return
	end
	local delta = b - a
	local len = delta.Magnitude
	if len < 1 then
		line.Visible = false
		return
	end
	local mid = a:Lerp(b, 0.5)
	line.Visible = true
	line.BackgroundColor3 = color
	line.BackgroundTransparency = 0
	line.Size = UDim2.fromOffset(math.max(thickness or 2, 2), len)
	line.Position = UDim2.fromOffset(mid.X, mid.Y)
	line.Rotation = math.deg(math.atan2(delta.Y, delta.X)) - 90
end

local function hideLine(line)
	if typeof(line) == "table" and line.kind == "drawing" then
		line.obj.Visible = false
		return
	end
	line.Visible = false
end

local function destroyLine(line)
	if typeof(line) == "table" and line.kind == "drawing" then
		pcall(function()
			line.obj:Remove()
		end)
		return
	end
	if typeof(line) == "Instance" then
		line:Destroy()
	end
end

local function makeTracer(parent)
	if Drawing and typeof(Drawing.new) == "function" then
		local ok, obj = pcall(Drawing.new, "Line")
		if ok and obj then
			obj.Visible = false
			obj.Thickness = 1.5
			obj.Transparency = 0.15
			return { kind = "drawing", obj = obj }
		end
	end
	return makeLine(parent, 130)
end

local function worldTo(cam, pos)
	local v, on = cam:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), on and v.Z > 0
end

function Feature.ESP()
	local settings = {
		enabled = false,
		box = true,
		boxMode = "Corners", -- Corners | Full
		roundedBox = true,
		health = true,
		heartHealth = true,
		name = true,
		nickname = true,
		distance = true,
		tracer = false,
		skeleton = false,
		headGlow = true,
		chams = false,
		teamCheck = false,
		streamLoad = true,
		maxDistance = 2500,
		boxColor = Color3.fromRGB(64, 168, 255),
		healthColor = Color3.fromRGB(255, 90, 120),
		nameColor = Color3.fromRGB(255, 255, 255),
		skeletonColor = Color3.fromRGB(180, 150, 255),
		glowColor = Color3.fromRGB(126, 91, 232),
	}

	local gui
	local drawings = {} -- keyed by UserId
	local conn
	local watchConns = {}
	local lastStream = 0
	local streamIndex = 1

	local function rootOf(char)
		if not char then
			return nil
		end
		return char:FindFirstChild("HumanoidRootPart")
			or char:FindFirstChild("UpperTorso")
			or char:FindFirstChild("Torso")
			or char.PrimaryPart
	end

	local function anyPart(char)
		local r = rootOf(char)
		if r then
			return r
		end
		if not char then
			return nil
		end
		for _, p in ipairs(char:GetChildren()) do
			if p:IsA("BasePart") then
				return p
			end
		end
		return nil
	end

	local function ensure()
		if gui and gui.Parent then
			return gui
		end
		gui = Instance.new("ScreenGui")
		gui.Name = "ObsidianESP"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 120
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		protect(gui)
		return gui
	end

	local function makeCornerBracket(parent)
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Visible = false
		holder.ZIndex = 112
		holder.Parent = parent
		local h = Instance.new("Frame")
		h.Name = "H"
		h.BorderSizePixel = 0
		h.ZIndex = 113
		h.Parent = holder
		local v = Instance.new("Frame")
		v.Name = "V"
		v.BorderSizePixel = 0
		v.ZIndex = 113
		v.Parent = holder
		return holder
	end

	local function clear(userId)
		local d = drawings[userId]
		if not d then
			return
		end
		if d.maid then
			for _, c in ipairs(d.maid) do
				if typeof(c) == "RBXScriptConnection" then
					c:Disconnect()
				elseif typeof(c) == "Instance" then
					pcall(function()
						c:Destroy()
					end)
				end
			end
		end
		if d.tracer then
			destroyLine(d.tracer)
		end
		if d.bones then
			for _, bone in ipairs(d.bones) do
				destroyLine(bone)
			end
		end
		if d.corners then
			for _, c in ipairs(d.corners) do
				if typeof(c) == "Instance" then
					c:Destroy()
				end
			end
		end
		for _, key in ipairs({ "chams", "bb", "box", "glow" }) do
			local x = d[key]
			if typeof(x) == "Instance" then
				pcall(function()
					x:Destroy()
				end)
			end
		end
		drawings[userId] = nil
	end

	local function create(char, player)
		if not char or not player then
			return
		end
		local root = anyPart(char)
		if not root then
			return
		end
		local head = char:FindFirstChild("Head")
		local host = ensure()
		local maid = {}
		local userId = player.UserId

		-- wipe previous drawing for this user
		if drawings[userId] then
			clear(userId)
		end

		local chams = Instance.new("Highlight")
		chams.FillTransparency = 0.75
		chams.OutlineTransparency = 0.15
		chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		chams.Adornee = char
		chams.Enabled = false
		chams.Parent = host
		table.insert(maid, chams)

		local bb = Instance.new("BillboardGui")
		bb.AlwaysOnTop = true
		bb.Size = UDim2.fromOffset(168, 0)
		bb.AutomaticSize = Enum.AutomaticSize.Y
		bb.StudsOffset = Vector3.new(0, 3.6, 0)
		bb.Adornee = head or root
		bb.Parent = host
		table.insert(maid, bb)

		local tagList = Instance.new("UIListLayout")
		tagList.FillDirection = Enum.FillDirection.Vertical
		tagList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		tagList.SortOrder = Enum.SortOrder.LayoutOrder
		tagList.Padding = UDim.new(0, 1)
		tagList.Parent = bb

		local function tagLabel(order, size, bold)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, 0, size)
			t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
			t.TextSize = bold and 12 or 10
			t.TextStrokeTransparency = 0.35
			t.TextXAlignment = Enum.TextXAlignment.Center
			t.LayoutOrder = order
			t.Visible = false
			t.Parent = bb
			return t
		end

		local nameL = tagLabel(1, 14, true)
		local nickL = tagLabel(2, 12, false)
		nickL.TextColor3 = Color3.fromRGB(180, 176, 190)
		local heartL = tagLabel(3, 14, true)
		local distL = tagLabel(4, 12, false)
		distL.TextColor3 = Color3.fromRGB(190, 190, 198)

		-- full rounded box
		local boxFrame = Instance.new("Frame")
		boxFrame.BackgroundTransparency = 1
		boxFrame.BorderSizePixel = 0
		boxFrame.Visible = false
		boxFrame.ZIndex = 110
		boxFrame.Parent = host
		local boxStroke = Instance.new("UIStroke")
		boxStroke.Thickness = 1.6
		boxStroke.Transparency = 0.05
		boxStroke.Parent = boxFrame
		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = UDim.new(0, 8)
		boxCorner.Parent = boxFrame
		table.insert(maid, boxFrame)

		-- corner brackets (classic ESP box)
		local corners = {
			TL = makeCornerBracket(host),
			TR = makeCornerBracket(host),
			BL = makeCornerBracket(host),
			BR = makeCornerBracket(host),
		}
		for _, c in ipairs(corners) do
			table.insert(maid, c)
		end

		local tracer = makeTracer(host)
		if typeof(tracer) == "Instance" then
			table.insert(maid, tracer)
		end

		local bones = {}
		for _ = 1, 16 do
			local ln = makeLine(host, 115)
			table.insert(bones, ln)
			table.insert(maid, ln)
		end

		local glow
		if head then
			glow = Instance.new("PointLight")
			glow.Name = "ObsidianHeadGlow"
			glow.Brightness = 1.4
			glow.Range = 8
			glow.Shadows = false
			glow.Parent = head
			table.insert(maid, glow)
		end

		-- don't wipe on brief stream unload; CharacterAdded handler recreates
		table.insert(maid, char.AncestryChanged:Connect(function(_, parent)
			if not parent then
				task.delay(0.35, function()
					local d = drawings[userId]
					if d and d.char == char and (not player.Character or player.Character ~= char) then
						clear(userId)
					end
				end)
			end
		end))

		drawings[userId] = {
			maid = maid,
			chams = chams,
			bb = bb,
			nameL = nameL,
			nickL = nickL,
			heartL = heartL,
			distL = distL,
			box = boxFrame,
			boxStroke = boxStroke,
			boxCorner = boxCorner,
			corners = corners,
			tracer = tracer,
			bones = bones,
			glow = glow,
			player = player,
			char = char,
			miss = 0,
		}
	end

	local function placeCorner(bracket, x, y, w, h, color, which)
		local len = math.clamp(math.min(w, h) * 0.28, 6, 18)
		local thick = 2
		bracket.Visible = true
		bracket.Position = UDim2.fromOffset(x, y)
		bracket.Size = UDim2.fromOffset(w, h)
		local H, V = bracket:FindFirstChild("H"), bracket:FindFirstChild("V")
		if not (H and V) then
			return
		end
		H.BackgroundColor3 = color
		V.BackgroundColor3 = color
		if which == "TL" then
			H.Size = UDim2.fromOffset(len, thick)
			H.Position = UDim2.fromOffset(0, 0)
			V.Size = UDim2.fromOffset(thick, len)
			V.Position = UDim2.fromOffset(0, 0)
		elseif which == "TR" then
			H.Size = UDim2.fromOffset(len, thick)
			H.Position = UDim2.new(1, -len, 0, 0)
			V.Size = UDim2.fromOffset(thick, len)
			V.Position = UDim2.new(1, -thick, 0, 0)
		elseif which == "BL" then
			H.Size = UDim2.fromOffset(len, thick)
			H.Position = UDim2.new(0, 0, 1, -thick)
			V.Size = UDim2.fromOffset(thick, len)
			V.Position = UDim2.new(0, 0, 1, -len)
		else -- BR
			H.Size = UDim2.fromOffset(len, thick)
			H.Position = UDim2.new(1, -len, 1, -thick)
			V.Size = UDim2.fromOffset(thick, len)
			V.Position = UDim2.new(1, -thick, 1, -len)
		end
	end

	local function hideCorners(d)
		if not d.corners then
			return
		end
		for _, c in ipairs(d.corners) do
			c.Visible = false
		end
	end

	local function getBounds(char, cam)
		local points = {}
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") then
				local cf, size = part.CFrame, part.Size
				for _, ox in ipairs({ -0.5, 0.5 }) do
					for _, oy in ipairs({ -0.5, 0.5 }) do
						for _, oz in ipairs({ -0.5, 0.5 }) do
							local world = (cf * CFrame.new(size.X * ox, size.Y * oy, size.Z * oz)).Position
							local v, on = worldTo(cam, world)
							if on then
								table.insert(points, v)
							end
						end
					end
				end
			end
		end
		if #points < 2 then
			local root = anyPart(char)
			if root then
				local v, on = worldTo(cam, root.Position)
				if on then
					return Vector2.new(v.X - 20, v.Y - 40), Vector2.new(40, 80)
				end
			end
			return nil
		end
		local minX, minY = math.huge, math.huge
		local maxX, maxY = -math.huge, -math.huge
		for _, p in ipairs(points) do
			minX, minY = math.min(minX, p.X), math.min(minY, p.Y)
			maxX, maxY = math.max(maxX, p.X), math.max(maxY, p.Y)
		end
		local padAmt = 3
		return Vector2.new(minX - padAmt, minY - padAmt), Vector2.new(maxX - minX + padAmt * 2, maxY - minY + padAmt * 2)
	end

	local function tryCreate(plr)
		local char = plr.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return
		end
		if not anyPart(char) then
			return
		end
		local existing = drawings[plr.UserId]
		if existing and existing.char == char then
			return
		end
		create(char, plr)
	end

	local function watchPlayer(plr)
		if plr == LocalPlayer then
			return
		end
		table.insert(watchConns, plr.CharacterAdded:Connect(function(char)
			task.spawn(function()
				-- wait for parts to stream in (new players / far players)
				for _ = 1, 40 do
					if not settings.enabled then
						return
					end
					if anyPart(char) and char:FindFirstChildOfClass("Humanoid") then
						tryCreate(plr)
						return
					end
					task.wait(0.15)
				end
				tryCreate(plr)
			end)
		end))
		table.insert(watchConns, plr.CharacterRemoving:Connect(function()
			-- soft clear after short delay so respawn can replace
			task.delay(0.2, function()
				if not plr.Character then
					clear(plr.UserId)
				end
			end)
		end))
		if plr.Character then
			task.defer(function()
				tryCreate(plr)
			end)
		end
	end

	local function step()
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local myRoot = rootOf(LocalPlayer.Character)
		local alive = {}
		local now = os.clock()
		local players = Players:GetPlayers()

		if settings.enabled and settings.streamLoad and myRoot and now - lastStream > 0.75 then
			lastStream = now
			streamIndex = (streamIndex % math.max(#players, 1)) + 1
			local target = players[streamIndex]
			if target and target ~= LocalPlayer then
				local pos = myRoot.Position
				local tChar = target.Character
				local tRoot = tChar and anyPart(tChar)
				if tRoot then
					pos = tRoot.Position
				end
				pcall(function()
					LocalPlayer:RequestStreamAroundAsync(pos, 10)
				end)
			end
		end

		if settings.enabled then
			for _, plr in ipairs(players) do
				if plr ~= LocalPlayer then
					local skip = settings.teamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team
					if not skip then
						local char = plr.Character
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						local root = anyPart(char)
						if char and hum and root and hum.Health > 0 then
							local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
							local existing = drawings[plr.UserId]
							local keepPad = existing and 120 or 0
							if dist <= settings.maxDistance + keepPad then
								alive[plr.UserId] = true
								if not existing or existing.char ~= char then
									create(char, plr)
								end
								local d = drawings[plr.UserId]
								if d then
									d.miss = 0
									d.chams.Enabled = settings.chams
									d.chams.OutlineColor = settings.boxColor
									d.chams.FillColor = settings.boxColor
									if d.chams.Adornee ~= char then
										d.chams.Adornee = char
									end

									local showTag = settings.name or settings.nickname or settings.health or settings.distance
									d.bb.Enabled = showTag
									local adorn = char:FindFirstChild("Head") or root
									if d.bb.Adornee ~= adorn then
										d.bb.Adornee = adorn
									end
									d.nameL.Visible = settings.name
									d.nameL.Text = plr.DisplayName
									d.nameL.TextColor3 = settings.nameColor
									d.nickL.Visible = settings.nickname
									d.nickL.Text = "@" .. plr.Name
									d.heartL.Visible = settings.health
									local hp = math.floor(hum.Health + 0.5)
									local maxHp = math.floor(hum.MaxHealth + 0.5)
									if settings.heartHealth then
										d.heartL.Text = string.format("♥ %d / %d", hp, maxHp)
									else
										d.heartL.Text = string.format("%d / %d", hp, maxHp)
									end
									d.heartL.TextColor3 = settings.healthColor
									d.distL.Visible = settings.distance
									d.distL.Text = string.format("%dm", math.floor(dist))

									if d.glow then
										d.glow.Enabled = settings.headGlow
										d.glow.Color = settings.glowColor
									elseif settings.headGlow then
										local head = char:FindFirstChild("Head")
										if head then
											local g = Instance.new("PointLight")
											g.Name = "ObsidianHeadGlow"
											g.Brightness = 1.4
											g.Range = 8
											g.Color = settings.glowColor
											g.Parent = head
											d.glow = g
											table.insert(d.maid, g)
										end
									end

									local mode = string.lower(tostring(settings.boxMode or "corners"))
									if settings.box then
										local pos, size = getBounds(char, cam)
										if pos and size and size.X > 2 and size.Y > 2 then
											if mode == "full" then
												hideCorners(d)
												d.box.Visible = true
												d.box.Position = UDim2.fromOffset(pos.X, pos.Y)
												d.box.Size = UDim2.fromOffset(math.max(size.X, 8), math.max(size.Y, 8))
												d.boxStroke.Color = settings.boxColor
												d.boxCorner.CornerRadius = UDim.new(0, settings.roundedBox and 8 or 2)
											else
												d.box.Visible = false
												placeCorner(d.corners.TL, pos.X, pos.Y, size.X, size.Y, settings.boxColor, "TL")
												placeCorner(d.corners.TR, pos.X, pos.Y, size.X, size.Y, settings.boxColor, "TR")
												placeCorner(d.corners.BL, pos.X, pos.Y, size.X, size.Y, settings.boxColor, "BL")
												placeCorner(d.corners.BR, pos.X, pos.Y, size.X, size.Y, settings.boxColor, "BR")
											end
										else
											d.box.Visible = false
											hideCorners(d)
										end
									else
										d.box.Visible = false
										hideCorners(d)
									end

									if settings.tracer then
										local head = char:FindFirstChild("Head")
										local targetPos = (head and head.Position) or root.Position
										local sp, on = worldTo(cam, targetPos)
										if on then
											local origin = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y - 2)
											placeLine(d.tracer, origin, sp, settings.boxColor, 2)
										else
											hideLine(d.tracer)
										end
									else
										hideLine(d.tracer)
									end

									local pairsList = char:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
									for _, bone in ipairs(d.bones) do
										bone.Visible = false
									end
									if settings.skeleton then
										local bi = 0
										for _, pair in ipairs(pairsList) do
											local aPart = char:FindFirstChild(pair[1])
											local bPart = char:FindFirstChild(pair[2])
											if aPart and bPart and aPart:IsA("BasePart") and bPart:IsA("BasePart") then
												local a, aOn = worldTo(cam, aPart.Position)
												local b, bOn = worldTo(cam, bPart.Position)
												if aOn and bOn then
													bi = bi + 1
													local line = d.bones[bi]
													if line then
														placeLine(line, a, b, settings.skeletonColor, 2)
													end
												end
											end
										end
									end
								end
							elseif existing then
								existing.miss = (existing.miss or 0) + 1
								if existing.miss < 45 then
									alive[plr.UserId] = true
								end
							end
						elseif drawings[plr.UserId] then
							local existing = drawings[plr.UserId]
							existing.miss = (existing.miss or 0) + 1
							if existing.miss < 45 then
								alive[plr.UserId] = true
							end
						end
					end
				end
			end
		end

		for userId in pairs(drawings) do
			if not settings.enabled or not alive[userId] then
				clear(userId)
			end
		end
	end

	return {
		Set = function(_, patch)
			for k, v in pairs(patch) do
				settings[k] = v
			end
			if patch.enabled == false then
				for userId in pairs(drawings) do
					clear(userId)
				end
			elseif patch.enabled == true then
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= LocalPlayer then
						tryCreate(plr)
					end
				end
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
			for _, c in ipairs(watchConns) do
				c:Disconnect()
			end
			table.clear(watchConns)
			table.insert(watchConns, Players.PlayerAdded:Connect(watchPlayer))
			table.insert(watchConns, Players.PlayerRemoving:Connect(function(plr)
				clear(plr.UserId)
			end))
			for _, plr in ipairs(Players:GetPlayers()) do
				watchPlayer(plr)
			end
			conn = RunService.RenderStepped:Connect(step)
		end,
		Stop = function()
			if conn then
				conn:Disconnect()
				conn = nil
			end
			for _, c in ipairs(watchConns) do
				c:Disconnect()
			end
			table.clear(watchConns)
			for userId in pairs(drawings) do
				clear(userId)
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
		speedMethod = "WalkSpeed", -- WalkSpeed | CFrame | Velocity
		jumpEnabled = false,
		jumpPower = 75,
		infiniteJump = false,
		noclip = false,
		fly = false,
		flySpeed = 50,
	}
	local defaults = { walk = 16, jump = 50 }
	local conns = {}
	local noclipParts = {}
	local bodyGyro, bodyVel
	local keys = { W = false, A = false, S = false, D = false, Space = false, LeftControl = false }

	local function hum()
		return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	end
	local function root()
		return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	end

	local function cleanupMovers()
		if bodyGyro then
			bodyGyro:Destroy()
			bodyGyro = nil
		end
		if bodyVel then
			bodyVel:Destroy()
			bodyVel = nil
		end
	end

	local function ensureFly()
		local r = root()
		if not r then
			return
		end
		if not bodyGyro or bodyGyro.Parent ~= r then
			cleanupMovers()
			bodyGyro = Instance.new("BodyGyro")
			bodyGyro.P = 9e4
			bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			bodyGyro.Parent = r
			bodyVel = Instance.new("BodyVelocity")
			bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			bodyVel.Velocity = Vector3.zero
			bodyVel.Parent = r
		end
	end

	local function applyWalkJump()
		local h = hum()
		if not h then
			return
		end
		if settings.speedEnabled and settings.speedMethod == "WalkSpeed" and not settings.fly then
			h.WalkSpeed = settings.speed
		elseif not settings.speedEnabled or settings.speedMethod ~= "WalkSpeed" then
			if not settings.fly then
				h.WalkSpeed = defaults.walk
			end
		end
		h.UseJumpPower = true
		h.JumpPower = settings.jumpEnabled and settings.jumpPower or defaults.jump
	end

	local function setNoclip(on)
		local char = LocalPlayer.Character
		if not char then
			return
		end
		if on then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					noclipParts[p] = p.CanCollide
					p.CanCollide = false
				end
			end
		else
			for p, was in ipairs(noclipParts) do
				if p.Parent then
					p.CanCollide = was
				end
			end
			table.clear(noclipParts)
		end
	end

	local function flyStep(dt)
		local r = root()
		local h = hum()
		local cam = Workspace.CurrentCamera
		if not (r and h and cam) then
			return
		end
		ensureFly()
		h.PlatformStand = true
		bodyGyro.CFrame = cam.CFrame
		local dir = Vector3.zero
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		if keys.W then
			dir = dir + look
		end
		if keys.S then
			dir = dir - look
		end
		if keys.A then
			dir = dir - right
		end
		if keys.D then
			dir = dir + right
		end
		if keys.Space then
			dir = dir + Vector3.yAxis
		end
		if keys.LeftControl then
			dir = dir - Vector3.yAxis
		end
		if dir.Magnitude > 0 then
			dir = dir.Unit * settings.flySpeed
		end
		bodyVel.Velocity = dir
	end

	local function speedStep(dt)
		if settings.fly or not settings.speedEnabled then
			return
		end
		local r = root()
		local h = hum()
		local cam = Workspace.CurrentCamera
		if not (r and h and cam) then
			return
		end
		local method = settings.speedMethod
		if method == "WalkSpeed" then
			h.WalkSpeed = settings.speed
			return
		end
		local move = h.MoveDirection
		if move.Magnitude < 0.05 then
			return
		end
		if method == "CFrame" then
			r.CFrame = r.CFrame + move * settings.speed * dt
		elseif method == "Velocity" then
			local v = r.AssemblyLinearVelocity
			local horiz = move * settings.speed
			r.AssemblyLinearVelocity = Vector3.new(horiz.X, v.Y, horiz.Z)
		end
	end

	return {
		Set = function(_, patch)
			for k, v in pairs(patch) do
				settings[k] = v
			end
			if patch.noclip ~= nil then
				setNoclip(patch.noclip)
			end
			if patch.fly == false or (patch.fly == nil and settings.fly == false) then
				if patch.fly == false then
					cleanupMovers()
					local h = hum()
					if h then
						h.PlatformStand = false
					end
				end
			end
			if settings.fly then
				ensureFly()
			else
				cleanupMovers()
				local h = hum()
				if h then
					h.PlatformStand = false
				end
			end
			applyWalkJump()
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
				applyWalkJump()
			end
			table.insert(conns, LocalPlayer.CharacterAdded:Connect(function(char)
				table.clear(noclipParts)
				cleanupMovers()
				task.defer(function()
					local h = char:WaitForChild("Humanoid", 5)
					if h then
						defaults.walk = h.WalkSpeed
						defaults.jump = h.JumpPower
					end
					applyWalkJump()
					if settings.noclip then
						setNoclip(true)
					end
					if settings.fly then
						ensureFly()
					end
				end)
			end))
			table.insert(conns, RunService.Heartbeat:Connect(function(dt)
				applyWalkJump()
				speedStep(dt)
				if settings.fly then
					flyStep(dt)
				end
				if settings.noclip and LocalPlayer.Character then
					for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
						if p:IsA("BasePart") then
							p.CanCollide = false
						end
					end
				end
			end))
			table.insert(conns, UserInputService.JumpRequest:Connect(function()
				if not settings.infiniteJump or settings.fly then
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
			table.insert(conns, UserInputService.InputBegan:Connect(function(input, gp)
				if gp then
					return
				end
				local k = input.KeyCode
				if k == Enum.KeyCode.W then
					keys.W = true
				elseif k == Enum.KeyCode.A then
					keys.A = true
				elseif k == Enum.KeyCode.S then
					keys.S = true
				elseif k == Enum.KeyCode.D then
					keys.D = true
				elseif k == Enum.KeyCode.Space then
					keys.Space = true
				elseif k == Enum.KeyCode.LeftControl then
					keys.LeftControl = true
				end
			end))
			table.insert(conns, UserInputService.InputEnded:Connect(function(input)
				local k = input.KeyCode
				if k == Enum.KeyCode.W then
					keys.W = false
				elseif k == Enum.KeyCode.A then
					keys.A = false
				elseif k == Enum.KeyCode.S then
					keys.S = false
				elseif k == Enum.KeyCode.D then
					keys.D = false
				elseif k == Enum.KeyCode.Space then
					keys.Space = false
				elseif k == Enum.KeyCode.LeftControl then
					keys.LeftControl = false
				end
			end))
		end,
		Stop = function()
			for _, c in ipairs(conns) do
				c:Disconnect()
			end
			table.clear(conns)
			cleanupMovers()
			setNoclip(false)
			local h = hum()
			if h then
				h.PlatformStand = false
				h.WalkSpeed = defaults.walk
				h.JumpPower = defaults.jump
			end
		end,
	}
end

function Feature.Game()
	local function info()
		return {
			placeId = game.PlaceId,
			jobId = game.JobId,
			placeName = (function()
				local ok, data = pcall(function()
					return MarketplaceService:GetProductInfo(game.PlaceId)
				end)
				if ok and data then
					return data.Name
				end
				return tostring(game.PlaceId)
			end)(),
			players = #Players:GetPlayers(),
			maxPlayers = Players.MaxPlayers,
			displayName = LocalPlayer.DisplayName,
			userName = LocalPlayer.Name,
		}
	end

	return {
		Info = info,
		GetInfo = info,
		Rejoin = function()
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
		end,
		Hop = function()
			-- soft hop: rejoin same place (new server when possible)
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
		end,
		CopyJobId = function()
			local id = game.JobId
			local ok = pcall(function()
				if setclipboard then
					setclipboard(id)
				elseif toclipboard then
					toclipboard(id)
				end
			end)
			return ok, id
		end,
		CopyPlaceId = function()
			local id = tostring(game.PlaceId)
			local ok = pcall(function()
				if setclipboard then
					setclipboard(id)
				elseif toclipboard then
					toclipboard(id)
				end
			end)
			return ok, id
		end,
		TeleportToPlace = function(_, placeId)
			pcall(function()
				TeleportService:Teleport(tonumber(placeId) or game.PlaceId, LocalPlayer)
			end)
		end,
	}
end

Obsidian.Feature = Feature

function Obsidian.Reload(url)
	url = url or Obsidian.SourceUrl
	if not url or url == "" then
		warn("[Obsidian] Reload: no SourceUrl set")
		return false
	end
	-- bust CDN / GitHub raw cache
	local bust = tostring(math.floor(os.clock() * 1000))
	local fetchUrl = url
	if string.find(url, "?", 1, true) then
		fetchUrl = url .. "&_=" .. bust
	else
		fetchUrl = url .. "?_=" .. bust
	end

	local ok, src = pcall(function()
		return game:HttpGet(fetchUrl)
	end)
	if not ok or type(src) ~= "string" or #src < 8 then
		-- retry without query (some hosts dislike ?)
		ok, src = pcall(function()
			return game:HttpGet(url)
		end)
	end
	if not ok or type(src) ~= "string" or #src < 8 then
		warn("[Obsidian] Reload: HttpGet failed", src)
		return false
	end

	pcall(function()
		local parents = {}
		if gethui then
			table.insert(parents, gethui())
		end
		table.insert(parents, CoreGui)
		local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		if pg then
			table.insert(parents, pg)
		end
		for _, parent in ipairs(parents) do
			if parent then
				for _, child in ipairs(parent:GetChildren()) do
					local n = child.Name
					if n == "ObsidianUI" or n == "ObsidianESP" or string.sub(n, 1, 8) == "Obsidian" then
						child:Destroy()
					end
				end
			end
		end
	end)

	Obsidian.DisableTeleportReload()
	local fn, err = loadstring(src)
	if not fn then
		warn("[Obsidian] Reload: loadstring failed", err)
		return false
	end
	task.defer(function()
		local ran, runErr = pcall(fn)
		if not ran then
			warn("[Obsidian] Reload: script error", runErr)
		end
	end)
	return true
end

local function queueTeleportScript(url)
	url = tostring(url or "")
	if url == "" then
		return false
	end
	local code = string.format(
		[[
local url = %q
local genv = (getgenv and getgenv()) or _G
if genv.__ObsidianTeleportBooting then return end
genv.__ObsidianTeleportBooting = true
task.defer(function()
	local ok, err = pcall(function()
		local src = game:HttpGet(url)
		assert(type(src) == "string" and #src > 0, "HttpGet empty")
		local fn, cerr = loadstring(src)
		assert(fn, tostring(cerr))
		fn()
	end)
	if not ok then
		warn("[Obsidian] teleport reload failed:", err)
	end
	task.delay(2, function()
		genv.__ObsidianTeleportBooting = nil
	end)
end)
]],
		url
	)

	local queued = false
	local function try(fn)
		if typeof(fn) == "function" then
			local ok = pcall(fn, code)
			if ok then
				queued = true
				return true
			end
		end
		return false
	end

	-- probe common executor globals without erroring if missing
	pcall(function()
		try(queue_on_teleport)
	end)
	pcall(function()
		try(queueonteleport)
	end)
	pcall(function()
		try(queueteleport)
	end)
	pcall(function()
		if syn then
			try(syn.queue_on_teleport)
		end
	end)
	pcall(function()
		if fluxus then
			try(fluxus.queue_on_teleport)
		end
	end)
	pcall(function()
		if getgenv then
			local g = getgenv()
			try(g.queue_on_teleport)
			try(g.queueonteleport)
		end
	end)

	pcall(function()
		local genv = (getgenv and getgenv()) or _G
		genv.__ObsidianHubUrl = url
		genv.__ObsidianTeleportReload = true
	end)

	return queued
end

-- Auto-reload after server hop / teleport (not interval-based)
function Obsidian.EnableTeleportReload(url)
	url = url or Obsidian.SourceUrl
	if not url or url == "" then
		warn("[Obsidian] EnableTeleportReload: no SourceUrl")
		return false
	end
	Obsidian.SourceUrl = url
	Obsidian._teleportReload = true

	local ok = queueTeleportScript(url)
	if not ok then
		warn("[Obsidian] queue_on_teleport not found on this executor — server-hop reload unavailable")
	end

	-- re-queue right before teleport when possible
	if Obsidian._teleportConn then
		pcall(function()
			Obsidian._teleportConn:Disconnect()
		end)
		Obsidian._teleportConn = nil
	end
	pcall(function()
		Obsidian._teleportConn = TeleportService.LocalPlayerTeleporting:Connect(function()
			if Obsidian._teleportReload and Obsidian.SourceUrl then
				queueTeleportScript(Obsidian.SourceUrl)
			end
		end)
	end)

	-- some executors drop the queue — keep refreshing while enabled
	if Obsidian._teleportKeepalive then
		task.cancel(Obsidian._teleportKeepalive)
		Obsidian._teleportKeepalive = nil
	end
	Obsidian._teleportKeepalive = task.spawn(function()
		while Obsidian._teleportReload do
			queueTeleportScript(Obsidian.SourceUrl or url)
			task.wait(8)
		end
	end)

	return ok
end

function Obsidian.DisableTeleportReload()
	Obsidian._teleportReload = false
	pcall(function()
		local genv = (getgenv and getgenv()) or _G
		genv.__ObsidianTeleportReload = false
	end)
	if Obsidian._teleportConn then
		pcall(function()
			Obsidian._teleportConn:Disconnect()
		end)
		Obsidian._teleportConn = nil
	end
	if Obsidian._teleportKeepalive then
		task.cancel(Obsidian._teleportKeepalive)
		Obsidian._teleportKeepalive = nil
	end
end

-- Backwards-compatible aliases
function Obsidian.StartAutoReload(url)
	return Obsidian.EnableTeleportReload(url)
end

function Obsidian.StopAutoReload()
	Obsidian.DisableTeleportReload()
end

return Obsidian
