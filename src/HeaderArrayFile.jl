module HeaderArrayFile

include("functions.jl")

using NamedArrays, StringEncodings

readHar = function (fileName, useCoefficientsAsNames=false, toLowerCase=true)

    # Header array files come from the age of paper tapes--we need to get records first
    records = getRecords(fileName)

    # Some records define the beginnings of headers
    headers = Dict{String,Array}()

    # Records do not have to be associated with a header, let's initialze currentHeader as an empty string
    currentHeader = ""

    for rr = records

        # if a record is of length 4, then it is a name of a header (collection of records)
        if length(rr) == 4
            currentHeader = read(IOBuffer(rr), String)

            # Headers may have trailing spaces on the right; remove them
            currentHeader = rstrip(currentHeader)

            # If we are doing lower case, make sure header names are lower case too
            if toLowerCase
                currentHeader = lowercase(currentHeader)
            end

            headers[currentHeader] = []
        else
            push!(headers[currentHeader], rr)
        end
    end
    
    # Once we have associated records with headers, we can interpret them and return them as a dictionary with each header's data
    toRet = Dict()

    for hh in headers
        # Process header conents
        headerContent = processHeader(hh[2], toLowerCase)
        # If the user selected to use coefficients as names and a coefficient name was provided for the header, we can report header data using coefficient names instead of header names
        nameHeader = useCoefficientsAsNames ? (haskey(toRet, "coefficient") ? toRet["coefficient"] : hh[1]) : hh[1]
        toRet[nameHeader] = headerContent["values"]
    end
    return toRet
end
end
