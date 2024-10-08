# Default implementations of getter/setter functions for OperationModel.
is_built(model::OperationModel) =
    IS.Optimization.get_status(get_internal(model)) == ModelBuildStatus.BUILT
isempty(model::OperationModel) =
    IS.Optimization.get_status(get_internal(model)) == ModelBuildStatus.EMPTY
warm_start_enabled(model::OperationModel) =
    get_warm_start(get_optimization_container(model).settings)
built_for_recurrent_solves(model::OperationModel) =
    get_optimization_container(model).built_for_recurrent_solves
get_constraints(model::OperationModel) =
    IS.Optimization.get_constraints(get_internal(model))
get_execution_count(model::OperationModel) =
    IS.Optimization.get_execution_count(get_internal(model))
get_executions(model::OperationModel) = IS.Optimization.get_executions(get_internal(model))
get_initial_time(model::OperationModel) = get_initial_time(get_settings(model))
get_internal(model::OperationModel) = model.internal

function get_jump_model(model::OperationModel)
    return get_jump_model(IS.Optimization.get_container(get_internal(model)))
end

get_name(model::OperationModel) = model.name
get_store(model::OperationModel) = model.store
is_synchronized(model::OperationModel) = is_synchronized(get_optimization_container(model))

function get_rebuild_model(model::OperationModel)
    sim_info = model.simulation_info
    if sim_info === nothing
        error("Model not part of a simulation")
    end
    return get_rebuild_model(get_optimization_container(model).settings)
end

function get_optimization_container(model::OperationModel)
    return IS.Optimization.get_optimization_container(get_internal(model))
end

function get_resolution(model::OperationModel)
    resolution = get_resolution(get_settings(model))
    return resolution
end

get_problem_base_power(model::OperationModel) = PSY.get_base_power(model.sys)
get_settings(model::OperationModel) = get_optimization_container(model).settings
get_optimizer_stats(model::OperationModel) =
    get_optimizer_stats(get_optimization_container(model))
get_simulation_info(model::OperationModel) = model.simulation_info
get_simulation_number(model::OperationModel) = get_number(get_simulation_info(model))
set_simulation_number!(model::OperationModel, val) =
    set_number!(get_simulation_info(model), val)
get_sequence_uuid(model::OperationModel) = get_sequence_uuid(get_simulation_info(model))
set_sequence_uuid!(model::OperationModel, val) =
    set_sequence_uuid!(get_simulation_info(model), val)
get_status(model::OperationModel) = IS.Optimization.get_status(get_internal(model))
get_system(model::OperationModel) = model.sys
get_template(model::OperationModel) = model.template
get_log_file(model::OperationModel) = joinpath(get_output_dir(model), PROBLEM_LOG_FILENAME)
get_store_params(model::OperationModel) =
    IS.Optimization.get_store_params(get_internal(model))
get_output_dir(model::OperationModel) = IS.Optimization.get_output_dir(get_internal(model))
get_initial_conditions_file(model::OperationModel) =
    joinpath(get_output_dir(model), "initial_conditions.bin")
get_recorder_dir(model::OperationModel) =
    joinpath(get_output_dir(model), "recorder")
get_variables(model::OperationModel) = get_variables(get_optimization_container(model))
get_parameters(model::OperationModel) = get_parameters(get_optimization_container(model))
get_duals(model::OperationModel) = get_duals(get_optimization_container(model))
get_initial_conditions(model::OperationModel) =
    get_initial_conditions(get_optimization_container(model))

get_interval(model::OperationModel) = get_store_params(model).interval
get_run_status(model::OperationModel) = get_run_status(get_simulation_info(model))
set_run_status!(model::OperationModel, status) =
    set_run_status!(get_simulation_info(model), status)
get_time_series_cache(model::OperationModel) =
    IS.Optimization.get_time_series_cache(get_internal(model))
empty_time_series_cache!(x::OperationModel) = empty!(get_time_series_cache(x))

