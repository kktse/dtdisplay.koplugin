local Blitbuffer = require("ffi/blitbuffer")
local Date = os.date
local Datetime = require("frontend/datetime")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require('ui/widget/container/framecontainer')
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local NetworkMgr = require("ui/network/manager")
local Screen = Device.screen
local TextBoxWidget = require("ui/widget/textboxwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")

local T = require("ffi/util").template
local _ = require("gettext")

local DisplayWidget = InputContainer:extend {
    on_dismiss = function()
    end,
}

function DisplayWidget:init()
    -- Properties
    self.datetime_vertical_group = nil
    self.autoRefresh = function()
        self:refresh()
        return UIManager:scheduleIn(60 - tonumber(Date("%S")), self.autoRefresh)
    end

    -- Events
    self.ges_events.TapClose = {
        GestureRange:new {
            ges = "tap",
            range = Geom:new {
                x = 0, y = 0,
                w = Screen:getWidth(),
                h = Screen:getHeight(),
            }
        }
    }

    -- Hints
    self.covers_fullscreen = true

    -- Render
    UIManager:setDirty("all", "flashpartial")
    self[1] = self:render()
end

function DisplayWidget:refresh()
    self[1] = self:render()
    UIManager:setDirty("all", "ui", self.datetime_vertical_group.dimen)
end

function DisplayWidget:onShow()
    return self:autoRefresh()
end

function DisplayWidget:onResume()
    UIManager:unschedule(self.autoRefresh)
end

function DisplayWidget:onSuspend()
    UIManager:unschedule(self.autoRefresh)
end

function DisplayWidget:onTapClose()
    self.on_dismiss()
    UIManager:unschedule(self.autoRefresh)
    UIManager:close(self)
end

DisplayWidget.onAnyKeyPressed = DisplayWidget.onTapClose

function DisplayWidget:getWifiStatusText()
    if NetworkMgr:isWifiOn() then
        return _("")
    else
        return _("")
    end
end

function DisplayWidget:getMemoryStatusText()
    -- Based on the implemenation in readerfooter.lua
    local statm = io.open("/proc/self/statm", "r")
    if statm then
        local dummy, rss = statm:read("*number", "*number")
        statm:close()
        -- we got the nb of 4Kb-pages used, that we convert to MiB
        rss = math.floor(rss * (4096 / 1024 / 1024))
        return T(_(" %1 MiB"), rss)
    end
end

function DisplayWidget:getBatteryStatusText()
    if Device:hasBattery() then
        local powerd = Device:getPowerDevice()
        local battery_level = powerd:getCapacity()
        local prefix = powerd:getBatterySymbol(
            powerd:isCharged(),
            powerd:isCharging(),
            battery_level
        )
        return T(_("%1 %2 %"), prefix, battery_level)
    end
end

function DisplayWidget:renderTimeWidget(now, width, font_face)
    return TextBoxWidget:new {
        text = Datetime.secondsToHour(now, true, false),
        face = font_face or Font:getFace("tfont", 119),
        width = width or Screen:getWidth(),
        alignment = "center",
        bold = true,
    }
end

function DisplayWidget:renderDateWidget(now, width, font_face, use_locale)
    return TextBoxWidget:new {
        text = Datetime.secondsToDate(now, use_locale),
        face = font_face or Font:getFace("infofont", 32),
        width = width or Screen:getWidth(),
        alignment = "center",
    }
end

function DisplayWidget:renderStatusWidget(width, font_face)
    local wifi_string = self:getWifiStatusText()
    local memory_string = self:getMemoryStatusText()
    local battery_string = self:getBatteryStatusText()

    local status_strings = { wifi_string, memory_string, battery_string }
    local status_text = table.concat(status_strings, " | ")

    return TextBoxWidget:new {
        text = status_text,
        face = font_face or Font:getFace("infofont"),
        width = width or Screen:getWidth(),
        alignment = "center",
    }
end

function DisplayWidget:render()
    local now = os.time()
    local screen_size = Screen:getSize()

    -- Insntiate widgets
    local time_widget = self:renderTimeWidget(
        now,
        screen_size.w,
        Font:getFace("tfont", 119)
    )
    local date_widget = self:renderDateWidget(
        now,
        screen_size.w,
        Font:getFace("largeffont"),
        true
    )
    local status_widget = self:renderStatusWidget(
        screen_size.w,
        Font:getFace("infofont")
    )

    -- Compute the widget heights and the amount of spacing we need
    local total_height = time_widget:getSize().h + date_widget:getSize().h
    local spacer_height = (screen_size.h - total_height) / 2

    -- HELP: is there a better way of drawing blank space?
    local spacer_widget = TextBoxWidget:new {
        text = nil,
        face = Font:getFace("cfont"),
        width = screen_size.w,
        height = spacer_height
    }

    -- Lay out and assemble
    self.datetime_vertical_group = VerticalGroup:new {
        date_widget,
        time_widget,
        status_widget,
    }
    local vertical_group = VerticalGroup:new {
        spacer_widget,
        self.datetime_vertical_group,
        spacer_widget,
    }

    return FrameContainer:new {
        geom = Geom:new { w = screen_size.w, screen_size.h },
        radius = 0,
        bordersize = 0,
        padding = 0,
        margin = 0,
        background = Blitbuffer.COLOUR_WHITE,
        color = Blitbuffer.COLOUR_WHITE,
        width = screen_size.w,
        height = screen_size.h,
        vertical_group
    }
end

return DisplayWidget
