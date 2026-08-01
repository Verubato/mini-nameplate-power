local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
---@type Db
local db
---@class Db
local dbDefaults = {
	Version = 3,
	ShowText = true,
	-- runic power bar config
	RunicPowerWidth = 120,
	RunicPowerHeight = 12,
	OffsetX = 0,
	OffsetY = 0,
}
local M = {
	DbDefaults = dbDefaults,
}

addon.Config = M

function M:Init()
	db = mini:GetSavedVars(dbDefaults)

	local panel = CreateFrame("Frame")
	panel.name = addonName

	local category = mini:AddCategory(panel)

	if not category then
		return
	end

	local verticalSpacing = mini.VerticalSpacing
	local horizontalSpacing = mini.HorizontalSpacing
	local columns = 4
	local columnWidth = mini:ColumnWidth(columns, 0, 0)

	local header = mini:PanelHeader({
		Parent = panel,
		Description = "Runic power tracker on target nameplate.",
		Gap = 6,
	})

	mini:RegisterSlashCommand(category, panel, {
		"/mininameplatepower",
		"/minnp",
		"/mnp",
	})

	local showText = mini:Checkbox({
		Parent = panel,
		LabelText = "Show text",
		GetValue = function()
			return db.ShowText
		end,
		SetValue = function(value)
			db.ShowText = value
			addon:Refresh()
		end,
	})

	showText:SetPoint("TOPLEFT", header.Anchor, "BOTTOMLEFT", 0, -verticalSpacing)

	local sliderWidth = (columns / 2 * columnWidth) - horizontalSpacing
	local rpWidthSlider = mini:Slider({
		Parent = panel,
		LabelText = "Power Width",
		Min = 50,
		Max = 800,
		Step = 10,
		Width = sliderWidth,
		GetValue = function()
			return db.RunicPowerWidth
		end,
		SetValue = function(value)
			db.RunicPowerWidth = mini:ClampInt(value, 50, 800, dbDefaults.RunicPowerWidth)
			addon:Refresh()
		end,
	})

	rpWidthSlider.Slider:SetPoint("TOPLEFT", showText, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local rpHeightSlider = mini:Slider({
		Parent = panel,
		LabelText = "Power Height",
		Min = 10,
		Max = 100,
		Step = 1,
		Width = sliderWidth,
		GetValue = function()
			return db.RunicPowerHeight
		end,
		SetValue = function(value)
			db.RunicPowerHeight = mini:ClampInt(value, 10, 100, dbDefaults.RunicPowerHeight)
			addon:Refresh()
		end,
	})

	rpHeightSlider.Slider:SetPoint("LEFT", rpWidthSlider.Slider, "RIGHT", horizontalSpacing, 0)

	local offsetXSlider = mini:Slider({
		Parent = panel,
		LabelText = "Offset X",
		Min = -400,
		Max = 400,
		Step = 1,
		Width = sliderWidth,
		GetValue = function()
			return db.OffsetX
		end,
		SetValue = function(value)
			db.OffsetX = mini:ClampInt(value, -400, 400, dbDefaults.OffsetX)
			addon:Refresh()
		end,
	})

	offsetXSlider.Slider:SetPoint("TOPLEFT", rpWidthSlider.Slider, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local offsetYSlider = mini:Slider({
		Parent = panel,
		LabelText = "Offset Y",
		Min = -400,
		Max = 400,
		Step = 1,
		Width = sliderWidth,
		GetValue = function()
			return db.OffsetY
		end,
		SetValue = function(value)
			db.OffsetY = mini:ClampInt(value, -400, 400, dbDefaults.OffsetY)
			addon:Refresh()
		end,
	})

	offsetYSlider.Slider:SetPoint("LEFT", offsetXSlider.Slider, "RIGHT", horizontalSpacing, 0)
end