function get_current_timestamp(model::OperationModel)
    # For EmulationModel interval and resolution are the same.
    return get_initial_time(model) + get_execution_count(model) * get_interval(model)
end

function get_timestamps(model::OperationModel)
    optimization_container = get_optimization_container(model)
    start_time = get_initial_time(optimization_container)
    resolution = get_resolution(model)
    horizon_count = get_time_steps(optimization_container)[end]
    return range(start_time; length = horizon_count, step = resolution)
end

function write_data(model::OperationModel, output_dir::AbstractString; kwargs...)
    write_data(get_optimization_container(model), output_dir; kwargs...)
    return
end

function get_initial_conditions(
    model::OperationModel,
    ::T,
    ::U,
) where {T <: InitialConditionType, U <: PSY.Device}
    return get_initial_conditions(get_optimization_container(model), T, U)
end

function solve_impl!(model::OperationModel)
    container = get_optimization_container(model)
    model_name = get_name(model)
    ts = get_current_timestamp(model)
    output_dir = get_output_dir(model)

    if get_export_optimization_model(get_settings(model))
        model_output_dir = joinpath(output_dir, "optimization_model_exports")
        mkpath(model_output_dir)
        tss = replace("$(ts)", ":" => "_")
        model_export_path = joinpath(model_output_dir, "exported_$(model_name)_$(tss).json")
        serialize_optimization_model(container, model_export_path)
    end

    status = solve_impl!(container, get_system(model))
    set_run_status!(model, status)
    if status != RunStatus.SUCCESSFULLY_FINALIZED
        settings = get_settings(model)
        infeasible_opt_path = joinpath(output_dir, "infeasible_$(model_name).json")
        @error("Serializing Infeasible Problem at $(infeasible_opt_path)")
        serialize_optimization_model(container, infeasible_opt_path)
        if !get_allow_fails(settings)
            error("Solving model $(model_name) failed at $(ts)")
        else
            @error "Solving model $(model_name) failed at $(ts). Failure Allowed"
        end
    end
    return
end

set_console_level!(model::OperationModel, val) =
    IS.Optimization.set_console_level!(get_internal(model), val)
set_file_level!(model::OperationModel, val) =
    IS.Optimization.set_file_level!(get_internal(model), val)
function set_executions!(model::OperationModel, val::Int)
    IS.Optimization.set_executions!(get_internal(model), val)
    return
end

function set_execution_count!(model::OperationModel, val::Int)
    IS.Optimization.set_execution_count!(get_internal(model), val)
    return
end

set_initial_time!(model::OperationModel, val::Dates.DateTime) =
    set_initial_time!(get_settings(model), val)

get_simulation_info(model::OperationModel, val) = model.simulation_info = val

function set_status!(model::OperationModel, status::ModelBuildStatus)
    IS.Optimization.set_status!(get_internal(model), status)
    return
end

function set_output_dir!(model::OperationModel, path::AbstractString)
    IS.Optimization.set_output_dir!(get_internal(model), path)
    return
end

function advance_execution_count!(model::OperationModel)
    internal = get_internal(model)
    internal.execution_count += 1
    return
end

function build_initial_conditions!(model::OperationModel)
    @assert IS.Optimization.get_initial_conditions_model_container(get_internal(model)) ===
            nothing
    requires_init = false
    for (device_type, device_model) in get_device_models(get_template(model))
        requires_init = requires_initialization(get_formulation(device_model)())
        if requires_init
            @debug "initial_conditions required for $device_type" _group =
                LOG_GROUP_BUILD_INITIAL_CONDITIONS
            build_initial_conditions_model!(model)
            break
        end
    end
    if !requires_init
        @info "No initial conditions in the model"
    end
    return
end

function write_initial_conditions_data!(model::OperationModel)
    write_initial_conditions_data!(
        get_optimization_container(model),
        IS.Optimization.get_initial_conditions_model_container(get_internal(model)),
    )
    return
