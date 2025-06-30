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

-- 频道配置（包含新添加的"世"按钮）
local channels = {
    { text = "说",     channel = "SAY",     command = "",       color = {1, 1, 1} },   -- 白色
    { text = "会",   channel = "GUILD",   command = "GUILD", color = {0, 1, 0} },   -- 绿色
    { text = "队",   channel = "PARTY",   command = "PARTY",  color = {0, 0.5, 1} }, -- 浅蓝色
    { text = "团",   channel = "RAID",    command = "RAID",   color = {1, 0.5, 0} }, -- 橙色
    { text = "喊",   channel = "YELL",    command = "YELL",   color = {1, 0, 0} },   -- 红色
    { 
        text = "R",  -- 随机骰子
        func = function()
            RandomRoll(1, 100)
        end,
        color = {0.5, 0, 1} -- 紫色
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
        end,
        color = {1, 1, 0} -- 黄色
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
        end,
        color = {1, 0.5, 0.5} -- 粉色
    },
    -- 重载界面按钮
    { 
        text = "载",  -- 重载界面
        func = function()
            ReloadUI()
        end,
        color = {0, 1, 1} -- 青色
    },
    -- 新添加的大脚世界频道按钮
    { 
        text = "世",  -- 大脚世界频道
        func = function()
            local channelName = "大脚世界频道"
            local channelIndex = GetChannelName(channelName)
            
            if channelIndex == 0 then
                -- 加入频道
                JoinChannelByName(channelName)
                
                -- 显示加入提示
                print("|cFF00FF00正在加入大脚世界频道...|r")
                
                -- 延迟0.5秒后切换到频道
                C_Timer.After(0.5, function()
                    channelIndex = GetChannelName(channelName)
                    if channelIndex > 0 then
                        ChatFrame_OpenChat("/"..channelIndex)
                    else
                        print("|cFFFF0000加入大脚世界频道失败|r")
                    end
                end)
            else
                -- 直接切换到频道
                ChatFrame_OpenChat("/"..channelIndex)
            end
        end,
        color = {0.5, 0.5, 1} -- 浅蓝色
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

-- 创建按钮（仅文字）
local buttons = {}
local buttonWidth, buttonHeight, spacing = 25, 22, 5
local font = "GameFontNormal" -- 使用游戏内置字体

for i, config in ipairs(channels) do
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(buttonWidth, buttonHeight)
    
    -- 创建文字对象
    local text = btn:CreateFontString(nil, "OVERLAY", font)
    text:SetPoint("CENTER")
    text:SetText(config.text)
    text:SetTextColor(unpack(config.color)) -- 设置文字颜色
    -- 添加粗体效果
    text:SetFont(text:GetFont(), 18, "OUTLINE") -- 18为字体大小，"OUTLINE"为粗体效果
    btn.text = text
    
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
