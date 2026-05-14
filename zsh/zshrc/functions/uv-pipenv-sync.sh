# Function to install pipenv stuff with uv
uv-pipenv-sync() {
  # 1. Python version detection from Pipfile
  # Specifically targets the value assigned to python_full_version or python_version
  local py_version
  py_version=$(sed -n 's/.*python_.*version.*=.*"\([^"]*\)".*/\1/p' Pipfile | head -n 1)

  if [[ -z "$py_version" ]]; then
    echo "Python version not found in Pipfile, using system default."
  else
    echo "Detected Python: $py_version"
  fi

  # 2. Create/Update .venv
  # If the existing .venv doesn't match the Pipfile version, we rebuild it
  if [[ -d .venv ]]; then
    local current_venv_ver=$(.venv/bin/python --version 2>/dev/null | cut -d' ' -f2)
    if [[ -n "$py_version" && "$current_venv_ver" != "$py_version"* ]]; then
      echo "Python version changed ($current_venv_ver -> $py_version). Rebuilding .venv..."
      rm -rf .venv
    fi
  fi

  if [[ ! -d .venv ]]; then
    uv venv .venv ${py_version:+"--python" "$py_version"} || return 1
  fi

  # 3. Convert Pipfile.lock to requirements and install via uv
  echo "Converting Pipfile.lock and syncing dependencies..."

  # Generate requirements from Lockfile (including dev deps)
  uv pip install -r <(uvx pipenv requirements --dev)

  echo "Environment is now synced and pinned to your Pipfile.lock!"
}
