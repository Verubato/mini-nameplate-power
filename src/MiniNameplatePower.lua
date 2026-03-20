local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
local LCG = LibStub("LibCustomGlow-1.0")
local eventFrame
local runicPowerBar
local runicPowerText
local runicPowerMarker
local stepCurve
local colorCurve
---@type Db
local db

local function IsDeathKnight()
	local _, classTag = UnitClass("player")
	return classTag == "DEATHKNIGHT"
end

local function AddBlackOutline(frame)
	local outline = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	outline:SetPoint("TOPLEFT", frame, 0, 0)
	outline:SetPoint("BOTTOMRIGHT", frame, 0, 0)

	outline:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})

	outline:SetBackdropBorderColor(0, 0, 0, 1)
end

local function CreateRunicPowerBar()
	local bar = CreateFrame("StatusBar", nil, UIParent)
	bar:SetFrameStrata("MEDIUM")
	bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	bar:SetMinMaxValues(0, 100)
	bar:SetValue(0)
	bar:SetStatusBarColor(0.0, 0.75, 1.0, 1.0)

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture("Interface\\Buttons\\WHITE8X8")
	bg:SetVertexColor(0, 0, 0, 0.35)

	local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER", bar, "CENTER", 0, 0)
	text:SetText("0")

	local marker = bar:CreateTexture(nil, "OVERLAY")
	marker:SetTexture("Interface\\Buttons\\WHITE8X8")
	marker:SetVertexColor(1, 1, 1, 0.8)
	marker:SetWidth(1)

	local currentMax = 100

	bar.SetCurrentMax = function(max)
		currentMax = max
	end

	bar:SetScript("OnSizeChanged", function(self, width)
		if currentMax > 0 and width > 0 then
			marker:ClearAllPoints()
			marker:SetPoint("TOP", bar, "TOPLEFT", width * (30 / currentMax), 0)
			marker:SetPoint("BOTTOM", bar, "BOTTOMLEFT", width * (30 / currentMax), 0)
		end
	end)

	AddBlackOutline(bar)

	bar:Hide()

	return bar, text, marker
end

local function GetRunicPower()
	local powerType = Enum.PowerType.RunicPower
	local cur = UnitPower("player", powerType)
	local max = UnitPowerMax("player", powerType)
	if not max or max <= 0 then
		max = 100
	end
	return cur or 0, max
end

local function UpdateMarker(max)
	runicPowerBar.SetCurrentMax(max)
	local width = runicPowerBar:GetWidth()
	if width > 0 and max > 0 then
		runicPowerMarker:ClearAllPoints()
		runicPowerMarker:SetPoint("TOP", runicPowerBar, "TOPLEFT", width * (30 / max), 0)
		runicPowerMarker:SetPoint("BOTTOM", runicPowerBar, "BOTTOMLEFT", width * (30 / max), 0)
	end
end

local function UpdateGlow()
	LCG.ProcGlow_Start(runicPowerBar, { startAnim = false })
	local alpha = UnitPowerPercent("player", Enum.PowerType.RunicPower, false, stepCurve)
	runicPowerBar._ProcGlow:SetAlpha(alpha)
end

local function UpdateBar()
	local cur, max = GetRunicPower()
	runicPowerBar:SetMinMaxValues(0, max)
	runicPowerBar:SetValue(cur)
	UpdateMarker(max)

	local color = UnitPowerPercent("player", Enum.PowerType.RunicPower, false, colorCurve)
	runicPowerBar:GetStatusBarTexture():SetVertexColor(color:GetRGB())

	if db.ShowText then
		runicPowerText:Show()
		runicPowerText:SetText(cur)
	else
		runicPowerText:Hide()
	end
end

local function UpdateNameplateAnchor()
	local nameplate = C_NamePlate.GetNamePlateForUnit("target")
	if nameplate and UnitCanAttack("player", "target") then
		runicPowerBar:ClearAllPoints()
		runicPowerBar:SetPoint("TOP", nameplate, "BOTTOM", db.OffsetX, db.OffsetY)
		runicPowerBar:SetSize(db.RunicPowerWidth, db.RunicPowerHeight)
		runicPowerBar:Show()
	else
		runicPowerBar:Hide()
	end
end

local function OnEvent(_, event, unit)
	if event == "UNIT_POWER_UPDATE" or event == "UNIT_DISPLAYPOWER" then
		if unit == "player" then
			UpdateBar()
			UpdateGlow()
		end
		return
	end

	if event == "PLAYER_TARGET_CHANGED" then
		UpdateNameplateAnchor()
		UpdateGlow()
		return
	end

	if event == "NAME_PLATE_UNIT_ADDED" then
		if UnitIsUnit(unit, "target") then
			UpdateNameplateAnchor()
			UpdateGlow()
		end
		return
	end

	if event == "NAME_PLATE_UNIT_REMOVED" then
		if UnitIsUnit(unit, "target") then
			runicPowerBar:Hide()
		end
		return
	end

	-- PLAYER_ENTERING_WORLD
	UpdateBar()
	UpdateNameplateAnchor()
	UpdateGlow()
end

local function Init()
	if not IsDeathKnight() then
		return
	end

	addon.Config:Init()
	db = mini:GetSavedVars()

	stepCurve = C_CurveUtil.CreateCurve()
	stepCurve:AddPoint(0, 0)
	stepCurve:AddPoint(1, 1)
	stepCurve:SetType(Enum.LuaCurveType.Step)

	colorCurve = C_CurveUtil.CreateColorCurve()
	colorCurve:AddPoint(0, CreateColor(0.0, 0.75, 1.0, 1.0))
	colorCurve:AddPoint(1, CreateColor(1.0, 0.0, 0.0, 1.0))
	colorCurve:SetType(Enum.LuaCurveType.Step)

	runicPowerBar, runicPowerText, runicPowerMarker = CreateRunicPowerBar()

	UpdateBar()
	UpdateNameplateAnchor()
	UpdateGlow()

	eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
	eventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
	eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	eventFrame:SetScript("OnEvent", OnEvent)
end

function addon:Refresh()
	UpdateBar()
	UpdateNameplateAnchor()
	UpdateGlow()
end

mini:WaitForAddonLoad(Init)
