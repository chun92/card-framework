# Quick Documentation Sync

Fast documentation update for development workflow - compares working directory with last commit.

## Usage
```
/quick-sync
```

## Process

### 1. Change Detection
- **Compare with HEAD**: `git diff --name-only HEAD` for working directory changes
- **Check staged files**: `git diff --cached --name-only` for staged changes
- **Focus on**: Only files in `addons/card-framework/` that affect public API

### 2. API Quick Update
- **Conditional analysis**: Only if GDScript files changed
- **Fast scan**: `/analyze [changed-files] --focus api --persona-scribe=en --uc`
- **Incremental update**: Update only affected sections in `docs/API.md`
- **Skip**: Comprehensive regeneration and changelog

### 3. Documentation Consistency Check
- **Version validation**: Ensure version numbers are consistent across files
- **Link verification**: Quick check of internal documentation links
- **Format validation**: Basic markdown syntax verification

### 4. Fast Review
- **Change summary**: Report what was updated and why
- **Warning flags**: Highlight potential issues requiring manual review
- **Recommendations**: Suggest when full `/sync-docs` is needed

## Use Cases
- **Development**: After API changes, before committing
- **PR preparation**: Quick validation before creating pull request
- **Continuous validation**: During iterative development cycles
- **Staging check**: Before pushing to shared branches

## When to Use Full Sync Instead
- Before creating version tags
- After major API changes
- When example projects are modified
- For release preparation

**Note:** This command works with uncommitted changes. For release preparation, always use `/sync-docs` with proper version tag.