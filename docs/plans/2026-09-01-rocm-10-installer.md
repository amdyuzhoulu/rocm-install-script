# ROCm 10.0.0 Installer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert `main` from the preserved ROCm 7.14.0 implementation to a ROCm 10.0.0 APT and Runfile installer, with advisory kernel handling and verified installation on four Radeon AI PRO R9700 GPUs.

**Architecture:** Retain the shell installer's KFD-first discovery, immutable install plan, staged lifecycle, cleanup policy, and command-injection test harness. Replace release-specific artifact and driver policy with source-verified ROCm 10.0.0 data, remove pip/tarball and all kernel mutation paths, then exercise the default APT lifecycle on `qin-9700`.

**Tech Stack:** Bash, Ubuntu APT, AMD ROCm package repositories, ROCm Runfile installer, shell fixture tests, SSH.

---

### Task 1: Verify ROCm 10.0.0 artifacts and driver policy

**Files:**
- Modify: `docs/plans/2026-09-01-rocm-10-installer.md`

**Step 1: Read official release inputs**

Read the ROCm 10.0.0 install selector, compatibility matrix, Runfile instructions, package-manager instructions, and AMD GPU driver 31.50 release documentation. Record exact Ubuntu 24.04 repository URLs, signing-key instructions, package names, Runfile name and URL, supported R9700/GFX target, and driver/kernel requirements.

**Step 2: Probe artifacts without installing**

Use HTTP metadata and APT repository indexes to prove every planned package and Runfile exists. Reject guessed names or URLs. Record checksums or repository metadata needed by the installer.

**Step 3: Update the plan source table**

Add the verified values and source URLs to this plan before writing release constants.

**Step 4: Commit**

```bash
git add docs/plans/2026-09-01-rocm-10-installer.md
git commit -m "docs: record ROCm 10 artifacts"
```

### Task 2: Define the ROCm 10 release contract in tests

**Files:**
- Modify: `tests/test_release_cli.sh`
- Modify: `tests/test_artifact_commands.sh`
- Modify: `tests/fixtures/rocm-7.14-artifacts.tsv` (rename to a ROCm 10 name)
- Modify: `tests/run_tests.sh`

**Step 1: Rename the release fixture**

Rename the fixture to `tests/fixtures/rocm-10.0-artifacts.tsv` and replace its rows only with artifacts proven in Task 1.

**Step 2: Write failing release assertions**

Assert ROCm `10.0.0`, its package series, the verified AMDGPU release/build marker, exact APT root, exact Runfile URL, and supported methods `apt` and `runfile` only. Assert `pip`, `tarball`, `--prepare-kernel`, `--reboot-after-kernel`, and `--allow-unqualified-kernel` are rejected.

**Step 3: Write failing artifact assertions**

Assert exact R9700 `gfx1201` APT package resolution and exact Runfile resolution. Remove pip/tarball artifact expectations.

**Step 4: Run focused tests and verify failure**

```bash
bash tests/test_release_cli.sh
bash tests/test_artifact_commands.sh
```

Expected: failures identify the still-current 7.14 constants and obsolete CLI methods.

**Step 5: Commit failing tests**

```bash
git add tests/test_release_cli.sh tests/test_artifact_commands.sh tests/fixtures tests/run_tests.sh
git commit -m "test: define ROCm 10 release contract"
```

### Task 3: Cut release constants and artifact resolution to ROCm 10

**Files:**
- Modify: `rocm-install.sh`

**Step 1: Replace release and driver constants**

Set the source-verified ROCm 10.0.0 version, package series, AMDGPU release/build marker, APT root, Runfile name/URL/root, supported OS keys, and GFX artifact data.

**Step 2: Remove pip and tarball resolution**

Delete their constants, CLI parsing, plan resolution, validation branches, environment roots, install/uninstall functions, and help text. Retain no aliases or compatibility shims.

**Step 3: Keep APT and Runfile ownership exclusive**

Update package discovery, exact uninstall candidates, environment configuration, ready-state detection, and conflict messages for the verified ROCm 10 layouts.

**Step 4: Run focused tests**

```bash
bash tests/test_release_cli.sh
bash tests/test_artifact_commands.sh
```

