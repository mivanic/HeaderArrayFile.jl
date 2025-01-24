# HeaderArrayFile.jl

[![Build Status](https://github.com/mivanic/HeaderArrayFile.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/mivanic/HeaderArrayFile.jl/actions/workflows/CI.yml?query=branch%3Amaster)


# The purpose of the package

The purpose of this package is to allow reading Fortran-style HAR files, common for GEMPACK applications, in native Julia. It is a partial translation of package `HARr` in R, currently only allowing the reading of the values.

The function reads a HAR file and returns a dictionary of the headers. It allows for several optional arguments: `useCoefficientsAsNames` which is by default set to `false` allows using the coefficient names from the HAR file as the names of the entries in the dictionary; `toLowerCase` which is set to `true` by default determines if the strings contained in the HAR file are converted to lower case---this is likely important because HAR files are not case sensitive, which may result in label inconsistencies.

```
using HeaderArrayFile, NamedArrays

parameters = HeaderArrayFile.readHar("./data.har", useCoefficientsAsNames=false, toLowerCase=true)
```

