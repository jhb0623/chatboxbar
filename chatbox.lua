-- chatbox.lua
local addonName, addon = ...
local DB_NAME = "ChannelButtonsDB"

-- 默认配置
local defaults = {
    position = {
        point = "BOTTOMLEFT",
        relativeTo = "ChatFrame1",
        relativePoint = "TOPLEFT",
        x = 0,
        y = 25
    }
}

-- 初始化数据库
ChannelButtonsDB = ChannelButtonsDB or CopyTable(defaults)
local db = ChannelButtonsDB

-- 频道配置
local channels = {
    { text = "说",     channel = "SAY",     command = ""       },
    { text = "会",   channel = "GUILD",   command = "GUILD" },
    { text = "队",   channel = "PARTY",   command = "PARTY"  },
    { text = "团",   channel = "RAID",    command = "RAID"   },
    { text = "喊",   channel = "YELL",    command = "YELL"   },
    { 
        text = "肉", 
        func = function()
            RandomRoll(1, 100)
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    },
    { 
        text = "到", 
        func = function()
            if IsInGroup() then
                local channel = IsInRaid() and "RAID" or "PARTY"
                SendChatMessage(UnitName("player").." 已准备就绪！", channel)
                PlaySound(SOUNDKIT.READY_CHECK)
            else
                print("|cFFFF0000需要加入队伍或团队|r")
            end
        end
    },
   }

-- 创建主框架
local frame = CreateFrame("Frame", "ChannelButtonsFrame", UIParent)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)

-- 设置初始位置
frame:SetPoint(
    db.position.point,
    db.position.relativeTo,
    db.position.relativePoint,
    db.position.x,
    db.position.y
)

-- 创建按钮
local buttons = {}
local buttonWidth, buttonHeight, spacing = 25, 22, 5

for i, config in ipairs(channels) do
    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btn:SetSize(buttonWidth, buttonHeight)
    btn:SetText(config.text)
    
    -- 定位按钮
    if i == 1 then
        btn:SetPoint("LEFT")
    else
        btn:SetPoint("LEFT", buttons[i-1], "RIGHT", spacing, 0)
    end
    
    -- 点击事件处理
    btn:SetScript("OnClick", function()
        if config.func then
            config.func()
        else
            ChatFrame_OpenChat("/"..config.channel:lower())
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
    
    -- 悬停提示
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local tip = config.text == "掷点" and "随机骰子 (1-100)"
                  or config.text == "就位" and "发送就位确认通知"
                  or config.text == "倒计时" and "发起5秒团队倒计时"
                  or "切换到"..config.text.."频道"
        GameTooltip:AddLine(tip)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    
    buttons[i] = btn
end

-- 调整框架尺寸
frame:SetWidth((buttonWidth + spacing) * #channels - spacing)
frame:SetHeight(buttonHeight)

-- 拖动处理
frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    db.position = {
        point = point,
        relativeTo = "ChatFrame1",
        relativePoint = relativePoint,
        x = x,
        y = y
    }
end)

-- 自动跟随聊天框
ChatFrame1:HookScript("OnSizeChanged", function()
    frame:ClearAllPoints()
    frame:SetPoint(db.position.point, 
        db.position.relativeTo, 
        db.position.relativePoint,
        db.position.x,
        db.position.y)
end)

-- 右键菜单
frame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        local menuFrame = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")
        local menuItems = {
            {
                text = "频道按钮设置",
                isTitle = true,
                notCheckable = true
            },
            {
                text = "重置位置",
                func = function()
                    frame:ClearAllPoints()
                    frame:SetPoint(defaults.position.point, 
                        defaults.position.relativeTo, 
                        defaults.position.relativePoint,
                        defaults.position.x,
                        defaults.position.y)
                    db.position = CopyTable(defaults.position)
                end
            }
        }
        
        UIDropDownMenu_Initialize(menuFrame, function()
            for _, item in ipairs(menuItems) do
                UIDropDownMenu_AddButton(item)
            end
        end)
        
        ToggleDropDownMenu(1, nil, menuFrame, self, 0, 0)
    end
end)