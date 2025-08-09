# Sync Documentation with Version Tag

Automatically synchronize all documentation files when a new version tag is created.

## Usage
```
/sync-docs [version-tag]
```

**Example:** `/sync-docs v1.1.4`

## Process Overview

This command performs a comprehensive documentation update by comparing changes between the current version and the specified tag, then regenerating all relevant documentation files using SuperClaude framework.

## Steps

### 1. Version Analysis
- **Find previous version tag**: Use `git tag --sort=version:refname | grep -v [current-tag] | tail -1`
- **Compare versions**: `git diff [previous-tag]..[current-tag]` for changed files
- **Extract commits**: `git log --oneline [previous-tag]..[current-tag]` for changelog
- **Focus areas**: Files in `addons/card-framework/`, `example1/`, `freecell/`
- **Change categorization**: Breaking changes, new features, bug fixes, documentation

### 2. API Documentation Update
- Use `/analyze addons/card-framework/ --focus api --persona-scribe=en --ultrathink`
- Update `docs/API.md` with latest class references, methods, and properties
- Maintain existing documentation structure and formatting style
- Preserve manual annotations and examples where applicable

### 3. Changelog Generation  
- **Collect commits**: `git log --oneline [previous-tag]..[current-tag]` 
- **Categorize changes**: Group by type (feat:, fix:, docs:, refactor:, etc.)
- **Generate entries**: Use `--persona-scribe=en` following Keep a Changelog format
- **Update CHANGELOG.md**: Add new version section with categorized changes
- **Include context**: Breaking changes, deprecations, migration notes

### 4. README Updates
- **Main README.md**: Update version badges, feature descriptions if changed
- **example1/README.md**: Sync with any example project changes using `--persona-scribe=en`
- **freecell/README.md**: Update advanced implementation patterns using `--persona-scribe=en`
- Maintain educational tone and beginner-friendly approach for example1
- Preserve advanced framework extension focus for freecell

### 5. Documentation Index Update
- Update `docs/index.md` with any new documentation files
- Ensure all cross-references are working
- Update version information and compatibility notes

### 6. Quality Review
- Use SuperClaude Task tool for comprehensive documentation review
- Check for consistency across all updated files
- Verify markdown formatting and link integrity
- Validate version number consistency throughout all files

### 7. Git Integration
- Stage all updated documentation files
- Create commit with descriptive message following project conventions
- Tag commit appropriately if needed

## SuperClaude Configuration

**Personas Used:**
- `--persona-scribe=en` for all documentation generation
- `--persona-analyzer` for change analysis
- `--persona-qa` for final review

**Flags Applied:**
- `--ultrathink` for API analysis requiring deep understanding
- `--think-hard` for changelog generation and impact assessment  
- `--uc` for token efficiency during bulk operations
- `--validate` for quality assurance steps

**MCP Integration:**
- **Context7**: For framework patterns and documentation standards
- **Sequential**: For systematic multi-step documentation updates
- **Task**: For comprehensive quality review process

## Error Handling

- Verify git tag exists before starting
- Backup existing documentation files
- Rollback on any step failure
- Report specific errors and suggested fixes

## Dependencies

- Git repository with proper version tagging
- SuperClaude framework available
- Internet connection for MCP servers
- Write access to docs/ directory

## Example Workflow

```bash
# Developer creates new tag
git tag v1.1.4
git push origin v1.1.4

# Run documentation sync
claude "/sync-docs v1.1.4"

# Review and commit changes
git add docs/ *.md **/README.md
git commit -m "docs: sync documentation for v1.1.4"
```