end

function handle_initial_conditions!(model::OperationModel)
    TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "Model Initialization" begin
        if isempty(get_template(model))
            return
        end
        settings = get_settings(model)
        initialize_model = get_initialize_model(settings)
        deserialize_initial_conditions = get_deserialize_initial_conditions(settings)
        serialized_initial_conditions_file = get_initial_conditions_file(model)
        custom_init_file = get_initialization_file(settings)

        if !initialize_model && deserialize_initial_conditions
            throw(
                IS.ConflictingInputsError(
                    "!initialize_model && deserialize_initial_conditions",
                ),
            )
        elseif !initialize_model && !isempty(custom_init_file)
            throw(IS.ConflictingInputsError("!initialize_model && initialization_file"))
        end

        if !initialize_model
            @info "Skip build of initial conditions"
            return
        end

        if !isempty(custom_init_file)
            if !isfile(custom_init_file)
                error("initialization_file = $custom_init_file does not exist")
            end
            if abspath(custom_init_file) != abspath(serialized_initial_conditions_file)
                cp(custom_init_file, serialized_initial_conditions_file; force = true)
            end
        end

        if deserialize_initial_conditions && isfile(serialized_initial_conditions_file)
            set_initial_conditions_data!(
                get_optimization_container(model),
                Serialization.deserialize(serialized_initial_conditions_file),
            )
            @info "Deserialized initial_conditions_data"
        else
            @info "Make Initial Conditions Model"
            build_initial_conditions!(model)
            initialize!(model)
        end
        IS.Optimization.set_initial_conditions_model_container!(
            get_internal(model),
            nothing,
        )
    end
    return
end

function initialize!(model::OperationModel)
    container = get_optimization_container(model)
    if IS.Optimization.get_initial_conditions_model_container(get_internal(model)) ===
       nothing
        return
    end
    @info "Solving Initialization Model for $(get_name(model))"
    status = solve_impl!(
        IS.Optimization.get_initial_conditions_model_container(get_internal(model)),
        get_system(model),
    )
    if status == RunStatus.FAILED
        error("Model failed to initialize")
    end

    write_initial_conditions_data!(
        container,
        IS.Optimization.get_initial_conditions_model_container(get_internal(model)),
    )
    init_file = get_initial_conditions_file(model)
    Serialization.serialize(init_file, get_initial_conditions_data(container))
    @info "Serialized initial conditions to $init_file"
    return
end

# TODO: Document requirements for solve_impl
# function solve_impl!(model::OperationModel)
# end

function validate_template(model::OperationModel)
    template = get_template(model)
    if isempty(template)
        error("Template can't be empty for models $(get_problem_type(model))")
    end
    modeled_types = get_component_types(template)
    system = get_system(model)
    system_component_types = PSY.get_existing_component_types(system)
    exclusions = [PSY.Arc, PSY.Area, PSY.ACBus, PSY.LoadZone]
    for m in setdiff(modeled_types, system_component_types)
        @warn "The system data doesn't include components of type $(m), consider changing the models in the template" _group =
            LOG_GROUP_MODELS_VALIDATION
    end
    for m in setdiff(system_component_types, union(modeled_types, exclusions))
        @warn "The template doesn't include models for components of type $(m), consider changing the template" _group =
            LOG_GROUP_MODELS_VALIDATION
    end
    return
end

function build_if_not_already_built!(model::OperationModel; kwargs...)
    status = get_status(model)
    if status == ModelBuildStatus.EMPTY
        if !haskey(kwargs, :output_dir)
            error(
                "'output_dir' must be provided as a kwarg if the model build status is $status",
            )
        else
            new_kwargs = Dict(k => v for (k, v) in kwargs if k != :optimizer)
            status = build!(model; new_kwargs...)
        end
    end
    if status != ModelBuildStatus.BUILT
        error("build! of the $(typeof(model)) $(get_name(model)) failed: $status")
    end
    return
end

