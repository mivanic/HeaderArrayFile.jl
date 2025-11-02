abstract type AbstractHarSet <: AbstractHarData end


"""
    HarSet <: AbstractHarSet

A container for a set of strings in a Header Array File. This contains the name
(if provided, defaults to the description from the metadata) and the data as a vector of strings.

Loads data for `1C` datatype.
"""
struct HarSet <: AbstractHarSet
    name::String
    data::Vector{String}
    function HarSet(file::IOStream, header::HarHeader, metadata::HarMetadata; normalizenames = lowercase)
        name = description(metadata)

        #@show name

        length(dimension_sizes(metadata)) == 2 || error("Datatype 1C must be 2-dimensional found $(length(dimension_sizes(metadata)))")

        num_elements, byte_length = dimension_sizes(metadata)
        found_data_points = 0
        data = String[]
        while found_data_points < num_elements
            _, line_data = read_chunk(file; normalizenames = normalizenames)
            new_data = line_data[13:end] |> y -> Iterators.partition(y, byte_length) .|> y-> decode(y, "latin2") .|> strip .|> normalizenames
            append!(data, new_data)
            found_data_points += length(new_data)
        end
        
        new(name, data)
    end
end

name(x::HarSet) = x.name
data(x::HarSet) = x.data

"""
    DataFrame(x::HarSet)

Convert a `HarSet` to a `DataFrame`. The resulting `DataFrame` will have one column
for the set values, with the column name `set`
"""
DataFrames.DataFrame(x::HarSet) = DataFrames.DataFrame([data(x)], [:set])

""" 
    NamedArray(x::HarSet)

Convert a `HarSet` to a `NamedArray`. The resulting `NamedArray` will be a 1-dimensional
array with the name of the set as its dimension name.

The index of this named array will be `1:length(data(x))`.
"""
NamedArrays.NamedArray(x::HarSet) = NamedArrays.NamedArray(data(x))