"""Tests for check_agents.py."""

import pathlib
import tempfile
import unittest
from unittest import mock

import check_agents

DEFAULT = {
    "model": "opus",
    "tools": ["Read", "Grep", "Glob", "Skill"],
    "skills": [],
}
SKILL_FAILURE = "mechanical role must not list the Skill tool"


def mechanical_config(tools):
    """Return a config granting every mechanical role the given tools."""
    config = {"default": dict(DEFAULT)}
    for slug in check_agents.MECHANICAL_ROLES:
        config[slug] = {"name": slug, "model": "haiku", "tools": list(tools)}
    return config


class CheckMechanicalToolsTests(unittest.TestCase):
    """check_mechanical_tools rejects the Skill tool on mechanical roles."""

    def test_mechanical_roles_without_skill_pass(self):
        """No failure when no mechanical role lists Skill."""
        config = mechanical_config(["Bash"])
        self.assertEqual(check_agents.check_mechanical_tools(config), [])

    def test_mechanical_role_with_skill_fails(self):
        """A mechanical role listing Skill is reported by slug."""
        config = mechanical_config(["Bash"])
        config["committer"]["tools"] = ["Bash", "Skill"]
        self.assertEqual(
            check_agents.check_mechanical_tools(config),
            [f"config.yaml committer: {SKILL_FAILURE}"],
        )

    def test_mechanical_role_inheriting_default_skill_fails(self):
        """A mechanical role without tools inherits default's Skill."""
        config = mechanical_config(["Bash"])
        del config["changelog"]["tools"]
        self.assertEqual(
            check_agents.check_mechanical_tools(config),
            [f"config.yaml changelog: {SKILL_FAILURE}"],
        )

    def test_non_mechanical_role_with_skill_passes(self):
        """Roles outside the mechanical set may keep Skill."""
        config = mechanical_config(["Bash"])
        config["code-writer"] = {"tools": ["Bash", "Skill"]}
        self.assertEqual(check_agents.check_mechanical_tools(config), [])


class RepositoryConfigTests(unittest.TestCase):
    """The repository's own config.yaml and agents pass every check."""

    def test_repository_config_is_valid(self):
        """main() reports no failure for the checked-in agents."""
        root = pathlib.Path(__file__).resolve().parents[3]
        agents = root / "ai" / "agents"
        skills = root / "ai" / "skills"
        with (
            mock.patch.object(check_agents, "AGENTS_DIR", agents),
            mock.patch.object(check_agents, "SKILLS_DIR", skills),
            mock.patch("builtins.print"),
        ):
            self.assertEqual(check_agents.main(), 0)


class MainTests(unittest.TestCase):
    """main() fails when a mechanical role lists Skill."""

    def test_main_fails_for_mechanical_skill(self):
        """main() returns 1 and names the role when committer lists Skill."""
        with tempfile.TemporaryDirectory() as directory:
            agents = pathlib.Path(directory) / "agents"
            agents.mkdir()
            (agents / "config.yaml").write_text(
                "default:\n  model: opus\n  tools: [Read]\n"
                "committer:\n  model: haiku\n  tools: [Bash, Skill]\n",
                encoding="utf8",
            )
            committer = agents / "committer"
            committer.mkdir()
            (committer / "AGENT.md").write_text(
                "---\nname: credfeto-committer\ndescription: Commits.\n"
                "model: haiku\ntools: Bash, Skill\n---\n",
                encoding="utf8",
            )
            skills = pathlib.Path(directory) / "skills"
            with (
                mock.patch.object(check_agents, "AGENTS_DIR", agents),
                mock.patch.object(check_agents, "SKILLS_DIR", skills),
                mock.patch("builtins.print") as printed,
            ):
                self.assertEqual(check_agents.main(), 1)
            messages = [call.args[0] for call in printed.call_args_list]
            self.assertIn(
                "::error::❌ config.yaml committer: "
                "mechanical role must not list the Skill tool",
                messages,
            )


if __name__ == "__main__":
    unittest.main()
