local OpenPresentAction = require("ChristmasPresents/OpenPresentAction")
local WrapPresentAction = require("ChristmasPresents/WrapPresentAction")
local PresentDefinitions = require("ChristmasPresents/PresentDefinitions")
local WrappingPaperDefinitions = require("ChristmasPresents/WrappingPaperDefinitions")
local Serialise = require("Starlit/serialise/Serialise")

---Returns true if the item is a valid wrapping paper item and is not equal to arg.
---@type ItemContainer_PredicateArg
local predicateWrappingPaperNotEqual = function(item, arg)
    return item ~= arg and WrappingPaperDefinitions[item:getFullType()] and true
end

---Module for christmas-present related UI.
local PresentsUI = {}

---Called when a player selects the option to wrap a present.
---@param player IsoPlayer The player wrapping the present
---@param item InventoryItem The item being wrapped
---@param wrappingPaperType string The full type of the wrapping paper item selected.
PresentsUI.onWrapPresent = function(player, item, wrappingPaperType)
    WrapPresentAction.queueNew(player, item, wrappingPaperType)
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

---Creates the wrapping paper submenu for a specific item.
---@param player IsoPlayer The player the submenu is being created for.
---@param context ISContextMenu The context menu to add the new submenu to.
---@param item InventoryItem The item to be wrapped.
---@param wrappingPaperList ArrayList ArrayList of all wrapping paper items to show in the submenu.
---@return ISContextMenu subMenu The wrapping paper submenu.
PresentsUI.createWrappingPaperSubmenu = function(player, context, item, wrappingPaperList)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(
        context:addOption(getText("IGUI_ChristmasPresents_WrapPresent")),
        subMenu
    )

    -- Lookup table of already displayed types, so we don't show e.g. wrapping paper green multiple times if the player has more than one
    local shownTypes = {} --[[@as {string : true}]]
    for i = 0, wrappingPaperList:size() - 1 do
        local wrappingPaper = wrappingPaperList:get(i) --[[@as InventoryItem]]
        local fullType = wrappingPaper:getFullType()
        if not shownTypes[fullType] then
            shownTypes[fullType] = true
            subMenu:addOption(
                wrappingPaper:getName(), player,
                PresentsUI.onWrapPresent, item, fullType)
        end
    end
    return subMenu
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

    if PresentDefinitions[primaryItem:getFullType()] then
        context:addOptionOnTop(
            getText("IGUI_ChristmasPresents_OpenPresent"),
            player, PresentsUI.onOpenPresent, primaryItem)
    elseif PresentsUI.isValidPresent(primaryItem) then
        local wrappingPapers = player:getInventory():getAllEvalArgRecurse(
            predicateWrappingPaperNotEqual, primaryItem)
        if not wrappingPapers:isEmpty() then
            PresentsUI.createWrappingPaperSubmenu(player, context, primaryItem, wrappingPapers)
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addPresentsContextOptions)

return PresentsUI