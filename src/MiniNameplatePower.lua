local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
local eventFrame
local runicPowerBar
local runicPowerText
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

	AddBlackOutline(bar)

	bar:Hide()

	return bar, text
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

local function UpdateBar()
	local cur, max = GetRunicPower()
	runicPowerBar:SetMinMaxValues(0, max)
	runicPowerBar:SetValue(cur)

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
		end
		return
	end

	if event == "PLAYER_TARGET_CHANGED" then
		UpdateNameplateAnchor()
		return
	end

	if event == "NAME_PLATE_UNIT_ADDED" then
		if UnitIsUnit(unit, "target") then
			UpdateNameplateAnchor()
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
end

local function Init()
	if not IsDeathKnight() then
		return
	end

	addon.Config:Init()
	db = mini:GetSavedVars()

	runicPowerBar, runicPowerText = CreateRunicPowerBar()

	UpdateBar()
	UpdateNameplateAnchor()

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
end

mini:WaitForAddonLoad(Init)
