local script = vim.fs.normalize(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)) .. "/../nvimx-remote.sh")

local function run(args, env)
  local cmd = vim.list_extend({ "bash", script }, args)
  return vim.system(cmd, { text = true, env = env, clear_env = env ~= nil }):wait()
end

local function expect(result, code, needle)
  assert(result.code == code, ("exit %d, want %d; stderr: %s"):format(result.code, code, result.stderr))
  assert(result.stderr:find(needle, 1, true), ("stderr has no %q: %s"):format(needle, result.stderr))
end

expect(run({}), 2, "usage: nvimx-remote HOST NAME")
expect(run({ "gaia" }), 2, "usage: nvimx-remote HOST NAME")
expect(run({ "gaia", "main", "extra" }), 2, "usage: nvimx-remote HOST NAME")
expect(run({ "gaia", "main;rm" }), 2, "NAME must use only letters")
expect(run({ "gaia", "../x" }), 2, "NAME must use only letters")

local empty = vim.fn.tempname()
vim.fn.mkdir(empty, "p")
local bash_dir = vim.fs.dirname(vim.fn.exepath("bash"))
local link = empty .. "/bash"
assert(vim.uv.fs_symlink(bash_dir .. "/bash", link))
expect(run({ "gaia", "main" }, { PATH = empty }), 1, "no ssh on PATH")
