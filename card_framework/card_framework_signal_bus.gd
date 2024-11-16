extends Node

signal drop_zone_added(zone_id: int, zone_node: DropZone)
signal drop_zone_deleted(zone_id: int)

signal drag_dropped(card: Card)
signal card_dropped(card: Card, drop_zone: DropZone)
signal card_move_done(card: Card)
