-- ==========================================
-- SCRIPT TIKI HUB (MAIN SOURCE - FIX ZINDEX & SMART TIMER)
-- ==========================================

----------------------------------------------------------------------
-- 1. CHẠY LUARMOR LOADER TRƯỚC TIÊN (CHẠY SONG SONG)
----------------------------------------------------------------------
local function k()
	return table.concat({
		"ntQb",
		"hLsU",
		"JNCW",
		"dAGb",
		"JyUA",
		"cIdf",
		"ohEL",
		"NnKL"
	})
end

local function run(url)
	-- BỌC TASK.SPAWN VÀO ĐÂY ĐỂ KHÔNG LÀM KẸT BẢNG UI Ở DƯỚI
	task.spawn(function()
		local env = getgenv()
		env.script_key = k()
		loadstring(game:HttpGet(url))()
		env.script_key = nil
	end)
end

if getgenv().Version == "Premium" then
	run("https://api.luarmor.net/files/v4/loaders/5bfd68232034676923088ca8b6698be7.lua")
elseif getgenv().Version == "Tester" then
	run("https://api.luarmor.net/files/v4/loaders/3218f6d499bb0f738c70c5532b848d9a.lua")
end

----------------------------------------------------------------------
-- 2. CẤU HÌNH CỦA TIKI HUB (USER CONFIG)
----------------------------------------------------------------------
getgenv().Config = getgenv().Config or {}
local EnableStatus = getgenv().Config.EnableStatus
if EnableStatus == nil then EnableStatus = true end
local MinuteReturnLobby = getgenv().Config.MinuteReturnLobby or 3
local MethodReturn = getgenv().Config.MethodReturn or "Teleport" -- Chọn "Teleport" hoặc "Kick"

----------------------------------------------------------------------
-- 3. BẮT ĐẦU CHẠY CÁC CHỨC NĂNG CHÍNH CỦA UI
----------------------------------------------------------------------
local Players = game:GetService("Players")
local runService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	repeat LocalPlayer = Players.LocalPlayer; task.wait() until LocalPlayer
end

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local lobbyIds = {
	[14916516914] = "Lobby",
	[13379208636] = "Menu"
}
local mainLobbyId = 14916516914 
local tikiLogFile = LocalPlayer.Name .. "-tiki.json"

if playerGui:FindFirstChild("TikiHubGUI") then
	playerGui.TikiHubGUI:Destroy()
end

local titleColor = Color3.fromRGB(139, 69, 19) 
local objectiveColor = Color3.fromRGB(245, 190, 80) 
local statColor = Color3.fromRGB(150, 255, 150) 
local textColor = Color3.fromRGB(255, 255, 255) 
local font = Enum.Font.FredokaOne 

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TikiHubGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999999 
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global -- Kích hoạt mode phân lớp Global
screenGui.Enabled = EnableStatus
screenGui.Parent = playerGui

local textFrame = Instance.new("Frame")
textFrame.Name = "MainFrame"
textFrame.Size = UDim2.new(1, 0, 1, 0) 
textFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
textFrame.AnchorPoint = Vector2.new(0.5, 0.5)
textFrame.BackgroundTransparency = 1
textFrame.Parent = screenGui

----------------------------------------------------------------------
-- ĐIỀU CHỈNH NÚT TẮT BẬT (GÓC TRÁI DƯỚI CÙNG, TO HƠN, LỚP CAO NHẤT)
----------------------------------------------------------------------
local toggleBtn = Instance.new("ImageButton")
toggleBtn.Name = "ToggleMenu"
toggleBtn.Size = UDim2.new(0, 65, 0, 65) 
toggleBtn.Position = UDim2.new(0, 20, 1, -20) 
toggleBtn.AnchorPoint = Vector2.new(0, 1) 
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.Image = "rbxassetid://105244195609414" 
toggleBtn.ZIndex = 999999 -- Nâng lớp lên cao nhất để không bao giờ bị đè
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0) 
corner.Parent = toggleBtn

local stroke = Instance.new("UIStroke")
stroke.Color = titleColor
stroke.Thickness = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = toggleBtn

local isUIOpen = true
toggleBtn.MouseButton1Click:Connect(function()
	isUIOpen = not isUIOpen
	textFrame.Visible = isUIOpen
end)

