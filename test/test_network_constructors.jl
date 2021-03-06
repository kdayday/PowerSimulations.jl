thermal_model = DeviceModel(ThermalStandard, ThermalDispatch)
load_model = DeviceModel(PowerLoad, StaticPowerLoad)
line_model = DeviceModel(Line, StaticLine)
transformer_model = DeviceModel(Transformer2W, StaticTransformer)
ttransformer_model = DeviceModel(TapTransformer, StaticTransformer)
dc_line = DeviceModel(HVDCLine, HVDCDispatch)

@testset "Network Copper Plate" begin
    network = CopperPlatePowerModel
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
    c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
    systems = [c_sys5, c_sys14, c_sys14_dc]
    parameters = [true, false]
    test_results = IdDict{System, Vector{Int}}(
        c_sys5 => [120, 0, 120, 120, 24],
        c_sys14 => [120, 0, 120, 120, 24],
        c_sys14_dc => [120, 0, 120, 120, 24],
    )
    constraint_names = [:CopperPlateBalance]
    objfuncs = [GAEVF, GQEVF, GQEVF]

    for (ix, sys) in enumerate(systems), p in parameters
        ps_model = OperationsProblem(
            TestOpProblem,
            network,
            sys;
            optimizer = OSQP_optimizer,
            use_parameters = p,
        )
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)
        construct_network!(ps_model, network)
        construct_device!(ps_model, :Line, line_model)
        construct_device!(ps_model, :Tf, transformer_model)
        construct_device!(ps_model, :TTf, ttransformer_model)
        construct_device!(ps_model, :DCLine, dc_line)

        moi_tests(
            ps_model,
            p,
            test_results[sys][1],
            test_results[sys][2],
            test_results[sys][3],
            test_results[sys][4],
            test_results[sys][5],
            false,
        )
        psi_constraint_test(ps_model, constraint_names)
        psi_checkobjfun_test(ps_model, objfuncs[ix])
        psi_checksolve_test(ps_model, [MOI.OPTIMAL, MOI.ALMOST_OPTIMAL])
    end
end

@testset "Network DC-PF with PTDF formulation" begin
    network = StandardPTDFModel
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
    c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
    systems = [c_sys5, c_sys14, c_sys14_dc]
    objfuncs = [GAEVF, GQEVF, GQEVF]
    constraint_names =
        [:RateLimit_lb__Line, :RateLimit_ub__Line, :CopperPlateBalance, :network_flow]
    parameters = [true, false]
    PTDF_ref = IdDict{System, PTDF}(
        c_sys5 => PTDF(c_sys5),
        c_sys14 => PTDF(c_sys14),
        c_sys14_dc => PTDF(c_sys14_dc),
    )
    test_results = IdDict{System, Vector{Int}}(
        c_sys5 => [264, 0, 264, 264, 168],
        c_sys14 => [600, 0, 600, 600, 504],
        c_sys14_dc => [600, 48, 552, 552, 456],
    )

    for (ix, sys) in enumerate(systems), p in parameters
        ps_model = OperationsProblem(
            TestOpProblem,
            network,
            sys;
            optimizer = OSQP_optimizer,
            use_parameters = p,
            PTDF = PTDF_ref[sys],
            constraint_duals = constraint_names,
        )
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)
        construct_network!(ps_model, network)
        construct_device!(ps_model, :Line, line_model)
        construct_device!(ps_model, :Tf, transformer_model)
        construct_device!(ps_model, :TTf, ttransformer_model)
        construct_device!(ps_model, :DCLine, dc_line)

        moi_tests(
            ps_model,
            p,
            test_results[sys][1],
            test_results[sys][2],
            test_results[sys][3],
            test_results[sys][4],
            test_results[sys][5],
            false,
        )
        psi_constraint_test(ps_model, constraint_names)
        psi_checkobjfun_test(ps_model, objfuncs[ix])
        psi_checksolve_test(ps_model, [MOI.ALMOST_OPTIMAL, MOI.OPTIMAL])
    end

    #PTDF input Error testing
    ps_model = OperationsProblem(TestOpProblem, network, c_sys5; optimizer = GLPK_optimizer)
    construct_device!(ps_model, :Thermal, thermal_model)
    construct_device!(ps_model, :Load, load_model)
end

