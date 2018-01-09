# Crust Firmware Build System

This repository contains a `Makefile` to build Crust firmware using other
firmware components.

## Getting Started

In order to build Crust firmware, the following dependencies must be installed:

- [aarch64-linux-musl cross compiler](http://www.musl-libc.org/download.html)
- [or1k-linux-musl cross
  compiler](https://github.com/openrisc/or1k-gcc/releases)
- [Device Tree Compiler](https://github.com/dgibson/dtc/releases)
- [SWIG](http://www.swig.org/download.html)

After installing the dependencies listed above, `Makefile` must be updated to
include the locations of your cross compilers. If the compilers are accesible
from your PATH, leave this section as-is.

```
# Cross compiler
CROSS_aarch64    = /path/to/compiler/aarch64-linux-musl-
CROSS_or1k       = /path/to/compiler/or1k-linux-musl-
```

Update `Makefile` with the board you are using. The following boards are
supported:

- Orange Pi Win and Orange Pi Win Plus: `orangepi_win`
- Orange Pi Zero Plus: `orangepi_zero_plus`

For example, if you are building the Crust firmware image for an Orange Pi
Win, `Makefile` should include the following board selection:

```
# Board selection
BOARD       ?= orangepi_win
```

Finally, build the image.

```bash
make
```

The image will be located in the `build/` directory and include the name of
your board.

## Troubleshooting

If you encounter any issues building the image, please verify that the error
message you receive is not one of the following common issues:

| Error message                                             | Cause
|-----------------------------------------------------------|-------------------------------------------------------------------------------------
| `aarch64-linux-gnu-gcc: Command not found`                | Path to `aarch64-linux-musl` cross compiler is incorrect or not accessible from PATH.
| `Can't find default configuration "arch/../configs/..."!` | Board selection is incorrect or not supported.
| `or1k-linux-musl-cpp: Command not found`                  | Path to `or1k-linux-musl` cross compiler is incorrect or not accessible from PATH.
| `sh: dtc: command not found`                              | Device Tree Compiler is not installed.
| `unable to execute 'swig': No such file or directory`     | SWIG is not installed.

If the error still persists, please file an
[issue](http://github.com/crust-firmware/meta/issues) with the following
information:

- GNU Make output and error message
- `Makefile` configuration section