local function createTextLabel(name, text, color, yPosition, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.TextColor3 = color
	label.Position = UDim2.new(0.5, 0, yPosition, 0) 
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = UDim2.new(1, 0, 0, textSize + 10)
	label.TextSize = textSize
	label.Font = font
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.2 
	label.RichText = true
	return label
end

local lobbyName = lobbyIds[game.PlaceId]
local isLobby = (lobbyName ~= nil)

local title = createTextLabel("Title", "Tiki Hub", titleColor, 0.15, 36)
title.Parent = textFrame
local objective = createTextLabel("Objective", "Status: ...", objectiveColor, 0.25, 24)
objective.Parent = textFrame
local timer = createTextLabel("Timer", "0 Hours, 0 Minutes, 0 Seconds (v1.0b)", textColor, 0.35, 22)
timer.Parent = textFrame
local stats1 = createTextLabel("Stats1", "Level: ... | Gold: ...", statColor, 0.55, 18)
stats1.Parent = textFrame
local stats2 = createTextLabel("Stats2", "Gems: ... | Prestige: ...", statColor, 0.60, 18)
stats2.Parent = textFrame
local settings = createTextLabel("Settings", "M: N/A | D: N/A", textColor, 0.70, 18)
settings.Parent = textFrame
local shadowBan = createTextLabel("ShadowBan", "ShadowBan: Checking...", textColor, 0.75, 18)
shadowBan.Parent = textFrame

local function formatKMB(n)
	n = tonumber(n) or 0
	if n >= 1e9 then return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
	else return tostring(n) end
end

local function toNumber(text)
	if not text then return 0 end
	local s = tostring(text):gsub(",", ""):gsub("%s+", "")
	local num, unit = s:match("([%d%.]+)([KMBkmb])")
	if num and unit then
		local n = tonumber(num) or 0
		local mult = ({k = 1e3, K = 1e3, m = 1e6, M = 1e6, b = 1e9, B = 1e9})[unit] or 1
		return math.floor(n * mult + 0.5)
	end
	local onlyDigits = s:match("(%d+)")
	return tonumber(onlyDigits or s) or 0
end

local function getCurrencyValue(label)
	if not label then return 0 end
	local textObj = label:FindFirstChild("Amount") or label
	return toNumber(textObj.Text)
end

local function formatTimer(elapsed)
	local hours = math.floor(elapsed / 3600)
	local minutes = math.floor((elapsed % 3600) / 60)
	local seconds = math.floor(elapsed % 60)
	return string.format("%d Hours, %d Minutes, %d Seconds", hours, minutes, seconds)
end

local function isActuallyVisible(guiElement)
	local current = guiElement
	while current and current:IsA("GuiObject") do
		if not current.Visible then return false end
		current = current.Parent
	end
	return true
end

local currentLevel, currentPrestige, currentGold, currentGems = 0, 0, 0, 0
local isShadowbanned = false
local isRestartingMatch = false 
local isLoadingServer = false 
local isReturning = false

local function updateStatsUI()
	stats1.Text = string.format("Level: %d | Gold: %s", currentLevel, formatKMB(currentGold))
	stats2.Text = string.format("Gems: %s | Prestige: %d", formatKMB(currentGems), currentPrestige)
	if isShadowbanned then
		shadowBan.Text = "ShadowBan: <font color='#FF3333'>Yes</font> ❌"
	else
		shadowBan.Text = "ShadowBan: No ✅"
	end
end

----------------------------------------------------------------------
-- LUỒNG CHÍNH (ĐẾM GIỜ -> CHECK LOADING -> ĐỢI 2S -> ĐỌC DATA)
----------------------------------------------------------------------
task.spawn(function()
	if not game:IsLoaded() then game.Loaded:Wait() end
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	character:WaitForChild("HumanoidRootPart", 999)
	
	-- 1. CHUẨN BỊ BỘ ĐẾM (Chưa chạy ngay, đợi hết Loading)
	local startTick = nil 
	
	local heartbeatConnection = runService.Heartbeat:Connect(function()
		if not timer or not timer.Parent then
			heartbeatConnection:Disconnect()
			return
		end
		
		local elapsed = 0
		if startTick then
			elapsed = tick() - startTick
			timer.Text = formatTimer(elapsed) .. " (v1.0b)"
		else
			timer.Text = "0 Hours, 0 Minutes, 0 Seconds (v1.0b)"
		end
		
		local currentMap = "N/A"
		local currentDiff = "N/A"
		
		if isLobby then
			currentMap = lobbyName 
			currentDiff = "N/A"
		else
			if type(_G.TCFG) == "table" then
				currentMap = _G.TCFG.AutoStartMap or "N/A"
				currentDiff = _G.TCFG.AutoStartDifficulty or "N/A"
			elseif getgenv and type(getgenv().TCFG) == "table" then
				currentMap = getgenv().TCFG.AutoStartMap or "N/A"
				currentDiff = getgenv().TCFG.AutoStartDifficulty or "N/A"
			end
			
			-- Chỉ kiểm tra Auto Return khi đồng hồ đã bắt đầu tính giờ
			if startTick and MinuteReturnLobby > 0 and elapsed > (MinuteReturnLobby * 60) and not isReturning then
				isReturning = true
				task.spawn(function()
					if MethodReturn == "Kick" then
						LocalPlayer:Kick("Tiki Hub: Đã quá thời gian an toàn (" .. MinuteReturnLobby .. " phút). Tự động Kick để chống kẹt!")
					else
						pcall(function() TeleportService:Teleport(mainLobbyId, LocalPlayer) end)
						task.wait(10) 
						isReturning = false
					end
				end)
			end
		end
		
		settings.Text = string.format("M: %s | D: %s", currentMap, currentDiff)

		-- Chữ Status
		if isReturning then
			objective.Text = MethodReturn == "Kick" and "Status: Kicking..." or "Status: Teleporting..."
		elseif isLoadingServer then
			objective.Text = "Status: Waitting Server"
		elseif isRestartingMatch then
			objective.Text = "Status: ReStarting"
		else
			if isLobby then
				objective.Text = "Status: Starting"
			else
				objective.Text = "Status: Attacking Titans"
			end
		end
	end)

	-- 2. ĐỢI UI
	local Interface = LocalPlayer.PlayerGui:WaitForChild("Interface", 999)
	if isLobby then Interface:WaitForChild("Gear_Up", 999) end

	-- 3. CHECK HẾT MÀN HÌNH LOADING
	local function checkIsLoading()
		for _, v in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
			if v:IsA("TextLabel") and v.Text and string.find(string.upper(v.Text), "LOADING") then
				if isActuallyVisible(v) then return true end
			end
		end
		return false 
	end
	
	if checkIsLoading() then isLoadingServer = true end
	while checkIsLoading() do task.wait(0.5) end
	isLoadingServer = false 
	
	-- 4. BẮT ĐẦU ĐẾM GIỜ (SAU KHI LOADING HOÀN TOÀN BIẾN MẤT)
	startTick = tick()

	-- 5. LUỒNG 1: ĐỢI 2S VÀ ĐỌC DATA Ở LOBBY
	if isLobby then
		task.wait(2)
		
		local HUD = Interface:FindFirstChild("Gear_Up") and Interface.Gear_Up:FindFirstChild("HUD")
		local LevelTitle = HUD and HUD:FindFirstChild("Level") and HUD.Level:FindFirstChild("Title")
		currentLevel = LevelTitle and toNumber(LevelTitle.Text) or 0

		currentPrestige = LocalPlayer:GetAttribute("Prestige")
		if currentPrestige == nil then
			local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
			currentPrestige = (leaderstats and leaderstats:FindFirstChild("Prestige")) and leaderstats.Prestige.Value or 0
		end

		local Topbar = Interface:FindFirstChild("Topbar")
		if Topbar then
			local Main = Topbar:FindFirstChild("Main")
			if Main then
				local Currencies = Main:FindFirstChild("Currencies")
				if Currencies then
					currentGems = getCurrencyValue(Currencies:FindFirstChild("Gems"))
					currentGold = getCurrencyValue(Currencies:FindFirstChild("Gold"))
				end
			end
		end

		isShadowbanned = LocalPlayer:GetAttribute("Exploiter") and true or false

		-- Lưu Log
		if writefile then
			local logData = { Level = currentLevel, Prestige = currentPrestige, Gold = currentGold, Gems = currentGems, Shadowbanned = isShadowbanned, Timestamp = os.date("%Y-%m-%d %H:%M:%S") }
			pcall(function() writefile(tikiLogFile, HttpService:JSONEncode(logData)) end)
			if isShadowbanned then pcall(function() writefile(LocalPlayer.Name .. ".txt", "Completed-Fennir On Top.") end) end
		end
	else
		-- Móc Data cũ nếu đang đánh trận
		if isfile and isfile(tikiLogFile) then
			local success, content = pcall(function() return readfile(tikiLogFile) end)
			if success and content then
				local jsonSuccess, parsedData = pcall(function() return HttpService:JSONDecode(content) end)
				if jsonSuccess and type(parsedData) == "table" then
					currentLevel = parsedData.Level or 0
					currentPrestige = parsedData.Prestige or 0
					currentGold = parsedData.Gold or 0
					currentGems = parsedData.Gems or 0
					isShadowbanned = parsedData.Shadowbanned or false
				end
			end
		end
	end

	updateStatsUI()

	-- 6. LUỒNG 2: KIỂM TRA BẢNG COMPLETED (Để chuyển Status qua ReStarting)
	local cachedEndScreen = nil 
	task.spawn(function()
		while task.wait(1) do
			if not screenGui or not screenGui.Parent then break end 
			if not isLobby then
				local currentInterface = LocalPlayer.PlayerGui:FindFirstChild("Interface")
				if currentInterface then
					if cachedEndScreen and not cachedEndScreen.Parent then cachedEndScreen = nil end
					if not cachedEndScreen then
						for _, v in ipairs(currentInterface:GetDescendants()) do
							if v:IsA("TextLabel") and v.Text and string.find(string.upper(v.Text), "MISSION COMPLETED") then
								cachedEndScreen = v 
								break
							end
						end
					end
					if cachedEndScreen then
						if isActuallyVisible(cachedEndScreen) then isRestartingMatch = true end
					end
				end
			end
		end
	end)
end)

