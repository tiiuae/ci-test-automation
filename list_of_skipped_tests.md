# Add/Remove info when changes in SKIPs/Tags Added/Removed

## Active SKIPS

| DATE SET   | TEST CASE                                               | TICKET / Additional Data.                                                                     |
|------------|---------------------------------------------------------| --------------------------------------------------------------------------------------------- |
| 11.06.2026 | Verify booting after restart by power (orin-nx)         | SSRCSP-8585                                                                                   |
| 11.06.2026 | functional-tests (orin-nx)                              | SSRCSP-8585                                                                                   |
| 29.05.2026 | Check Grafana log forwarding after disconnected state   | SSRCSP-8525                                                                                   |
| 25.05.2026 | Reboot from power menu                                  | SSRCSP-8490                                                                                   |
| 22.05.2026 | Check logging rate (Dell)                               | SSRCSP-8481                                                                                   |
| 13.05.2026 | Validate Forward Secure Sealing                         | SSRCSP-8425                                                                                   |
| 30.04.2026 | Open PDF from VM                                        | SSRCSP-8367                                                                                   |
| 30.03.2026 | Check Camera in VMs (Dell)                              | SSRCSP-8266                                                                                   |
| 30.03.2026 | Check Camera Application (Dell checked in chrome-vm)    | SSRCSP-8266                                                                                   |
| 23.03.2026 | Verify camera block persisted (Lenovo X1)               | SSRCSP-8224                                                                                   |
| 26.02.2026 | Check systemctl status in every VM (retry added for NX) | Timeout of Executing command 'systemctl list-units --plain --no-legend --no-pager '.          |
| 11.02.2026 | Check device id                                         | SSRCSP-7997                                                                                   |
| 11.02.2026 | Check net-vm hostname                                   | SSRCSP-7997                                                                                   |
| 23.10.2025 | Save host journalctl/Verify NetVM is started            | SSRCSP-7453                                                                                   |
| 16.09.2025 | Check systemctl status in every VM                      | [Full list of skips in the test case](/Robot-Framework/test-suites/functional-tests/vm.robot) |
|            | Measure Hard Boot Time                                  | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time      |
|            | Measure Soft Boot Time -Dell                            | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time.     |
|            | OP-TEE xtest 1033 -orin-agx & orin-nx                   | Known issue encountered, skipping the test                                                    |
|            | OP-TEE xtest 1008 -orin-agx & orin-nx                   | Known issue encountered, skipping the test                                                    |
|            | OP-TEE xtest 1006 -orin-agx & orin-nx                   | Known issue SSRCSP-8198 encountered, skipping the test                                        |
|            | OP-TEE xtest 1024 -orin-agx & orin-nx                   | Known issue SSRCSP-8198 encountered, skipping the test                                        |

## TAGs removed

| DATE SET   | TEST CASE                                  | TICKET / Additional Data.                                                              |
| ---------- | ------------------------------------------ | -------------------------------------------------------------------------------------- |
| 24.04.2026 | Rebuild tests removed from regression      | Rebuild tests do not work properly with signed images                                  |
| 27.02.2026 | Measure Soft Boot Time (Darter Pro)        | Test removed because the Enter finger causes inaccuracy to the result                  |
| 20.02.2026 | Test ballooning in chrome-vm / business-vm | Ballooning feature was turned off in ghaf by PR#1770                                   |
| 03.09.2025 | Performance/network suite (AGX)            | SSRCSP-7160. Network-adapter usage had impact on results. Needs further investigation. |
| 03/2025    | Performance Network.robot - ‘orin-nx’      | SSRCSP-6372 - Works locally but problems when Jenkins used, fails all..                |
