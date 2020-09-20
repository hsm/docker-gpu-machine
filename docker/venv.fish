function venv
  python3 -m venv .venv
  .venv/bin/python -m pip install --upgrade pip setuptools wheel
end

function av
  source .venv/bin/activate.fish
end

