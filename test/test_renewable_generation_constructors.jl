@testset "Renewable data misspecification" begin
    # See https://discourse.julialang.org/t/how-to-use-test-warn/15557/5 about testing for warning throwing
    warn_message = "The data doesn't include devices of type RenewableDispatch, consider changing the device models"
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableFullDispatch)
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5)
    @test_logs (:warn, warn_message) construct_device!(op_model, :Renewable, model)
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys14)
    @test_logs (:warn, warn_message) construct_device!(op_model, :Renewable, model)
end

@testset "Renewable DCPLossLess FullDispatch" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableFullDispatch)

    #5 Bus testing case
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5_re)
    construct_device!(op_model, :Renewable, model)
    moi_tests(op_model, false, 72, 0, 72, 0, 0, false)

    psi_checkobjfun_test(op_model, GAEVF)

    # Using Parameters Testing
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5_re; use_parameters = true)
    construct_device!(op_model, :Renewable, model)
    moi_tests(op_model, true, 72, 0, 72, 0, 0, false)
    psi_checkobjfun_test(op_model, GAEVF)

    # No Forecast - No Parameters Testing
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5_re; use_forecast_data = false)
    construct_device!(op_model, :Renewable, model)
    moi_tests(op_model, false, 3, 3, 0, 0, 0, false)
    psi_checkobjfun_test(op_model, GAEVF)

    # No Forecast Testing
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5_re; use_parameters = true, use_forecast_data = false)
    construct_device!(op_model, :Renewable, model)
    moi_tests(op_model, true, 3, 0, 3, 0, 0, false)
    psi_checkobjfun_test(op_model, GAEVF)
end

@testset "Renewable ACPPower Full Dispatch" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableFullDispatch)
    for p in [true, false]
        op_model = OperationsProblem(TestOptModel, ACPPowerModel, c_sys5_re; use_parameters = p)
        construct_device!(op_model, :Renewable, model)
        if p
            moi_tests(op_model, p, 144, 24, 72, 0, 48, false)
            psi_checkobjfun_test(op_model, GAEVF)
        else
            moi_tests(op_model, p, 144, 24, 72, 0, 48, false)

            psi_checkobjfun_test(op_model, GAEVF)
        end
    end
    # No Forecast Test
    for p in [true, false]
        op_model = OperationsProblem(TestOptModel, ACPPowerModel, c_sys5_re; use_forecast_data = false, use_parameters = p)
        construct_device!(op_model, :Renewable, model)
        if p
            moi_tests(op_model, p, 6, 1, 3, 0, 2, false)
            psi_checkobjfun_test(op_model, GAEVF)
        else
            moi_tests(op_model, p, 6, 4, 0, 0, 2, false)

            psi_checkobjfun_test(op_model, GAEVF)
        end
    end
end

@testset "Renewable DCPLossLess ConstantPowerFactor" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableConstantPowerFactor)

    #5 Bus testing case
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5_re)
    construct_device!(op_model, :Renewable, model)
    moi_tests(op_model, false, 72, 0, 72, 0, 0, false)

    psi_checkobjfun_test(op_model, GAEVF)

    # Using Parameters Testing
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5_re; use_parameters = true)
    construct_device!(op_model, :Renewable, model)
    moi_tests(op_model, true, 72, 0, 72, 0, 0, false)
    psi_checkobjfun_test(op_model, GAEVF)

    # No Forecast - No Parameters Testing
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5_re; use_forecast_data = false)
    construct_device!(op_model, :Renewable, model)
    moi_tests(op_model, false, 3, 3, 0, 0, 0, false)
    psi_checkobjfun_test(op_model, GAEVF)

    # No Forecast Testing
    op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5_re; use_parameters = true, use_forecast_data = false)
    construct_device!(op_model, :Renewable, model)
    moi_tests(op_model, true, 3, 0, 3, 0, 0, false)
    psi_checkobjfun_test(op_model, GAEVF)
end

@testset "Renewable ACPPower ConstantPowerFactor" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableConstantPowerFactor)
    for p in [true, false]
        op_model = OperationsProblem(TestOptModel, ACPPowerModel, c_sys5_re; use_parameters = p)
        construct_device!(op_model, :Renewable, model)
        if p
            moi_tests(op_model, p, 144, 0, 72, 0, 72, false)
            psi_checkobjfun_test(op_model, GAEVF)
        else
            moi_tests(op_model, p, 144, 0, 72, 0, 72, false)

            psi_checkobjfun_test(op_model, GAEVF)
        end
    end
    # No Forecast Test
    for p in [true, false]
        op_model = OperationsProblem(TestOptModel, ACPPowerModel, c_sys5_re; use_forecast_data = false, use_parameters = p)
        construct_device!(op_model, :Renewable, model)
        if p
            moi_tests(op_model, p, 6, 0, 3, 0, 3, false)
            psi_checkobjfun_test(op_model, GAEVF)
        else
            moi_tests(op_model, p, 6, 3, 0, 0, 3, false)

            psi_checkobjfun_test(op_model, GAEVF)
        end
    end
end

@testset "Renewable DCPLossLess FixedOutput" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableFixed)
    for p in [true, false]
        op_model = OperationsProblem(TestOptModel, DCPPowerModel, c_sys5_re; use_parameters = p)
        construct_device!(op_model, :Renewable, model)
        if p
            moi_tests(op_model, p, 0, 0, 0, 0, 0, false)
            psi_checkobjfun_test(op_model, GAEVF)
        else
            moi_tests(op_model, p, 0, 0, 0, 0, 0, false)
            psi_checkobjfun_test(op_model, GAEVF)
        end
    end
end

@testset "Renewable ACPPowerModel FixedOutput" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableFixed)
    for p in [true, false]
        op_model = OperationsProblem(TestOptModel, ACPPowerModel, c_sys5_re; use_parameters = p)
        construct_device!(op_model, :Renewable, model)
        if p
            moi_tests(op_model, p, 0, 0, 0, 0, 0, false)
            psi_checkobjfun_test(op_model, GAEVF)
        else
            moi_tests(op_model, p, 0, 0, 0, 0, 0, false)
            psi_checkobjfun_test(op_model, GAEVF)
        end
    end
end
