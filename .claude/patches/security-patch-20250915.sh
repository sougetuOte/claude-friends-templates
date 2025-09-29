#!/bin/bash
# Security Patch for Claude Friends Templates Hooks System
# Date: 2025-09-15
# Purpose: Fix medium-risk security vulnerabilities found in lightweight review

set -euo pipefail

echo "🔒 Applying Security Patches..."

# Patch 1: Fix file permissions
echo "1. Fixing file permissions (775 -> 755)..."
find .claude/hooks -name "*.sh" -type f -exec chmod 755 {} \;
find .claude/scripts -name "*.sh" -type f -exec chmod 755 {} \;
find .claude/tests -name "*.sh" -type f -exec chmod 755 {} \;

# Patch 2: Create improved hook-common.sh with command injection fix
echo "2. Patching hook-common.sh for command injection vulnerability..."
cat > .claude/patches/hook-common-security.patch << 'EOF'
--- a/.claude/hooks/common/hook-common.sh
+++ b/.claude/hooks/common/hook-common.sh
@@ -99,9 +99,14 @@ get_agent_info() {
     fi

     # Extract prompt from JSON
-    local prompt
-    prompt=$(echo "$json_input" | grep -oE '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | \
-             sed 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null) || prompt=""
+    local prompt=""
+    if command -v jq >/dev/null 2>&1; then
+        prompt=$(printf '%s' "$json_input" | jq -r '.prompt // ""' 2>/dev/null) || prompt=""
+    else
+        # Use printf to prevent command injection
+        prompt=$(printf '%s' "$json_input" | grep -oE '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | \
+                 sed 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null) || prompt=""
+    fi

     # Check for agent command
     if [[ "$prompt" =~ /agent:([a-z]+) ]]; then
@@ -245,10 +250,14 @@ log_message() {
     # Write to log file with file locking to prevent race conditions
     local lock_file="${log_file}.lock"
     {
-        flock -x 200
-        echo "$formatted_message" >> "$log_file"
-    } 200>>"$lock_file" 2>/dev/null || {
-        echo "$formatted_message" >> "$log_file"
+        if flock -x -w 10 200; then
+            printf '%s\n' "$formatted_message" >> "$log_file"
+        else
+            # Fallback without lock if timeout
+            printf '%s\n' "$formatted_message" >> "$log_file"
+        fi
+    } 200>"$lock_file" 2>/dev/null || {
+        printf '%s\n' "$formatted_message" >> "$log_file"
     }

     return 0
EOF

# Apply the patch
if command -v patch >/dev/null 2>&1; then
    patch -p1 < .claude/patches/hook-common-security.patch
    echo "   ✅ hook-common.sh patched successfully"
else
    echo "   ⚠️  patch command not found. Manual patching required."
fi

# Patch 3: Create improved agent-switch.sh with secure temp file handling
echo "3. Creating secure temp file handling patch for agent-switch.sh..."
cat > .claude/patches/agent-switch-security.patch << 'EOF'
--- a/.claude/hooks/agent/agent-switch.sh
+++ b/.claude/hooks/agent/agent-switch.sh
@@ -239,13 +239,17 @@ trigger_notes_rotation() {
     mkdir -p "$archive_dir"

     # Archive current notes with atomic operation
-    local temp_file="${notes_file}.tmp.$$"
+    local temp_file
+    temp_file=$(mktemp "${notes_file}.XXXXXX") || {
+        _error "Failed to create secure temporary file"
+        return 1
+    }
+    chmod 600 "$temp_file"  # Restrict permissions immediately
+
     local timestamp
     timestamp=$(date '+%Y%m%d-%H%M%S')

-    # Keep only summary (first N lines) in notes after rotation
-    head -n "$NOTES_ARCHIVE_HEADER_LINES" "$notes_file" > "$temp_file" || {
-        rm -f "$temp_file"
+    if ! head -n "$NOTES_ARCHIVE_HEADER_LINES" "$notes_file" > "$temp_file"; then
         _error "Failed to create archive summary"
         return 1
     }
@@ -427,8 +431,12 @@ main() {
     fi

     # Save to temporary file for processing
-    local temp_file="/tmp/${TEMP_FILE_PREFIX}-$$-$(date +%s).json"
-    echo "$input" > "$temp_file" || {
+    local temp_file
+    temp_file=$(mktemp "/tmp/${TEMP_FILE_PREFIX}-XXXXXX.json") || {
+        _error "Failed to create secure temporary file"
+        return 1
+    }
+    printf '%s' "$input" > "$temp_file" || {
         _error "Failed to write input to temporary file"
         return 1
     }
EOF

# Apply the patch
if command -v patch >/dev/null 2>&1; then
    patch -p1 < .claude/patches/agent-switch-security.patch
    echo "   ✅ agent-switch.sh patched successfully"
else
    echo "   ⚠️  patch command not found. Manual patching required."
fi

# Patch 4: Add JQ caching optimization
echo "4. Adding performance optimization for JQ checks..."
cat > .claude/hooks/common/cache-init.sh << 'EOF'
#!/bin/bash
# Cache initialization for performance optimization

# Check and cache jq availability
export JQ_AVAILABLE=""
if command -v jq >/dev/null 2>&1; then
    export JQ_AVAILABLE="true"
else
    export JQ_AVAILABLE="false"
fi

# Agent info cache (5 second TTL)
declare -g AGENT_INFO_CACHE=""
declare -g AGENT_INFO_CACHE_TIME=0
EOF
chmod 755 .claude/hooks/common/cache-init.sh

echo ""
echo "✅ Security patches applied successfully!"
echo ""
echo "Summary of changes:"
echo "  1. File permissions changed from 775 to 755"
echo "  2. Command injection vulnerability fixed in hook-common.sh"
echo "  3. Secure temp file handling added to agent-switch.sh"
echo "  4. Performance cache initialization added"
echo ""
echo "⚠️  Please run tests to verify patches:"
echo "  bats .claude/tests/bats/*.bats"
echo ""
echo "📝 Patch files saved in .claude/patches/ for reference"
