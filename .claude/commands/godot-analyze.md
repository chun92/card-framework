# Godot Card Framework Analysis

Analyze specific components of the Godot Card Framework project.

## Usage
```
/godot-analyze [component]
```

## Steps:
1. Read the GDScript files of the requested component to understand structure
2. Analyze related scene (.tscn) files if available
3. Check dependency relationships with other components
4. Review compliance with Godot 4.x best practices
5. Suggest improvements or extension possibilities

## Analysis Targets:
- Card (base card class)
- CardContainer (card container base class)  
- Pile (card stack)
- Hand (player hand)
- CardManager (card manager)
- CardFactory (card factory)
- DraggableObject (draggable object)
- DropZone (drop zone)