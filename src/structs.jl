abstract type AbstractHarData end

"""
    HarHeader

A container for the 4-byte header name of a HAR record.
"""
struct HarHeader
    name::String
    function HarHeader(data::Vector{UInt8}; normalizenames = lowercase)  
        length(data) == 4 || error("Header must be 4 bytes")

        new(String(data) |> strip |> normalizenames)
    end
end

name(x::HarHeader) = x.name
Base.isempty(x::HarHeader) = name(x) == ""
Base.show(io::IO, x::HarHeader) = print(io, name(x))

"""
    HarMetadata

A container for metadata associated with a HAR record, including its data type,
storage type, description, and dimension sizes.
"""
struct HarMetadata
    data_type::String
    storage_type::String
    description::String
    dimension_sizes::Vector{Int32}
    function HarMetadata(data::Vector{UInt8}; normalizenames = lowercase)
        length(data) >= 80 || error("Metadata must be at least 80 bytes")

        data_type = String(data[1:2]) |> strip |> uppercase
        storage_type = String(data[3:6]) |> strip |> uppercase
        dimension_sizes = reinterpret(Int32, data[81:end]) 
        
        if data_type ∈ ["RE", "RL"]
            dimension_sizes = filter(!=(1), dimension_sizes)
        end

        new(
            data_type,
            storage_type,
            String(data[7:76]) |> strip,
            dimension_sizes
        )
    end
end

datatype(x::HarMetadata) = x.data_type
storage_type(x::HarMetadata) = x.storage_type
description(x::HarMetadata) = x.description
dimension_sizes(x::HarMetadata) = x.dimension_sizes

"""
    HarRecord

A container for a single record in a HAR file, containing its header, metadata, 
and data.
"""
struct HarRecord 
    header::HarHeader
    metadata::HarMetadata
    data::AbstractHarData
end


Base.show(io::IO, x::HarRecord) = print(io, 
    "HarRecord(\"$(description(x))\", $(typeof(data(x))))"
)


"""
    header(x::HarRecord)

Return the `HarHeader` of the record.
"""
header(x::HarRecord) = x.header

"""
    metadata(x::HarRecord)

Return the `HarMetadata` of the record.
"""
metadata(x::HarRecord) = x.metadata

"""
    data(x::HarRecord)

Return the data of the record, which is a subtype of `AbstractHarData`.
"""
data(x::HarRecord) = x.data

"""
    description(x::HarRecord)

Return the description of the record, from its metadata.
"""
description(x::HarRecord) = description(metadata(x))

"""
    name(x::HarRecord)

Return the header name of the record.
"""
name(x::HarRecord) = name(header(x))

"""
    DataFrame(x::HarRecord)

Return a `DataFrame` representation of the record's data.
"""
DataFrames.DataFrame(x::HarRecord) = DataFrames.DataFrame(data(x))

"""
    NamedArray(x::HarRecord)

Return a `NamedArray` representation of the record's data.
"""
NamedArrays.NamedArray(x::HarRecord) = NamedArrays.NamedArray(data(x))


"""
    HarFile

A container for `HarRecord`s, indexed by their header names.
"""
struct HarFile
    records::OrderedDict{String, HarRecord}
    function HarFile()
        new(OrderedDict{String, HarRecord}())
    end
end

records(x::HarFile) = x.records
Base.getindex(x::HarFile, name::String) = records(x)[name]
Base.setindex!(x::HarFile, record::HarRecord, name::String) = (records(x)[name] = record)

Base.keys(x::HarFile) = keys(records(x))
Base.values(x::HarFile) = values(records(x))
Base.length(x::HarFile) = length(records(x))
Base.iterate(x::HarFile) = iterate(records(x))
Base.iterate(x::HarFile, state) = iterate(records(x), state)

function Base.show(io::IO, x::HarFile) 
    println(io, "HarFile with $(length(x)) records:") 
    for (key, record) in x
        f(x) = key isa AbstractString ? "\"$x\"" : ":$x"
        println(io, "  $(f(key)) => $record")
    end

end



"""
    internal_data(x::HarFile)

Return an `OrderedDict` of all internal data (keys starting with "XX").
"""
function internal_data(x::HarFile)
    return OrderedDict(
        key => value for (key, value) in x if startswith(lowercase(key), "xx")
    )
end

"""
    sets(x::HarFile)

Return an `OrderedDict` of all sets, or `1C` records. 
"""
function sets(x::HarFile)
    return OrderedDict(
        key => value for (key, value) in x if !startswith(lowercase(key), "xx") && isa(data(value), AbstractHarSet)
    )

end

"""
    parameters(x::HarFile)

Return an `OrderedDict` of all parameters, or `RE` records.
"""
function parameters(x::HarFile)
    return OrderedDict(
        key => value for (key, value) in x if !startswith(lowercase(key), "xx") && isa(data(value), AbstractHarParameter)
    )
end


"""
    not_loaded(x::HarFile)

Return an `OrderedDict` of all records that have not been loaded, i.e. their 
data is `HarDefaultData`.

Any unsupported datatypes get loaded as `HarDefaultData`.
"""
function not_loaded(x::HarFile)
    return OrderedDict(
        key => value for (key, value) in x if !startswith(lowercase(key), "xx") && isa(data(value), HarDefaultData)
    )
end