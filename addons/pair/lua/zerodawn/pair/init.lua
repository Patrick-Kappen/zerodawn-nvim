local M = {}

local opts
local active = false
local group = vim.api.nvim_create_augroup("zerodawn.pair", { clear = true })

local function notify(message, level)
  vim.notify("pair: " .. message, level or vim.log.levels.INFO)
end

local function command(...)
  return vim.list_extend({ opts.command, "--tmux", opts.tmux }, { ... })
end

local function modified_buffers()
  local names = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified and vim.bo[buf].buftype == "" then
      table.insert(names, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:."))
    end
  end
  return names
end

-- Move the paired tmux clients to dir. Exit 3 means no client is paired any more.
local function open(dir)
  vim.system(command("open", vim.v.servername, dir), { text = true }, function(result)
    vim.schedule(function()
      if result.code == 3 then
        active = false
        notify("no tmux client is paired any more; pair stopped. Press the pair key to start it again.")
      elseif result.code ~= 0 then
        notify(vim.trim(result.stderr), vim.log.levels.ERROR)
      end
    end)
  end)
end

local function check(o)
  vim.validate("opts", o, "table")
  vim.validate("opts.command", o.command, "string")
  vim.validate("opts.tmux", o.tmux, "string")
  vim.validate("opts.terminal", o.terminal, "table")
  vim.validate("opts.switch", o.switch, "function", true)
  if vim.fn.executable(o.command) ~= 1 then
    error(("pair: opts.command %s is not executable; give the path of the zerodawn-tmux pair script"):format(o.command))
  end
  if #o.terminal == 0 then
    error("pair: opts.terminal is empty; give the terminal command, for example { 'wezterm', 'start', '--' }")
  end
end

--- opts.command: path of the pair script of the zerodawn-tmux addon pair.
--- opts.tmux: the tmux command that loads your config.
--- opts.terminal: the command that opens a terminal; the attach command is added at the end.
--- opts.switch: function(dir) that changes the folder; default vim.cmd.cd.
function M.setup(o)
  check(o)
  opts = o
  vim.api.nvim_clear_autocmds({ group = group })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    pattern = "global",
    callback = function()
      if active then
        open(vim.fn.getcwd())
      end
    end,
  })
end

function M.active()
  return active
end

--- Open a terminal on the tmux window of the current folder, paired with this nvim server.
--- When a tmux client is already paired, move it to the current folder and open no terminal.
function M.start()
  assert(opts, "pair: call require('zerodawn.pair').setup() first")
  if vim.v.servername == "" then
    error("pair: this nvim has no server address; start it with --listen or use nvimx-gui")
  end
  local moved = vim.system(command("open", vim.v.servername, vim.fn.getcwd()), { text = true }):wait()
  if moved.code == 0 then
    active = true
    notify("a tmux client is already paired; it shows " .. vim.fn.getcwd())
    return
  elseif moved.code ~= 3 then
    error(("pair: %s open failed: %s"):format(opts.command, vim.trim(moved.stderr)))
  end
  local cmd = vim.list_extend(vim.deepcopy(opts.terminal), command("attach", vim.v.servername, vim.fn.getcwd()))
  local ok, err = pcall(vim.system, cmd, { detach = true })
  if not ok then
    error(("pair: cannot start the terminal %s: %s"):format(opts.terminal[1], err))
  end
  active = true
end

function M.stop()
  active = false
end

--- Called by tmux over RPC when a paired client changes window. Returns at once; the work runs later.
function M.follow(dir)
  vim.schedule(function()
    if not opts then
      notify(
        "tmux asked to follow, but setup() did not run; call require('zerodawn.pair').setup()",
        vim.log.levels.ERROR
      )
      return
    end
    active = true
    if vim.fs.normalize(dir) == vim.fs.normalize(vim.fn.getcwd()) then
      return
    end
    local changed = modified_buffers()
    if #changed > 0 then
      notify(("save or discard %s first; tmux goes back to %s"):format(table.concat(changed, ", "), vim.fn.getcwd()))
      open(vim.fn.getcwd())
      return
    end
    (opts.switch or vim.cmd.cd)(dir)
  end)
  return ""
end

return M
