extends Node
## Generic utility functions


## Verifies a component exists [br]
## ## Parameters [br]
## `component`: The component to verify [br]
## `required`: If true, blocks on null check failure; else, pushes warning [br]
## ## Returns [br]
## True if component is valid, false otherwise
func verify_component(component: Variant, required: bool = false) -> bool:
    if required:
        assert(component, "Required component is null")
    elif not component:
        push_warning("Optional component is null")
        return false
    return true


## Verifies all components in an array exist [br]
## ## Parameters [br]
## `components`: The array of components to verify [br]
## `required`: If true, blocks on null check failure; else, pushes warning [br]
## ## Returns [br]
## True if all components are valid, false otherwise
func verify_component_list(components: Array, required: bool = false) -> bool:
    var valid := components.find(null) == -1
    if required:
        assert(valid, "One or more required components is null: %s" % components)
    elif not valid:
        push_warning("One or more optional components is null: %s" % components)
        return false
    return true
