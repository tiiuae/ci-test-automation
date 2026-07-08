# Add/Remove info when changes in SKIPs/Tags Added/Removed

## Active SKIPS

| DATE SET   | TEST CASE                                            | TICKET / Additional Data                                                |
| ---------- | ---------------------------------------------------- | ----------------------------------------------------------------------- |
| 06.07.2026 | Open video with COSMIC Media Player                  | SSRCSP-8367                                                             |
| 01.07.2026 | Account lockout after failed GUI login               | Test under development                                                  |
| 15.06.2026 | VM memory usage snapshot (Dell 7330)                 | Dell has less memory than other targets                                 |
| 25.05.2026 | Reboot from power menu                               | SSRCSP-8490                                                             |
| 22.05.2026 | Check logging rate (Dell)                            | SSRCSP-8481                                                             |
| 13.05.2026 | Validate Forward Secure Sealing                      | SSRCSP-8425                                                             |
| 30.04.2026 | Open PDF from VM                                     | SSRCSP-8367                                                             |
| 30.03.2026 | Check Camera in VMs (Dell)                           | SSRCSP-8266                                                             |
| 30.03.2026 | Check Camera Application (Dell checked in chrome-vm) | SSRCSP-8266                                                             |
| 23.03.2026 | Verify camera block persisted (Lenovo X1)            | SSRCSP-8224                                                             |
| 17.03.2026 | OP-TEE xtest 1006, OP-TEE xtest 1024 (Orins)         | SSRCSP-8198                                                             |
| 11.02.2026 | Check device id (storeDisk)                          | SSRCSP-7997                                                             |
| 11.02.2026 | Check net-vm hostname (storeDisk)                    | SSRCSP-7997                                                             |
| 23.10.2025 | Verify NetVM is started (Orin NX)                    | SSRCSP-7453                                                             |
| 16.09.2025 | Check systemctl status in every VM                   | [List of skips](/Robot-Framework/test-suites/functional-tests/vm.robot) |
| 21.12.2023 | OP-TEE xtest 1033, OP-TEE xtest 1008 (Orins)         | Known issue encountered, skipping the test                              |

## TAGs removed

| DATE SET   | TEST CASE (removed tag)                                  | TICKET / Additional Data                                                               |
| ---------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| 24.04.2026 | Rebuild tests (regression)                               | Rebuild tests do not work properly with signed images                                  |
| 27.02.2026 | Measure Soft Boot Time (darter-pro)                      | Test removed because the Enter finger causes inaccuracy to the result                  |
| 20.02.2026 | Test ballooning in chrome-vm / business-vm (performance) | Ballooning feature was turned off in ghaf by PR#1770                                   |
| 03.09.2025 | Performance/network suite (orin-agx)                     | SSRCSP-7160. Network-adapter usage had impact on results. Needs further investigation. |
| 17.03.2025 | Performance/network suite (orin-nx)                      | SSRCSP-6372 - Works locally but problems when Jenkins used, fails all..                |

## Workarounds

| DATE SET   | TEST CASE / KEYWORD                   | TICKET / Additional Data                                                                                   |
| ---------- | ------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| 30.06.2026 | Unlock account and login              | Try to login twice after unlocking, first login after unlocking the account fails                          |
| 22.06.2026 | Set RTC time                          | SSRCSP-8622, separate command for Lenovo X1                                                                |
| 17.06.2026 | Verify service status                 | SSRCSP-8662, welcome check disabled                                                                        |
| 15.06.2026 | VM memory usage snapshot              | Orin host check is skipped, swap is not enabled                                                            |
| 08.06.2026 | Soft Reboot Device                    | SSRCSP-8490, reboot from host if reboot from gui-vm failed                                                 |
| 27.03.2026 | Get Actual Device ID                  | Additional Device ID path added for https://github.com/tiiuae/ghaf/pull/1421                               |
| 26.02.2026 | Check systemctl status in every VM    | Retry on Orin NX, Executing command 'systemctl list-units --plain --no-legend --no-pager ' fails sometimes |
| 17.02.2026 | Verify booting after restart by power | Try to boot Orin NX second time if first time did not work                                                 |
| 29.01.2026 | Reboot Orin if ssh connection dropped | This keyword is a workaround for the SSH connection dropping on Orin, reboots and connect again            |
| 27.01.2026 | Verify shutdown via serial            | Shutdown is checked via network if shutdown log was not found in serial output                             |
