module GBIO

using GBCore
using FileIO
using JLD2, CodecZlib
using GZip
using Dates
using ProgressMeter

include("fuzzy_matching.jl")
include("jld2.jl")
include("tsv.jl")
include("vcf.jl")

export levenshteindistance, isfuzzymatch
export readjld2, writejld2
export readdelimited, writedelimited
export vcfcountloci,
    vcfchunkify,
    vcfextractentriesandformats,
    vcfextractinfo,
    vcfinstantiateoutput,
    vcfparsecoordinates,
    vcfextractallelefreqs!
export readvcf, writevcf

end
