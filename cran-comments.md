## Summary of Submission (v1.6.0)

This package was archived on 2025-11-19 due to multiple submissions that didn't clean up code written to the `~/.cache` directory. This is a re-submission with said issue resolved.

This issue failed to be resolved as the maintainer (myself, Craig Gower-Page) was submitting submissions to fix other issues and had wrongly assumed that the `~/.cache` issue been already resolved and that the CRAN test hadn't re-run (I had simply missunderstood the logs). We have now updated our code to fix the issue and have a dedicated test pipeline that was able replicate the issue and show that it is fixed.

During this period the package was re-submitted several times as wer were trying (and failing) to implement a caching feature during CRANs tests in order to keep our run time below 10 minutes whilst not disabling any tests. In order to improve stability on CRANs servers whilst respecting the 10 minute restriction we have now opted to remove all caching on CRAN and reduce the number of tests that we run. To maintain the package quality though we have setup a cron job on our servers that runs the full test suite in order to alert of us of any breaking issues.

We hope with this you would be willing to reconsider allowing rbmi onto CRAN.

## R CMD check results

Maintainer: ‘Craig Gower-Page <craig.gower-page@novartis.com>’
  
  New submission
  
  Package was archived on CRAN
  
  CRAN repository db overrides:
    X-CRAN-Comment: Archived on 2025-11-19 as issues were not corrected
      in time.
  
    Still does not clean up in ~/.cache.

0 errors ✔ | 0 warnings ✔ | 1 notes ✖

## Test environments

The package was tested in the following environments:

- MacOS, R release (Local Machine)
- Windows, R release (Win-Builder)
- MacOS, devel (macOS builder)
- Ubuntu 22.04 LTS, devel (GitHub Actions)
