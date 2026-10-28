local M = {}

local opts
local state = { scope = nil, mode = nil }

local KIND_HL = { worktree = "Special", project = "Directory" }

local function notify(message, level)
  vim.notify("projects: " .. message, level or vim.log.levels.INFO)
end

local function command(...)
  return vim.list_extend({ opts.command, "--tmux", opts.tmux }, { ... })
end

local function run(cmd, cwd)
  local result = vim.system(cmd, { text = true, cwd = cwd }):wait()
  if result.code ~= 0 then
    error(("projects: %s failed: %s"):format(table.concat(cmd, " "), vim.trim(result.stderr)))
  end
  return result.stdout
end

-- git is optional here: outside a repo the picker still shows open worktrees and projects.
local function git(args, cwd)
  local result = vim.system(vim.list_extend({ "git" }, args), { text = true, cwd = cwd }):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr)
  end
  return vim.trim(result.stdout)
end

local function set_text(item)
  item.text = table.concat({ item.kind, item.branch or "", item.file }, " ")
end

local function open_entries()
  local out = run(command("list"))
  local items = {}
  for line in (out .. "\n"):gmatch("(.-)\n") do
    if line ~= "" then
      local repo, worktree, window, agent = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$")
      if not repo then
        error(
          ("projects: %s list printed a line that is not REPO<TAB>WORKTREE<TAB>WINDOW<TAB>AGENT: %s"):format(
            opts.command,
            line
          )
        )
      end
      local item = {
        kind = "worktree",
        file = vim.fs.normalize(worktree),
        repo = vim.fs.normalize(repo),
        window = window,
        open = true,
        agent = agent == "1",
        worktree = true,
      }
      set_text(item)
      items[#items + 1] = item
    end
  end
  return items
end

local function repo_worktrees()
  local common = git({ "rev-parse", "--path-format=absolute", "--git-common-dir" }, vim.fn.getcwd())
  if not common then
    return {}
  end
  local repo = vim.fs.dirname(common)
  local out = git({ "worktree", "list", "--porcelain" }, repo)
  if not out then
    return {}
  end
  local items, item = {}, nil
  for line in (out .. "\n\n"):gmatch("(.-)\n") do
    if line:match("^worktree ") then
      item = { kind = "worktree", file = line:sub(10), repo = repo, worktree = true }
    elseif item and line:match("^branch ") then
      item.branch = line:gsub("^branch refs/heads/", "")
    elseif item and line == "detached" then
      item.branch = "detached"
    elseif item and line == "bare" then
      item.bare = true
    elseif line == "" then
      if item and not item.bare then
        item.file = vim.fs.normalize(item.file)
        set_text(item)
        items[#items + 1] = item
      end
      item = nil
    end
  end
  return items
end

local function mark_open(items)
  local open = {}
  for _, entry in ipairs(open_entries()) do
    local seen = open[entry.file]
    open[entry.file] = { window = seen and seen.window or entry.window, agent = entry.agent or (seen and seen.agent) }
  end
  for _, item in ipairs(items) do
    local entry = open[item.file]
    if entry then
      item.open = true
      item.agent = entry.agent
      item.window = entry.window
    end
  end
  return items
end

local function worktree_items()
  local items = mark_open(repo_worktrees())
  table.sort(items, function(a, b)
    if a.open ~= b.open then
      return a.open
    end
    return a.file < b.file
  end)
  return items
end

local function project_items()
  local out = run({ opts.zoxide, "query", "-l" })
  local items, seen = {}, {}
  for line in (out .. "\n"):gmatch("(.-)\n") do
    local dir = vim.fs.normalize(vim.trim(line))
    if dir ~= "" and not seen[dir] and vim.fn.isdirectory(dir) == 1 then
      seen[dir] = true
      local item = { kind = "project", file = dir }
      set_text(item)
      items[#items + 1] = item
    end
  end
  return mark_open(items)
end

local NEXT_SCOPE = { open = "worktrees", worktrees = "projects", projects = "open" }

local function find()
  if state.scope == "open" then
    return open_entries()
  elseif state.scope == "worktrees" then
    return worktree_items()
  end
  return project_items()
end

local function title()
  return ("Projects · %s · <Tab> %s · Enter switch · type a path · Ctrl-n new · Ctrl-d delete"):format(
    state.scope,
    NEXT_SCOPE[state.scope]
  )
end

local function set_mode(picker, mode, text, query)
  state.mode = mode
  picker.mode = mode
  picker.input:set(query, "")
  picker.title = text
  picker:update_titles()
end

local function format(item)
  local ret = {
    item.open and { "● ", "Special" } or { "  ", "Comment" },
    item.agent and { "π ", "DiagnosticWarn" } or { "  ", "Comment" },
    { ("%-9s"):format(item.kind), KIND_HL[item.kind] or "Normal" },
  }
  if item.branch then
    ret[#ret + 1] = { "\u{e725} " .. item.branch .. "  ", "Special" }
  end
  ret[#ret + 1] = { item.file, "Normal" }
  return ret
end

local function switch(dir)
  dir = vim.fs.normalize(dir)
  if dir == vim.fs.normalize(vim.fn.getcwd()) then
    return
  end
  opts.switch(dir)
end

local function typed_folder(query)
  if not query:match("^[~/.]") then
    return nil
  end
  local dir = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(query), ":p"))
  if vim.fn.isdirectory(dir) == 1 then
    return dir
  end
end

local function copy_ignored(from, to)
  local out, err = git({ "ls-files", "--others", "--ignored", "--exclude-standard", "--directory", "-z" }, from)
  if not out then
    notify("list ignored files in " .. from .. " failed: " .. err, vim.log.levels.ERROR)
    return
  end
  local copied = {}
  for rel in out:gmatch("[^%z]+") do
    local src = from .. "/" .. rel
    local stat = vim.uv.fs_lstat(src)
    if stat and stat.type == "file" then
      local dest = to .. "/" .. rel
      vim.fn.mkdir(vim.fs.dirname(dest), "p")
      local ok, copy_err = vim.uv.fs_copyfile(src, dest)
      if not ok then
        notify("copy " .. src .. " failed: " .. tostring(copy_err), vim.log.levels.ERROR)
        return
      end
      copied[#copied + 1] = rel
    end
  end
  if #copied > 0 then
    notify("copied ignored files: " .. table.concat(copied, ", "))
  end
end

local function make_worktree(picker, branch)
  if branch == "" then
    notify("type a branch name for the new worktree", vim.log.levels.WARN)
    return
  end
  local common = git({ "rev-parse", "--path-format=absolute", "--git-common-dir" }, vim.fn.getcwd())
  if not common then
    notify("the current folder is not in a git repo; go to a repo first", vim.log.levels.WARN)
    return
  end
  local repo_dir = vim.fs.dirname(common)
  local slug = branch:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
  local path = ("%s/%s/%s"):format(opts.worktree_root, vim.fs.basename(repo_dir), slug)
  local args
  if git({ "show-ref", "--verify", "--quiet", "refs/heads/" .. branch }, repo_dir) then
    args = { "worktree", "add", path, branch }
  else
    local base = git({ "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, repo_dir)
    if not base then
      notify("no default branch for origin; run `git remote set-head origin -a`", vim.log.levels.WARN)
      return
    end
    args = { "worktree", "add", "-b", branch, path, base }
  end
  local _, err = git(args, repo_dir)
  if err then
    notify("git worktree add " .. path .. " failed: " .. err, vim.log.levels.ERROR)
    return
  end
  picker:close()
  copy_ignored(repo_dir, path)
  switch(path)
end

local function remove_worktree(picker, item)
  if not item or not item.worktree then
    notify("choose a worktree (a line with a branch)", vim.log.levels.WARN)
    return
  end
  if item.file == vim.fs.normalize(vim.fn.getcwd()) then
    notify("switch to another folder first", vim.log.levels.WARN)
    return
  end
  if item.agent and not opts.confirm(("pi runs in %s. Delete it?"):format(item.file)) then
    notify("delete cancelled")
    return
  end
  local _, err = git({ "worktree", "remove", item.file }, item.repo or vim.fn.getcwd())
  if err then
    notify("git worktree remove " .. item.file .. " failed: " .. err, vim.log.levels.ERROR)
    return
  end
  notify("worktree deleted: " .. item.file)
  set_mode(picker, nil, title(), "")
  picker:find()
end

local function new_worktree(picker)
  set_mode(picker, "new", "New worktree · type the branch name · Enter creates it · Esc cancels", "")
end

local function delete_worktree(picker)
  set_mode(picker, "delete", "Delete worktree · search it · Enter deletes it · Esc cancels", "worktree ")
end

local function toggle_scope(picker)
  state.scope = NEXT_SCOPE[state.scope]
  picker.title = title()
  picker:update_titles()
  picker:find()
end

local function enter(picker)
  local query = vim.trim(picker.input:get())
  if state.mode == "new" then
    make_worktree(picker, query)
  elseif state.mode == "delete" then
    remove_worktree(picker, picker:current())
  else
    local dir = typed_folder(query)
    if dir then
      picker:close()
      switch(dir)
    else
      picker:action("confirm")
    end
  end
end

local function confirm(picker, item)
  picker:close()
  if item then
    switch(item.file)
  end
end

local function snacks()
  if opts.snacks then
    return opts.snacks
  end
  local ok, module = pcall(require, "snacks")
  if not ok then
    error(
      "projects: cannot load snacks.nvim; put it on the runtimepath and call require('snacks').setup(): "
        .. tostring(module)
    )
  end
  return module
end

local function check(o)
  vim.validate("opts", o, "table")
  vim.validate("opts.command", o.command, "string")
  vim.validate("opts.tmux", o.tmux, "string")
  vim.validate("opts.zoxide", o.zoxide, "string", true)
  vim.validate("opts.worktree_root", o.worktree_root, "string", true)
  vim.validate("opts.switch", o.switch, "function", true)
  vim.validate("opts.confirm", o.confirm, "function", true)
  vim.validate("opts.snacks", o.snacks, "table", true)
  if vim.fn.executable(o.command) ~= 1 then
    error(
      ("projects: opts.command %s is not executable; give the path of the zerodawn-tmux pair script"):format(o.command)
    )
  end
  local zoxide = o.zoxide or "zoxide"
  if vim.fn.executable(zoxide) ~= 1 then
    error(("projects: opts.zoxide %s is not executable; install zoxide or give its path"):format(zoxide))
  end
  if o.tmux == "" then
    error("projects: opts.tmux is empty; give the tmux command that loads your config")
  end
end

--- opts.command: path of the pair script of the zerodawn-tmux addon pair.
--- opts.tmux: the tmux command that loads your config.
--- opts.zoxide: the zoxide command, default "zoxide"; its recent folders are the projects.
--- opts.worktree_root: where Ctrl-n makes worktrees, default "~/.worktrees".
--- opts.switch: function(dir) that changes the folder; default require("zerodawn.pair").follow.
--- opts.confirm: function(question) that returns true to delete; default vim.fn.confirm.
--- opts.snacks: the module that has picker, for tests; default require("snacks").
function M.setup(o)
  check(o)
  opts = {
    command = o.command,
    tmux = o.tmux,
    zoxide = o.zoxide or "zoxide",
    worktree_root = vim.fs.normalize(o.worktree_root or "~/.worktrees"),
    switch = o.switch or function(dir)
      require("zerodawn.pair").follow(dir)
    end,
    confirm = o.confirm or function(question)
      return vim.fn.confirm("projects: " .. question, "&Delete\n&Cancel", 2) == 1
    end,
    snacks = o.snacks,
  }
  state = { scope = nil, mode = nil }
end

--- Open the picker on the open worktrees; Tab goes to the worktrees of this repo, then to the projects.
function M.pick()
  assert(opts, "projects: call require('zerodawn.projects').setup() first")
  state.scope = "open"
  state.mode = nil
  return snacks().picker.pick({
    title = title(),
    layout = { preset = "dropdown", preview = false },
    finder = find,
    format = format,
    confirm = confirm,
    actions = {
      enter = enter,
      toggle_scope = toggle_scope,
      new_worktree = new_worktree,
      delete_worktree = delete_worktree,
    },
    win = {
      input = {
        keys = {
          ["<cr>"] = { "enter", mode = { "n", "i" } },
          ["<tab>"] = { "toggle_scope", mode = { "n", "i" } },
          ["<c-n>"] = { "new_worktree", mode = { "n", "i" } },
          ["<c-d>"] = { "delete_worktree", mode = { "n", "i" } },
        },
      },
    },
  })
end

return M
