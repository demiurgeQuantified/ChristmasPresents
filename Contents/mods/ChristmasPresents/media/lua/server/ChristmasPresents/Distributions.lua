local WrappingPaperDefinitions = require("ChristmasPresents/WrappingPaperDefinitions")

local rand = newrandom()

---Module for item distributions.
local Distributions = {}

---List of wrapping paper items to replace placeholders with.
---This is automatically populated from WrappingPaperDefinitions during OnPostDistributionMerge.
---@type string[]
Distributions.wrappingPaperList = {}

Events.OnPostDistributionMerge.Add(function()
    for type, _ in pairs(WrappingPaperDefinitions) do
        table.insert(Distributions.wrappingPaperList, type)
    end
end)

Events.OnInitGlobalModData.Add(function()
    if not SandboxVars.ChristmasPresents.spawnItems then return end

    table.insert(ProceduralDistributions.list.GigamartToys.items,
                 "ChristmasPresents.Internal_WrappingPaperPlaceholder")
    table.insert(ProceduralDistributions.list.GigamartToys.items,
                 20)
    table.insert(ProceduralDistributions.list.GigamartToys.items,
                 "ChristmasPresents.Internal_WrappingPaperPlaceholder")
    table.insert(ProceduralDistributions.list.GigamartToys.items,
                 10)

    ItemPickerJava.Parse()
end)

Events.OnFillContainer.Add(function(_, _, container)
    local placeholders = container:getAllType("ChristmasPresents.Internal_WrappingPaperPlaceholder")
    for i = 0, placeholders:size() - 1 do
        container:Remove(placeholders:get(i))
        container:AddItem(
            Distributions.wrappingPaperList[
                rand:random(#Distributions.wrappingPaperList)]
        )
    end
end)

return Distributions