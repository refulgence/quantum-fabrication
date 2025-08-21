-- Compatibility with a mod that removes products from a rocket parts recipe
if mods["quality-rocket-parts"] then
    local recipe = data.raw["recipe"]["rocket-part"]
    if next(recipe.results) == nil then
        recipe.results = {{type="item", name="rocket-part", amount=1}}
    end
end