# Unit tests for complement regions in set operations.
# This file is supposed to be included from runtests.jl.

# Test fixtures: A = column 0, rows 0..5; B = column 0, rows 3..8
# Derived facts (used throughout):
#   A ∩ B = Run(0, 3:5)     A ∪ B = Run(0, 0:8)
#   A \ B = Run(0, 0:2)     B \ A = Run(0, 6:8)

@testset "Complement" begin

    A = Region([Run(0, 0:5)])
    B = Region([Run(0, 3:8)])

    # complement() flips the complement flag and preserves runs
    @test complement(A).complement == true
    @test complement(A).runs == A.runs
    @test complement(complement(A)) == A

    # contains() inverts for complement regions
    cA = complement(A)
    @test !contains(cA, 0, 2)   # row 2 in col 0 is inside A → not in complement(A)
    @test contains(cA, 0, 7)    # row 7 in col 0 is outside A → in complement(A)
    @test contains(cA, 1, 0)    # col 1 has no run → in complement(A)

    # union(complement(A), complement(B)) = complement(A ∩ B)   [DeMorgan]
    r = union(complement(A), complement(B))
    @test r.complement == true
    @test r.runs == intersection(A, B).runs   # runs of A ∩ B = [Run(0, 3:5)]

    # union(complement(A), B) = complement(A \ B)
    r = union(complement(A), B)
    @test r.complement == true
    @test r.runs == difference(A, B).runs     # runs of A \ B = [Run(0, 0:2)]

    # union(A, complement(B)) = complement(B \ A)
    r = union(A, complement(B))
    @test r.complement == true
    @test r.runs == difference(B, A).runs     # runs of B \ A = [Run(0, 6:8)]

    # intersection(complement(A), complement(B)) = complement(A ∪ B)   [DeMorgan]
    r = intersection(complement(A), complement(B))
    @test r.complement == true
    @test r.runs == union(A, B).runs          # runs of A ∪ B = [Run(0, 0:8)]

    # intersection(complement(A), B) = B \ A
    r = intersection(complement(A), B)
    @test r.complement == false
    @test r.runs == difference(B, A).runs     # [Run(0, 6:8)]

    # intersection(A, complement(B)) = A \ B
    r = intersection(A, complement(B))
    @test r.complement == false
    @test r.runs == difference(A, B).runs     # [Run(0, 0:2)]

    # difference(complement(A), complement(B)) = B \ A
    r = difference(complement(A), complement(B))
    @test r.complement == false
    @test r.runs == difference(B, A).runs     # [Run(0, 6:8)]

    # difference(complement(A), B) = complement(A ∪ B)
    r = difference(complement(A), B)
    @test r.complement == true
    @test r.runs == union(A, B).runs          # runs of A ∪ B = [Run(0, 0:8)]

    # difference(A, complement(B)) = A ∩ B
    r = difference(A, complement(B))
    @test r.complement == false
    @test r.runs == intersection(A, B).runs   # [Run(0, 3:5)]

    # Verify with contains() that membership is correct for a sample case
    # intersection(A, complement(B)) should be A \ B = column 0, rows 0..2
    r = intersection(A, complement(B))
    @test contains(r, 0, 0)    # (col=0, row=0) ∈ A \ B
    @test contains(r, 0, 2)    # (col=0, row=2) ∈ A \ B
    @test !contains(r, 0, 3)   # (col=0, row=3) ∉ A \ B  (it's in B)
    @test !contains(r, 0, 7)   # (col=0, row=7) ∉ A \ B  (it's only in B)

end # "Complement"
