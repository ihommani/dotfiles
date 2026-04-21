function tmux() {
  # If arguments are provided, pass them directly to the real tmux binary
  if [[ $# -gt 0 ]]; then
    command tmux "$@"
    return
  fi

  # Check if we are not already inside a tmux session
  if [[ -z "$TMUX" ]]; then
    # Get the basename of the current directory and use it as the session name
    local SESSION_NAME
    SESSION_NAME=$(basename "$(pwd)")

    # If the session already exists, attach to it, otherwise create a new one
    if command tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      command tmux attach -t "$SESSION_NAME"
    else
      command tmux new -s "$SESSION_NAME"
    fi
  else
    # Warn the user if already inside a tmux session
    echo "You are already inside a tmux session. To create a new one, exit the current session or use 'tmux new -s <session_name>'."
  fi
}
