# Godot Card Framework Export

Package the Card Framework for Godot AssetLib or export to other projects.

## Usage
```
/godot-export [type] [options]
```

## Steps:
1. Select files to export (addons/card-framework/*)
2. Exclude unnecessary files (.import, .tmp, etc.)
3. Check/create plugin.cfg file
4. Organize README and documentation files
5. Decide whether to include example projects
6. Create compressed package or prepare for AssetLib

## Export Types:
- assetlib: Package for Godot AssetLib
- addon: Addon for other projects
- source: Source code only
- complete: Complete package with examples

## Key Files to Include:
- addons/card-framework/ (core framework)
- example1/ (basic example)
- freecell/ (advanced example)
- README.md
- LICENSE.md