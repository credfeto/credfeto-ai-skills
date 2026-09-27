"""Fail if agent definitions disagree with ai/agents/config.yaml.

Checks that every skill config.yaml preloads exists in ai/skills, and that
every AGENT.md frontmatter has exactly the documented keys with the values
config.yaml requires.
"""

import pathlib
import re
import sys

import yaml

AGENTS_DIR = pathlib.Path("ai/agents")
SKILLS_DIR = pathlib.Path("ai/skills")
SKILL_PREFIX = "credfeto-"
ALLOWED_KEYS = {"name", "description", "model", "tools", "skills"}
FRONTMATTER = re.compile(r"\A---[ \t]*\n(.*?)\n---[ \t]*(?:\n|\Z)", re.DOTALL)


def read_frontmatter(path):
    """Return the parsed YAML frontmatter of a file, or None if absent."""
    match = FRONTMATTER.match(path.read_text(encoding="utf8"))
    if match is None:
        return None
    parsed = yaml.safe_load(match.group(1))
    return parsed if isinstance(parsed, dict) else {}


def resolve_entry(slug, config):
    """Return an agent's config.yaml entry with default: values applied."""
    return {**(config.get("default") or {}), **(config.get(slug) or {})}


def check_skills_exist(config):
    """Return a failure for each preloaded skill with no SKILL.md."""
    failures = []
    for slug, entry in config.items():
        for skill in (entry or {}).get("skills") or []:
            folder = skill.removeprefix(SKILL_PREFIX)
            if not skill.startswith(SKILL_PREFIX):
                failures.append(
                    f"config.yaml {slug}: skill {skill!r} "
                    f"lacks the {SKILL_PREFIX} prefix"
                )
            elif not (SKILLS_DIR / folder / "SKILL.md").is_file():
                failures.append(
                    f"config.yaml {slug}: preloads {skill}, but "
                    f"{SKILLS_DIR / folder / 'SKILL.md'} does not exist"
                )
    return failures


def check_frontmatter(definition, config):
    """Return a failure for each frontmatter problem in one AGENT.md."""
    try:
        frontmatter = read_frontmatter(definition)
    except yaml.YAMLError as error:
        return [f"{definition}: invalid YAML frontmatter: {error}"]
    if frontmatter is None:
        return [f"{definition}: missing YAML frontmatter"]

    failures = [
        f"{definition}: unexpected frontmatter {key!r}"
        for key in sorted(set(frontmatter) - ALLOWED_KEYS)
    ]

    if not str(frontmatter.get("description") or "").strip():
        failures.append(f"{definition}: missing description")

    entry = resolve_entry(definition.parent.name, config)
    expected = {
        "name": f"credfeto-{definition.parent.name}",
        "model": entry.get("model"),
        "tools": ", ".join(entry.get("tools") or []),
        "skills": list(entry.get("skills") or []),
    }
    actual = {
        "name": frontmatter.get("name"),
        "model": frontmatter.get("model"),
        "tools": frontmatter.get("tools"),
        "skills": list(frontmatter.get("skills") or []),
    }

    for field, value in expected.items():
        if actual[field] != value:
            failures.append(
                f"{definition}: {field} is {actual[field]!r}, "
                f"config.yaml expects {value!r}"
            )
    return failures


def main():
    """Report every problem and return a non-zero exit code if any."""
    config_text = (AGENTS_DIR / "config.yaml").read_text(encoding="utf8")
    config = yaml.safe_load(config_text) or {}

    failures = check_skills_exist(config)
    for definition in sorted(AGENTS_DIR.glob("*/AGENT.md")):
        failures.extend(check_frontmatter(definition, config))

    for failure in failures:
        print(f"::error::❌ {failure}")

    if failures:
        return 1

    print("✅ Agent skills and frontmatter match ai/agents/config.yaml")
    return 0


if __name__ == "__main__":
    sys.exit(main())
