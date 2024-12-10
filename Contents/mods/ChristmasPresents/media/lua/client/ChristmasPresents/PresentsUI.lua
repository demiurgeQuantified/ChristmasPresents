local OpenPresentAction = require("ChristmasPresents/OpenPresentAction")
local WrapPresentAction = require("ChristmasPresents/WrapPresentAction")

---@type InventoryContainer
local inventoryContainerMetatable = __classmetatables[InventoryContainer.class].__index

-- prevents looking inside the container

local getCategory = inventoryContainerMetatable.getCategory
inventoryContainerMetatable.getCategory = function(self)
    if self:getFullType() == "ChristmasPresents.Present" then
        return "Item"
    end
    return getCategory(self)
end

---@class Item
---@field Capacity integer

local PRESENT_CAPACITY = ScriptManager.instance:getItem("ChristmasPresents.Present").Capacity
local PRESENT_WEIGHT = ScriptManager.instance:getItem("ChristmasPresents.Present"):getActualWeight()
local tempArrayList = ArrayList.new()

-- prevents the tooltip from showing contained items
-- also hides the capacity

local old_render = ISToolTipInv.render
---@diagnostic disable-next-line: duplicate-set-field
ISToolTipInv.render = function(self)
    if self.item:getFullType() == "ChristmasPresents.Present" then
        local item = self.item --[[@as InventoryContainer]]

        local inv = item:getInventory()
        local items = inv:getItems()
        local weight = item:getActualWeight()

        -- have to fake the weight because the items are removed when the tooltip calculates it
        item:setActualWeight(weight + item:getContentsWeight())
        item:setCapacity(0)
        inv:setItems(tempArrayList)

        old_render(self)

        inv:setItems(items)
        item:setCapacity(PRESENT_CAPACITY)
        item:setActualWeight(PRESENT_WEIGHT)
    else
        old_render(self)
    end
end

-- FIXME: timed actions can still access the item lol
-- bytedata bullshit didn't work out, write item serialisation for starlit

-- ---@diagnostic disable-next-line: param-type-mismatch
-- local unsaveableObject = IsoZombieGiblets.new(nil)

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

    local itemType = primaryItem:getFullType()

    if itemType == "ChristmasPresents.Present" then
        context:addOptionOnTop(
            getText("IGUI_ChristmasPresents_OpenPresent"),
            player, PresentsUI.onOpenPresent, primaryItem)
    elseif player:getInventory():containsTypeRecurse("ChristmasPresents.WrappingPaper")
            and itemType ~= "ChristmasPresents.WrappingPaper" then
        context:addOption(
            getText("IGUI_ChristmasPresents_WrapPresent"),
            player, PresentsUI.onWrapPresent, primaryItem)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addPresentsContextOptions)

return PresentsUI