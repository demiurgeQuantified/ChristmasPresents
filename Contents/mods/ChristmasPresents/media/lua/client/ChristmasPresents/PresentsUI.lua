local OpenPresentAction = require("ChristmasPresents/OpenPresentAction")
local WrapPresentAction = require("ChristmasPresents/WrapPresentAction")
local Serialise = require("Starlit/serialise/Serialise")
local PresentDefinitions = require("ChristmasPresents/PresentDefinitions")

---Returns false if the item is equal to arg. Used to exclude one specific item from a search.
---@type ItemContainer_PredicateArg
local predicateNotEqual = function(item, arg)
    return item ~= arg
end

local PresentsUI = {}

---Called when a player selects the option to wrap a present.
---@param player IsoPlayer The player wrapping the present
---@param item InventoryItem The item being wrapped
PresentsUI.onWrapPresent = function(player, item)
    WrapPresentAction.queueNew(player, item)
end

---Called when a player selects the option to open a present.
---@param player IsoPlayer The player opening the present
---@param present InventoryContainer The present being opened
PresentsUI.onOpenPresent = function(player, present)
    OpenPresentAction.queueNew(player, present)
end

---Determines whether the "Wrap Present" context option should be shown for an item.
---@param item InventoryItem The item to test.
---@return boolean result Whether the item is valid.
---@nodiscard
PresentsUI.isValidPresent = function(item)
    return Serialise.canSerialiseInventoryItemLosslessly(item)
end

---@type Callback_OnFillInventoryObjectContextMenu
local addPresentsContextOptions = function(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)

    local primaryItem = items[1]
    if not instanceof(primaryItem, "InventoryItem") then
        ---@cast primaryItem -InventoryItem
        primaryItem = primaryItem.items[1]
    else
        ---@cast primaryItem InventoryItem
    end

    if PresentDefinitions.lookup[primaryItem:getFullType()] then
        context:addOptionOnTop(
            getText("IGUI_ChristmasPresents_OpenPresent"),
            player, PresentsUI.onOpenPresent, primaryItem)
    elseif player:getInventory():containsTypeEvalArgRecurse(
        "ChristmasPresents.WrappingPaper", predicateNotEqual, primaryItem)
            and PresentsUI.isValidPresent(primaryItem) then
        context:addOption(
            getText("IGUI_ChristmasPresents_WrapPresent"),
            player, PresentsUI.onWrapPresent, primaryItem)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addPresentsContextOptions)

return PresentsUI