Expected: both pass.

**Step 5: Commit**

```bash
git add rocm-install.sh tests
git commit -m "feat: switch installer artifacts to ROCm 10"
```

### Task 4: Define advisory kernel behavior in tests

**Files:**
- Modify: `tests/test_kernel_state.sh`
- Modify: `tests/test_system_flow.sh`
- Modify: `tests/test_release_cli.sh`

**Step 1: Replace kernel transition tests**

Delete pending-state, metapackage installation, GRUB selection, and reboot retry tests. Add tests proving no removed option parses and no kernel transition state is written.

**Step 2: Add version-boundary tests**

Cover `6.7.*` as blocked before mutation, `6.8.*` as allowed, and R9700 on `6.17.*` as allowed with a recommendation for Ubuntu 24.04 GA 6.8.

**Step 3: Add system-flow safety assertions**

Assert the 6.17 R9700 flow reaches driver/ROCm work and captured commands contain no kernel package installation, `grub-*`, `reboot`, or `shutdown` command. Assert 6.7 exits before driver mutation.

**Step 4: Run focused tests and verify failure**

```bash
bash tests/test_kernel_state.sh
bash tests/test_system_flow.sh
bash tests/test_release_cli.sh
```

Expected: failures identify the existing strict kernel state machine and obsolete flags.

**Step 5: Commit failing tests**

```bash
git add tests/test_kernel_state.sh tests/test_system_flow.sh tests/test_release_cli.sh
git commit -m "test: define advisory kernel policy"
```

### Task 5: Replace kernel mutation with warnings

**Files:**
- Modify: `rocm-install.sh`

**Step 1: Remove mutation state and CLI**

Delete kernel metapackage installation, `/boot` checks, GRUB discovery and mutation, pending-kernel files, reboot execution, and their options.

**Step 2: Implement numeric minimum comparison**

Parse the running major/minor release. Reject malformed releases and versions below 6.8 before any mutation. Do not use lexical comparison.

**Step 3: Implement official recommendation output**

Resolve the recommendation from OS and GPU class. For R9700/gfx1201 on Ubuntu 24.04, print GA `6.8` when the running series differs; set the plan status to a non-blocking advisory state. Keep current and recommended releases explicit in the plan.

**Step 4: Ensure lifecycle cannot reboot**

Driver activation may return a reboot-required status, but the script only reports it. No execution path invokes reboot or bootloader tools.

**Step 5: Run focused tests**

```bash
bash tests/test_kernel_state.sh
bash tests/test_system_flow.sh
bash tests/test_release_cli.sh
```

Expected: all pass.

**Step 6: Commit**

```bash
git add rocm-install.sh tests
git commit -m "feat: make kernel policy advisory"
```

### Task 6: Migrate lifecycle and Runfile tests

**Files:**
- Modify: `tests/test_lifecycle.sh`
- Modify: `tests/test_runfile.sh`
- Modify: `tests/test_artifact_commands.sh`
- Modify: `tests/test_system_flow.sh`

**Step 1: Update APT lifecycle expectations**

Use the exact ROCm 10 package names, roots, environment paths, `rocminfo` path, `amd-smi` path, migration candidates, and uninstall commands.

**Step 2: Update Runfile ownership expectations**

Use the exact ROCm 10 marker, URL, install root, idempotence query, install command, and vendor uninstall command.

**Step 3: Delete removed-method coverage**

Remove pip and tarball setup, verification, rollback, and cleanup scenarios. Preserve generic assertions still used by APT or Runfile.

**Step 4: Run lifecycle tests and fix source defects**

```bash
bash tests/test_lifecycle.sh
bash tests/test_runfile.sh
bash tests/test_system_flow.sh
bash tests/test_artifact_commands.sh
```

Expected: all pass and captured commands contain only verified ROCm 10 artifacts.

**Step 5: Commit**

```bash
git add rocm-install.sh tests
git commit -m "test: migrate ROCm 10 lifecycle coverage"
```

### Task 7: Update user documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/rocm-7.14-ubuntu-26.04-gfx1151-research.md` (remove if strictly 7.14-only and already preserved on the branch)

