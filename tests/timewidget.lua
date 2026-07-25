local calls = {}
local twelve_hour_clock = false

package.preload["ffi/blitbuffer"] = function()
    return {}
end

package.preload["frontend/datetime"] = function()
    return {
        secondsToHour = function(seconds, use_twelve_hour_clock, pad_with_spaces)
            calls[#calls + 1] = {
                seconds = seconds,
                use_twelve_hour_clock = use_twelve_hour_clock,
                pad_with_spaces = pad_with_spaces,
            }
            if use_twelve_hour_clock then
                return "12:34 PM"
            end
            return "12:34"
        end,
    }
end

package.preload["device"] = function()
    return { screen = {} }
end

package.preload["ui/font"] = function()
    return {}
end

package.preload["ui/widget/container/framecontainer"] = function()
    return {}
end

package.preload["ui/geometry"] = function()
    return {}
end

package.preload["ui/gesturerange"] = function()
    return {}
end

package.preload["ui/widget/container/inputcontainer"] = function()
    return {
        extend = function(_, definition)
            return definition
        end,
    }
end

package.preload["ui/network/manager"] = function()
    return {}
end

package.preload["ui/widget/textboxwidget"] = function()
    return {}
end

package.preload["ui/uimanager"] = function()
    return {}
end

package.preload["ui/widget/verticalgroup"] = function()
    return {}
end

package.preload["ffi/util"] = function()
    return { template = function() end }
end

package.preload.gettext = function()
    return function(text)
        return text
    end
end

_G.G_reader_settings = {
    isTrue = function(_, setting_name)
        assert(setting_name == "twelve_hour_clock")
        return twelve_hour_clock
    end,
}

local DisplayWidget = require("displaywidget")

local function assert_equal(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local function assert_format(setting, expected_format, expected_text)
    twelve_hour_clock = setting
    calls = {}

    local text = DisplayWidget:getTimeText(45240)

    assert_equal(text, expected_text, "formatted time")
    assert_equal(#calls, 1, "formatter call count")
    assert_equal(calls[1].seconds, 45240, "formatter timestamp")
    assert_equal(calls[1].use_twelve_hour_clock, expected_format, "twelve-hour formatter argument")
    assert_equal(calls[1].pad_with_spaces, false, "formatter padding argument")
end

assert_format(false, false, "12:34")
assert_format(true, true, "12:34 PM")

print("displaywidget time-format regression tests passed")
