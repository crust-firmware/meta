# Crust Firmware Build System

This repository contains a `Makefile` to build the Crust firmware along with
other firmware components into a single flashable image.

## Getting Started

In order to build Crust firmware, the following dependencies must be installed:

- An ARM or AArch64 cross compiler, for 32-bit or 64-bit boards, respectively.
  The libc they target does not matter. These can be installed from a
  distribution package, downloaded from [Linaro][linaro-gcc], or compiled from
  source, e.g. with [musl-cross-make][mcm].
- An [OpenRISC 1000 cross compiler][or1k-gcc]
- The [Device Tree Compiler][dtc] (required by U-Boot)
- [SWIG][swig] (also required by U-Boot)

[dtc]: https://github.com/dgibson/dtc/releases
[linaro-gcc]: https://releases.linaro.org/components/toolchain/binaries/
[mcm]: https://github.com/richfelker/musl-cross-make
[or1k-gcc]: https://github.com/openrisc/or1k-gcc/releases
[swig]: http://www.swig.org/download.html

After installing the dependencies listed above, `Makefile` must be updated to
include the locations of your cross compilers. If the compilers are accessible
from your shell's `PATH`, leave this section as-is.

```
# Cross compiler
CROSS_aarch64	 = /path/to/compiler/aarch64-linux-musl-
CROSS_or1k	 = /path/to/compiler/or1k-linux-musl-
```

Update `Makefile` with the board you are using. The following boards are
currently supported:

- Orange Pi Win and Orange Pi Win Plus: `orangepi_win`
- Orange Pi Zero Plus H5: `orangepi_zero_plus`

For example, if you are building the Crust firmware image for an Orange Pi Win,
`Makefile` should include the following board selection:

```
# Board selection
BOARD		?= orangepi_win
```

Finally, build the image:

```bash
make
```

The image will be located in the `build/` directory and include the name of
your board.

## Troubleshooting

If you encounter any issues building the image, please verify that the error
message you receive is not one of the following common issues:

- `aarch64-linux-gnu-gcc: Command not found`
  - The path to your AArch64 cross compiler is incorrect or the compiler is
    not accessible from your shell's `PATH`. Fix the path in the Makefile.
- `Can't find default configuration "arch/../configs/..."!`
  - The board you selected is incorrect or is not supported. Try using a board
    listed in the documentation or copying the configuration from a similar
    board.
- `or1k-linux-musl-cpp: Command not found`
  - The path to your OpenRISC 1000 cross compiler is incorrect or the compiler
    is not accessible from your shell's `PATH`. Fix the path in the Makefile.
- `sh: dtc: command not found`
  - Device Tree Compiler is not installed.
- `unable to execute 'swig': No such file or directory`
  - SWIG is not installed.

You can run `make V=1` to have the build system output detailed information
about what it is doing. This may provide a more helpful error message.

If the error still persists, please file an [issue][issues]. Include the full
output from `make`, especially the lines surrounding any error messages. Please
also include the configuration section from the top of your `Makefile`, if you
have changed it.

[issues]: http://github.com/crust-firmware/meta/issues
