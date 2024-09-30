local style = data.raw['gui-style'].default

style.qf_item_group_table =
{
  type = "table_style",
  draw_type = "outer",
  horizontal_spacing = 0,
  vertical_spacing = 0,
  padding = 0,
  background_graphical_set =
  {
    position = {0, 0},
    corner_size = 8,
    overall_tiling_vertical_size = 53,
    overall_tiling_vertical_spacing = 22,
    overall_tiling_vertical_padding = 11,
    overall_tiling_horizontal_size = 83,
    overall_tiling_horizontal_spacing = 22,
    overall_tiling_horizontal_padding = 11
  }
}

style.qf_item_slots =
{
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame",
  background_graphical_set =
  {
    position = {282, 17},
    corner_size = 8,
    overall_tiling_vertical_size = 30,
    overall_tiling_vertical_spacing = 10,
    overall_tiling_vertical_padding = 4,
    overall_tiling_horizontal_size = 30,
    overall_tiling_horizontal_spacing = 10,
    overall_tiling_horizontal_padding = 4
  },
  vertical_flow_style =
  {
    type = "vertical_flow_style",
    vertical_spacing = 0
  },
  horizontal_flow_style =
  {
    type = "horizontal_flow_style",
    horizontal_spacing = 0
  }
}