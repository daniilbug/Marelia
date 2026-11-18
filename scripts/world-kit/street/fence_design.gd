@tool
class_name StreetFenceDesign
extends StreetPropDesign

## Distance between section starts. Shared end posts are rendered only once.
@export_range(1, 1024, 1) var section_step := 29
