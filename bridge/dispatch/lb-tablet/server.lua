--[[
    LB Tablet adapter (its police and ambulance dispatch). Written against the vendor's
    documentation and the open files of lb-tablet 1.7.0; see docs/adapters.md.

    The server export AddDispatch(options) answers the id of the new dispatch, a list of ids
    when it went to several departments, or false.

    What to know about lb-tablet:
      - a place needs a name (`location.label`). The server cannot read street names, so
        without `location` in the alert the title is shown there;
      - `time` is how long the dispatch stays, in seconds;
      - the priority has the same three words the bridge uses.
]]

return {
    caps = { blip = true, priority = true, code = true },

    send = function(alert)
        local id = exports['lb-tablet']:AddDispatch({
            priority = alert.priority,
            code = alert.code or '',
            title = alert.title,
            description = alert.message,
            location = {
                label = alert.location or alert.title,
                coords = { x = alert.coords.x, y = alert.coords.y },
            },
            time = alert.blip.seconds,
            job = alert.jobs,
            blip = {
                sprite = alert.blip.sprite,
                color = alert.blip.colour,
                size = alert.blip.scale,
                label = alert.title,
            },
        })
        return id ~= false and id ~= nil
    end,
}
