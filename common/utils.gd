extends Node
## Generic utility functions


## Verifies a component exists [br]
## ## Parameters [br]
## `caller`: Caller [br]
## `component`: The component to verify [br]
## `required`: If true, blocks on null check failure; else, pushes warning [br]
## ## Returns [br]
## True if component is valid, false otherwise
func verify_component(caller: Variant, component: Variant, required: bool = false) -> bool:
    if required:
        assert(component, "%s %s: Required component is null" % str(caller))
    elif not component:
        push_warning("%s: Optional component is null" % str(caller))
        return false
    return true


## Verifies all components in an array exist [br]
## ## Parameters [br]
## `caller`: Caller [br]
## `components`: The array of components to verify [br]
## `required`: If true, blocks on null check failure; else, pushes warning [br]
## ## Returns [br]
## True if all components are valid, false otherwise
func verify_component_list(caller: Variant, components: Array, required: bool = false) -> bool:
    var valid := components.find(null) == -1
    if required:
        assert(
            valid,
            "%s: One or more required components is null: %s" % [str(caller), str(components)]
        )
    elif not valid:
        push_warning(
            "%s: One or more optional components is null: %s" % [str(caller), str(components)]
        )
        return false
    return true
