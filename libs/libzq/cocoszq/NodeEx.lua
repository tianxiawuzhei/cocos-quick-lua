--[[--

针对 cc.Node 的扩展

]]

local c = cc
local Node = c.Node

function Node:schedule(callback, interval)
    interval = interval or 0
    if not self._schedule_callback_list then
        self._schedule_callback_list = {}
    end

    local wrapper = nil
    local callback_action = nil
    for i, v in ipairs(self._schedule_callback_list) do
        local  single = v
        if (v["callback_fn"] == callback) then
            wrapper = v["wrapper"]
            callback_action = v["action"]
            table.remove(self._schedule_callback_list, i)
            break
        end
    end

    if wrapper then
        self:stopAction(callback_action)
    end

    wrapper = handler(self, callback)
    local seq = transition.sequence({
        cc.DelayTime:create(interval),
        cc.CallFunc:create(wrapper),
    })
    local action = cc.RepeatForever:create(seq)
    self:runAction(action)
    table.insert(self._schedule_callback_list, {
        ["callback_fn"] = callback,
        ["wrapper"] = wrapper,
        ["action"] = action
        })

    return action
end

function Node:scheduleOnce(callback, delay)
    delay = delay or 0
    if not self._schedule_callback_list then
        self._schedule_callback_list = {}
    end

    local wrapper = nil
    local callback_action = nil
    for i, v in ipairs(self._schedule_callback_list) do
        local  single = v
        if (v["callback_fn"] == callback) then
            wrapper = v["wrapper"]
            callback_action = v["action"]
            table.remove(self._schedule_callback_list, i)
            break
        end
    end

    if not tolua.isnull(callback_action) then
        self:stopAction(callback_action)
    end

    wrapper = handler(self, callback)
    local action = transition.sequence({
        cc.DelayTime:create(delay),
        cc.CallFunc:create(wrapper),
    })
    self:runAction(action)
    table.insert(self._schedule_callback_list, {
        ["callback_fn"] = callback,
        ["wrapper"] = wrapper,
        ["action"] = action
        })

    return action
end

---
-- mixed: callback_fn 对象方法; action: schedule(return value)
--
function Node:unschedule(mixed_fn_action)
    if not self._schedule_callback_list then
        return
    end

    local wrapper = nil
    local callback_action = nil
    for i, v in ipairs(self._schedule_callback_list) do
        local  single = v
        if (v["callback_fn"] == mixed_fn_action or v["action"] == mixed_fn_action) then
            wrapper = v["wrapper"]
            callback_action = v["action"]
            table.remove(self._schedule_callback_list, i)
            break
        end
    end

    if not tolua.isnull(callback_action) then
        self:stopAction(callback_action)
    end
end

function Node:unscheduleAllCallbacks()
    if not self._schedule_callback_list then
        return
    end

    for i=#self._schedule_callback_list,1,-1 do
        local single = self._schedule_callback_list[i]
        local action = single["action"]

        if not tolua.isnull(action) then
            self:stopAction(action)
        end

        table.remove(self._schedule_callback_list, i)
    end
end

function Node:getWidth()
    return self:getContentSize().width
end

function Node:getHeight()
    return self:getContentSize().height
end

function Node:setWidth(width)
    self:setContentSize(width, self:getHeight())
end

function Node:setHeight(height)
    self:setContentSize(self:getWidth(), height)
end

function Node:getTransformSize()
    local rect = self:getBoundingBox()
    return cc.size(rect.width, rect.height)
end

function Node:getTransformWidth()
    return self:getBoundingBox().width
end

function Node:getTransformHeight()
    return self:getBoundingBox().heigth
end

function Node:getTransformPoint(point)
    local origin = self:getContentSize()
    local percent = cc.p(point.x*origin.width, point.y*origin.height)
    local transform = self:getTransformSize()
    return cc.p(percent.x*transform.widht, percent.y*transform.height)
end

function Node:setX(x)
    self:setPositionX(x)
end

function Node:setY(y)
    self:setPositionY(y)
end

function Node:getX()
    self:getPositionX()
end

function Node:getY()
    self:getPositionY()
end

function Node:incX(delta)
    self:setX(self:getX() + delta)
end

function Node:incY(delta)
    self:setY(self:getY() + delta)
end

function Node:getRect()
    local size = self:getContentSize()
    return cc.rect(0, 0, size.width, size.height)
end

function Node:getTop()
    return self:getY() + (1 - self:getAnchorPoint().y) * self:getTransformHeight()
end

function Node:getRight()
    return self:getX() + (1 - self:getAnchorPoint().x) * self:getTransformWidth()
end

