@testitem "Reading Data" begin
    using DataFrames
    using NamedArrays

    X = HeaderArrayFile.File(joinpath(@__DIR__, "data", "gsdemiss.har"); normalizenames = lowercase)

    FC_data = ["coa", "oil", "gas", "p_c", "gdt"]
    FC_na = NamedArray(FC_data)
    FC_df = DataFrame(set = FC_data)

    @test HeaderArrayFile.NamedArray(X["fc"]) == FC_na
    @test DataFrame(X["fc"]) == FC_df

    # Data generated as a random sample from the MIP parameter
    test_mip = [
        ("p_c", "irn", Float32(1.3761944))
        ("p_c", "fin", Float32(1.5882112))
        ("p_c", "geo", Float32(1.1024551))
        ("p_c", "zaf", Float32(5.1148553))
        ("oil", "lva", Float32(0.0))
        ("gas", "xna", Float32(1.6893886e-5))
        ("oil", "est", Float32(0.0))
        ("coa", "ken", Float32(1.2834563e-7))
        ("p_c", "dnk", Float32(3.8657405))
        ("p_c", "usa", Float32(69.66114))
        ("gas", "est", Float32(0.00015696559))
        ("coa", "xsa", Float32(1.0074453e-6))
        ("oil", "mus", Float32(0.0))
        ("p_c", "usa", Float32(69.66114))
        ("gdt", "irl", Float32(0.4845783))
        ("oil", "ecu", Float32(0.0))
        ("p_c", "egy", Float32(0.8112632))
        ("coa", "chn", Float32(10.6382065))
        ("oil", "hnd", Float32(0.0))
        ("coa", "ltu", Float32(0.26090768))
    ]

    na = NamedArray(X["mip"])

    all(na[comm, reg] == val for (comm, reg, val) in test_mip)

    df = DataFrame(X["mip"])
    @test all(
        only(df[df.fuel_comm .== comm .&& df.reg .== reg, :value]) == val
        for (comm, reg, val) in test_mip
    )


    ## Same test, uppercase

    X = HeaderArrayFile.File(joinpath(@__DIR__, "data", "gsdemiss.har"); normalizenames = uppercase)

    FC_data = uppercase.(FC_data)
    FC_na = NamedArray(FC_data)
    FC_df = DataFrame(set = FC_data)

    @test HeaderArrayFile.NamedArray(X["FC"]) == FC_na
    @test DataFrame(X["FC"]) == FC_df

    test_mip = [(uppercase(comm), uppercase(reg), val) for (comm, reg, val) in test_mip]

    na = NamedArray(X["MIP"])
    all(na[comm, reg] == val for (comm, reg, val) in test_mip)

    df = DataFrame(X["MIP"])
    @test all(
        only(df[df.FUEL_COMM .== comm .&& df.REG .== reg, :value]) == val
        for (comm, reg, val) in test_mip
    )


end

