## Summary of Submission (v1.6.0)

This package was archived on 2025-11-19 due to multiple submissions that didn't clean up files written to the `~/.cache` directory. This is a re-submission with said issue resolved.

This issue failed to be resolved as the maintainer (Craig Gower-Page) was submitting submissions to fix other issues and had wrongly assumed that the `~/.cache` issue been already resolved and that the CRAN test hadn't re-run (he had by his own admission misunderstood the logs). We now have a dedicated test pipeline for this particular issue to ensure there are no regressions.

As mentioned above, the package was re-submitted several times in a short span of time as we were trying to implement a caching feature during CRANs tests in order to keep our run time below 10 minutes whilst not reducing our test coverage. In order to improve stability on CRANs servers, whilst respecting the 10 minute restriction, we have now opted to remove all caching on CRAN and reduce the number of tests that we run. To maintain the package quality though, we have setup a cron job on GitHub that runs the full test suite in order to alert of us of any breaking issues.

We hope with this you would be willing to reconsider allowing rbmi onto CRAN.

For reference we have transferred the maintainer role of the package from Craig Gower-Page to Lukas Widmer whilst Craig is off on extended leave; our intention is to return the maintainer role back to Craig at a future date once he is back from leave.

## R CMD check results

Maintainer: ‘Lukas Widmer <lukas_andreas.widmer@novartis.com>’

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
- Windows, R release (Local Machine)
- Fedora, R release (Local Machine)
- MacOS, devel (macOS builder)
