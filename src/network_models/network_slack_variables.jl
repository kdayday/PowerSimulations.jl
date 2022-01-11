get_variable_multiplier(::SystemBalanceSlackUp, ::Type{PSY.System}, _) = 1.0
get_variable_multiplier(::SystemBalanceSlackDown, ::Type{PSY.System}, _) = -1.0

function add_variables!(
    container::OptimizationContainer,
    ::Type{T},
    ::PSY.System,
    ::Type{U},
) where {
    T <: Union{SystemBalanceSlackUp, SystemBalanceSlackDown},
    U <: Union{CopperPlatePowerModel, StandardPTDFModel},
}
    time_steps = get_time_steps(container)
    variable = add_variable_container!(container, T(), PSY.System, time_steps)

    for t in time_steps
        variable[t] =
            JuMP.@variable(container.JuMPmodel, base_name = "$(T)_{$t}", lower_bound = 0.0)
    end
    return
end

function cost_function!(
    container,
    ::Type{PSY.System},
    model::NetworkModel{T},
    S::Type{T},
) where {T <: Union{CopperPlatePowerModel, StandardPTDFModel}}
    variable_up = get_variable(container, SystemBalanceSlackUp(), PSY.System)
    variable_dn = get_variable(container, SystemBalanceSlackDown(), PSY.System)

    for t in get_time_steps(container)
        add_to_objective_function!(
            container,
            (variable_dn[t] + variable_up[t]) * BALANCE_SLACK_COST,
        )
    end
    return
end
