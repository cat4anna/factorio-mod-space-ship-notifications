
local function get_ship_notification(string_id, ship_id, planet_name)
    return {string_id, string.format("[space-platform=%d]", ship_id), string.format("[planet=%s]", planet_name),}
end

local function get_player_notification_filter(player_index)
    return settings.get_player_settings(player_index)["notification-filter-setting"].value
end

local function get_planet_name_from_surface(surface)
    if surface and surface.planet then
        return surface.planet.name
    end
end

local function test_if_player_is_on_planet(player, planet_name)
    local player_planet = get_planet_name_from_surface(player.physical_surface)
    return player_planet and player_planet == planet_name
end

local function filter_setting_to_table(filter_setting)
    return {
        hitchhiking = filter_setting == "hitchhiking" and true or nil,
        arrivals = filter_setting == "arrivals" and true or nil,
        none = filter_setting == "none" and true or nil,
    }
end

local function process_planet_notification(planet_name, notification, filter)
    for _, player in pairs(game.players) do
        local filter_setting = get_player_notification_filter(player.index)
        if filter[filter_setting] then

            local player_filter = filter_setting_to_table(filter_setting)

            local wants_notification =
                (player_filter.arrivals) or
                (player_filter.hitchhiking and test_if_player_is_on_planet(player, planet_name))

            if wants_notification then
                player.print(notification)
            end
        end
    end
end

local function update_space_ship_status(event)
    local platform = event.platform
    -- local old_state = event.old_state
    local new_state = platform.state
    local state = defines.space_platform_state

    if new_state == state.waiting_at_station then
        local location = platform.space_location
        local notification = get_ship_notification("notifications.platform-arrived-at", platform.index, location.name)
        process_planet_notification(location.name, notification, {arrivals=1, hitchhiking=1})
    end

    if new_state == state.on_the_path then
        local connection = platform.space_connection
        local from = connection.from
        local to = connection.to

        -- swap to/from if ship is the other end
        if platform.distance > 0.5 then
            to,from = from,to
        end

        local from_notification = get_ship_notification("notifications.platform-departed-from", platform.index, from.name)
        local to_notification = get_ship_notification("notifications.platform-heading-to", platform.index, to.name)

        process_planet_notification(from.name, from_notification, {hitchhiking=1})
        process_planet_notification(to.name, to_notification, {hitchhiking=1})
    end
end

script.on_event(defines.events.on_space_platform_changed_state, update_space_ship_status)
