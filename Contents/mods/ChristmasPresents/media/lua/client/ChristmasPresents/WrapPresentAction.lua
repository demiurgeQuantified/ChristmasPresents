local WrappingPaperDefinitions = require("ChristmasPresents/WrappingPaperDefinitions")
local TimedActionUtils = require("Starlit/client/timedActions/TimedActionUtils")
local Serialise = require("Starlit/serialise/Serialise")

---Returns true if the item is the specified type and is not equal to arg.
---Argument should be a table where index 1 contains the item and index 2 contains the desired item type.
---@type ItemContainer_PredicateArg
---@param arg [InventoryItem, string]
local predicateTypeAndNotEqual = function(item, arg)
    return item ~= arg[1] and item:getFullType() == arg[2]
end

---Timed action for wrapping an item into a christmas present.
---@class WrapPresentAction : ISBaseTimedAction
---@field character IsoGameCharacter
---@field item InventoryItem The item to wrap into a present at the end of the action.
---@field wrappingPaper InventoryItem The wrapping paper used to wrap the present.
---@field handle integer The action sound's handle.
local WrapPresentAction = ISBaseTimedAction:derive("WrapPresentAction")
WrapPresentAction.__index = WrapPresentAction

WrapPresentAction.isValidStart = function(self)
    local inventory = self.character:getInventory()

    if not inventory:contains(self.item) then
        return false
    end

    if not inventory:containsEvalArg(
            predicateTypeAndNotEqual, {self.item, self.wrappingPaperType}) then
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
    self.item:setJobType(getText("IGUI_JobType_WrapPresent"))
    self.wrappingPaper = self.character:getInventory():getFirstEvalArg(
        predicateTypeAndNotEqual, {self.item, self.wrappingPaperType})
    self.wrappingPaper:setJobType(getText("IGUI_JobType_WrapPresent"))
end

WrapPresentAction.update = function(self)
    self.item:setJobDelta(self:getJobDelta())
    self.wrappingPaper:setJobDelta(self:getJobDelta())
end

--- Code common to both stop and perform
WrapPresentAction.stopCommon = function(self)
    self.character:getEmitter():stopSound(self.handle)
    self.wrappingPaper:setJobDelta(0)
end

WrapPresentAction.stop = function(self)
    self:stopCommon()
    self.item:setJobDelta(0)
    ISBaseTimedAction.stop(self)
end

WrapPresentAction.perform = function(self)
    self:stopCommon()

    local inventory = self.character:getInventory()
    local present = inventory:AddItem(
        WrappingPaperDefinitions[self.wrappingPaperType])

    inventory:Remove(self.item)

    present:getModData().ChristmasPresentContainedItem = Serialise.serialiseInventoryItem(self.item)
    local presentWeight = present:getActualWeight() + self.item:getActualWeight()
    present:setActualWeight(presentWeight)
    present:setWeight(presentWeight)
    present:setCustomWeight(true)

    self.wrappingPaper:Use()

    ISBaseTimedAction.perform(self)
end

---Queues a new WrapPresentAction for a character, also queueing any prerequisite actions.
---@param character IsoGameCharacter The player to perform the action.
---@param item InventoryItem The item to wrap.
---@param wrappingPaperType string The full type of wrapping paper to use.
WrapPresentAction.queueNew = function(character, item, wrappingPaperType)
    TimedActionUtils.transfer(character, item)
    TimedActionUtils.transferFirstValid(
        character, nil,
        predicateTypeAndNotEqual, {item, wrappingPaperType})
    TimedActionUtils.unequip(character, item)
    ISTimedActionQueue.add(
        WrapPresentAction.new(character, item, wrappingPaperType))
end

---Creates a new WrapPresentAction.
---@param character IsoGameCharacter The character performing the action.
---@param item InventoryItem The item to wrap.
---@param wrappingPaperType string The full type of wrapping paper to use.
---@return WrapPresentAction action
---@nodiscard
WrapPresentAction.new = function(character, item, wrappingPaperType)
    local o = ISBaseTimedAction:new(character) --[[@as WrapPresentAction]]
    setmetatable(o, WrapPresentAction)

    o.item = item
    o.wrappingPaperType = wrappingPaperType

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