local DisplayWidget = require("displaywidget")
local Font = require("ui/font")
local FontList = require("fontlist")
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
        sub_item_table = {
            {
                text = _("Launch"),
                separator = true,
                callback = function()
                    UIManager:show(DisplayWidget:new {})
                end,
            },
            {
                text = _("Date widget font"),
                sub_item_table = self:getFontMenuList(),
            },
            {
                text = _("Time widget font"),
                sub_item_table = self:getFontMenuList(),
            },
            {
                text = _("Status line font"),
                sub_item_table = self:getFontMenuList(),
            }
        },
    }
end

function DtDisplay:getFontMenuList()
    -- Based on readerfont.lua
    cre = require("document/credocument"):engineInit()
    local face_list = cre.getFontFaces()
    local menu_list = {}
    for k, v in ipairs(face_list) do
        local font_filename, font_faceindex, is_monospace = cre.getFontFaceFilenameAndFaceIndex(v)
        table.insert(menu_list, {
            text_func = function()
                -- defaults are hardcoded in credocument.lua
                local default_font = G_reader_settings:readSetting("cre_font")
                local fallback_font = G_reader_settings:readSetting("fallback_font")
                local monospace_font = G_reader_settings:readSetting("monospace_font")
                local text = v
                if font_filename and font_faceindex then
                    text = FontList:getLocalizedFontName(font_filename, font_faceindex) or text
                end

                if v == monospace_font then
                    text = text .. " \u{1F13C}" -- Squared Latin Capital Letter M
                elseif is_monospace then
                    text = text .. " \u{1D39}"  -- Modified Letter Capital M
                end
                if v == default_font then
                    text = text .. "   ★"
                end
                if v == fallback_font then
                    text = text .. "   �"
                end
                return text
            end,
            font_func = function(size)
                if G_reader_settings:nilOrTrue("font_menu_use_font_face") then
                    if font_filename and font_faceindex then
                        return Font:getFace(font_filename, size, font_faceindex)
                    end
                end
            end,
            callback = function()
            end,
            hold_callback = function(touchmenu_instance)
            end,
            checked_func = function()
            end,
            menu_item_id = v,
        })
    end

    return menu_list
end

return DtDisplay
