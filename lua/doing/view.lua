local View = {}

--- Weather the winbar should visible, when view_enabled is true, and there are items in the list
---@param state DoState
---@return boolean
function View.is_visible(state)
  return state.view_enabled and state.tasks:has_items() or not not state.message
end

---Create a winbar string for the current task
---@param state DoState
---@return string
function View.render(state)
  if not View.is_visible(state) then
    return ""
  end

  -- using pcall so that it won't spam error messages
  local ok, display = pcall(function()
    local count = state.tasks:count()
    local left = ""
    local right = ""
    local aligned = false
    local current = state.tasks:current()

    if state.message then
      return state.message
    end

    if count == 0 then
      return ""
    end

    left = state.options.doing_prefix .. current

    -- append task count number if there is more than 1 task
    if count > 1 then
      right = '+' .. (count - 1) .. " more"
      aligned = true
    end

    if not state.tasks.file then
      left = left .. (aligned and "" or "%=") .. "(:DoSave)"
    end

    local middle = string.rep(' ', vim.fn.winwidth(0) - string.len(left) - string.len(right) - 4)
    return left .. middle .. right
  end)

  if not ok then
    return "ERR: " .. display
  end

  return display
end

function View.render_inactive(state)
  if not View.is_visible(state) then
    return ""
  end

  return "  "
end

View.stl = "%!v:lua.DoStatusline('active')"
View.stl_nc = "%!v:lua.DoStatusline('inactive')"

return View
