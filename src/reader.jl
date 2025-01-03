"""
    readJLD2(type::Type, fname::String = missing)::Type

Load a core (`Genomes`, `Phenomes`, and `Trials`), simulation (`SimulatedEffects`), and model (`TEBV`) struct from a JLD2 file.

## Examples
```jldoctest; setup = :(using GBCore, GBIO)
julia> genomes = GBCore.simulategenomes(n=2, verbose=false);

julia> fname = writeJLD2(genomes);

julia> readJLD2(Genomes, fname) == genomes
true

julia> phenomes = Phenomes(n=2, t=2); phenomes.entries = ["entry_1", "entry_2"]; phenomes.traits = ["trait_1", "trait_2"];

julia> fname = writeJLD2(phenomes);

julia> readJLD2(Phenomes, fname) == phenomes
true

julia> trials = Trials(n=1, t=2); trials.entries = ["entry_1"];

julia> fname = writeJLD2(trials);

julia> readJLD2(Trials, fname) == trials
true
```
"""
function readJLD2(type::Type{T}, fname::String = missing)::T where {T<:AbstractGB}
    if !isfile(fname)
        throw(ArgumentError("JLD2 file: " * fname * " does not exist."))
    end
    d = load(fname)
    struct_name::String = collect(keys(d))[1]
    x::type = d[struct_name]
    if !checkdims(x)
        throw(DimensionMismatch(struct_name * " struct from the JLD2 file: " * fname * " is corrupted."))
    end
    return x
end


"""
    readdelimited(type::Type{Genomes}; fname::String, sep::String = "\\t")::Genomes

Load a `Genomes` struct from a string-delimited (default=`\\t`) file. 
Each row corresponds to a locus-allele combination.
The first 4 columns correspond to the chromosome, position, all alleles in the locus (delimited by `|`), and the specific allele.
The subsequency columns refer to the samples, pools, entries or genotypes.

# Examples
```jldoctest; setup = :(using GBCore, GBIO)
julia> genomes = GBCore.simulategenomes(n=10, verbose=false);

julia> fname = writedelimited(genomes);

julia> genomes_reloaded = readdelimited(Genomes, fname=fname);

julia> genomes == genomes_reloaded
true
```
"""
function readdelimited(type::Type{Genomes}; fname::String, sep::String = "\t")::Genomes
    # genomes = GBCore.simulategenomes(n=10); sep::String = "\t"; fname = writedelimited(genomes);
    # Check input arguments
    if !isfile(fname)
        throw(ErrorException("The file: " * fname * " does not exist."))
    end
    # Count the number of lines in the file which are not header lines or comments
    # n_lines::Int64 = countlines(fname) # Only works if there are no comments other than the first 2 header lines
    n_lines::Int64 = 0
    file = open(fname, "r")
    for raw_line in eachline(file)
        if raw_line[1][1] != '#'
            n_lines += 1
        end
    end
    close(file)
    # Read the 2 header lines
    file = open(fname, "r")
    header_1::Vector{String} = split(readline(file), sep)
    header_2::Vector{String} = split(readline(file), sep)
    close(file)
    if (length(header_1) != length(header_2)) || (header_1[1:4] != header_2[1:4])
        throw(ErrorException("The 2 header lines in the genomes file: '" * fname * "' do not match."))
    end
    # Define the expected dimensions of the Genomes struct
    n::Int64 = length(header_1) - 4
    p::Int64 = n_lines
    # Instatiate the output struct
    genomes::type = Genomes(n = n, p = p)
    genomes.entries = header_1[5:end]
    genomes.populations = header_2[5:end]
    genomes.mask .= true
    # Check for duplicate entries
    unique_entries::Vector{String} = unique(genomes.entries)
    duplicated_entries::Vector{String} = []
    for entry in unique_entries
        if sum(genomes.entries .== entry) > 1
            push!(duplicated_entries, entry)
        end
    end
    if length(genomes.entries) > length(unique_entries)
        throw(
            ErrorException(
                string("Duplicate entries in file: '", fname, "' i.e.:\n\t‣ ", join(duplicated_entries, "\n\t‣ ")),
            ),
        )
    end
    # Read the file line by line
    line_counter::Int64 = 0
    i::Int64 = 0
    file = open(fname, "r")
    for raw_line in eachline(file)
        # println(string("i=", i, "; line_counter=", line_counter))
        line = split(raw_line, sep)
        line_counter += 1
        # Skip commented out lines including the forst 2 header
        if line[1][1] != '#'
            if length(header_1) != length(line)
                throw(
                    ErrorException(
                        "The header line and line: " *
                        string(line_counter) *
                        " of the genomes file: '" *
                        fname *
                        "' do have the same number of columns.",
                    ),
                )
            end
            i += 1
            chrom = line[1]
            pos = try
                parse(Int64, line[2])
            catch
                throw(
                    ErrorException(
                        "Cannot parse the second column, i.e. position field at line: " *
                        string(line_counter) *
                        " ('" *
                        line[2] *
                        "') of the genomes file: '" *
                        fname *
                        "'.",
                    ),
                )
            end
            refalts = line[3]
            allele = line[4]
            genomes.loci_alleles[i] = join([chrom, pos, refalts, allele], "\t")
            genomes.allele_frequencies[:, i] = try
                parse.(Float64, line[5:end])
            catch
                throw(
                    ErrorException(
                        "Cannot parse columns 5 to " *
                        string(length(line)) *
                        ", i.e. allele frequencies at line: " *
                        string(line_counter) *
                        " of the genomes file: '" *
                        fname *
                        "'.",
                    ),
                )
            end
        end
    end
    close(file)
    # Checks
    unique_loci_alleles::Vector{String} = unique(genomes.loci_alleles)
    duplicated_loci_alleles::Vector{String} = []
    for locus_allele in unique_loci_alleles
        if sum(genomes.loci_alleles .== locus_allele) > 1
            push!(duplicated_loci_alleles, locus_allele)
        end
    end
    if length(genomes.loci_alleles) > length(unique_loci_alleles)
        throw(
            ErrorException(
                string(
                    "Duplicate loci-allele combinations in file: '",
                    fname,
                    "' at:\n\t‣ ",
                    join(duplicated_loci_alleles, "\n\t‣ "),
                ),
            ),
        )
    end
    if !checkdims(genomes)
        throw(ErrorException("Error loading Genomes struct from the file: '" * fname * "'"))
    end
    # Output
    genomes
end

function readdelimited(type::Type{Phenomes}; fname::String, sep::String = "\t")::Phenomes end

function readdelimited(type::Type{Trials}; fname::String, sep::String = "\t")::Trials end

function readvcf(fname::String)::Genomes end
