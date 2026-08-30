-- Drives the runic power bar through the mocked client's event and unit APIs. The bar and its
-- marker texture are file-local, so every case here finds them back through WowMock.Frames the
-- way tests/Helpers/Arena.lua finds its gated frame in MiniDampen.

local fw = require("TestFramework")
local harness = require("AddonHarness")
local WowMock = require("WowMock")

local function Load()
	return harness.Run("MiniNameplatePower", { class = "DEATHKNIGHT" })
end

---The runic power bar is the only StatusBar the addon parents straight to UIParent.
local function FindBar()
	for _, frame in ipairs(WowMock.Frames) do
		if frame.__objectType == "StatusBar" and frame.__parent == _G.UIParent then
			return frame
		end
	end
end

---The marker is the only OVERLAY-layer texture CreateRunicPowerBar registers on the bar; the
---status bar texture and the background sit on ARTWORK and BACKGROUND respectively.
local function FindMarker(bar)
	for _, region in ipairs(bar.__regions) do
		if region.__objectType == "Texture" and region.__layer == "OVERLAY" then
			return region
		end
	end
end

local function ShowBar()
	local bar = FindBar()
	local nameplate = WowMock.NewFrame("Frame")

	_G.C_NamePlate.GetNamePlateForUnit = function()
		return nameplate
	end
	_G.UnitCanAttack = function()
		return true
	end

	WowMock.FireEvent("PLAYER_TARGET_CHANGED")

	return bar
end

fw.describe("MiniNameplatePower - GetRunicPower", function()
	local bar

	fw.before_each(function()
		Load()
		bar = ShowBar()
	end)

	fw.it("reads current power and max straight through", function()
		_G.UnitPower = function()
			return 42
		end
		_G.UnitPowerMax = function()
			return 100
		end

		WowMock.FireEvent("UNIT_DISPLAYPOWER", "player")

		local min, max = bar:GetMinMaxValues()

		fw.eq(min, 0, "min stays 0")
		fw.eq(max, 100, "max read straight through")
		fw.eq(bar:GetValue(), 42, "current power read straight through")
	end)

	fw.it("defaults max to 100 when the API answers nil", function()
		_G.UnitPower = function()
			return 10
		end
		_G.UnitPowerMax = function()
			return nil
		end

		WowMock.FireEvent("UNIT_DISPLAYPOWER", "player")

		local _, max = bar:GetMinMaxValues()

		fw.eq(max, 100, "nil max defaults to 100")
	end)

	fw.it("defaults max to 100 when the API answers 0", function()
		_G.UnitPower = function()
			return 10
		end
		_G.UnitPowerMax = function()
			return 0
		end

		WowMock.FireEvent("UNIT_DISPLAYPOWER", "player")

		local _, max = bar:GetMinMaxValues()

		fw.eq(max, 100, "a zero max defaults to 100 too")
	end)

	fw.it("treats a nil current power as 0", function()
		_G.UnitPower = function()
			return nil
		end
		_G.UnitPowerMax = function()
			return 100
		end

		WowMock.FireEvent("UNIT_DISPLAYPOWER", "player")

		fw.eq(bar:GetValue(), 0, "nil power reads as 0")
	end)
end)

fw.describe("MiniNameplatePower - marker placement", function()
	fw.before_each(function()
		Load()
	end)

	fw.it("places the marker at width * (30 / max)", function()
		local bar = ShowBar()
		local marker = FindMarker(bar)

		_G.UnitPower = function()
			return 50
		end
		_G.UnitPowerMax = function()
			return 60
		end

		WowMock.FireEvent("UNIT_DISPLAYPOWER", "player")

		local _, _, _, offsetX = marker:GetPoint(1)

		fw.eq(offsetX, bar:GetWidth() * (30 / 60), "marker offset matches width * (30 / max)")
	end)

	-- The mock's GetWidth never reports 0, so it is overridden here to reach the guard.
	fw.it("does not error and leaves the marker where it was when the bar reports zero width", function()
		local bar = ShowBar()
		local marker = FindMarker(bar)
		local _, _, _, offsetXBefore = marker:GetPoint(1)

		bar.GetWidth = function()
			return 0
		end

		fw.no_error(function()
			_G.UnitPower = function()
				return 50
			end
			_G.UnitPowerMax = function()
				return 60
			end

			WowMock.FireEvent("UNIT_DISPLAYPOWER", "player")
		end, "a bar reporting zero width")

		local _, _, _, offsetXAfter = marker:GetPoint(1)

		fw.eq(offsetXAfter, offsetXBefore, "the guard skipped repositioning rather than dividing by a zero width")
	end)
end)

fw.describe("MiniNameplatePower - event routing", function()
	local bar

	fw.before_each(function()
		Load()
		bar = ShowBar()

		_G.UnitPower = function()
			return 77
		end
		_G.UnitPowerMax = function()
			return 100
		end
	end)

	fw.it("ignores UNIT_POWER_UPDATE for a power type that is not runic power", function()
		local before = bar:GetValue()

		WowMock.FireEvent("UNIT_POWER_UPDATE", "player", "MANA")

		fw.eq(bar:GetValue(), before, "the bar did not redraw for a foreign power type")
	end)

	fw.it("redraws on UNIT_POWER_UPDATE when the power type is runic power", function()
		WowMock.FireEvent("UNIT_POWER_UPDATE", "player", "RUNIC_POWER")

		fw.eq(bar:GetValue(), 77, "redrew for its own power type")
	end)

	fw.it("always redraws on UNIT_DISPLAYPOWER, which carries no power type", function()
		WowMock.FireEvent("UNIT_DISPLAYPOWER", "player")

		fw.eq(bar:GetValue(), 77, "redrew unconditionally")
	end)
end)

fw.describe("MiniNameplatePower - bar visibility", function()
	local bar
	local nameplate

	fw.before_each(function()
		Load()
		bar = FindBar()
		nameplate = WowMock.NewFrame("Frame")

		_G.C_NamePlate.GetNamePlateForUnit = function()
			return nameplate
		end
	end)

	fw.it("shows the bar when the player can attack the target", function()
		_G.UnitCanAttack = function()
			return true
		end

		WowMock.FireEvent("PLAYER_TARGET_CHANGED")

		fw.truthy(bar:IsShown(), "bar shown against an attackable target")
	end)

	fw.it("hides the bar when the player cannot attack the target", function()
		_G.UnitCanAttack = function()
			return true
		end

		WowMock.FireEvent("PLAYER_TARGET_CHANGED")

		fw.truthy(bar:IsShown(), "shown first")

		_G.UnitCanAttack = function()
			return false
		end

		WowMock.FireEvent("PLAYER_TARGET_CHANGED")

		fw.falsy(bar:IsShown(), "hidden once the target can't be attacked")
	end)
end)

fw.describe("MiniNameplatePower - non-death-knight login", function()
	-- MiniFramework's own AddonLoad and Combat listener frames exist regardless of class, so the
	-- gate is checked on what the addon itself would only add once IsDeathKnight passes: its
	-- slash command, not the framework's frame count.
	fw.it("registers no slash command for another class", function()
		local context = harness.Run("MiniNameplatePower", { class = "WARRIOR" })

		local activity = context.LoginResult.Activity

		fw.eq(activity.SlashCommands, 0, "IsDeathKnight gated the config panel, so no slash command")
	end)

	fw.it("creates no runic power bar for another class", function()
		harness.Run("MiniNameplatePower", { class = "WARRIOR" })

		fw.is_nil(FindBar(), "no StatusBar created against UIParent")
	end)
end)
