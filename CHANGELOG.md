# Changelog
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep the newest entry at top, format date according to ISO 8601: `YYYY-MM-DD`.
Categories:
- major release trigger
   - _Added_ for new features.
   - _Removed_ for now removed features.
- minor release trigger
   - _Changed_ for changes in existing functionality.
   - _Deprecated_ for soon-to-be removed features.
- bug-fix release trigger
   - _Fixed_ for any bug fixes.
   - _Security_ in case of vulnerabilities.

This project is _not_ released in any formal way, so this file is informative onle.

## [ 2.3.0 ] - 2020-03-28
### Changed
- update keycloak to 9.0.2
- identity-first login flow

## [ 2.2.0 ] - 2020-03-24
### Changed
- use 'latest' version for own docker images
- all admin users have the same password
- refine the information displayed by the `up` script

## [ 2.1.0 ] - 2020-03-16
### Changed
- handle logout
- also shows response header

## [ 2.0.0 ] - 2020-03-13
### Added
- echo api returns json, light use of javascript for the ui
### Removed
- return of pre-composed html page from echo

## [ 1.1.0 ] - 2020-03-10
### Changed
- X-UserInfo includes a custom claim

## [ 1.0.0 ] - 2020-03-6
### Added
- MIT license & related, the repo is now public
