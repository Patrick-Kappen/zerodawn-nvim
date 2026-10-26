local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/a", "p")
vim.fn.mkdir(tmp .. "/b", "p")
local log = tmp .. "/calls"
local fake = tmp .. "/pair"
-- The fake pair script logs its arguments; "open" exits with the code in the file exit, default 0.
vim.fn.writefile({
  "#!" .. vim.fn.exepath("bash"),
  'printf "%s\\n" "$*" >> ' .. vim.fn.shellescape(log),
  "if [[ $3 == open && -f " .. vim.fn.shellescape(tmp .. "/exit") .. " ]]; then exit $(<" .. vim.fn.shellescape(
    tmp .. "/exit"
  ) .. "); fi",
}, fake)
vim.fn.setfperm(fake, "rwx------")

local function calls()
  return vim.fn.filereadable(log) == 1 and vim.fn.readfile(log) or {}
end
local function wait(cond, what)
  assert(vim.wait(2000, cond, 20), "timeout: " .. what)
end

local pair = require("zerodawn.pair")

assert(not pcall(pair.setup, { command = "/no/such/file", tmux = "tmux", terminal = { "true" } }))
assert(not pcall(pair.setup, { command = fake, tmux = "tmux", terminal = {} }))

local switched
pair.setup({
  command = fake,
  tmux = "tmuxw",
  terminal = { fake, "terminal" },
  switch = function(dir)
    switched = dir
    vim.cmd.cd(dir)
  end,
})
vim.cmd.cd(tmp .. "/a")

-- start opens the terminal with the attach command for this server and folder
local server = vim.v.servername
assert(server ~= "", "headless nvim has no server address")
pair.start()
assert(pair.active())
wait(function()
  return #calls() == 1
end, "attach call")
assert(
  calls()[1] == ("terminal %s --tmux tmuxw attach %s %s"):format(fake, server, tmp .. "/a"),
  "attach call: " .. calls()[1]
)

-- a folder change in nvim moves tmux
vim.cmd.cd(tmp .. "/b")
wait(function()
  return #calls() == 2
end, "open call")
assert(calls()[2] == ("--tmux tmuxw open %s %s"):format(server, tmp .. "/b"), "open call: " .. calls()[2])

-- tmux asks to follow: nvim switches folder
pair.follow(tmp .. "/a")
wait(function()
  return switched == tmp .. "/a"
end, "follow switch")

-- follow to the same folder does nothing
switched = nil
pair.follow(tmp .. "/a")
vim.wait(100)
assert(switched == nil, "follow to the same folder switched")

-- a modified buffer blocks follow and sends tmux back
local before = #calls()
vim.cmd.enew()
vim.api.nvim_buf_set_name(0, tmp .. "/a/file.txt")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
pair.follow(tmp .. "/b")
wait(function()
  return #calls() > before
end, "open back")
assert(switched == nil, "follow switched with a modified buffer")
assert(calls()[#calls()]:find(" open " .. server .. " " .. tmp .. "/a", 1, true), "open back: " .. calls()[#calls()])
vim.bo.modified = false

-- exit 3 from open stops the pair
vim.fn.writefile({ "3" }, tmp .. "/exit")
vim.cmd.cd(tmp .. "/b")
wait(function()
  return not pair.active()
end, "pair stopped")

-- no event when the pair is off
before = #calls()
vim.cmd.cd(tmp .. "/a")
vim.wait(200)
assert(#calls() == before, "open called while the pair is off")
