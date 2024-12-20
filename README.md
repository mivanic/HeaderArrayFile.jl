# HeaderArrayFile.jl

[![Build Status](https://github.com/mivanic/HeaderArrayFile.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/mivanic/HeaderArrayFile.jl/actions/workflows/CI.yml?query=branch%3Amaster)

# Purpose 
This package can read HAR files (Fortran-style, Header Array files) which are common for GEMPACK applications. It returns a dictionary with the header names as keys by default.


```
using HeaderArrayFile, NamedArrays

parameters = HeaderArrayFile.readHar("./data.har")
```