function Node:getBottom()
    return self:getY() - self:getAnchorPoint().y * self:getTransformHeight()
end

function Node:getLeft()
    return self:getX() - self:getAnchorPoint().x * self:getTransformWidth()
end

function Node:center()
    local size = self:getContentSize();
    return cc.p(size.width * 0.5, size.height * 0.5)
end

function Node:centerX()
    return self:getWidth()*0.5
end

function Node:centerY()
    return self:getHeight()*0.5
end

function Node:halfPosition()
    local size = self:getTransformSize();
    local pos  = self:getPosition();
    local ar   = self:getAnchorPoint();
    return cc.p(pos.x + (0.5 - ar.x) * size.width, pos.y + (0.5 - ar.y) * size.height);
end

function Node:halfPositionX()
    return self:halfPosition().x
end

function Node:halfPositionY()
    return self:halfPosition().y
end

function Node:pointToWorld(point)
    return self:convertToWorldSpace(point)
end

function Node:sizeToWorld(size)
    return cc.sizeApplyAffineTransform(size, self:getNodeToWorldAffineTransform())
end

function Node:rectToWorld(rect)
    local origin = self:convertToWorldSpace(cc.p(rect.x, rect.y))
    local size = self:sizeToWorld(cc.size(rect.width, rect.height))
    return cc.rect(origin.x, origin.y, size.width, size.height)
end

function Node:pointToNode(node, point)
    local pt = self:convertToWorldSpace(point)
    pt = node:convertToNodeSpace(pt)
    return pt
end

function Node:sizeToNode(node, size)
    local sz = cc.sizeApplyAffineTransform(size, self:getNodeToWorldAffineTransform())
    sz = cc.sizeApplyAffineTransform(sz, node:getWorldToNodeAffineTransform())
    return sz
end

function Node:rectToNode(node, rect)
    local origin = self:pointToNode(node, cc.p(rect.x, rect,y))
    local size = self:sizeToNode(node, cc.size(rect.width, rect.height))
    return cc.rect(origin.x, origin.y, size.width, size.height)
end

function Node:stopAllChildrenActions()
    self:stopAllActions()
    local child = self:getChildren()
    for i,v in ipairs(child) do
        v.stopAllChildrenActions()
    end
end

function Node:unscheduleAllChildren()
    self:unscheduleAllCallbacks()
    local child = self:getChildren()
    for i,v in ipairs(child) do
        v.unscheduleAllChildren()
    end
end

function Node:setChildrenCascadeOpacity(enable)
    self:setCascadeOpacityEnabled(enable)
    local child = self:getChildren()
    for i,v in ipairs(child) do
        v:setChildrenCascadeOpacity(enable)
    end
end

function Node:enableDebugDrawRect(enable, random, anchor)
    if self._debug_draw_rect_enable_ == enable then
        return
    end

    self._debug_draw_rect_enable_ = enable
    self._debug_draw_rect_color_ = self._debug_draw_rect_color_ or cc.c4f(1, 0, 0, 1)
    self._debug_draw_rect_anchor_ = anchor or false
    self._debug_draw_rect_size_ = self._debug_draw_rect_size_ or cc.size(0, 0)
    if not self._debug_draw_rect_node_ then
        self._debug_draw_rect_node_ = cc.DrawNode:create()
        self._debug_draw_rect_node_:setAnchorPoint(cc.p(0, 0))
        self._debug_draw_rect_node_:setPosition(cc.p(0, 0))
        self:addChild(self._debug_draw_rect_node_, zq.Int32Max)
    end

    self._debug_draw_rect_node_:setVisible(enable)
    if random then
        self._debug_draw_rect_color_ = cc.c4f(math.random(), math.random(), math.random(), 1)
    end

    if (not enable) then
        return
    end

    if self._debug_draw_rect_handle_ then
        self:stopAction(self._debug_draw_rect_handle_)
    end

    self._debug_draw_rect_handle_ = self:schedule(handler(self, self.debugDrawCallFunc), 0)

end

function Node:debugDrawCallFunc()
    if cc.sizeEqualToSize(self._debug_draw_rect_size_, self:getContentSize()) then
        return
    end

    self._debug_draw_rect_size_ = self:getContentSize()
    local points = {
        cc.p(0, 0),
        cc.p(0, self._debug_draw_rect_size_.height),
        cc.p(self._debug_draw_rect_size_.width, self._debug_draw_rect_size_.height),
        cc.p(self._debug_draw_rect_size_.width, 0)
    }

    local params = {}
    params.borderWidth = 0.6
    params.borderColor = self._debug_draw_rect_color_
    params.fillColor = cc.c4f(0,0,0,0)
    self._debug_draw_rect_node_:clear()
    self._debug_draw_rect_node_:drawPolygon(points, params)

    if self._debug_draw_rect_anchor_ then
        local anchorXPos = self:getAnchorPoint().x*self._debug_draw_rect_size_.width
        local anchorYPos = self:getAnchorPoint().y*self._debug_draw_rect_size_.height
        local points = {
            cc.p(anchorXPos-3, anchorYPos-3),
            cc.p(anchorXPos-3, anchorYPos+3),
            cc.p(anchorXPos+3, anchorYPos+3),
            cc.p(anchorXPos+3, anchorYPos-3)
        }

        self._debug_draw_rect_node_:drawPolygon(points, params)
    end
