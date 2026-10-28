local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
vim.cmd.cd(tmp)

local function write(path, lines)
  vim.fn.writefile(lines, path)
end

local function script(name, lines)
  local path = tmp .. "/" .. name
  write(path, vim.list_extend({ "#!" .. vim.fn.exepath("bash") }, lines))
  vim.fn.setfperm(path, "rwx------")
  return path
end

local function sh(cmd)
  local out = vim.fn.system(cmd)
  assert(vim.v.shell_error == 0, table.concat(cmd, " ") .. ": " .. out)
  return out
end

local pair_log = tmp .. "/pair-calls"
local list = tmp .. "/list"
local pair = script("pair", {
  'printf "%s\\n" "$*" >> ' .. vim.fn.shellescape(pair_log),
  "if [[ $3 == list ]]; then cat " .. vim.fn.shellescape(list) .. "; fi",
})
local fail = script("pair-fail", {
  'if [[ $3 == list ]]; then echo "no tmux server" >&2; exit 1; fi',
})
local recent = tmp .. "/recent"
local zoxide_log = tmp .. "/zoxide-calls"
local zoxide = script("zoxide", {
  'printf "%s\\n" "$*" >> ' .. vim.fn.shellescape(zoxide_log),
  "cat " .. vim.fn.shellescape(recent),
})

local followed
package.preload["zerodawn.pair"] = function()
  return {
    follow = function(dir)
      followed = dir
    end,
  }
end

local spec
local picker
local function make_picker(query, current)
  local self = { title = "", mode = nil, closed = false, finds = 0, query = query or "" }
  self.input = {
    get = function()
      return self.query
    end,
    set = function(_, value)
      self.query = value
    end,
  }
  self.current = function()
    return current
  end
  self.close = function()
    self.closed = true
  end
  self.action = function(_, name)
    self.action_name = name
  end
  self.find = function()
    self.finds = self.finds + 1
  end
  self.update_titles = function() end
  return self
end
local snacks = {
  picker = {
    pick = function(pick_spec)
      spec = pick_spec
      return picker
    end,
  },
}

local projects = require("zerodawn.projects")

local function open(query, current)
  picker = make_picker(query, current)
  return projects.pick()
end

local function setup(extra)
  projects.setup(vim.tbl_extend("force", {
    command = pair,
    tmux = "tmux",
    zoxide = zoxide,
    worktree_root = tmp .. "/worktrees",
    snacks = snacks,
  }, extra or {}))
end

-- setup fails loud for a missing input
assert(not pcall(projects.pick), "pick before setup did not fail")
local ok, err = pcall(projects.setup, { command = "/no/such/pair", tmux = "tmux", zoxide = zoxide, snacks = snacks })
assert(not ok and err:find("not executable"), "bad command: " .. tostring(err))
ok, err = pcall(projects.setup, { command = pair, tmux = "tmux", zoxide = "/no/such/zoxide", snacks = snacks })
assert(not ok and err:find("zoxide"), "bad zoxide: " .. tostring(err))
ok, err = pcall(projects.setup, { command = pair, tmux = "", zoxide = zoxide, snacks = snacks })
assert(not ok and err:find("tmux"), "empty tmux: " .. tostring(err))

vim.fn.mkdir(tmp .. "/wt1", "p")
vim.fn.mkdir(tmp .. "/wt2", "p")
vim.fn.mkdir(tmp .. "/proj1", "p")
vim.fn.mkdir(tmp .. "/proj2", "p")
write(recent, { tmp .. "/proj1", tmp .. "/proj2", tmp .. "/gone" })

