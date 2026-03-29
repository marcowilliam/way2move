# ─────────────────────────────────────────────────────────────────────────────
# w2m — Way2Move environment switcher (zsh compatible)
#
# Usage:
#   w2m <branch>          Switch to branch, start emulator + flutter web
#   w2m <branch> --seed   Same but also seed the database
#   w2m stop              Kill all running emulator + flutter processes
#   w2m ls                List available worktrees
#   w2m status            Show what's currently running
#
# Add to your shell: source /projects/way2move/main/scripts/w2m.sh
# ─────────────────────────────────────────────────────────────────────────────

W2M_ROOT="/projects/way2move"
W2M_EMU_DATA="$HOME/way2move-emulator-data"
W2M_LOG_DIR="/tmp/w2m"

# Snapshot full PATH at source time so background jobs can inherit it.
_W2M_PATH="$PATH"

_w2m_resolve_path() {
  local branch="$1"
  if [[ "$branch" == "main" ]]; then
    echo "$W2M_ROOT/main"
  elif [[ -d "$W2M_ROOT/feature/$branch" ]]; then
    echo "$W2M_ROOT/feature/$branch"
  elif [[ -d "$W2M_ROOT/$branch" ]]; then
    echo "$W2M_ROOT/$branch"
  else
    echo ""
  fi
}

_w2m_stop() {
  echo "⏹  Stopping running processes..."

  # Flutter — kill immediately (no state to save)
  pkill -f "flutter.*run.*chrome" 2>/dev/null
  pkill -f "flutter_tools.*run" 2>/dev/null
  pkill -f "dart.*DevServer" 2>/dev/null
  pkill -f "Google Chrome.*flutter" 2>/dev/null

  # Firebase emulator — SIGINT first so --export-on-exit can flush data
  if pgrep -f "firebase.*emulators" &>/dev/null; then
    echo "   Gracefully stopping emulator (exporting data)..."
    pkill -INT -f "firebase.*emulators" 2>/dev/null
    # Wait up to 10s for it to export and exit
    local i=0
    while [[ $i -lt 10 ]] && pgrep -f "firebase.*emulators" &>/dev/null; do
      command sleep 1
      i=$((i + 1))
    done
    # Force kill anything still hanging
    pkill -9 -f "firebase.*emulators" 2>/dev/null
  fi

  # Clean up any leftover port holders
  for port in 4000 9099 8080 5001 9199 5002; do
    lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null
  done

  command sleep 1
  echo "   Done."
}

_w2m_status() {
  echo "── Way2Move Status ──"
  echo ""

  if lsof -ti:4000 &>/dev/null; then
    echo "🔥 Emulator:  running (UI on :4000)"
  else
    echo "🔥 Emulator:  stopped"
  fi

  local flutter_pid
  flutter_pid=$(pgrep -f "flutter.*run" 2>/dev/null | head -1)
  if [[ -n "$flutter_pid" ]]; then
    echo "🏃 Flutter:   running (pid $flutter_pid)"
  else
    echo "🏃 Flutter:   stopped"
  fi

  if [[ -f "$W2M_LOG_DIR/active_branch" ]]; then
    echo "📂 Branch:    $(cat $W2M_LOG_DIR/active_branch)"
  fi
  echo ""
}

_w2m_ls() {
  echo "── Available Worktrees ──"
  git -C "$W2M_ROOT/main" worktree list | while read -r path hash branch; do
    local name="${path##*/}"
    [[ "$path" == *".bare"* ]] && continue
    printf "  %-20s %s  %s\n" "$name" "$hash" "$branch"
  done
  echo ""
}

w2m() {
  local cmd="$1"
  local flag="$2"

  command mkdir -p "$W2M_LOG_DIR"

  case "$cmd" in
    stop)
      _w2m_stop
      command rm -f "$W2M_LOG_DIR/active_branch"
      return 0
      ;;
    ls|list)
      _w2m_ls
      return 0
      ;;
    status|st)
      _w2m_status
      return 0
      ;;
    -h|--help|help|"")
      echo "Usage: w2m <branch> [--seed] | w2m stop | w2m ls | w2m status"
      return 0
      ;;
  esac

  local branch="$cmd"
  local wt_path
  wt_path=$(_w2m_resolve_path "$branch")

  if [[ -z "$wt_path" ]]; then
    echo "❌ No worktree found for '$branch'"
    _w2m_ls
    return 1
  fi

  echo "🔄 Switching to: $wt_path"
  echo ""

  # 1. Stop existing
  _w2m_stop

  # 2. Build functions
  if [[ -d "$wt_path/backend/functions/src" ]]; then
    echo "🔨 Building Cloud Functions..."
    (export PATH="$_W2M_PATH"; cd "$wt_path/backend/functions" && npm run build 2>&1 | command tail -3)
    echo ""
  fi

  # 3. Start Firebase emulators — use nohup + full PATH
  echo "🔥 Starting Firebase emulators..."
  nohup env PATH="$_W2M_PATH" bash -c "cd '$wt_path' && firebase emulators:start --export-on-exit='$W2M_EMU_DATA' --import='$W2M_EMU_DATA'" \
    > "$W2M_LOG_DIR/emulator.log" 2>&1 &
  echo "   PID: $! (log: $W2M_LOG_DIR/emulator.log)"

  # Wait for Firestore on 8080
  echo -n "   Waiting for emulator"
  local i=0
  while [[ $i -lt 30 ]]; do
    if command curl -s http://localhost:8080 &>/dev/null; then
      echo " ready!"
      break
    fi
    command sleep 1
    echo -n "."
    i=$((i + 1))
  done
  if [[ $i -eq 30 ]]; then
    echo " timeout! Check $W2M_LOG_DIR/emulator.log"
  fi

  # 4. Seed if requested
  if [[ "$flag" == "--seed" ]]; then
    echo "🌱 Seeding database..."
    (export PATH="$_W2M_PATH"; cd "$wt_path/backend/functions" && npm run seed 2>&1 | command tail -5)
    echo ""
  fi

  # 5. Start Flutter web — use nohup + full PATH
  echo "🏃 Starting Flutter web..."
  nohup env PATH="$_W2M_PATH" bash -c "cd '$wt_path/frontend/mobile' && flutter run -d chrome" \
    > "$W2M_LOG_DIR/flutter.log" 2>&1 &
  echo "   PID: $! (log: $W2M_LOG_DIR/flutter.log)"

  # Save state
  echo "$branch ($wt_path)" > "$W2M_LOG_DIR/active_branch"

  echo ""
  echo "✅ Environment ready!"
  echo "   Emulator UI:  http://localhost:4000"
  echo "   Flutter web:  (check $W2M_LOG_DIR/flutter.log for URL)"
  echo ""
  echo "   w2m status    → check what's running"
  echo "   w2m stop      → kill everything"
  echo "   w2m <other>   → switch to another branch"
}
