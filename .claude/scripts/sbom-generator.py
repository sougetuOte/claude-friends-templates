#!/usr/bin/env python3

"""
SBOM Generator
ソフトウェア部品表（Software Bill of Materials）自動生成
CISA 2025標準準拠、SPDX形式対応
"""

import os
import json
import hashlib
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Set
from dataclasses import dataclass, asdict
import uuid
import re

@dataclass
class Component:
    """コンポーネント情報"""
    name: str
    version: str
    type: str  # library, application, framework, etc.
    supplier: str
    download_location: str
    files_analyzed: List[str]
    license_concluded: str
    license_declared: str
    copyright_text: str
    checksums: Dict[str, str]
    external_refs: List[Dict[str, str]]
    vulnerability_status: str = "unknown"

@dataclass
class Relationship:
    """コンポーネント間の関係"""
    spdx_element_id: str
    relationship_type: str  # DEPENDS_ON, CONTAINS, etc.
    related_spdx_element: str

class SBOMGenerator:
    """SBOM生成器"""

    def __init__(self, config_path: str = ".claude/security-config.json"):
        self.config = self.load_config(config_path)
        self.components: List[Component] = []
        self.relationships: List[Relationship] = []
        self.document_namespace = f"https://claude-friends-templates/{uuid.uuid4()}"

    def load_config(self, config_path: str) -> dict:
        """設定ファイルの読み込み"""
        if Path(config_path).exists():
            with open(config_path, 'r') as f:
                config = json.load(f)
                return config.get('sbom', {})

        # デフォルト設定
        return {
            "enabled": True,
            "auto_generate": True,
            "format": "spdx",
            "output_path": ".claude/security/sbom.json",
            "vulnerability_check": True,
            "cisa_compliance": True
        }

    def analyze_project(self, project_path: str = ".") -> None:
        """プロジェクト分析"""
        project_root = Path(project_path).resolve()

        # Python依存関係の分析
        self.analyze_python_dependencies(project_root)

        # Node.js依存関係の分析
        self.analyze_nodejs_dependencies(project_root)

        # Docker依存関係の分析
        self.analyze_docker_dependencies(project_root)

        # 静的ファイルの分析
        self.analyze_static_files(project_root)

        # システムコンポーネントの分析
        self.analyze_system_components(project_root)

    def analyze_python_dependencies(self, project_root: Path) -> None:
        """Python依存関係の分析"""
        # requirements.txt
        req_file = project_root / "requirements.txt"
        if req_file.exists():
            self.parse_requirements_file(req_file)

        # Pipfile
        pipfile = project_root / "Pipfile"
        if pipfile.exists():
            self.parse_pipfile(pipfile)

        # setup.py / pyproject.toml
        setup_py = project_root / "setup.py"
        if setup_py.exists():
            self.parse_setup_py(setup_py)

        pyproject = project_root / "pyproject.toml"
        if pyproject.exists():
            self.parse_pyproject_toml(pyproject)

    def parse_requirements_file(self, req_file: Path) -> None:
        """requirements.txtの解析"""
        try:
            with open(req_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        self.parse_python_requirement(line, str(req_file))
        except Exception as e:
            print(f"Error parsing {req_file}: {e}")

    def parse_python_requirement(self, requirement: str, source_file: str) -> None:
        """Python要件の解析"""
        # 基本的なパターンマッチング（pkg==1.0.0, pkg>=1.0.0等）
        match = re.match(r'^([a-zA-Z0-9_-]+)([><=!~]+)?(.+)?', requirement)
        if match:
            name = match.group(1)
            version = match.group(3) if match.group(3) else "unknown"

            component = Component(
                name=name,
                version=version,
                type="library",
                supplier="PyPI",
                download_location=f"https://pypi.org/project/{name}/",
                files_analyzed=[source_file],
                license_concluded="NOASSERTION",
                license_declared="NOASSERTION",
                copyright_text="NOASSERTION",
                checksums={},
                external_refs=[
                    {"category": "PACKAGE_MANAGER", "type": "purl", "locator": f"pkg:pypi/{name}@{version}"}
                ]
            )

            self.components.append(component)

    def analyze_nodejs_dependencies(self, project_root: Path) -> None:
        """Node.js依存関係の分析"""
        package_json = project_root / "package.json"
        if package_json.exists():
            try:
                with open(package_json, 'r') as f:
                    data = json.load(f)

                # dependencies
                deps = data.get('dependencies', {})
                for name, version in deps.items():
                    self.add_npm_component(name, version, str(package_json))

                # devDependencies
                dev_deps = data.get('devDependencies', {})
                for name, version in dev_deps.items():
                    self.add_npm_component(name, version, str(package_json), dev=True)

            except Exception as e:
                print(f"Error parsing package.json: {e}")

    def add_npm_component(self, name: str, version: str, source_file: str, dev: bool = False) -> None:
        """NPMコンポーネントの追加"""
        component = Component(
            name=name,
            version=version,
            type="library",
            supplier="npm",
            download_location=f"https://www.npmjs.com/package/{name}",
            files_analyzed=[source_file],
            license_concluded="NOASSERTION",
            license_declared="NOASSERTION",
            copyright_text="NOASSERTION",
            checksums={},
            external_refs=[
                {"category": "PACKAGE_MANAGER", "type": "purl", "locator": f"pkg:npm/{name}@{version}"}
            ]
        )

        self.components.append(component)

    def analyze_docker_dependencies(self, project_root: Path) -> None:
        """Docker依存関係の分析"""
        dockerfile = project_root / "Dockerfile"
        if dockerfile.exists():
            try:
                with open(dockerfile, 'r') as f:
                    content = f.read()

                # FROM文の解析
                from_patterns = re.findall(r'^FROM\s+([^\s]+)', content, re.MULTILINE)
                for image in from_patterns:
                    self.add_docker_component(image, str(dockerfile))

            except Exception as e:
                print(f"Error parsing Dockerfile: {e}")

    def add_docker_component(self, image: str, source_file: str) -> None:
        """Dockerコンポーネントの追加"""
        # イメージ名とタグの分離
        if ':' in image:
            name, tag = image.rsplit(':', 1)
        else:
            name, tag = image, "latest"

        component = Component(
            name=name,
            version=tag,
            type="container",
            supplier="Docker Hub",
            download_location=f"https://hub.docker.com/_/{name}",
            files_analyzed=[source_file],
            license_concluded="NOASSERTION",
            license_declared="NOASSERTION",
            copyright_text="NOASSERTION",
            checksums={},
            external_refs=[
                {"category": "PACKAGE_MANAGER", "type": "purl", "locator": f"pkg:docker/{name}@{tag}"}
            ]
        )

        self.components.append(component)

    def analyze_static_files(self, project_root: Path) -> None:
        """静的ファイルの分析"""
        static_extensions = {'.js', '.css', '.html', '.py', '.sh', '.md', '.json', '.yaml', '.yml'}

        for file_path in project_root.rglob("*"):
            if (file_path.is_file() and
                file_path.suffix in static_extensions and
                not any(exclude in str(file_path) for exclude in ['.git', '__pycache__', 'node_modules'])):

                checksum = self.calculate_file_checksum(file_path)

                component = Component(
                    name=file_path.name,
                    version="1.0.0",
                    type="file",
                    supplier="local",
                    download_location=str(file_path),
                    files_analyzed=[str(file_path)],
                    license_concluded="NOASSERTION",
                    license_declared="NOASSERTION",
                    copyright_text="NOASSERTION",
                    checksums={"SHA256": checksum},
                    external_refs=[]
                )

                self.components.append(component)

    def analyze_system_components(self, project_root: Path) -> None:
        """システムコンポーネントの分析"""
        # Claude Code自体
        claude_component = Component(
            name="claude-friends-templates",
            version="2.0.0",
            type="application",
            supplier="local",
            download_location="https://github.com/sougetuOte/claude-friends-templates.git",
            files_analyzed=[str(project_root)],
            license_concluded="MIT",
            license_declared="MIT",
            copyright_text="Copyright (c) 2025 claude-friends-templates",
            checksums={},
            external_refs=[]
        )

        self.components.append(claude_component)

    def calculate_file_checksum(self, file_path: Path) -> str:
        """ファイルのチェックサム計算"""
        try:
            with open(file_path, 'rb') as f:
                content = f.read()
                return hashlib.sha256(content).hexdigest()
        except Exception:
            return "unknown"

    def check_vulnerabilities(self) -> None:
        """脆弱性チェック"""
        if not self.config.get('vulnerability_check', True):
            return

        # OSVデータベースとの照合（簡易版）
        known_vulnerabilities = {
            # 例: 既知の脆弱性のあるパッケージ
            "lodash": ["4.17.20", "4.17.19"],
            "axios": ["0.21.0"],
        }

        for component in self.components:
            if component.name in known_vulnerabilities:
                vulnerable_versions = known_vulnerabilities[component.name]
                if component.version in vulnerable_versions:
                    component.vulnerability_status = "vulnerable"
                else:
                    component.vulnerability_status = "not_vulnerable"

    def generate_spdx_document(self) -> Dict:
        """SPDX文書の生成"""
        document = {
            "spdxVersion": "SPDX-2.3",
            "dataLicense": "CC0-1.0",
            "SPDXID": "SPDXRef-DOCUMENT",
            "name": "claude-friends-templates-sbom",
            "documentNamespace": self.document_namespace,
            "creators": [
                "Tool: claude-friends-templates-sbom-generator",
                f"Organization: claude-friends-templates",
                f"Created: {datetime.now().isoformat()}"
            ],
            "created": datetime.now().isoformat(),
            "packages": [],
            "relationships": []
        }

        # パッケージ情報の追加
        for i, component in enumerate(self.components):
            package = {
                "SPDXID": f"SPDXRef-Package-{i}",
                "name": component.name,
                "versionInfo": component.version,
                "downloadLocation": component.download_location,
                "filesAnalyzed": len(component.files_analyzed) > 0,
                "licenseConcluded": component.license_concluded,
                "licenseDeclared": component.license_declared,
                "copyrightText": component.copyright_text,
                "supplier": f"Organization: {component.supplier}",
                "externalRefs": component.external_refs
            }

            if component.checksums:
                package["checksums"] = [
                    {"algorithm": alg, "checksumValue": value}
                    for alg, value in component.checksums.items()
                ]

            document["packages"].append(package)

        # 関係性の追加
        for relationship in self.relationships:
            document["relationships"].append(asdict(relationship))

        return document

    def save_sbom(self, output_path: str = None) -> str:
        """SBOMの保存"""
        if output_path is None:
            output_path = self.config.get('output_path', '.claude/security/sbom.json')

        # 脆弱性チェックの実行
        self.check_vulnerabilities()

        # SPDX文書の生成
        spdx_document = self.generate_spdx_document()

        # ファイル保存
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(spdx_document, f, indent=2, ensure_ascii=False)

        print(f"SBOM generated: {output_file}")
        print(f"Components found: {len(self.components)}")

        # 脆弱性サマリー
        vulnerable_components = [c for c in self.components if c.vulnerability_status == "vulnerable"]
        if vulnerable_components:
            print(f"⚠️  Vulnerable components detected: {len(vulnerable_components)}")
            for comp in vulnerable_components:
                print(f"  - {comp.name} {comp.version}")

        return str(output_file)

    def generate_summary_report(self) -> Dict:
        """サマリーレポートの生成"""
        component_types = {}
        suppliers = {}
        licenses = {}
        vulnerabilities = {"vulnerable": 0, "not_vulnerable": 0, "unknown": 0}

        for component in self.components:
            # タイプ別集計
            component_types[component.type] = component_types.get(component.type, 0) + 1

            # サプライヤー別集計
            suppliers[component.supplier] = suppliers.get(component.supplier, 0) + 1

            # ライセンス別集計
            licenses[component.license_concluded] = licenses.get(component.license_concluded, 0) + 1

            # 脆弱性別集計
            vulnerabilities[component.vulnerability_status] = vulnerabilities.get(component.vulnerability_status, 0) + 1

        return {
            "total_components": len(self.components),
            "component_types": component_types,
            "suppliers": suppliers,
            "licenses": licenses,
            "vulnerabilities": vulnerabilities,
            "generated_at": datetime.now().isoformat()
        }

def main():
    """メイン処理"""
    generator = SBOMGenerator()

    print("Analyzing project dependencies...")
    generator.analyze_project()

    print("Generating SBOM...")
    sbom_path = generator.save_sbom()

    print("\nSummary Report:")
    summary = generator.generate_summary_report()
    print(json.dumps(summary, indent=2))

    return sbom_path

if __name__ == "__main__":
    main()