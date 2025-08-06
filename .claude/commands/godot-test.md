# Godot Card Framework Testing

Create scenes or scripts to test Card Framework functionality.

## Usage
```  
/godot-test [test_type] [component]
```

## Steps:
1. Identify key features of the component to test
2. Create test scene (.tscn) or script (.gd)
3. Compare expected behavior with actual behavior
4. Test edge cases and error conditions
5. Document test results

## Test Types:
- unit: Individual class/method testing
- integration: Inter-component interaction testing
- performance: Performance and memory usage testing
- visual: UI/animation behavior testing
- gameplay: Real gameplay scenario testing

## Testable Components:
- Card drag-and-drop
- CardContainer add/remove
- Hand reordering
- Pile stacking
- Factory card creation
- History undo/redo