-- the default scope is the open worktree windows, marked open and with the pi mark
write(list, { "repo\t" .. tmp .. "/wt1\t%1\t1", "repo\t" .. tmp .. "/wt2\t%2\t0" })
setup()
assert(open() == picker, "pick does not return the picker")
assert(vim.fn.maparg("<A-p>", "n") == "" and vim.fn.maparg("<leader>p", "n") == "", "the addon bound a key")
local items = spec.finder()
assert(#items == 2, "default items: " .. vim.inspect(items))
assert(spec.title:find("· open · <Tab>", 1, true), "default title: " .. spec.title)
assert(items[1].open and items[1].agent, "first entry is not an open pi entry")
assert(items[1].file == tmp .. "/wt1" and items[1].text:find("wt1", 1, true), "first entry path")
assert(items[2].open and not items[2].agent, "second entry marks")
assert(vim.fn.readfile(pair_log)[1] == "--tmux tmux list", "pair call: " .. vim.inspect(vim.fn.readfile(pair_log)))

-- with nothing open the picker still starts on the open scope, and it is empty
write(list, {})
open()
assert(spec.title:find("· open · <Tab>", 1, true), "empty open title: " .. spec.title)
assert(#spec.finder() == 0, "open scope is not empty")

-- Tab goes from open to worktrees, to projects, and back to open
write(list, { "repo\t" .. tmp .. "/proj2\t%1\t1", "repo\t" .. tmp .. "/proj2\t%2\t0" })
open()
spec.actions.toggle_scope(picker)
assert(picker.finds == 1 and picker.title:find("· worktrees · <Tab>", 1, true), "tab to worktrees: " .. picker.title)
assert(#spec.finder() == 0, "worktrees outside a repo: " .. vim.inspect(spec.finder()))
spec.actions.toggle_scope(picker)
assert(picker.finds == 2 and picker.title:find("· projects · <Tab>", 1, true), "tab to projects: " .. picker.title)
items = spec.finder()
assert(#items == 2, "project items: " .. vim.inspect(items))
assert(items[1].kind == "project" and items[1].file == tmp .. "/proj2", "the open project is not first")
assert(items[1].open and items[1].agent, "an open project is not marked open")
assert(items[2].file == tmp .. "/proj1", "second project")
assert(not items[2].open and not items[2].agent, "a closed project is marked open")
assert(vim.fn.readfile(zoxide_log)[1] == "query -l", "zoxide call: " .. vim.inspect(vim.fn.readfile(zoxide_log)))
spec.actions.toggle_scope(picker)
assert(picker.finds == 3 and picker.title:find("· open · <Tab>", 1, true), "tab to open: " .. picker.title)

-- a typed folder switches there
local typed = tmp .. "/typed"
vim.fn.mkdir(typed, "p")
open(typed)
followed = nil
spec.actions.enter(picker)
assert(followed == typed, "typed path not switched: " .. tostring(followed))
assert(picker.closed, "typed path did not close the picker")

-- Enter on an entry switches through zerodawn.pair
followed = nil
open()
items = spec.finder()
spec.confirm(picker, items[1])
assert(followed == items[1].file, "entry not switched: " .. tostring(followed))
assert(picker.closed, "entry did not close the picker")

-- Ctrl-n makes a worktree and switches to it
local repo = tmp .. "/repo"
vim.fn.mkdir(repo, "p")
sh({ "git", "init", "-b", "main", repo })
sh({ "git", "-C", repo, "config", "user.email", "test@example.com" })
sh({ "git", "-C", repo, "config", "user.name", "Test" })
write(repo .. "/file", { "x" })
sh({ "git", "-C", repo, "add", "file" })
sh({ "git", "-C", repo, "-c", "commit.gpgsign=false", "commit", "-m", "init" })
sh({ "git", "-C", repo, "branch", "feature" })
vim.cmd.cd(repo)
write(list, {})
write(recent, {})
setup()
open()
spec.actions.new_worktree(picker)
assert(picker.mode == "new" and picker.query == "", "new mode: " .. tostring(picker.query))
picker.query = "feature"
spec.actions.enter(picker)
local wt = tmp .. "/worktrees/repo/feature"
assert(vim.fn.isdirectory(wt) == 1, "worktree not made: " .. wt)
assert(followed == wt, "new worktree not switched: " .. tostring(followed))
assert(picker.closed, "new worktree did not close the picker")

-- the worktrees scope lists the worktrees of this repo, the open ones first
write(list, { "repo\t" .. wt .. "\t%3\t0" })
open()
spec.actions.toggle_scope(picker)
items = spec.finder()
assert(#items == 2, "repo worktrees: " .. vim.inspect(items))
assert(items[1].file == wt and items[1].open and items[1].branch == "feature", "open worktree first")
assert(items[2].file == vim.fs.normalize(vim.uv.fs_realpath(repo)) and not items[2].open, "main worktree")
assert(items[2].current and not items[1].current, "the current folder is not marked: " .. vim.inspect(items))
assert(spec.format(items[2])[1][1] == "▶ ", "the current mark does not show: " .. vim.inspect(spec.format(items[2])))
assert(spec.format(items[1])[1][1] == "  ", "another entry shows the current mark")
write(list, {})

-- Ctrl-d deletes a worktree, and asks first when pi runs there
local answer = false
setup({
  confirm = function(question)
    assert(question:find("pi runs", 1, true), "confirm question: " .. question)
    return answer
  end,
})
local entry = { kind = "worktree", file = wt, repo = repo, worktree = true, agent = true, text = "worktree " .. wt }
open(nil, entry)
spec.actions.delete_worktree(picker)
assert(picker.mode == "delete" and picker.query == "worktree ", "delete mode")
spec.actions.enter(picker)
assert(vim.fn.isdirectory(wt) == 1, "deleted without confirmation")
answer = true
spec.actions.delete_worktree(picker)
spec.actions.enter(picker)
assert(vim.fn.isdirectory(wt) == 0, "worktree not deleted")
assert(picker.mode == nil and picker.finds == 1, "delete did not return to the list")

-- a line that is not the pair list contract is an error
write(list, { "not a pair line" })
open()
ok, err = pcall(spec.finder)
assert(not ok and err:find("REPO<TAB>", 1, true), "bad pair line: " .. tostring(err))

-- a failing pair command is an error that names the command
setup({ command = fail })
write(list, {})
open()
ok, err = pcall(spec.finder)
assert(
  not ok and err:find("failed", 1, true) and err:find("no tmux server", 1, true),
  "pair failure: " .. tostring(err)
)
