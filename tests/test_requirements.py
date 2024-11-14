import os
from dataclasses import dataclass, field
import platform
from typing import Set, Optional
from unittest import TestCase


@dataclass(frozen=True, eq=True)
class Package:
    name: str
    version: str
    markers: Optional[str] = field(default="")


class TestRequirements(TestCase):
    @classmethod
    def setUpClass(cls):

        requirements_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "requirements")
        if platform.machine() in ["arm64", "aarch64"]:
            cls.requirements = "arm64-requirements.txt"
        elif platform.machine() == "x86_64":
            cls.requirements = "amd64-gpu-requirements.txt"
        else:
            raise ValueError(f"Unsupported platform: {platform.machine()}")

        cls.requirements = os.path.join(requirements_dir, cls.requirements)
        if not os.path.exists(cls.requirements):
            raise FileNotFoundError(f"Requirements file not found: {cls.requirements}")

        cls.generated_requirements = os.path.join(requirements_dir, "generated-requirements.txt")
        if not os.path.exists(cls.generated_requirements):
            raise FileNotFoundError(f"Generated requirements file not found: {cls.generated_requirements}")

    def _parse_requirements(self, file_path: str) -> Set[Package]:
        """Parses requirements file and returns a set of Package objects"""
        requirements = set()
        with open(file_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    # Separate markers if present (e.g., ;python_version<'3.8')
                    markers = ""
                    if ';' in line:
                        markers = line.split(';', 1)[1].strip()
                        line = line.split(';', 1)[0].strip()

                    # Split package name and version, and clean up the name
                    if '==' in line:
                        package, version = line.split('==')
                        package = package.replace('_', '-').lower().strip()
                        requirements.add(Package(name=package, version=version, markers=markers))
        return requirements

    def test_compare_requirements(self):
        """Compares requirements.txt with generated-requirements.txt and prints differences"""
        req1 = self._parse_requirements(self.requirements)
        req2 = self._parse_requirements(self.generated_requirements)

        # Track differences by comparing sets of Package objects
        only_in_req1 = req1 - req2
        only_in_req2 = req2 - req1
        version_mismatches = []

        # Check for version mismatches in common packages
        for package1 in req1:
            for package2 in req2:
                if package1.name == package2.name and package1.markers == package2.markers and package1.version != package2.version:
                    version_mismatches.append((package1, package2))

        # Print results
        if only_in_req1 or only_in_req2 or version_mismatches:
            print("Differences found between requirements files:")
            for package in only_in_req1:
                print(f"Only in {self.requirements}: {package.name}=={package.version} {package.markers}")
            for package in only_in_req2:
                print(f"Only in {self.generated_requirements}: {package.name}=={package.version} {package.markers}")
            for package1, package2 in version_mismatches:
                print(f"Version mismatch for {package1.name}: {self.requirements} version: {package1.version}, "
                      f"{self.generated_requirements} version: {package2.version}")
        else:
            print("No differences found between requirements files.")

        # Optionally assert no differences
        self.assertFalse(only_in_req1 or only_in_req2 or version_mismatches,
                         "Differences found between requirements files.")
