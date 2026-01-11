# Release Scripts

Scripts for creating Card Framework releases.

## Quick Start

### Linux / Mac / Git Bash (Windows)
```bash
chmod +x scripts/create-release.sh
./scripts/create-release.sh 1.3.1
```

### Windows PowerShell
```powershell
.\scripts\create-release.ps1 1.3.1
```

## What the Script Does

1. **Validates** version format (X.Y.Z)
2. **Checks** for uncommitted changes
3. **Creates** full project archive in `releases/` folder
4. **Excludes** unnecessary files:
   - `.git/`, `.godot/`, `*.import`
   - `.taskmaster/`, `.vscode/`, `.env`
   - `releases/`, `.claude/`
5. **Verifies** archive contains required directories
6. **Displays** next steps for GitHub Release

## Output

**File location:** `releases/card-framework-vX.Y.Z-full.zip`

**Contains:**
- `addons/card-framework/` - Core addon code
- `example1/` - Basic example project
- `freecell/` - Complete FreeCell game
- `docs/` - Full documentation
- `README.md`, `LICENSE.md`, etc.

## Manual Release Process

### 1. Update Version Numbers

Before running the script, update version in:
- `addons/card-framework/README.md` (line 27)
- `README.md` (line 3 and 80)
- `docs/CHANGELOG.md` (add new entry)

### 2. Run Release Script

```bash
# Bash
./scripts/create-release.sh 1.3.1

# PowerShell
.\scripts\create-release.ps1 1.3.1
```

### 3. Test the Archive

```bash
# Extract to test folder
unzip releases/card-framework-v1.3.1-full.zip -d test-extract/

# Open in Godot
cd test-extract
godot project.godot

# Test both examples
# - Run example1/example1.tscn
# - Run freecell/scenes/menu/menu.tscn
```

### 4. Create Git Tag

```bash
git tag -a v1.3.1 -m "Release v1.3.1"
git push origin v1.3.1
```

### 5. Create GitHub Release

1. Go to https://github.com/chun92/card-framework/releases/new
2. Select tag: `v1.3.1`
3. Release title: `Card Framework v1.3.1`
4. Upload `releases/card-framework-v1.3.1-full.zip`
5. Add release notes:

```markdown
## What's New in v1.3.1

### Features
- New feature description

### Bug Fixes
- Fixed issue description

### Documentation
- Updated documentation

## Downloads

- **For Asset Library users:** "Source code (zip)" - Addon only
- **For learning/development:** "card-framework-v1.3.1-full.zip" - Includes examples and documentation

## Installation

**From Asset Library:**
Search "Card Framework" in Godot's AssetLib tab

**Manual Installation:**
Extract and copy `addons/card-framework/` to your project

## Full Changelog

See [CHANGELOG.md](https://github.com/chun92/card-framework/blob/main/docs/CHANGELOG.md)
```

6. Publish release

### 6. Update Asset Library Submission

If this is a new major/minor version, update the Asset Library entry:
- Go to https://godotengine.org/asset-library/asset
- Update version and download link

## GitHub Actions (Optional)

For automated releases, see `.github/workflows/release.yml` (to be created).

## Troubleshooting

### "Permission denied" on Bash script
```bash
chmod +x scripts/create-release.sh
```

### PowerShell execution policy error
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Archive missing files
- Check exclude patterns in script
- Verify `.gitattributes` is not affecting manual zip creation

### "Must run from project root" error
```bash
cd /path/to/card-framework
./scripts/create-release.sh 1.3.1
```

## Notes

- Script creates archive in `releases/` folder (auto-created)
- Always test the archive before publishing
- GitHub's automatic "Source code" downloads respect `.gitattributes`
- Manual upload (`-full.zip`) ignores `.gitattributes`
