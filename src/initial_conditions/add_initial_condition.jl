function _get_initial_condition_value(
    ::Vector{T},
    component::PSY.Component,
    ::U,
    ::V,
    ::OptimizationContainer,
) where {
    T <: InitialCondition{U, Float64},
    V <: Union{
        AbstractDeviceFormulation,
        AbstractServiceFormulation,
    },
} where {U <: InitialConditionType}
    val = get_initial_condition_value(U(), component, V())
    return T(component, val)
end

function _get_initial_condition_value(
    ::Vector{T},
    component::PSY.Component,
    ::U,
    ::V,
    container::OptimizationContainer,
) where {
    T <: InitialCondition{U, PJ.ParameterRef},
    V <: Union{
        AbstractDeviceFormulation,
        AbstractServiceFormulation,
    },
} where {U <: InitialConditionType}
    val = get_initial_condition_value(U(), component, V())
    return T(component, add_jump_parameter(get_jump_model(container), val))
end

function add_initial_condition!(
    container::OptimizationContainer,
    components::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    ::U,
    ::D,
) where {
    T <: PSY.Component,
    U <: Union{AbstractDeviceFormulation, AbstractServiceFormulation},
    D <: InitialConditionType,
}
    ini_cond_vector = add_initial_condition_container!(container, D(), T, components)
    for (ix, component) in enumerate(components)
        ini_cond_vector[ix] =
            _get_initial_condition_value(ini_cond_vector, component, D(), U(), container)
    end
end
