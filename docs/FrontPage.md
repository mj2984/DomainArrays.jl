# DomainArrays.jl

`DomainArrays.jl` provides lightweight, coordinate-aware array wrappers for Julia. It bridges the gap between **domain space** (real-valued coordinates) and **sample space** (integer indices).

## Key Features

*   **Coordinate Slicing**: Index arrays using real-world units (e.g., `da[0.5:1.5, :]`).
*   **Precision Control**: Toggle between `DefaultRounding` and `@extreme_view` for conservative boundary estimation.
*   **Domain Shifting**: Use `shiftdomain` to adjust origins without copying data.
*   **Metadata-Preserving Arithmetic**: Standard arithmetic (+, -, *, /) and broadcasting automatically check for matching rates and preserve domain metadata.
*   **Sample-Space Escape Hatch**: Use the `@sampleidx` macro to perform raw integer indexing on the underlying data within a block of code.
*   **Rich Printing**: Pretty-printed headers show the total domain span and sampling rates for every dimension.

## Quick Start

### 1. Creation
Create arrays by specifying `(length, rate)` pairs. A rate of `nothing` indicates standard integer indexing.

```julia
using DomainArrays

# Create a 2D array: 10.0 units long at 44.1kHz, and 2 raw channels
da = domainzeros(Float64, (10.0, 44100), (2, nothing))

# The show method displays: (10.0, 2.0) DomainArray @ (44100.0, _)
```

### 2. Views and Offsets
DomainView tracks accumulated offsets as you slice your data.
```
# Take a view from 1.0s to 2.0s
dv = domainview(da, 1.0:2.0, :)

# Shift the domain origin by 5.0 units
shifted = shiftdomain(dv, 5.0, 0)
```

### 3. Coordinate-Aware Arithmetic
Broadcasting is domain-aware; it prevents you from accidentally adding arrays with different sampling rates.
```
a = domainones((1.0, 100))
b = domainones((1.0, 100))
c = a .+ b  # Works! Result is a DomainArray at 100.0 units/sample

d = domainones((1.0, 200))
# a + d  # Throws "Domain rates do not match" error
```

### 4. Efficient Raw Access
When you need to ignore the domain and hit the raw indices:
```
@sampleidx begin
    # This accesses da.data[1:10, 1] directly
    val = da[1:10, 1] 
end
```
