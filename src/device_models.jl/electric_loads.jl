

function LoadVariables(m::JuMP.Model, devices::Array{T,1}, T) where T <: InterruptibleLoad
    on_set = [d.name for d in devices if d.status == true]
    t = 1:T
    @variable(m::JuMP.Model, P_cl[on_set,t]) # Power output of generators
    return true    
end