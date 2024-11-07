storage.craft_data = {}
storage.filtered_data = {}
for _, player in pairs(game.players) do
    local main_frame = player.gui.screen.qf_fabricator_frame
    if main_frame then main_frame.destroy() end
end