@testset "Network DC lossless -PF network with PowerModels DCPlosslessForm" begin
    network = DCPPowerModel
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
    c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
    systems = [c_sys5, c_sys14, c_sys14_dc]
    objfuncs = [GAEVF, GQEVF, GQEVF]
    constraint_names = [
        :RateLimit_ub__Line,
        :RateLimit_lb__Line,
        PSI.make_constraint_name(PSI.NODAL_BALANCE_ACTIVE, PSY.Bus),
    ]
    parameters = [true, false]
    test_results = Dict{System, Vector{Int}}(
        c_sys5 => [384, 0, 408, 408, 288],
        c_sys14 => [936, 0, 1080, 1080, 840],
        c_sys14_dc => [984, 48, 984, 984, 840],
    )

    for (ix, sys) in enumerate(systems), p in parameters
        ps_model = OperationsProblem(
            TestOpProblem,
            network,
            sys;
            optimizer = OSQP_optimizer,
            use_parameters = p,
        )
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)
        construct_network!(ps_model, network)
        construct_device!(ps_model, :Line, line_model)
        construct_device!(ps_model, :Tf, transformer_model)
        construct_device!(ps_model, :TTf, ttransformer_model)
        construct_device!(ps_model, :DCLine, dc_line)

        moi_tests(
            ps_model,
            p,
            test_results[sys][1],
            test_results[sys][2],
            test_results[sys][3],
            test_results[sys][4],
            test_results[sys][5],
            false,
        )
        psi_constraint_test(ps_model, constraint_names)
        psi_checkobjfun_test(ps_model, objfuncs[ix])
        psi_checksolve_test(ps_model, [MOI.OPTIMAL, MOI.ALMOST_OPTIMAL])
    end
end

@testset "Test Locational Marginal Prices between DC lossless with PowerModels vs StandardPTDFModel" begin
    network = [DCPPowerModel, StandardPTDFModel]
    sys = PSB.build_system(PSITestSystems, "c_sys5")
    dual_constraint = [[:nodal_balance_active__Bus], [:CopperPlateBalance, :network_flow]]
    services = Dict{Symbol, ServiceModel}()
    devices = Dict(:Thermal => thermal_model, :Load => load_model)
    branches = Dict{Symbol, DeviceModel}(
        :Line => line_model,
        :Tf => transformer_model,
        :Ttf => ttransformer_model,
        :DCLine => dc_line,
    )
    parameters = [true, false]
    ptdf = PTDF(sys)
    LMPs = []
    for (ix, net) in enumerate(network), p in parameters
        template = OperationsProblemTemplate(net, devices, branches, services)
        ps_model = OperationsProblem(
            TestOpProblem,
            template,
            sys;
            optimizer = OSQP_optimizer,
            use_parameters = p,
            PTDF = ptdf,
            constraint_duals = dual_constraint[ix],
        )

        if net == StandardPTDFModel
            push!(LMPs, abs.(psi_ptdf_lmps(ps_model, ptdf)))
        else
            res = solve!(ps_model)
            duals = abs.(res.dual_values[:nodal_balance_active__Bus])
            push!(LMPs, duals[!, sort(propertynames(duals))])
        end
    end
    @test isapprox(convert(Array, LMPs[1]), convert(Array, LMPs[2]), atol = 100.0)
end

@testset "Network Solve AC-PF PowerModels StandardACPModel" begin
    network = ACPPowerModel
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
    c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
    systems = [c_sys5, c_sys14, c_sys14_dc]
    objfuncs = [GAEVF, GQEVF, GQEVF]
    constraint_names = [
        :RateLimitFT__Line,
        :RateLimitTF__Line,
        PSI.make_constraint_name(PSI.NODAL_BALANCE_ACTIVE, PSY.Bus),
        PSI.make_constraint_name(PSI.NODAL_BALANCE_REACTIVE, PSY.Bus),
    ]
    parameters = [true, false]
    test_results = Dict{System, Vector{Int}}(
        c_sys5 => [1056, 0, 384, 384, 264],
        c_sys14 => [2832, 0, 720, 720, 696],
        c_sys14_dc => [2832, 96, 672, 672, 744],
    ) # TODO: changed the interval constraint number to 336 from 240. double check

    for (ix, sys) in enumerate(systems), p in parameters
        ps_model = OperationsProblem(
            TestOpProblem,
            network,
            sys;
            optimizer = fast_ipopt_optimizer,
            use_parameters = p,
        )
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)
        construct_network!(ps_model, network)
        construct_device!(ps_model, :Line, line_model)
        construct_device!(ps_model, :Tf, transformer_model)
        construct_device!(ps_model, :TTf, ttransformer_model)
        construct_device!(ps_model, :DCLine, dc_line)

        moi_tests(
            ps_model,
            p,
            test_results[sys][1],
            test_results[sys][2],
            test_results[sys][3],
            test_results[sys][4],
            test_results[sys][5],
            false,
        )
        psi_constraint_test(ps_model, constraint_names)
        psi_checkobjfun_test(ps_model, objfuncs[ix])
        psi_checksolve_test(ps_model, [MOI.TIME_LIMIT, MOI.OPTIMAL, MOI.LOCALLY_SOLVED])
        # Disabled because the primal status isn't consisten between operating systems
        #@test primal_status(ps_model.optimization_container.JuMPmodel) == MOI.FEASIBLE_POINT
    end
end

