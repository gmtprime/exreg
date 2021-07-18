# Changelog

## v1.0.0

### Enhancements

  * Updated dependencies.
  * Replaces `:pg2` with `:pg` so it works with OTP 24.
  * Uses a scoped `:pg` process to avoid clashing with other `:pg` uses.

## v0.1.0

### Enhancements

  * Updated dependencies.
  * Now supports several processes with the same name as long as they are not
    in the same node.
  * Added formatter.
