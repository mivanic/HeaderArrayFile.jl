# Header Array Files

A Header ARray file (HAR) is a structured byte array for storing GEMPACK data. 

To add this package to your Julia environment, run:

```julia
import Pkg
Pkg.add(url="https://github.com/mitchphillipson/HeaderArray.jl")
```

Basic usage example:

```julia
using HeaderArrayFile
const HAR = HeaderArrayFile # Create alias for convenience

using DataFrames
using NamedArrays

X = HAR.File("path/to/file.har") # Load HAR file

C = X["header_name"] # Access record by header name

DataFrame(C) # This is implemented for HarRecord types
NamedArray(C) # This is implemented for HarRecord types

HAR.internal_data(X) # List all internal data in the file

HAR.sets(X) # List all sets in the file
HAR.parameters(X) # List all parameters in the file

HAR.not_loaded(X) # List all records that are not loaded
```

This package does not export any functions or types. This is the purpose of the alias `HAR` in the example above.

## Currently Implemented Data Types

- RL - Stored as `HarParameter` type
- 1C - Stored as `HarSet` type
- 2I - Stored as `HarParameter` type
- 2R - Stored as `HarParameter` type




# Structure of a HAR file

## Chunks

A `chunk` has three parts:

1. Size - 4 bytes (Int32) indicating the size, N, of the payload in bytes
2. Payload - N bytes of data
3. Size - The same four bytes as part 1, indicating the end of the chunk.

In total, a chunk is N + 8 bytes long.

Note: If the payload does not start with 4 empty bytes (0x20) then it is a header.

## Records

A `record` is a sequence of chunks. 

1. Header - Unique identifier for the record. Always 4 bytes.
2. Metadata - Information about the record, the structure is:
   1. Bytes 1:4 - Empty (always zero)
   2. Bytes 5:6 - Data type (Options: 1C, 2I, 2R, RL, RE)
   3. Bytes 7:10 - Storage type (Options: FULL, SPSE)
   4. Bytes 11:80 - Description (text string)
   5. Bytes 81:84 - Number of dimensions (Int32)
   6. Bytes 85:end - Dimensions sizes (4 bytes per dimension)
3. Data - Format depends on data and storage type. This can repeat for multiple rows.


Headers are four character case insensitive strings matching the pattern ` [a-z0-9]`. Headers starting with `XX` are for internal program use.

### Data Types

- 1C - 1 dimensional character array
- 2I - 2 dimensional integer array
- 2R - 2 dimensional real array
- RL - Up to 7 dimensional real array
- RE - Up to 7 dimensional real array with set elements

### Storage Types

- FULL - Dense array
- SPSE - Sparse array

## RE Data

1. Metadata 
   1. Bytes 1:4 - Empty (always zero)
   2. Bytes 5:8 - 
   3. Bytes 9:12 - 
   4. Bytes 13:16 - 
   5. Bytes 17:28 - Parameter Name (String)
   6. Bytes 29:32 -
   7. Bytes 33:33+12*D-1 - Dimension Names (D dimensions, 12 bytes each)
   8. Bytes 33+12*D:end
2. Domain - Repeated for each unique dimension.
   1. Bytes 1:4 - Empty (always zero)
   2. Bytes 5:8 -
   3. Bytes 9:12 - Number of elements in domain (Int32)?
   4. Bytes 13:16 - Number of elements in domain (Int32)?
   5. Bytes 17:end - Domain values (12 bytes each)

From here the structure diverges based on storage type.

### FULL

1. Metadata 
   1. Bytes 1:4 - Empty (always zero)
   2. Bytes 5:8 -
   3. Bytes 9:12 - Maximum number of dimensions (Int32)?
   4. Bytes 13:end - Dimension sizes (4 bytes per dimension)
2. Metadata specific to following data
   1. Bytes 1:4 - Empty (always zero)
   2. Bytes 5:end - Sequence of 4 byte integers. Meaning unknown.
3. Data
   1. Bytes 1:4 - Empty (always zero)
   2. Bytes 5:8 - 
   3. Bytes 9:end - Data values (4 bytes each, Float32)
   
Points 2 and 3 repeat until all the data is read. The data is matched with the domains in columnar order. 

For example, say there are two dimensions, $A=[a_1,a_2]$ and $B=[b_1,b_2,b_3]$. The data will be ordered as follows:

| A | B | Value |
|---|---|-------|
| a1 | b1 | v1 |
| a2 | b1 | v2 |
| a1 | b2 | v3 |
| a2 | b2 | v4 |
| a1 | b3 | v5 |
| a2 | b3 | v6 |

### SPSE

1. Metadata 
   1. Bytes 1:4 - Empty (always zero)
   2. Bytes 5:8 - Total number of non-zero values (Int32)
   3. Bytes 9:12 - Key size, $K$ (Int32)?
   4. Bytes 13:16 - Data size, $D$ (Int32)?
   5. Bytes 17:end - Empty
2. Data
   1. Bytes 1:4 - Empty (always zero)
   2. Bytes 5:8 -
   3. Bytes 9:12 - 
   4. Bytes 13:16 - Number of data points, $N$ (Int32)
   5. Bytes 17:$17 + N\cdot K-1$ - Keys ($K$ bytes each, Int32)
   6. Bytes $17 + N\cdot K$:end - Data values ($D$ bytes each, Float32)
   
Point 2 gets repeated until all the data is read. The key array and data array must have the same size, $N$. To correlate the data and the elements, picture the table from before having an index. The key is the index column.

|index | A | B | Value |
|---|---|---|-------|
| 1 | a1 | b1 | v1 |
| 2 | a2 | b1 | v2 |
| 3 | a1 | b2 | v3 |
| 4 | a2 | b2 | v4 |
| 5 | a1 | b3 | v5 |
| 6 | a2 | b3 | v6 |


## 1C

The dimension sizes in the metadata will have two entries, number of elements and byte length, $N$, of each element. 

### FULL

1. Data
   1. Bytes 1:4 - Empty (always zero)
   2. Bytes 5:8 -
   3. Bytes 9:12 - Number of elements (Int32)?
   4. Bytes 13:16 - Number of elements (Int32)?
   5. Bytes 17:end - Data values ($N$ bytes each, String)
   
This may be repeated for additional data. - CHECK THIS