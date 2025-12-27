module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [
      2,
      "always",
      [
        "feat",
        "fix",
        "docs",
        "style",
        "refactor",
        "perf",
        "test",
        "chore",
        "revert",
        "ci",
        "build",
        "deps",
      ],
    ],
    "type-case": [2, "always", "lowercase"],
    "type-empty": [2, "never"],
    "subject-case": [0], // Disabled - allow any case in subject
    "subject-empty": [2, "never"],
    "subject-full-stop": [2, "never", "."],
    "header-max-length": [2, "always", 100],
    "body-max-line-length": [2, "always", 100],
    // Scope is optional, but if used, must be from this list
    "scope-enum": [
      2,
      "always",
      [
        "api",
        "auth",
        "config",
        "core",
        "db",
        "infra",
        "ui",
        // Add project-specific scopes as needed
      ],
    ],
  },
};
