# ROCm 10.0.0 Installer Design

## Goal

Preserve the current ROCm 7.14.0 installer on a dedicated `7.14.0` branch, then convert `main` into a ROCm 10.0.0 installer using the official APT and Runfile methods. Validate the result on the four-card Radeon AI PRO R9700 host `qin-9700` without automatic kernel installation, bootloader changes, or reboot.

## Sources and observed host

The implementation uses the ROCm 10.0.0 installation selector and compatibility matrix as its authority:

- <https://rocm.docs.amd.com/en/latest/install/rocm.html>
- <https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html>

The target host currently reports Ubuntu 24.04, Linux `6.17.0-23-generic`, four AMD display devices with PCI ID `1002:7551`, and KFD target `gfx1201`. ROCm 10.0.0 lists Radeon AI PRO R9700 as `gfx1201` and Ubuntu 24.04.4 GA kernel 6.8 as the supported R9000-series configuration.

## Branch preservation

Create `7.14.0` at the current `main` commit `7794bdc` and push it to `origin` before changing `main`. The preservation branch contains the existing installer exactly; design, implementation, and documentation changes for ROCm 10.0.0 remain on `main`.

## Installation methods

Retain two explicit installation methods:

- APT/package manager is the default system-wide installation.
- Runfile is the explicit offline or all-architecture fallback.

Remove pip and tarball CLI choices, lifecycle code, tests, fixtures, and documentation. Determine ROCm 10.0.0 repositories, package names, Runfile artifact, driver release, roots, and verification binaries from official documentation and live AMD repository metadata. Do not infer validity by replacing `7.14` strings alone.

GPU selection remains KFD-first. Four identical R9700 cards produce `gpu_count=4`, one normalized `gfx1201` installation artifact, and post-install checks against the complete physical inventory.

## Kernel policy

Kernel handling becomes advisory except for kernels older than 6.8:

- A running kernel older than 6.8 prints an upgrade warning and stops before driver or ROCm mutation.
- A kernel at least 6.8 continues installation.
- When the running kernel differs from the official device/OS recommendation, the plan prints both the current kernel and the recommended kernel. R9700 on Ubuntu 24.04.4 recommends GA 6.8; Linux 6.17 therefore warns but proceeds.
- The script never installs a kernel, changes GRUB, writes pending-kernel state, or invokes reboot.

Remove `--prepare-kernel`, `--reboot-after-kernel`, the R9700-specific `--allow-unqualified-kernel` escape hatch, and all automatic kernel transition state. If driver or ROCm activation requires a reboot, report it and exit. A human controls the reboot and reruns the script.

## Lifecycle and errors

Before mutation, print the detected host, GPU count and GFX set, driver state, current and recommended kernel, exact artifacts, and ordered actions. Keep the existing confirmation boundary and stage-specific failures.

A clean matching ROCm 10.0.0 installation is idempotent. Migration removes only positively identified conflicting ROCm or driver state under the configured cleanup policy. APT and Runfile layouts remain mutually exclusive; conflicts stop with an exact remediation command rather than mixing ownership.

## Automated verification

Migrate existing shell tests to ROCm 10.0.0 and retain observable behavior coverage for GPU detection, plan validation, artifact commands, lifecycle, Runfile state, and uninstall safety. Add explicit kernel boundary cases:

- 6.7 is rejected before mutation.
- 6.8 proceeds.
- 6.17 prints the 6.8 recommendation and proceeds for R9700.
- No path emits kernel package installation, GRUB mutation, or reboot commands.

Delete pip and tarball expectations instead of retaining dead compatibility paths.

## R9700 host verification

On `qin-9700`:

1. Run the non-mutating plan and confirm Ubuntu 24.04, four `1002:7551` devices, `gpu_count=4`, and `gfx1201`.
2. Confirm Linux 6.17 receives the Ubuntu 24.04/R9700 GA 6.8 recommendation but is not blocked.
3. Install ROCm 10.0.0 with the default APT path, allowing only the installer's explicit ROCm/driver migration policy.
4. If activation requires reboot, stop and report it; never reboot automatically.
5. Verify all four R9700 devices are bound to `amdgpu`, KFD reports `gfx1201`, `rocminfo` succeeds, and `amd-smi version` reports ROCm 10.0.0.
6. Compile and run a minimal HIP program.
7. Rerun the installer and verify it is idempotent and does not request kernel mutation or reboot.
