#!/bin/bash

# Claude Friends Templates Security Setup
# セキュリティシステム統合セットアップスクリプト
# 2025年セキュリティベストプラクティス準拠

set -euo pipefail

# 色付きログ出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# プロジェクトルートの確認
if [[ ! -d ".claude" ]]; then
    log_error "Claude Friends Templatesプロジェクトルートで実行してください"
    exit 1
fi

log_info "Claude Friends Templates セキュリティシステムセットアップ開始"

# 必要なディレクトリの作成
log_info "ディレクトリ構造の作成..."
mkdir -p .claude/logs
mkdir -p .claude/security
mkdir -p .claude/security/scan-results
mkdir -p .claude/dashboard

# Pythonの依存関係チェック
log_info "Python環境の確認..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
    log_success "Python $PYTHON_VERSION detected"
else
    log_error "Python 3が見つかりません"
    exit 1
fi

# 設定ファイルの初期化
log_info "セキュリティ設定の初期化..."
if [[ ! -f ".claude/security-config.json" ]]; then
    cat > .claude/security-config.json << 'EOF'
{
  "scan": {
    "exclude": [
      "node_modules",
      "vendor",
      ".git",
      "__pycache__",
      "dist",
      "build",
      ".cache",
      ".ccache",
      "coverage",
      "*.min.js",
      "*.min.css"
    ],
    "include": [
      "src",
      "lib",
      "api",
      "app",
      "public",
      "scripts",
      "config"
    ]
  },
  "checks": {
    "secrets": true,
    "sql_injection": true,
    "xss": true,
    "path_traversal": true,
    "command_injection": true,
    "permissions": true,
    "dependencies": true
  },
  "severity_threshold": "medium",
  "auto_fix": false,
  "report": {
    "format": "markdown",
    "output": ".claude/security-report.md",
    "include_recommendations": true
  },
  "zero_trust": {
    "enabled": true,
    "access_control": {
      "principle": "least_privilege",
      "session_timeout": 3600,
      "verification_level": "continuous",
      "max_failed_attempts": 3,
      "lockout_duration": 300
    },
    "session_monitoring": {
      "enabled": true,
      "anomaly_detection": true,
      "log_level": "info",
      "alert_threshold": "medium"
    },
    "authentication": {
      "multi_factor": false,
      "continuous_validation": true,
      "risk_based": true
    }
  },
  "sbom": {
    "enabled": true,
    "auto_generate": true,
    "format": "spdx",
    "output_path": ".claude/security/sbom.json",
    "vulnerability_check": true,
    "cisa_compliance": true
  },
  "sast": {
    "cvss_version": "4.0",
    "ai_assisted": true,
    "false_positive_reduction": true,
    "custom_rules": true
  },
  "input_validation": {
    "prompt_injection_protection": true,
    "sanitization_level": "strict",
    "max_input_length": 10000,
    "allowed_patterns": [
      "^[a-zA-Z0-9\\s\\-_\\.\\(\\)\\[\\]\\{\\}\\@\\#\\$\\%\\^\\&\\*\\+\\=\\!\\?\\,\\;\\:\\\\\\/]*$"
    ]
  },
  "devsecops": {
    "ci_cd_integration": true,
    "github_actions": true,
    "auto_security_scan": true,
    "policy_enforcement": "strict"
  },
  "security_policy": {
    "zero_trust_required": true,
    "sbom_required": true,
    "sast_required": true,
    "input_validation_required": true,
    "min_security_score": 80
  }
}
EOF
    log_success "セキュリティ設定ファイル作成完了"
else
    log_info "既存のセキュリティ設定を使用"
fi

# ログローテーション設定
log_info "ログローテーション設定..."
cat > .claude/logs/logrotate.conf << 'EOF'
.claude/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF

# セキュリティスクリプトの実行権限付与
log_info "セキュリティスクリプトの権限設定..."
chmod +x .claude/scripts/security-*.py 2>/dev/null || true
chmod +x .claude/scripts/zero-trust-*.py 2>/dev/null || true
chmod +x .claude/scripts/sbom-*.py 2>/dev/null || true
chmod +x .claude/scripts/input-*.py 2>/dev/null || true