function _check_numerical_bounds(model::OperationModel)
    variable_bounds = get_variable_numerical_bounds(model)
    if variable_bounds.bounds.max - variable_bounds.bounds.min > 1e9
        @warn "Variable bounds range is $(variable_bounds.bounds.max - variable_bounds.bounds.min) and can result in numerical problems for the solver. \\
        max_bound_variable = $(encode_key_as_string(variable_bounds.bounds.max_index)) \\
        min_bound_variable = $(encode_key_as_string(variable_bounds.bounds.min_index)) \\
        Run get_detailed_variable_numerical_bounds on the model for a deeper analysis"
    else
        @info "Variable bounds range is [$(variable_bounds.bounds.min) $(variable_bounds.bounds.max)]"
    end

    constraint_bounds = get_constraint_numerical_bounds(model)
    if constraint_bounds.coefficient.max - constraint_bounds.coefficient.min > 1e9
        @warn "Constraint coefficient bounds range is $(constraint_bounds.coefficient.max - constraint_bounds.coefficient.min) and can result in numerical problems for the solver. \\
        max_bound_constraint = $(encode_key_as_string(constraint_bounds.coefficient.max_index)) \\
        min_bound_constraint = $(encode_key_as_string(constraint_bounds.coefficient.min_index)) \\
        Run get_detailed_constraint_numerical_bounds on the model for a deeper analysis"
    else
        @info "Constraint coefficient bounds range is [$(constraint_bounds.coefficient.min) $(constraint_bounds.coefficient.max)]"
    end

    if constraint_bounds.rhs.max - constraint_bounds.rhs.min > 1e9
        @warn "Constraint right-hand-side bounds range is $(constraint_bounds.rhs.max - constraint_bounds.rhs.min) and can result in numerical problems for the solver. \\
        max_bound_constraint = $(encode_key_as_string(constraint_bounds.rhs.max_index)) \\
        min_bound_constraint = $(encode_key_as_string(constraint_bounds.rhs.min_index)) \\
        Run get_detailed_constraint_numerical_bounds on the model for a deeper analysis"
    else
        @info "Constraint right-hand-side bounds [$(constraint_bounds.rhs.min) $(constraint_bounds.rhs.max)]"
    end
    return
end

function _pre_solve_model_checks(model::OperationModel, optimizer = nothing)
    jump_model = get_jump_model(model)
    if optimizer !== nothing
        JuMP.set_optimizer(jump_model, optimizer)
    end

    if JuMP.mode(jump_model) != JuMP.DIRECT
        if JuMP.backend(jump_model).state == MOIU.NO_OPTIMIZER
            error("No Optimizer has been defined, can't solve the operational problem")
        end
    else
        @assert get_direct_mode_optimizer(get_settings(model))
    end

    optimizer_name = JuMP.solver_name(jump_model)
    @info "$(get_name(model)) optimizer set to: $optimizer_name"
    settings = get_settings(model)
    if get_check_numerical_bounds(settings)
        @info "Checking Numerical Bounds"
        TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "Numerical Bounds Check" begin
            _check_numerical_bounds(model)
        end
    end
    return
end

function _list_names(model::OperationModel, container_type)
    return encode_keys_as_strings(
        IS.Optimization.list_keys(get_store(model), container_type),
    )
end

read_dual(model::OperationModel, key::ConstraintKey) = _read_results(model, key)
read_parameter(model::OperationModel, key::ParameterKey) = _read_results(model, key)
read_aux_variable(model::OperationModel, key::AuxVarKey) = _read_results(model, key)
read_variable(model::OperationModel, key::VariableKey) = _read_results(model, key)
read_expression(model::OperationModel, key::ExpressionKey) = _read_results(model, key)

