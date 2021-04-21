using PkgDeps
using Test
using UUIDs


const DEPOT = joinpath(@__DIR__, "resources")
const ALL_REGISTRIES = reachable_registries(; depots=DEPOT)
const FOOBAR_REGISTRY = reachable_registries("Foobar"; depots=DEPOT)


@testset "internal functions" begin
    @testset "_get_pkg_name" begin
        @testset "uuid to name" begin
            expected = "Case1"
            pkg_name = PkgDeps._get_pkg_name(UUID("00000000-1111-2222-3333-444444444444"); registries=[FOOBAR_REGISTRY])

            @test expected == pkg_name
        end

        @testset "exception" begin
            @test_throws NoUUIDMatch PkgDeps._get_pkg_name(UUID("00000000-0000-0000-0000-000000000000"); registries=[FOOBAR_REGISTRY])
        end
    end

    @testset "_get_pkg_uuid" begin
        @testset "name to uuid" begin
            expected = UUID("00000000-1111-2222-3333-444444444444")

            pkg_uuid = PkgDeps._get_pkg_uuid("Case1", "Foobar"; depots=DEPOT)
            @test expected == pkg_uuid

            pkg_uuid = PkgDeps._get_pkg_uuid("Case1", FOOBAR_REGISTRY)
            @test expected == pkg_uuid
        end

        @testset "exception" begin
            @test_throws PackageNotInRegistry PkgDeps._get_pkg_uuid("PkgDepsFakePackage", "General")
            @test_throws PackageNotInRegistry PkgDeps._get_pkg_uuid("FakePackage", FOOBAR_REGISTRY)
        end
    end

    @testset "_get_latest_version" begin
        expected = v"0.2.0"
        path = joinpath("resources", "registries", "General", "Case4")
        result = PkgDeps._get_latest_version(path)

        @test expected == result
    end
end

@testset "reachable_registries" begin
    @testset "specfic registry -- $(typeof(v))" for v in ("Foobar", ["Foobar"])
        registry = reachable_registries("Foobar"; depots=DEPOT)

        @test registry.name == "Foobar"
    end

    @testset "all registries" begin
        @test length(ALL_REGISTRIES) == 2
    end
end

@testset "users" begin

    @testset "specific registry" begin
        dependents = users("DownDep", FOOBAR_REGISTRY; registries=[FOOBAR_REGISTRY])

        @test length(dependents) == 2
        [@test case in dependents for case in ["Case1", "Case2"]]
    end

    @testset "all registries" begin
        dependents = users("DownDep", FOOBAR_REGISTRY; registries=ALL_REGISTRIES)

        @test length(dependents) == 3
        @test !("Case4" in dependents)
        [@test case in dependents for case in ["Case1", "Case2", "Case3"]]
    end
end

@testset "find_direct_dependencies" begin
    @test find_direct_dependencies(foobar_registry[].pkgs["Case1"]) == ["DownDep"]
    @test find_direct_dependencies(foobar_registry[].pkgs["Case2"]) == ["DownDep"]

    general = reachable_registries("General"; depots=depot)[]
    @test find_direct_dependencies(general.pkgs["Case3"]) == ["DownDep"]
    @test find_direct_dependencies(general.pkgs["Case4"]) == String[]
end

@testset "find_dependencies" begin
    @test find_dependencies("Case1"; registries=FOOBAR_REGISTRY) == Set(["DownDep"])
    @test find_dependencies("Case2"; registries=FOOBAR_REGISTRY) == Set(["DownDep"])
    @test find_dependencies("Case3"; registries=ALL_REGISTRIES) == Set(["DownDep"])
    @test find_dependencies("Case4"; registries=ALL_REGISTRIES) == Set{String}()
    @test find_dependencies("Case5"; registries=ALL_REGISTRIES) == Set(["Case3", "DownDep"])
end
