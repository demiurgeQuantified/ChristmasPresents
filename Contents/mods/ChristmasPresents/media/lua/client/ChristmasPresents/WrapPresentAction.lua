local TimedActionUtils = require("Starlit/client/timedActions/TimedActionUtils")

---@class WrapPresentAction : ISBaseTimedAction
---@field character IsoGameCharacter
---@field item InventoryItem The item to wrap into a present at the end of the action.
---@field handle integer The action sound's handle.
local WrapPresentAction = ISBaseTimedAction:derive("WrapPresentAction")
WrapPresentAction.__index = WrapPresentAction

WrapPresentAction.isValidStart = function(self)
    local inventory = self.character:getInventory()

    if not inventory:contains(self.item) then
        return false
    end

    if not inventory:getFirstType("ChristmasPresents.WrappingPaper") then
        return false
    end

    return true
end

WrapPresentAction.isValid = function(self)
    return true
end

WrapPresentAction.start = function(self)
    self.handle = self.character:getEmitter():playSound("FixWithTape")
    self:setActionAnim("RipSheets")
end

--- Code common to both stop and perform
WrapPresentAction.stopCommon = function(self)
    self.character:getEmitter():stopSound(self.handle)
end

WrapPresentAction.stop = function(self)
    self:stopCommon()
    ISBaseTimedAction.stop(self)
end

WrapPresentAction.perform = function(self)
    self:stopCommon()

    local inventory = self.character:getInventory()
    local present = inventory:AddItem("ChristmasPresents.Present") --[[@as InventoryContainer]]

    inventory:Remove(self.item)

    -- -- creates the present's ByteData
    -- present:storeInByteData(unsaveableObject)
    -- ---@diagnostic disable-next-line: missing-parameter
    -- item:save(present:getByteData())

    present:getInventory():addItem(self.item)

    inventory:getFirstType("ChristmasPresents.WrappingPaper"):Use()

    ISBaseTimedAction.perform(self)
end

---Queues a new WrapPresentAction for a character, also queueing any prerequisite actions.
---@param character IsoGameCharacter The player to perform the action.
---@param item InventoryItem The item to wrap.
WrapPresentAction.queueNew = function(character, item)
    -- temporary hack to prevent grabbing items out of presents by wrapping twice
    -- real solution is to serialise items
    if item:getContainer():getContainingItem()
            and item:getContainer():getContainingItem():getFullType() == "ChristmasPresents.Present" then
        return
    end
    TimedActionUtils.transfer(character, item)
    TimedActionUtils.transferFirstType(character, "ChristmasPresents.WrappingPaper")
    ISTimedActionQueue.add(WrapPresentAction.new(character, item))
end

---Creates a new WrapPresentAction.
---@param character IsoGameCharacter The character performing the action.
---@param item InventoryItem The item to wrap.
---@return WrapPresentAction action
---@nodiscard
WrapPresentAction.new = function(character, item)
    local o = ISBaseTimedAction:new(character) --[[@as WrapPresentAction]]
    setmetatable(o, WrapPresentAction)

    o.item = item

    o.maxTime = 100
    if character:isTimedActionInstant() then
        o.maxTime = 1
    end

    o.stopOnAim = true
    o.stopOnWalk = true
    o.stopOnRun = true

    return o
end

return WrapPresentAction