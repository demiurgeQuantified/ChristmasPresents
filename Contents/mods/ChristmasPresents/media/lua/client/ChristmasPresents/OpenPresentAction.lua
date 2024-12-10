local TimedActionUtils = require("Starlit/client/timedActions/TimedActionUtils")

---@class OpenPresentAction : ISBaseTimedAction
---@field character IsoGameCharacter
---@field present InventoryContainer The present to open at the end of the action.
---@field handle integer The action sound's handle.
local OpenPresentAction = ISBaseTimedAction:derive("OpenPresentAction")
OpenPresentAction.__index = OpenPresentAction

OpenPresentAction.isValidStart = function(self)
    if not self.character:getInventory():contains(self.present) then
        return false
    end
    return true
end

OpenPresentAction.isValid = function(self)
    return true
end

OpenPresentAction.start = function(self)
    self.handle = self.character:getEmitter():playSound("ClothesRipping")
    self:setActionAnim("RipSheets")
end

--- Code common to both stop and perform
OpenPresentAction.stopCommon = function(self)
    self.character:getEmitter():stopSound(self.handle)
end

OpenPresentAction.stop = function(self)
    self:stopCommon()
    ISBaseTimedAction.stop(self)
end

OpenPresentAction.perform = function(self)
    self:stopCommon()

    local presentItems = self.present:getInventory():getItems()
    local inventory = self.character:getInventory()
    for i = presentItems:size()-1, 0, -1 do
        inventory:addItem(presentItems:get(i))
    end
    inventory:Remove(self.present)

    --inventory:addItem(InventoryItem.loadItem(present:getByteData(), IsoWorld.WorldVersion))

    inventory:AddItem("ChristmasPresents.WrappingPaperRipped")

    ISBaseTimedAction.perform(self)
end

---Queues a new OpenPresentAction for a character, also queueing any prerequisite actions.
---@param character IsoGameCharacter The player to perform the action.
---@param present InventoryContainer The present to open.
OpenPresentAction.queueNew = function(character, present)
    TimedActionUtils.transfer(character, present)
    ISTimedActionQueue.add(OpenPresentAction.new(character, present))
end

---Creates a new OpenPresentAction.
---@param character IsoGameCharacter The character performing the action.
---@param present InventoryContainer The present to open.
---@return OpenPresentAction action
---@nodiscard
OpenPresentAction.new = function(character, present)
    local o = ISBaseTimedAction:new(character) --[[@as OpenPresentAction]]
    setmetatable(o, OpenPresentAction)

    o.present = present

    o.maxTime = 100
    if character:isTimedActionInstant() then
        o.maxTime = 1
    end

    o.stopOnAim = true
    o.stopOnWalk = true
    o.stopOnRun = true

    return o
end

return OpenPresentAction