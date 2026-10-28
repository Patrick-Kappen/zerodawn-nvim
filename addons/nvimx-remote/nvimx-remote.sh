# shellcheck shell=bash
if [[ $# -ne 2 ]]; then
  echo "usage: nvimx-remote HOST NAME   (HOST from your ssh config, NAME of the nvim@NAME server, for example: nvimx-remote gaia main)" >&2
  exit 2
fi
host="$1"
name="$2"

if [[ ! $name =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "nvimx-remote: NAME must use only letters, digits, - and _; got: $name" >&2
  exit 2
fi

# The ssh of the system, not of nixpkgs: the macOS ssh reads UseKeychain and the agent of the login session.
command -v ssh >/dev/null || {
  echo "nvimx-remote: no ssh on PATH; install OpenSSH" >&2
  exit 1
}

# NAME is checked above, so it is safe to expand on this side.
# shellcheck disable=SC2029
remote_runtime="$(ssh "$host" "systemctl --user start nvim@${name}.service && printf '%s' \"\$XDG_RUNTIME_DIR\"")" || {
  echo "nvimx-remote: cannot start nvim@${name} on ${host}; run: ssh ${host} journalctl --user -u nvim@${name}" >&2
  exit 1
}
if [[ -z $remote_runtime ]]; then
  echo "nvimx-remote: XDG_RUNTIME_DIR is empty on ${host}; log in on ${host} once so systemd starts your user session" >&2
  exit 1
fi
remote_socket="${remote_runtime}/nvim/${name}.sock"

local_dir="${TMPDIR:-/tmp}/nvimx-remote"
mkdir -p "$local_dir"
chmod 700 "$local_dir"
local_socket="${local_dir}/${host}-${name}.sock"
rm -f "$local_socket"

ssh -N -o ExitOnForwardFailure=yes -o StreamLocalBindUnlink=yes -L "${local_socket}:${remote_socket}" "$host" &
tunnel=$!
trap 'kill "$tunnel" 2>/dev/null; rm -f "$local_socket"' EXIT

for _ in $(seq 100); do
  [[ -S $local_socket ]] && break
  kill -0 "$tunnel" 2>/dev/null || {
    echo "nvimx-remote: the ssh tunnel to ${host} stopped; run: ssh -v -N -L ${local_socket}:${remote_socket} ${host}" >&2
    exit 1
  }
  sleep 0.1
done
if [[ ! -S $local_socket ]]; then
  echo "nvimx-remote: no tunnel socket at ${local_socket} after 10 seconds; check the ssh connection to ${host}" >&2
  exit 1
fi

neovide --server "$local_socket"
