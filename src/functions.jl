# Get all records as listed sequentially in the header array file
getRecords = function (fileName)

    # Open file name (.HAR)
    bf = Base.open(fileName)

    # Initialize an empty record vector
    records = []

    # Read records until the end of tape (File)
    while !Base.eof(bf)

        # The first Int32 indicates the number of bytes in the record
        recordSize = read(bf, Int32)

        # Once we know the size of the record, we can read it in ()
        recordData = Vector{UInt8}()
        for rs = 1:recordSize
            push!(recordData, read(bf, UInt8))
        end

        # At the end of the record, we should find the size of the record again (allowing that the tape be rewound)
        recordSizeCheck = read(bf, Int32)

        # If the record size is not the same after the end of the record, we notify the user
        if recordSizeCheck != recordSize
            printl("Inconsistent record size")
        end

        # Add a vector of raw bytes to the record
        push!(records, recordData)

    end

    # Close the file
    Base.close(bf)

    return records
end

# Interpret headers found in the file
processHeader = function (hh, toLowerCase)

    # Initialize an empty dictionary of data to be returned
    toRet = Dict()

    # The type of the data is found on bytes 5 through 10
    toRet["type"] = read(IOBuffer(hh[1][5:10]), String)

    # The description is on positions 11 through 80
    toRet["description"] = read(IOBuffer(hh[1][11:80]), String)

    # Number of dimensions is on position 81 through 84
    toRet["numberOfDimensions"] = read(IOBuffer(hh[1][81:84]), Int32)

    # The sizes of dimensions are listed flexibly after position 84
    toRet["dimensions"] = map(i -> read(IOBuffer(hh[1][(85+(i-1)*4):(84+i*4)]), Int32), 1:toRet["numberOfDimensions"])

    # If type is 1CFULL we read in a vector of strings (e.g., set names)
    if toRet["type"] == "1CFULL"

        # Read all strings as listed after position 16
        combinedData = reduce((a, f) -> append!(f[17:length(f)], a), hh[2:length(hh)], init=Vector{UInt8}())

        #combinedString = read(IOBuffer(combinedData), String)
        combinedString = decode(read(IOBuffer(combinedData), UInt8), "latin2")


        toRet["values"] = map(f -> combinedString[((f-1)*toRet["dimensions"][2]+1):(f*toRet["dimensions"][2])] |> strip, 1:toRet["dimensions"][1])

        if toLowerCase == true
            toRet["values"] = map(lowercase, toRet["values"])
        end

    elseif toRet["type"] == "2IFULL"
        combinedData = reduce((a, f) -> append!(f[17:length(f)], a), hh[2:length(hh)], init=Vector{UInt8}())
        combinedBuffer = IOBuffer(combinedData)
        combinedIntegers = map(f -> read(combinedBuffer, Int32), 1:(toRet["dimensions"][1]*toRet["dimensions"][2]))
        toRet["values"] = reshape(combinedIntegers, (toRet["dimensions"][1], toRet["dimensions"][2]))
    elseif in(toRet["type"], ["REFULL", "RESPSE"])
        definedDimensions = read(IOBuffer(hh[2][5:8]), Int32)
        usedDimensions = read(IOBuffer(hh[2][13:16]), Int32)
        coefficient = strip(read(IOBuffer(hh[2][17:28]), String))

        toRet["coefficient"] = coefficient

        # Default dimensions
        allDimensions = ["dimensions"]
        dnames = 1:toRet["numberOfDimensions"]
        dimNames = Dict()
        for d = 1:toRet["numberOfDimensions"]
            dimNames[d] = 1:1:toRet["dimensions"][d]
        end
        uniqueDimNames = []
        if usedDimensions > 0
            allDimensions = read(IOBuffer(hh[2][33:(33+usedDimensions*12-1)]), String)
            dnames = map(f -> strip(allDimensions[((f-1)*12+1):(f*12)]), 1:usedDimensions)

            if toLowerCase
                dnames = map(lowercase,dnames)
            end

            dimNames = Dict()

            uniqueDimNames = unique(dnames)

            for d = 1:length(uniqueDimNames)
                nele = read(IOBuffer(hh[2+d][13:16]), Int32)
                allDim = read(IOBuffer(hh[2+d][17:(17+nele*12-1)]), String)
                dimNames[uniqueDimNames[d]] = map(f -> String(strip(allDim[((f-1)*12+1):(f*12)])), 1:nele)

                if toLowerCase == true
                    dimNames[uniqueDimNames[d]] = map(lowercase, dimNames[uniqueDimNames[d]])
                end

            end

        end

        dataStart = 2 + length(uniqueDimNames) + 1

        if toRet["type"] == "REFULL"
            numberOfFrames = read(IOBuffer(hh[dataStart][5:8]), Int32)

            numberOfDataFrames = convert(Int32, (numberOfFrames - 1) / 2)


            dataFrames = (dataStart) .+ (1:numberOfDataFrames) .* 2

            dataBytes = reduce((a, f) -> append!(a, hh[f][9:length(hh[f])]), dataFrames, init=Vector{UInt8}())

            numberOfValues = 1
            for (key, value) in dimNames
                numberOfValues = numberOfValues * length(value)
            end

            dims = map(f -> length(dimNames[f]), dnames)
            namesElements = map(f -> dimNames[f], dnames)

            numberOfValues = reduce((a, f) -> a * length(dimNames[f]), dnames, init=1)

            dataBytesBuffer = IOBuffer(dataBytes)

            dataVector = map(f -> read(dataBytesBuffer, Float32), 1:numberOfValues)


            toRet["values"] = NamedArray(reshape(dataVector, Tuple(dims)), Tuple(namesElements), Tuple(dnames))

        else
            elements = read(IOBuffer(hh[dataStart][5:8]), Int32)
            numberOfValues = reduce((a, f) -> a * length(dimNames[f]), dnames, init=1)
            dataVector = zeros(numberOfValues)

            for rr = (dataStart+1):length(hh)

                dataBytes = hh[rr][17:length(hh[rr])]

                currentPoints = convert(Int64, length(dataBytes) / 8)


                locationsBuffer = IOBuffer(dataBytes[1:(4*currentPoints)])

                locations = map(f -> read(locationsBuffer, Int32), 1:currentPoints) 

                valuesBuffer = IOBuffer(dataBytes[(4*currentPoints+1):(8*currentPoints)])

                values = map(f -> read(valuesBuffer, Float32), 1:currentPoints) 

                dataVector[locations] = values

                dims = map(f -> length(dimNames[f]), dnames)
                namesElements = map(f -> dimNames[f], dnames)

                toRet["values"] = NamedArray(reshape(dataVector, Tuple(dims)), Tuple(namesElements), Tuple(dnames))
            end

        end
    else
        toRet["values"] = nothing
    end
    return toRet
end