function _read_col_name(axes)
    if length(axes) == 1
        error("Axes of size 1 are not supported")
    end
    # Currently, variables that don't have timestamps have a dummy axes to keep
    # two axes in the Store (HDF or Memory). This if-else is used to decide if a
    # dummy axes is being used or not.
    if typeof(axes[2]) <: UnitRange{Int}
        return axes[1]
    elseif typeof(axes[2]) <: Vector{String}
        IS.@assert_op length(axes[1]) == 1
        return axes[2]
    else
        error("Second axes in store is not allowed to be $(typeof(axes[2]))")
    end
end

function _read_results(model::OperationModel, key::OptimizationContainerKey)
    res = read_results(get_store(model), key)
    col_name = _read_col_name(axes(res))
    return DataFrames.DataFrame(permutedims(res.data), col_name)
end

read_optimizer_stats(model::OperationModel) = read_optimizer_stats(get_store(model))

function add_recorders!(model::OperationModel, recorders)
    internal = get_internal(model)
    for name in union(REQUIRED_RECORDERS, recorders)
        IS.Optimization.add_recorder!(internal, name)
    end
end

function register_recorders!(model::OperationModel, file_mode)
    recorder_dir = get_recorder_dir(model)
    mkpath(recorder_dir)
    for name in IS.Optimization.get_recorders(get_internal(model))
        IS.register_recorder!(name; mode = file_mode, directory = recorder_dir)
    end
end

function unregister_recorders!(model::OperationModel)
    for name in IS.Optimization.get_recorders(get_internal(model))
        IS.unregister_recorder!(name)
    end
end

const _JUMP_MODEL_FILENAME = "jump_model.json"

function serialize_optimization_model(model::OperationModel)
    serialize_optimization_model(
        get_optimization_container(model),
        joinpath(get_output_dir(model), _JUMP_MODEL_FILENAME),
    )
    return
end

function update_model!(model::OperationModel, source, ini_cond_chronology)
    TimerOutputs.@timeit RUN_SIMULATION_TIMER "Parameter Updates" begin
        update_parameters!(model, get_decision_states(source))
    end
    TimerOutputs.@timeit RUN_SIMULATION_TIMER "Ini Cond Updates" begin
        update_initial_conditions!(model, source, ini_cond_chronology)
    end
    return
end

function instantiate_network_model(model::OperationModel)
    template = get_template(model)
    network_model = get_network_model(template)
    instantiate_network_model(network_model, get_system(model))
    return
end

list_aux_variable_keys(x::OperationModel) =
    IS.Optimization.list_keys(get_store(x), STORE_CONTAINER_AUX_VARIABLES)
list_aux_variable_names(x::OperationModel) = _list_names(x, STORE_CONTAINER_AUX_VARIABLES)
list_variable_keys(x::OperationModel) =
    IS.Optimization.list_keys(get_store(x), STORE_CONTAINER_VARIABLES)
list_variable_names(x::OperationModel) = _list_names(x, STORE_CONTAINER_VARIABLES)
list_parameter_keys(x::OperationModel) =
    IS.Optimization.list_keys(get_store(x), STORE_CONTAINER_PARAMETERS)
list_parameter_names(x::OperationModel) = _list_names(x, STORE_CONTAINER_PARAMETERS)
list_dual_keys(x::OperationModel) =
    IS.Optimization.list_keys(get_store(x), STORE_CONTAINER_DUALS)
list_dual_names(x::OperationModel) = _list_names(x, STORE_CONTAINER_DUALS)
list_expression_keys(x::OperationModel) =
    IS.Optimization.list_keys(get_store(x), STORE_CONTAINER_EXPRESSIONS)
list_expression_names(x::OperationModel) = _list_names(x, STORE_CONTAINER_EXPRESSIONS)

function list_all_keys(x::OperationModel)
    return Iterators.flatten(
        keys(get_data_field(get_store(x), f)) for f in STORE_CONTAINERS
    )
end

function serialize_optimization_model(model::OperationModel, save_path::String)
    serialize_jump_optimization_model(
        get_jump_model(get_optimization_container(model)),
        save_path,
    )
    return
end
