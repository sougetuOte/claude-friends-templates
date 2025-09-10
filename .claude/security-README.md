# Claude Code Security Settings

🌐 **English** | **[日本語](security-README_ja.md)**

This project includes security settings for safe use of Claude Code.

## Implementation

### 1. Deny List
A mechanism to automatically block dangerous commands.

**Blocked Commands:**
- System destruction (`rm -rf /`, `rm -rf /usr`, `chmod -R 777 /`)
- Remote code execution (`curl | sh`, `wget | bash`)
- Privilege escalation to root shell (`sudo su`, `sudo -i`)
- Direct disk operations (`dd if=/dev/zero of=/dev/`, `> /dev/sda`)
- Database destruction (`DROP DATABASE`)

### 2. Allow List
A mechanism to pre-approve commonly used safe commands.

**Allowed Commands:**
- All file operations (`ls`, `cat`, `mkdir`, `cp`, `mv`, `rm`, etc.)
- All Git operations (`git status`, `git config`, `git commit`, etc.)
- Development tools (`npm`, `yarn`, `python`, `pip`, `cargo`, etc.)
- Modern CLI tools (`eza`, `batcat`, `rg`, `fd`, etc.)
- Text processing (`awk`, `sed`, `grep`, `jq`, etc.)
- Safe network operations (`curl`, `wget`, `ping`, etc.)

### 3. File Structure

```
.claude/
├── settings.json          # Main configuration file
├── scripts/
│   ├── deny-check.sh     # Deny list checker
│   └── allow-check.sh    # Allow list checker
└── security-README.md    # This file
```

## Security Log

Executed commands are logged to `~/.claude/security.log`:

```
[2024-01-01 12:00:00] BLOCKED: rm -rf / (matched: rm -rf /)
[2024-01-01 12:01:00] ALLOWED: git status
[2024-01-01 12:02:00] DENIED: custom-command (not in allow list)
```

## Configuration Modifications

### Adding to Allow List
1. Add pattern to `ALLOWED_PATTERNS` in `.claude/scripts/allow-check.sh`
2. Test the pattern works as expected

### Adding to Deny List
1. Add pattern to `DANGEROUS_PATTERNS` in `.claude/scripts/deny-check.sh`
2. Ensure it doesn't block legitimate commands

## Emergency Response

If security settings cause problems:

1. **Temporarily disable**
   ```bash
   mv .claude/settings.json .claude/settings.json.backup
   ```

2. **Check logs**
   ```bash
   tail -f ~/.claude/security.log
   ```

3. **Restore settings**
   ```bash
   mv .claude/settings.json.backup .claude/settings.json
   ```

## Important Notes

- **Before changes**: Always backup configurations
- **Testing**: Thoroughly test before production use
- **Monitoring**: Regularly check security logs
- **Updates**: Update settings based on threat information

## Design Philosophy

The security system is designed to:
- Block only truly dangerous operations
- Allow all normal development workflows
- Be transparent and debuggable
- Minimize false positives

## Support

Contact the project administrator for configuration issues.

---

**Last Updated**: 2025-09-10  
**Version**: 2.4.0