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
        text = "R",  -- 随机骰子
        func = function()
            RandomRoll(1, 100)
        end
    },
    { 
        text = "就",  -- 就位确认
        func = function()
            if IsInGroup() then
                DoReadyCheck()
                local channelType = IsInRaid() and "RAID" or "PARTY"
                SendChatMessage("就位确认已开始，请检查状态！", channelType)
            else
                print("|cFFFF0000需要加入队伍或团队|r")
            end
        end
    },
    -- DBM倒计时
    { 
        text = "倒",  -- 倒计时
        func = function()
            if IsInGroup() then
                if DBM then
                    SlashCmdList["DEADLYBOSSMODS"]("pull 5")
                else
                    print("|cFFFF0000需要安装DBM插件|r")
                end
            else
                print("|cFFFF0000需要加入队伍或团队|r")
            end
        end
    },
    -- 重载界面按钮
    { 
        text = "载",  -- 重载界面
        func = function()
            ReloadUI()
        end
    }
}

-- 创建主框架
local frame = CreateFrame("Frame", "ChannelButtonsFrame", UIParent)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)

-- 位置跟踪变量
frame.lastCheck = 0
frame.isDragging = false

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
    end)
    
    -- 悬停提示
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local tip = config.text == "R" and "随机骰子 (1-100)"
                  or config.text == "就" and "发起就位确认"
                  or config.text == "倒" and "发起DBM 5秒倒计时"
                  or config.text == "载" and "重载用户界面"
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

-- 右键点击重置位置
frame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        self:ClearAllPoints()
        self:SetPoint(defaults.position.point, 
                     defaults.position.relativeTo, 
                     defaults.position.relativePoint,
                     defaults.position.x,
                     defaults.position.y)
        db.position = CopyTable(defaults.position)
        print("|cFF00FF00频道按钮位置已重置|r")
    end
end)

-- 拖动处理
frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
    self.isDragging = true
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self.isDragging = false
    
    -- 统一保存为BOTTOMLEFT相对于TOPLEFT格式
    self:ClearAllPoints()
    local cfLeft = ChatFrame1:GetLeft()
    local cfTop = ChatFrame1:GetTop()
    local selfLeft = self:GetLeft()
    local selfBottom = self:GetBottom()
    
    local offsetX = selfLeft - cfLeft
    local offsetY = selfBottom - cfTop
    
    self:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", offsetX, offsetY)
    
    db.position = {
        point = "BOTTOMLEFT",
        relativeTo = "ChatFrame1",
        relativePoint = "TOPLEFT",
        x = offsetX,
        y = offsetY
    }
end)

-- 位置跟踪：每0.5秒检查一次聊天框位置
frame:SetScript("OnUpdate", function(self, elapsed)
    self.lastCheck = self.lastCheck + elapsed
    if self.lastCheck > 0.5 then
        self.lastCheck = 0
        
        if self.isDragging then return end
        
        local cfPoint, cfRelativeTo, cfRelativePoint, cfX, cfY = ChatFrame1:GetPoint(1)
        local cfRelativeToName = cfRelativeTo and cfRelativeTo:GetName() or nil
        
        if not self.lastChatPoint then
            -- 首次记录位置
            self.lastChatPoint = {cfPoint, cfRelativeToName, cfRelativePoint, cfX, cfY}
        else
            -- 检查位置变化
            local current = {cfPoint, cfRelativeToName, cfRelativePoint, cfX, cfY}
            local changed = false
            
            for i = 1, #current do
                if current[i] ~= self.lastChatPoint[i] then
                    changed = true
                    break
                end
            end
            
            if changed then
                -- 更新按钮面板位置
                self:ClearAllPoints()
                self:SetPoint(
                    db.position.point,
                    db.position.relativeTo,
                    db.position.relativePoint,
                    db.position.x,
                    db.position.y
                )
                self.lastChatPoint = current
            end
        end
    end
end)