@testset "Network Solve AC-PF PowerModels linear approximation models" begin
    networks = [DCPPowerModel, NFAPowerModel]
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
    c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
    systems = [c_sys5, c_sys14, c_sys14_dc]
    p = true
    for network in networks, sys in systems
        @info "Test construction of a $(network) network"
        ps_model = OperationsProblem(
            TestOpProblem,
            network,
            sys;
            optimizer = OSQP_optimizer,
            use_parameters = p,
        )
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)
        construct_network!(ps_model, network)
        construct_device!(ps_model, :Line, line_model)
        construct_device!(ps_model, :DCLine, dc_line)
        psi_checksolve_test(ps_model, [MOI.OPTIMAL, MOI.ALMOST_OPTIMAL])
    end
end

@testset "Network AC-PF PowerModels non-convex models" begin
    networks = [#ACPPowerModel, Already tested
        ACRPowerModel,
        ACTPowerModel,
    ]
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
    c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
    systems = [c_sys5, c_sys14, c_sys14_dc]

    for network in networks, sys in systems
        @info "Test construction of a $(network) network"
        ps_model =
            OperationsProblem(TestOpProblem, network, sys; optimizer = fast_ipopt_optimizer)
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)
        construct_network!(ps_model, network)
        construct_device!(ps_model, :Line, line_model)
        @test !isnothing(ps_model.optimization_container.pm)
    end
end

@testset "Network AC-PF PowerModels quadratic loss approximations models" begin
    networks = [DCPLLPowerModel, LPACCPowerModel]
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
    c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
    systems = [c_sys5, c_sys14, c_sys14_dc]

    for network in networks, sys in systems
        @info "Test construction of a $(network) network"
        ps_model =
            OperationsProblem(TestOpProblem, network, sys; optimizer = fast_ipopt_optimizer)
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)
        construct_network!(ps_model, network)
        construct_device!(ps_model, :Line, line_model)
        construct_device!(ps_model, :DCLine, dc_line)
        @test !isnothing(ps_model.optimization_container.pm)
    end
end

@testset "Network AC-PF PowerModels quadratic relaxations models" begin
    networks = [SOCWRPowerModel, QCRMPowerModel, QCLSPowerModel]
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
    c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
    systems = [c_sys5, c_sys14, c_sys14_dc]

    for network in networks, sys in systems
        @info "Test construction of a $(network) network"
        ps_model =
            OperationsProblem(TestOpProblem, network, sys; optimizer = fast_ipopt_optimizer)
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)
        construct_network!(ps_model, network)
        construct_device!(ps_model, :Line, line_model)
        construct_device!(ps_model, :DCLine, dc_line)
        @test !isnothing(ps_model.optimization_container.pm)
    end
end

@testset "Network Unsupported Power Model Formulations" begin
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    for network in PSI.UNSUPPORTED_POWERMODELS
        ps_model =
            OperationsProblem(TestOpProblem, network, c_sys5; optimizer = ipopt_optimizer)
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)

        @test_throws ArgumentError construct_network!(ps_model, network)
    end
end

@testset "All PowerModels models" begin
    networks = [
        (PM.ACPPowerModel, fast_ipopt_optimizer),
        (PM.ACRPowerModel, fast_ipopt_optimizer),
        (PM.ACTPowerModel, fast_ipopt_optimizer),
        #(PM.IVRPowerModel, fast_ipopt_optimizer), #instantiate_ivp_expr_model not working
        (PM.DCPPowerModel, fast_ipopt_optimizer),
        (PM.DCMPPowerModel, fast_ipopt_optimizer),
        (PM.NFAPowerModel, fast_ipopt_optimizer),
        (PM.DCPLLPowerModel, fast_ipopt_optimizer),
        (PM.LPACCPowerModel, fast_ipopt_optimizer),
        (PM.SOCWRPowerModel, fast_ipopt_optimizer),
        (PM.SOCWRConicPowerModel, scs_solver),
        (PM.QCRMPowerModel, fast_ipopt_optimizer),
        (PM.QCLSPowerModel, fast_ipopt_optimizer),
        #(PM.SOCBFPowerModel, fast_ipopt_optimizer), # not working
        (PM.BFAPowerModel, fast_ipopt_optimizer),
        #(PM.SOCBFConicPowerModel, fast_ipopt_optimizer), # not working
        (PM.SDPWRMPowerModel, scs_solver),
        (PM.SparseSDPWRMPowerModel, scs_solver),
    ]
    c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
    c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
    c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
    systems = [c_sys5]#, c_sys14, c_sys14_dc]
    for (network, solver) in networks, sys in systems
        @info "Test construction of a $(network) network"
        ps_model = OperationsProblem(TestOpProblem, network, sys; optimizer = solver)
        construct_device!(ps_model, :Thermal, thermal_model)
        construct_device!(ps_model, :Load, load_model)
        construct_network!(ps_model, network)
        construct_device!(ps_model, :Line, line_model)
        construct_device!(ps_model, :DCLine, dc_line)
        @test !isnothing(ps_model.optimization_container.pm)
    end
end
