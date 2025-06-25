local tracking = require("scripts/tracking_utils")

for type, request_table in pairs(storage.tracked_requests) do
    if type ~= "revivals" and type ~= "destroys" and type ~= "upgrades" then
        for id, entry in pairs(request_table) do
            if entry.entity then
                if not entry.entity.valid or entry.entity.force.name ~= "player" then
                    tracking.remove_tracked_request(type, id)
                end
            end
        end
    end
end