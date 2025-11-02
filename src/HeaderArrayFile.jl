module HeaderArrayFile

    using DataFrames

    using NamedArrays

    import OrderedCollections: OrderedDict
    import StringEncodings: decode

    include("structs.jl")

    include("parameter.jl")

    include("sets.jl")

    include("default.jl")

    include("read.jl")

end # module HeaderArrayFiles