end

function Node:setDebugDrawColor(intColor)
    self._debug_draw_rect_color_ = zq.color.intToc4f(intColor)
end

function Node:setContentSize(width, height)
    if not height then
        height = width.height
        width = width.width
    end
    local func = tolua.getcfunction(self, "setContentSize")
    func(self, width, height)
end

-- ccbi
function Node:playCCBI(ccbi, remove, callback)
    remove = remove or false

    local block = function (time)
        local handle = function ()
            if callback then
                callback()
            end

            if remove then
                self:removeFromParent(true)
            end
        end

        local action = transition.sequence({
            cc.DelayTime:create(time),
            cc.CallFunc:create(handle),
        })

        if self._ccb_temp then
            self._ccb_temp:runAction(action)
        else
            handle()
        end
    end

    if (not self:loadCCBI(ccbi)) then
        block(0)
        return 0
    end

    block(self._ccb_duration)
    return self._ccb_duration
end

function Node:loadCCBI(ccbi)
    self:removeCCBI()

    if (not zq.ZQCCBILoader:getInstance():load(ccbi, true)) then
        return false
    end

    local reader = zq.ZQCCBILoader:createCCBReader()
    self._ccb_host = zq.ZQCCBILoader:getInstance():readNodeGraphFromFile(ccbi, reader)
    if (self._ccb_host) then
        self._ccb_host:setPosition(self:center())
        self._ccb_host:setChildrenCascadeOpacity(true)
        self:addChild(self._ccb_host)

        local animationManager = reader:getActionManager()
        local autoPlaySequenceId = animationManager:getAutoPlaySequenceId()

        local ccbSequence = animationManager:getSequence(autoPlaySequenceId)
        self._ccb_duration = 0
        if ccbSequence then
            self._ccb_duration = ccbSequence:getDuration()
        end

        if (not self._ccb_temp) then
            self._ccb_temp = cc.Node:create()
            self:addChild(self._ccb_temp)
        end

        return true
    end

    return false
end

function Node:removeCCBI()
    if self._ccb_host then
        self._ccb_host:removeFromParent(true)
    end

    if self._ccb_temp then
        self._ccb_temp:removeFromParent(true)
    end

    self._ccb_host = nil
    self._ccb_temp = nil
end

function Node:ccbiHost()
    return self._ccb_host
end

function Node:ccbiVisit(callback, cls)
    local store = {}
    local block = function (node)
        if (not cls or isinstanceof(node, cls)) then
            table.insert(store, node)
        end

        local children = node:getChildren()
        for k,v in pairs(children) do
            block(v)
        end
    end

    if self._ccb_host then
        block(self._ccb_host)
    end

    for k,v in pairs(store) do
        callback(v)
    end
end

function Node:ccbiChildren(cls)
    local store = {}
    self:ccbiVisit(function (node)
        table.insert(store, node)
    end, cls)

    return store
end

function Node:ccbiRect()
    local rect = nil
    self:ccbiVisit(function (node)
        local temp = cc.rect(0, 0, node:getWidth(), node:getHeight())
        temp = ndoe:rectToNode(self, temp)

        if rect then
            rect = cc.rectUnion(rect, temp)
        else
            rect = temp
        end
    end)

    if rect then
        return rect
    else
        return cc.rect(0, 0, 0, 0)
    end
end

function Node:ccbiSize()
    local rect = self:ccbiRect()
    return cc.size(rect.width, rect.height)
end

function Node:setParticle(plist, particle_type)
    particle_type = particle_type or cc.POSITION_TYPE_RELATIVE

    if self._particle then
        self._particle:removeFromParent(true)
        self._particle = nil
    end

    if plist and string.len(zq.ZQFileManage:getInstance():load_file(plist)) > 0 then
        self._particle = cc.ParticleSystemQuad:create(plist)
        self._particle:setAnchorPoint(0.5, 0.5)
        self._particle:setPosition(self:center())
        self._particle:setPositionType(particle_type)
        self:addChild(self._particle)
    end
end


