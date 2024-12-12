local PresentDefinitions = {}

---List of all present item types. It's best to use this as read-only and use registerItem to add new items.
---@type string[]
PresentDefinitions.list = {}

---Lookup table of all present item types. It's best to use this as read-only and use registerItem to add new items.
---@type {string : true}
PresentDefinitions.lookup = {}

---Registers an item by its full type as a valid present item.
---@param fullType string The full type of the item.
PresentDefinitions.registerItem = function(fullType)
    if PresentDefinitions.lookup[fullType] then return end -- avoids double entry
    table.insert(PresentDefinitions.list, fullType)
    PresentDefinitions.lookup[fullType] = true
end

PresentDefinitions.registerItem("ChristmasPresents.Present")

return PresentDefinitions