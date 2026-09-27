"""Fail if any AGENT.md frontmatter differs from ai/agents/config.yaml."""

import pathlib
import sys

import yaml

AGENTS_DIR = pathlib.Path("ai/agents")
ALLOWED_KEYS = {"name", "description", "model", "tools", "skills"}


def read_frontmatter(path):
    """Return the parsed YAML frontmatter of a file, or None if absent."""
    parts = path.read_text(encoding="utf8").split("---", 2)
    if len(parts) < 3 or parts[0].strip():
        return None
    return yaml.safe_load(parts[1]) or {}


def expected_frontmatter(slug, config):
    """Return the frontmatter config.yaml requires for an agent slug."""
    entry = {**config.get("default", {}), **(config.get(slug) or {})}
    return {
        "name": f"credfeto-{slug}",
        "model": entry.get("model"),
        "tools": ", ".join(entry.get("tools", [])),
        "skills": list(entry.get("skills", [])),
    }


def main():
    """Report every mismatch and return a non-zero exit code if any."""
    config_text = (AGENTS_DIR / "config.yaml").read_text(encoding="utf8")
    config = yaml.safe_load(config_text) or {}
    failures = []

    for definition in sorted(AGENTS_DIR.glob("*/AGENT.md")):
        slug = definition.parent.name
        frontmatter = read_frontmatter(definition)
        if frontmatter is None:
            failures.append(f"{definition}: missing YAML frontmatter")
            continue

        for key in sorted(set(frontmatter) - ALLOWED_KEYS):
            failures.append(f"{definition}: unexpected frontmatter {key!r}")

        if not str(frontmatter.get("description") or "").strip():
            failures.append(f"{definition}: missing description")

        actual = {
            "name": frontmatter.get("name"),
            "model": frontmatter.get("model"),
            "tools": frontmatter.get("tools"),
            "skills": list(frontmatter.get("skills") or []),
        }

        for field, value in expected_frontmatter(slug, config).items():
            if actual[field] != value:
                failures.append(
                    f"{definition}: {field} is {actual[field]!r}, "
                    f"config.yaml expects {value!r}"
                )

    for failure in failures:
        print(f"::error::❌ {failure}")

    if failures:
        return 1

    print("✅ Every AGENT.md frontmatter matches ai/agents/config.yaml")
    return 0


if __name__ == "__main__":
    sys.exit(main())
