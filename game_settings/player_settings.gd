class_name PlayerSettings extends Resource
## Holds runtime-configurable player settings

signal mouse_sensitivity_updated
signal mouse_inverted_updated
signal fov_updated

@export_range(1, 100, 1) var mouse_sensitivity := 50:
    set(value):
        if value != mouse_sensitivity:
            mouse_sensitivity = value
            mouse_sensitivity_updated.emit(value)

@export var mouse_inverted := false:
    set(value):
        if value != mouse_inverted:
            mouse_inverted = value
            mouse_inverted_updated.emit(value)

@export_range(50, 110) var fov := 90:
    set(value):
        if value != fov:
            fov = value
            fov_updated.emit(value)
