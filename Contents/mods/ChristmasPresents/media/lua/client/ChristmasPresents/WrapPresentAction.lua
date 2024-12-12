local TimedActionUtils = require("Starlit/client/timedActions/TimedActionUtils")
local Serialise = require("Starlit/serialise/Serialise")
local PresentDefinitions = require("ChristmasPresents/PresentDefinitions")

local rand = newrandom()

---Returns true if the item is a valid wrapping paper item and is not equal to arg.
---Needed because there is no getFirstTypeEvalArg lol
---@type ItemContainer_PredicateArg
local predicateWrappingPaperNotEqual = function(item, arg)
    return item ~= arg and item:getFullType() == "ChristmasPresents.WrappingPaper"
end

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

    if not inventory:getFirstEvalArg(predicateWrappingPaperNotEqual, self.item) then
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
    self.wrappingPaper = self.character:getInventory():getFirstEvalArg(predicateWrappingPaperNotEqual, self.item)
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
        PresentDefinitions.list[rand:random(#PresentDefinitions.list)])

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
WrapPresentAction.queueNew = function(character, item)
    TimedActionUtils.transfer(character, item)
    TimedActionUtils.transferFirstType(
        character, "ChristmasPresents.WrappingPaper",
        predicateWrappingPaperNotEqual, item)
    TimedActionUtils.unequip(character, item)
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