Multi-package Reflex example
---

This repo is an example of combining `cabal.project`, Nix,
`reflex-platform`, and `jsaddle-warp` to drastically improve the
developer experience.

First, run `./reflex-platform/try-reflex` at least once. We won't use
it at all in this project, but it does some extra work to setup your
system requirements automatically, namely installing Nix and
configuring the Reflex binary cache.

Once Nix is installed, everything else is mostly handled for you. To
build the project's backend and `jsaddle-warp` app, use the `./cabal`
script:

```bash
$ ./cabal new-build all
```

To build the GHCJS app, use the `./cabal-ghcjs` script:

```bash
$ ./cabal-ghcjs new-build all
```

You can use GHCi with the `jsaddle-warp` app for much better dev
cycles:

```bash
$ ./cabal new-repl frontend
```

Motivation
---

Building a multi-package project with Nix can be a pain because of
Nix's lack of incremental building. A small change to a common package
will require Nix to rebuild that package from scratch, causing a huge
interruption during development. Although this is usually where Stack
would shine, Stack doesn't officially support using Nix for Haskell
derivations, and has zero support for Nix with GHCJS. You *can* build
Reflex apps using only Stack and no Nix, but you lose a lot of
benefits that `reflex-platform` provides, like the curated set of
package versions that Reflex works best with (including a
GHCJS-optimized `text`library), binary caches of all the Haskell
derivations, and zero-effort cross compilation for native mobile apps.

How it works
---

See
[developing-packages.md](https://github.com/reflex-frp/reflex-platform/blob/develop/docs/project-development.md).

---

TODO
---

- Actually implement a backend / frontend that uses the `common`
  library to show that even cross-package dependencies are built
  incrementally.
- `new-build` doesn't yet support any means of programmatically
  finding build products. It would be nice to have some kind of
  solution for this, especially so that the backend could serve the
  `dist-ghcjs` products without some hardcoded path.
