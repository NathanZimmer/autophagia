extends Node
## Generic utility functions

## Push warning for `verify_component_list()` calls with `required=false`
const WARN_MISSING_OPTIONAL = false


## Verifies a component exists [br]
## ## Parameters [br]
## `caller`: Caller [br]
## `component`: The component to verify [br]
## `required`: If true, blocks on null check failure; else, pushes warning [br]
## ## Returns [br]
## True if component is valid, false otherwise
func verify_component(caller: Variant, component: Variant, required: bool = false) -> bool:
    var valid := component != null
    if required:
        assert(valid, "%s %s: Required component is null" % str(caller))
    elif not valid and WARN_MISSING_OPTIONAL:
        push_warning("%s: Optional component is null" % str(caller))
    return valid


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
    elif not valid and WARN_MISSING_OPTIONAL:
        push_warning(
            "%s: One or more optional components is null: %s" % [str(caller), str(components)]
        )
    return valid
