# Version Helper Commands

Utility commands for version comparison and analysis in documentation sync workflows.

## Git Commands for Version Analysis

### Find Previous Version Tag
```bash
# Get all version tags sorted by version number
CURRENT_TAG="v1.1.4"
PREVIOUS_TAG=$(git tag --sort=version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | grep -v "$CURRENT_TAG" | tail -1)
echo "Comparing $PREVIOUS_TAG → $CURRENT_TAG"
```

### Compare Versions
```bash
# Get changed files between versions
git diff --name-only $PREVIOUS_TAG..$CURRENT_TAG

# Focus on framework files
git diff --name-only $PREVIOUS_TAG..$CURRENT_TAG -- addons/card-framework/

# Get commit messages for changelog
git log --oneline $PREVIOUS_TAG..$CURRENT_TAG

# Get detailed changes for specific files
git diff $PREVIOUS_TAG..$CURRENT_TAG -- addons/card-framework/
```

### Change Categorization
```bash
# Categorize commits by conventional commit types
git log --oneline $PREVIOUS_TAG..$CURRENT_TAG | grep -E '^[a-f0-9]+ feat:'    # New features
git log --oneline $PREVIOUS_TAG..$CURRENT_TAG | grep -E '^[a-f0-9]+ fix:'     # Bug fixes  
git log --oneline $PREVIOUS_TAG..$CURRENT_TAG | grep -E '^[a-f0-9]+ docs:'    # Documentation
git log --oneline $PREVIOUS_TAG..$CURRENT_TAG | grep -E '^[a-f0-9]+ refactor:' # Refactoring
git log --oneline $PREVIOUS_TAG..$CURRENT_TAG | grep -E '^[a-f0-9]+ test:'    # Tests
```

### Quick Sync Change Detection
```bash
# Working directory changes
git diff --name-only HEAD

# Staged changes
git diff --cached --name-only  

# Focus on API-affecting files
git diff --name-only HEAD -- addons/card-framework/ | grep '\.gd$'

# Check if any GDScript files changed
if git diff --name-only HEAD -- addons/card-framework/ | grep -q '\.gd$'; then
    echo "API files changed - documentation update needed"
fi
```

## Claude Commands Integration

### Full Sync Implementation
```bash
#!/bin/bash
# Implementation for /sync-docs command

CURRENT_TAG="$1"
PREVIOUS_TAG=$(git tag --sort=version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | grep -v "$CURRENT_TAG" | tail -1)

echo "📊 Analyzing changes from $PREVIOUS_TAG to $CURRENT_TAG"

# Get changed files
CHANGED_FILES=$(git diff --name-only $PREVIOUS_TAG..$CURRENT_TAG -- addons/card-framework/)

# Get commit messages for changelog
COMMITS=$(git log --oneline $PREVIOUS_TAG..$CURRENT_TAG)

# Pass to Claude for analysis
claude "/analyze addons/card-framework/ --focus api --persona-scribe=en --ultrathink --context '$CHANGED_FILES' --changelog-commits '$COMMITS'"
```

### Quick Sync Implementation  
```bash
#!/bin/bash
# Implementation for /quick-sync command

# Check for changes
WORKING_CHANGES=$(git diff --name-only HEAD -- addons/card-framework/ | grep '\.gd$' || true)
STAGED_CHANGES=$(git diff --cached --name-only -- addons/card-framework/ | grep '\.gd$' || true)

if [ -z "$WORKING_CHANGES" ] && [ -z "$STAGED_CHANGES" ]; then
    echo "✅ No API changes detected"
    exit 0
fi

echo "📝 Updating documentation for changed files:"
echo "$WORKING_CHANGES"
echo "$STAGED_CHANGES"

# Quick analysis of changed files only
claude "/analyze $WORKING_CHANGES $STAGED_CHANGES --focus api --persona-scribe=en --uc --incremental-update docs/API.md"
```

## Version Tag Best Practices

### Semantic Versioning
- `v1.0.0` - Major version (breaking changes)
- `v1.1.0` - Minor version (new features, backward compatible)  
- `v1.1.1` - Patch version (bug fixes)

### Tagging Workflow
```bash
# Create and push tag
git tag v1.1.4 -m "Release version 1.1.4"
git push origin v1.1.4

# List all tags
git tag -l --sort=version:refname

# Get latest tag  
git describe --tags --abbrev=0

# Check if tag exists
git rev-parse --verify "refs/tags/v1.1.4" >/dev/null 2>&1
```

## Error Handling

### Common Issues
1. **No previous tag found**: Handle initial release case
2. **Invalid tag format**: Validate semantic versioning
3. **Empty diff**: Handle no changes between versions
4. **Tag doesn't exist**: Verify tag before processing

### Fallback Strategies
```bash
# If no previous tag, use initial commit
PREVIOUS_TAG=${PREVIOUS_TAG:-$(git rev-list --max-parents=0 HEAD)}

# If current tag doesn't exist, use HEAD
CURRENT_TAG=${CURRENT_TAG:-"HEAD"}

# Validate tag format
if [[ ! "$CURRENT_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Warning: Tag format should be vX.Y.Z"
fi
```