# セキュリティマネージャーの初期化
log_info "セキュリティマネージャーの初期化..."
if python3 .claude/scripts/security-manager.py init; then
    log_success "セキュリティマネージャー初期化完了"
else
    log_warning "セキュリティマネージャー初期化で警告が発生しました"
fi

# 初回セキュリティスキャンの実行
log_info "初回セキュリティスキャンの実行..."
if python3 .claude/scripts/security-manager.py scan; then
    log_success "初回セキュリティスキャン完了"
else
    log_warning "初回セキュリティスキャンで問題が検出されました"
fi

# ダッシュボードの生成
log_info "セキュリティダッシュボードの生成..."
if python3 .claude/scripts/security-manager.py dashboard; then
    log_success "セキュリティダッシュボード生成完了"
    log_info "ダッシュボード: .claude/security/dashboard.md"
fi

# GitHub Actions設定の確認
log_info "GitHub Actions設定の確認..."
if [[ -f ".github/workflows/security-scan.yml" ]]; then
    log_success "DevSecOps パイプライン設定済み"
else
    log_warning "GitHub Actionsワークフローが見つかりません"
fi

# 定期実行のためのcron設定例を表示
log_info "定期実行設定の推奨事項:"
echo "以下をcrontabに追加することを推奨します:"
echo "# 毎日午前2時にセキュリティスキャン"
echo "0 2 * * * cd $(pwd) && python3 .claude/scripts/security-manager.py scan"
echo ""
echo "# 毎週月曜日にSBOM更新"
echo "0 3 * * 1 cd $(pwd) && python3 .claude/scripts/sbom-generator.py"

# セキュリティ設定の検証
log_info "セキュリティ設定の検証..."
if python3 .claude/scripts/security-manager.py status; then
    log_success "セキュリティ設定検証完了"
fi

# README更新の提案
if [[ -f "README.md" ]] && ! grep -q "Security Dashboard" README.md; then
    log_info "README.mdにセキュリティ情報の追加を推奨"
    cat >> README_security_addition.md << 'EOF'

## 🔒 Security

This project implements comprehensive security measures following 2025 best practices:

### Security Features
- **Zero Trust Access Control**: Continuous authentication and authorization
- **SBOM Generation**: Automated Software Bill of Materials with vulnerability scanning
- **Enhanced SAST**: Static analysis with CVSS v4.0 scoring and AI-assisted false positive reduction
- **Input Validation**: Protection against prompt injection and other input-based attacks
- **DevSecOps Integration**: Automated security scanning in CI/CD pipeline

### Security Dashboard
View the current security status: [Security Dashboard](.claude/security/dashboard.md)

### Security Commands
```bash
# Initialize security systems
./claude/scripts/setup-security.sh

# Run security scan
python3 .claude/scripts/security-manager.py scan

# Check security status
python3 .claude/scripts/security-manager.py status

# Generate security dashboard
python3 .claude/scripts/security-manager.py dashboard
```

### Compliance
- CISA 2025 Standards
- Zero Trust Architecture (NIST SP 800-207)
- SPDX 2.3 for SBOM
- CVSS v4.0 for vulnerability scoring
EOF
    log_info "README.md追加内容がREADME_security_addition.mdに保存されました"
fi

# セットアップ完了の確認
log_success "🎉 Claude Friends Templates セキュリティシステムセットアップ完了!"
echo ""
log_info "次のステップ:"
echo "1. セキュリティダッシュボードを確認: cat .claude/security/dashboard.md"
echo "2. GitHub Actionsでセキュリティスキャンをテスト"
echo "3. 定期実行スケジュールの設定"
echo "4. セキュリティポリシーのカスタマイズ: .claude/security-config.json"
echo ""
log_info "セキュリティスキャンは以下で実行できます:"
echo "python3 .claude/scripts/security-manager.py scan"