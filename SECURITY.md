# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | :white_check_mark: |
| 1.x.x   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do not** create a public GitHub issue
2. **Send an email** to security@claude-friends-templates.local
3. **Include** detailed information about the vulnerability
4. **Wait** for our response before public disclosure

## Security Measures

### Code Security
- **Static Analysis**: Automated security scanning with Bandit
- **Dependency Scanning**: Regular vulnerability checks with pip-audit and Safety
- **SBOM Generation**: Software Bill of Materials (SBOM) generation for supply chain security
- **Code Review**: Manual security review for all code changes

### Security Audit Results (September 2025)
- **High-Risk Vulnerabilities**: 0 (Zero)
- **Medium-Risk Vulnerabilities**: 0 (All resolved)
- **Code Quality**: All scripts rated A for maintainability
- **Recent Fixes**:
  - Fixed hardcoded temporary directory (B108) in input-validator.py
  - Migrated to `tempfile.mkdtemp()` with secure prefix generation
  - Enhanced input validation with comprehensive sanitization

### Infrastructure Security
- **Access Control**: Principle of least privilege
- **Encryption**: Data encryption in transit and at rest
- **Monitoring**: Security event logging and monitoring
- **Updates**: Regular security updates and patches

### Development Security
- **Secure Coding**: Following OWASP secure coding practices
- **Input Validation**: Comprehensive input validation and sanitization
- **Authentication**: Multi-factor authentication where applicable
- **CI/CD Security**: Secure development pipeline with automated security checks

## Security Standards

### Compliance
- **OWASP Top 10**: Protection against common web vulnerabilities
- **CIS Controls**: Implementation of Center for Internet Security controls
- **NIST Framework**: Alignment with NIST Cybersecurity Framework
- **Supply Chain Security**: SLSA (Supply-chain Levels for Software Artifacts) compliance

### Vulnerability Management
- **Severity Classification**: CVSS v3.1 scoring system
- **Response Times**:
  - Critical: 24 hours
  - High: 72 hours
  - Medium: 7 days
  - Low: 30 days

### Security Tools
- **SAST**: Static Application Security Testing
- **DAST**: Dynamic Application Security Testing
- **SCA**: Software Composition Analysis
- **SBOM**: Software Bill of Materials generation

## Security Configuration

### Required Dependencies
```
bandit==1.8.0              # Python security linter
pip-audit==2.8.0           # Vulnerability scanning
safety==3.6.2              # Safety database checking
cyclonedx-bom==5.3.0       # SBOM generation
```

### Security Scanning Commands
```bash
# Run security scans
python .claude/scripts/vulnerability-scanner.py --format json

# Generate SBOM
python .claude/scripts/sbom-generator.py --format cyclonedx --output sbom.json

# Run all security checks
bandit -r .claude/ -f json
pip-audit --requirement requirements.txt
safety check --json
```

## Incident Response

### Response Team
- **Security Lead**: Primary security contact
- **Development Lead**: Technical assessment and remediation
- **Project Manager**: Communication and coordination

### Response Process
1. **Detection**: Automated monitoring or manual reporting
2. **Assessment**: Severity evaluation and impact analysis
3. **Containment**: Immediate measures to limit damage
4. **Eradication**: Root cause removal and system hardening
5. **Recovery**: Service restoration and validation
6. **Lessons Learned**: Post-incident review and improvement

## Security Awareness

### Training
- Regular security awareness training for all contributors
- Secure coding practices workshops
- Vulnerability assessment training

### Best Practices
- Use strong, unique passwords
- Enable two-factor authentication
- Keep software and dependencies updated
- Follow secure coding guidelines
- Perform regular security assessments

## Contact Information

- **Security Team**: security@claude-friends-templates.local
- **General Inquiries**: info@claude-friends-templates.local
- **Emergency Contact**: +1-555-SECURITY

## Updates

This security policy is reviewed and updated annually or as needed when significant changes occur to the project or threat landscape.

**Last Updated**: 2025-09-29
**Version**: 2.0.0
