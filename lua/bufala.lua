-- Bufala is a Neovim plugin designed to make buffers more ergonomic.
-- Bufala wraps many of the more arcane <C-w> commands in functions
-- that, if nothing else, suit the author's use-case. Bufala is a
-- refinement of the buffer management in dbm.nvim, itself inspired
-- by tiling window managers.

M = {}
M.state = {}
M.state.layout = nil -- implemented layouts are stack, row, spiral, and dwindle.
M.state.last_split = nil

-- Go to the next buffer on screen in order of creation
M.cycle = function(count)
  if count == nil then count = '' end
  return vim.cmd(count .. ' wincmd w')
end

-- Swap the current buffer with the first / main buffer
M.focus = function()
  local a_buffer_number = vim.fn.bufnr()

  vim.cmd('1000000 wincmd h')
  vim.cmd('1000000 wincmd k')

  local b_buffer_number = vim.fn.bufnr()

  -- do nothing if first buffer
  if a_buffer_number == b_buffer_number then return 0 end

  vim.cmd(':buffer ' .. a_buffer_number)
  vim.cmd('wincmd p')
  vim.cmd(':buffer ' .. b_buffer_number)

  return vim.cmd('wincmd p')
end

-- Open a split in any direction or per layout configuration
M.split = function(direction, name)
  local window_count = #vim.api.nvim_list_wins()

  local splitUp = function()
    M.state.last_split = 'up'
    return vim.cmd('aboveleft split ' .. name)
  end

  local splitDown = function()
    M.state.last_split = 'down'
    return vim.cmd('belowright split ' .. name)
  end

  local splitLeft = function()
    M.state.last_split = 'left'
    return vim.cmd('aboveleft  vsplit ' .. name)
  end

  local splitRight = function()
    M.state.last_split = 'right'
    return vim.cmd('belowright vsplit ' .. name)
  end

  -- Open a blank buffer if no name given
  if name == nil then name = '' end

  -- Stack layout:
  --
  --          | Buffer 2
  -- Buffer 1 +--------
  --          | Buffer 2
  --
  if direction == nil and M.state.layout == 'stack' then
    vim.cmd('windo $')
    if window_count > 1 then return splitDown() end
    return splitRight()
  end

  -- Row layout:
  --
  --        Buffer 1
  -- ---------+---------
  -- Buffer 2 | Buffer 3 
  --
  if direction == nil and M.state.layout == 'row' then
    vim.cmd('windo $')
    if window_count > 1 then return splitRight() end
    return splitDown()
  end

  if direction == 'up'    then return splitUp()    end
  if direction == 'down'  then return splitUp()    end
  if direction == 'left'  then return splitLeft()  end
  if direction == 'right' then return splitRight() end

  print('No direction given, and no default layout specified.')

  return 0
end

-- Swap the current and last buffer windows' positions
M.swap = function()
  local a_buffer_number = vim.fn.bufnr()
  vim.cmd('wincmd p')
  local b_buffer_number = vim.fn.bufnr()
  vim.cmd(':buffer ' .. a_buffer_number)
  vim.cmd('wincmd p')
  return vim.cmd(':buffer ' .. b_buffer_number)
end

-- Handle command input
M.cmd = function(args)
  local string2list = function(string)
    local list = {}
    for each in string:gmatch("%w+") do table.insert(list, each) end
    return list
  end

  local parsed = string2list(args.args)

  local opts = {
    subcmd = parsed[1],
    arg1   = parsed[2],
    arg2   = parsed[3]
  }

  if opts.subcmd == 'cycle' then M.cycle(opts.arg1)            end
  if opts.subcmd == 'focus' then M.focus()                     end
  if opts.subcmd == 'split' then M.split(opts.arg1, opts.arg2) end
  if opts.subcmd == 'swap'  then M.swap()                      end
end

M.setup = function(opts)
  -- TODO: figure out how to get multiple "levels" of completion,
  -- so that, e.g., `Bufala split` will suggest left, right, etc.
  local completion = function(_, _, _)
    return {
      'cycle',
      'focus',
      'split',
      'swap'
    }
  end

  if opts.layout ~= nil then M.state.layout = opts.layout end

  vim.api.nvim_create_user_command(
    'Bufala',
    M.cmd,
    {nargs = '*', complete = completion
  })
end

return M