**Step 1: Rewrite the supported contract**

Document ROCm 10.0.0, APT default, explicit Runfile fallback, supported OS/GFX data, exact repositories and roots, migration boundaries, and verification commands.

**Step 2: Document kernel behavior prominently**

State that kernels below 6.8 are blocked; kernels 6.8 or newer proceed; non-recommended kernels receive advice only; the installer never installs a kernel, modifies GRUB, or reboots.

**Step 3: Document release preservation**

Link users needing the old installer to the `7.14.0` branch. Keep all `main` quick-start commands targeting `main`.

**Step 4: Check stale documentation strings**

Search tracked source, tests, and README for `7.14`, pip/tarball CLI promises, kernel preparation, automatic reboot, and old roots. Remaining occurrences must be intentional history/design references only.

**Step 5: Commit**

```bash
git add README.md docs
 git commit -m "docs: publish ROCm 10 installation guide"
```

### Task 8: Run local behavioral verification

**Files:**
- Modify only if verification exposes a defect: `rocm-install.sh`, `tests/*`

**Step 1: Run syntax checks**

```bash
bash -n rocm-install.sh
```

Expected: exit 0.

**Step 2: Run the complete automated suite**

```bash
bash tests/run_tests.sh
```

Expected: every ROCm 10 installer test passes.

**Step 3: Exercise the actual CLI**

Run `--help` and a fixture-backed/non-mutating plan path. Confirm only APT and Runfile are advertised and the kernel plan cannot request mutation or reboot.

**Step 4: Commit verification fixes if needed**

Use one focused commit describing the corrected observable behavior; do not make a verification-only empty commit.

### Task 9: Validate and install on qin-9700

**Files:**
- No repository file changes unless a reproducible host result exposes a source defect.

**Step 1: Capture pre-install state**

Over SSH, record OS release, kernel, boot ID, four R9700 PCI devices and bindings, KFD topology, installed ROCm/AMDGPU packages, DKMS state, active ROCm roots, disk space, and current `rocminfo`/`amd-smi` versions.

**Step 2: Run the real non-mutating plan**

Copy the exact working-tree script to a temporary remote path and run its plan/confirmation-abort path. Confirm `gpu_count=4`, `gfx1201`, current `6.17`, recommended `6.8`, allowed continuation, exact ROCm 10 artifacts, and no kernel/reboot action.

**Step 3: Execute the default APT lifecycle**

Run the script interactively or with only the minimum explicit non-interactive cleanup policy required by observed state. Do not broaden deletion. Capture complete output and exit status.

**Step 4: Handle a human reboot boundary**

If the driver stage reports reboot required, stop. Do not invoke reboot. Report the exact state and wait for the user to reboot before continuing the remaining steps.

**Step 5: Verify the installed surface**

After any user-controlled reboot, verify four `amdgpu`-bound R9700 devices, KFD `gfx1201`, successful `rocminfo`, `amd-smi version` equal to 10.0.0, and expected ROCm 10 package ownership.

**Step 6: Run a minimal HIP smoke program**

Compile a program with the installed `hipcc` that enumerates devices, checks the count is four, allocates device memory, launches a trivial kernel on each device, synchronizes, and validates copied results. Expected: success for all four devices.

**Step 7: Verify idempotence**

Run the installer again. Expected: matching ROCm/driver state is retained, no conflicting cleanup occurs, and no kernel mutation or reboot command is proposed.

### Task 10: Final review and publish main

**Files:**
- Review: `rocm-install.sh`
- Review: `tests/`
- Review: `README.md`
- Review: `docs/plans/`

**Step 1: Review the complete diff**

Check for obsolete code paths, accidental compatibility aliases, unsafe broad package removal, unquoted shell expansions, ignored command failures, and claims not proven by local or R9700 verification.

**Step 2: Run final verification**

```bash
bash -n rocm-install.sh
bash tests/run_tests.sh
```

Expected: exit 0 and all tests pass.

**Step 3: Push main**

```bash
git push origin main
```

Expected: `origin/main` contains the verified ROCm 10.0.0 implementation; `origin/7.14.0` remains at `7794bdc`.
