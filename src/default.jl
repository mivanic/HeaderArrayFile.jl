
"""
    HarDefaultData <: AbstractHarData

A container for data types that do not have a specific implementation in this package.
"""
mutable struct HarDefaultData <: AbstractHarData
    data::Vector{Vector{UInt8}}
    function HarDefaultData(file::IOStream, metadata::HarMetadata; kwargs... )
        new([])
    end
end

add_data!(X::HarDefaultData, data::Vector{UInt8}) = push!(X.data, data)