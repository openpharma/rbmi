## Summary of Submission (v1.7.0)

Release 1.7.0 adds new features and fixes one bug:
* New argument for pool()
* Multi arm support for ancova()
* Now correctly rejects treatment-covariate interaction models for ancova()

## R CMD check results

Status: OK

## Reverse dependency check results

✔ junco 0.1.6                            ── E: 0     | W: 0     | N: 0 
✔ rbmiUtils 0.3.0                        ── E: 0     | W: 0     | N: 0 
OK: 2    

## Test environments

The package was tested in the following environments:

- Windows, R devel (Windows Builder)
- Mac, R release (macOS Builder)
- gcc14, atlas, clang-asan (rhub)
- Ubuntu-latest (docker)
