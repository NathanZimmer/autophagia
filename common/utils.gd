extends Node
## Generic utility functions

## Whether verification functions call `push_warning` on failed optional component checks
const _WARN_ON_MISSING_OPTIONAL = true


## Verifies a component exists [br]
## ## Parameters [br]
## `caller`: Caller [br]
## `component`: The component to verify [br]
## `required`: If true, blocks on null check failure; else, pushes warning depending on
## `_WARN_ON_MISSING_OPTIONAL` [br]
## ## Returns [br]
## True if component is valid, false otherwise
func verify_component(caller: Variant, component: Variant, required: bool = false) -> bool:
    var valid := component != null
    if required:
        assert(valid, "%s: Required component is null" % str(caller))
    elif not valid and _WARN_ON_MISSING_OPTIONAL:
        push_warning("%s: Optional component is null" % str(caller))
    return valid


## Verifies all components in an array exist [br]
## ## Parameters [br]
## `caller`: Caller [br]
## `components`: The array of components to verify [br]
## `required`: If true, blocks on null check failure; else, pushes warning depending on
## `_WARN_ON_MISSING_OPTIONAL` [br]
## ## Returns [br]
## True if all components are valid, false otherwise
func verify_component_list(caller: Variant, components: Array, required: bool = false) -> bool:
    var valid := components.find(null) == -1
    if required:
        assert(
            valid,
            "%s: One or more required components is null: %s" % [str(caller), str(components)]
        )
    elif not valid and _WARN_ON_MISSING_OPTIONAL:
        push_warning(
            "%s: One or more optional components is null: %s" % [str(caller), str(components)]
        )
    return valid


## Transform `target` from `original_ref` frame into `new_ref` frame [br]
## ## Parameters [br]
## `target`: The global transform of interest [br]
## `original_ref`: The global reference transform to convert from [br]
## `new_ref`: The global reference transform to convert to [br]
## ## Returns [br]
## `new_transform`: The global transform of `target` rotated from
## `original_ref` into `new_ref` [br]
func get_relative_transform(
    target: Transform3D,
    orignal_ref: Transform3D,
    new_ref: Transform3D,
) -> Transform3D:
    var transform_offset := orignal_ref.affine_inverse() * target  # Get offset to orignal reference
    return new_ref * transform_offset  # Apply offest to new reference


## Get the type of `value` regardless of whether it is a primitive, built-in node, or user defined
## class [br]
## ## Parameters [br]
## `value`: Value to check [br]
## ## Returns [br]
## type as string
func get_type(value: Variant) -> String:
    if is_instance_of(value, Object):
        if value.has_method(&"get_script"):
            return value.get_script().get_global_name()
        return value.get_class()
    return type_string(typeof(value))
