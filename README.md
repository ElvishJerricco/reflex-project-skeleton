Multi-package Reflex example
---

This repo is an example of combining `cabal.project`, Nix,
`reflex-platform`, and `jsaddle-warp` to drastically improve the
developer experience. To build the project's backend and `jsaddle`
app, use the `./cabal` script:

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
$ ./cabal new-repl frontend-warp
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

Newer versions of Cabal have the new `cabal.project` format, which
allows you to build multi-package projects using Cabal. Although this
does require `new-build`, we of course will not be using `new-build`'s
dependency management. Instead, we will always run `cabal` from inside
a `nix-shell` that provides it with the GHC it needs, including all
the packages the project depends on. This way `reflex-platform` is
defining the dependencies and we get its binary cache.

In order to support simultaneously working with GHC and GHCJS for the
frontend, two different `dist` directories and `cabal.project` files
are used. To use GHCJS, all you need to do is use `./cabal-ghcjs`
instead of using `cabal` yourself. This script takes care of entering
the `nix-shell` and invoking `cabal` with the arguments necessary to
use this `dist` directory and `cabal-ghcjs.project` file with
GHCJS. Similarly, there is a `./cabal` script for invoking `cabal`
under the GHC `nix-shell`, but it is much simpler. Both scripts add
the `nix-shell` dependencies as Nix GC roots in `dist-*/gc-roots/`.

The shared `nix-shell` and `cabal.project` multi-package setup lets
you make changes to the `common` package incrementally. If you just
used `cabal` around `frontend` alone, the `nix-shell` would have to
rebuild `common` from scratch after every little change, which could
even lead to rebuilding `frontend` from scratch. With `cabal.project`,
changes to `common` can be built for `frontend` and `backend`
incrementally. Only the minimal number of modules will be recompiled.

When building with GHC, the frontend uses `jsaddle-warp` as the JS
backend. This provides numerous advantages over GHCJS. GHC is a much
faster compiler, so build times are reduced. It can be used in GHCi,
so dev cycles are even faster and more interactive. And the resulting
app runs much faster, which is a nice convenience and gives you an
idea of how much faster Reflex's native apps will be than the JS
apps. But to clarify, `jsaddle-warp` apps aren't meant to be deployed;
it is intended solely for local use.

The shell is provided by `reflex-platform`'s admittedly sketchy
`workOnMulti` function, which takes a list of package names and a
Haskell package set containing those packages, and produces a shell
with only the dependencies of those packages. This allows you to
define the packages individually, despite their shared development
shell. This is nice because it lets you just use `callCabal2nix` to
define the packages so that you don't have to do any work to keep the
nix expressions up to date with the cabal files. It also gives you
full package granularity in Nix so that your devops can depend on
things individually.

```bash
$ nix-build -A ghc.backend
$ nix-build -A ghcjs.frontend
```

---

TODO
---

- Actually implement a backend / frontend that uses the `common`
  library to show that even cross-package dependencies are built
  incrementally.
- Although the `frontend.cabal` file uses `impl(ghcjs)` to rule out
  `jsaddle-warp` as a dependency on GHCJS, there is [a slight
  issue](https://github.com/obsidiansystems/nixpkgs/pull/6/) with the
  way `callCabal2nix` is defined in `reflex-platform` that causes
  `jsaddle-warp` to needlessly be built for GHCJS anyway. This is
  harmless, but does waste some time.
- The `frontend` package duplicates a lot of Cabal configuration
  between its two executable components. It would be better if the
  `library` component were used for this common stuff, with the
  executables merely providing the main file. But using `cabal
  new-repl` on an executable will not currently allow you to use `:r`
  to reload this library code. A consequence of this is that the
  "library" modules must be added to the `other-modules` field of both
  components. **Forgetting this will often cause forgotten modules to
  not be rebuilt**, which can be a tricky issue to track down.
- There are some Nix functions in `default.nix` that perhaps ought to
  be in `reflex-platform`. It would be nice if the only Nix required
  to get this entire environment were something like `import
  ./reflex-platform { packages = [ ./common ./backend ./frontend ];
  }`.
- `new-build` doesn't yet support any means of programmatically
  finding build products. It would be nice to have some kind of
  solution for this, especially so that the backend could serve the
  `dist-ghcjs` products without some hardcoded path.
