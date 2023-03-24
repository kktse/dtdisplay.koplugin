local DisplayWidget = require("displaywidget")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local DtDisplay = WidgetContainer:extend {
    name = "dtdisplay",
    is_doc_only = false,
}

function DtDisplay:init()
    self.ui.menu:registerToMainMenu(self)
end

function DtDisplay:addToMainMenu(menu_items)
    menu_items.dtdisplay = {
        text = _("Time & Day"),
        sorting_hint = "more_tools",
        callback = function()
            UIManager:show(DisplayWidget:new {})
        end,
    }
end

return DtDisplay
