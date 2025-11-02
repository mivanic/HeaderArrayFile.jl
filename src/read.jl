
"""
    read_chunk(file::IOStream)

Internal function to read a chunk from a Header Array File. This reads the
header and data, returning a tuple with the header as a `HarHeader` and the
data as a `Vector{UInt8}`.
"""
function read_chunk(file::IOStream;  normalizenames = lowercase)
    N = read(file, 4) |> x -> reinterpret(Int32, x) |> first
    payload = read(file, N)
    N2 = read(file, 4) |> x -> reinterpret(Int32, x) |> first
    N2 == N || error("Data integrity check failed")
    return (header = HarHeader(payload[1:4],normalizenames = normalizenames), data = payload[5:end])
end

"""
    File(
        file_path::String;
        normalizenames = lowercase,
        load_unsupported = false,
        parameter_types = Dict(
            "1C" => HarSet,
            "RE" => HarParameter,
            "RL" => HarParameter,
            )
        )

Read a Header Array File from the specified file path. The `parameter_types`
dictionary maps data types to their corresponding container types. If a data type
is not found in the dictionary, it defaults to `HarDefaultData`.

## Arguments

- `file_path::String`: The path to the HAR file to be read.

## Keyword Arguments

- `normalizenames`: A function to normalize header names (default is `lowercase`).
- `load_unsupported`: A boolean indicating whether to load unsupported data types (default is `false`).
- `parameter_types`: A dictionary mapping data types to their corresponding 
    container types, any type not found in the dictionary defaults to [`HarDefaultData`](@ref).
"""
function File(
        file_path::String;
        normalizenames = lowercase,
        load_unsupported = false,
        parameter_types = Dict(
            "1C" => HarSet,
            "RE" => HarParameter,
            "RL" => HarParameter,
            "2I" => HarParameter,
            "2R" => HarParameter,
            )
        )

    out = HarFile()

    file = open(file_path)

    parameter = nothing
    
    while !eof(file)
        header, data = read_chunk(file; normalizenames = normalizenames)
        if !isempty(header)
            _, M = read_chunk(file)
            metadata = HarMetadata(M; normalizenames = normalizenames)
            parameter_type = get(parameter_types, datatype(metadata), HarDefaultData)
            parameter = parameter_type(file, header, metadata; normalizenames = normalizenames)
            if load_unsupported
                out[name(header)] = HarRecord(header, metadata, parameter)
            elseif parameter_type != HarDefaultData
                out[name(header)] = HarRecord(header, metadata, parameter)
            end
        else
            add_data!(parameter, data)
        end
    end

    close(file)

    return out

end