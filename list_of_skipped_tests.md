# Add/Remove info when changes in SKIPs/Tags Added/Removed

## Active SKIPS

| DATE SET   | TEST CASE                                                                                   | TICKET / Additional Data.                                                                     |
| ---------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| 26.02.2026 | Check systemctl status in every VM (Native NX)                                              | Timeout of Executing command 'systemctl list-units --plain --no-legend --no-pager '.          |
| 13.02.2026 | Measure Soft Boot Time (Darter Pro)                                                         | Needs refactoring (SSRCSP-8027)                                                               |
| 12.02.2026 | Account lockout after failed login                                                          | SSRCSP-8006                                                                                   |
| 05.02.2026 | Validate Forward Secure Sealing                                                             | SSRCSP-7973                                                                                   |
| 11.02.2026 | Check device id                                                                             | SSRCSP-7997                                                                                   |
| 11.02.2026 | Check net-vm hostname                                                                       | SSRCSP-7997                                                                                   |
| 29.01.2026 | Check that unauthorised user has limited access to file system (Pictures folder check only) | SSRCSP-7918                                                                                   |
| 11.12.2025 | GUI Shutdown                                                                                | SSRCSP-7512                                                                                   |
| 07.11.2025 | Measure time to launch COSMIC Settings                                                      | SSRCSP-7518                                                                                   |
| 23.10.2025 | Save host journalctl/Verify NetVM is started                                                | SSRCSP-7453                                                                                   |
| 16.09.2025 | Check systemctl status in every VM                                                          | [Full list of skips in the test case](/Robot-Framework/test-suites/functional-tests/vm.robot) |
| 13.06.2025 | Record Video With Camera (Dell)                                                             | SSRCSP-6694                                                                                   |
|            | Measure Hard Boot Time                                                                      | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time      |
|            | Measure Soft Boot Time -Dell                                                                | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time.     |
|            | OP-TEE xtest 1033 -orin-agx & orin-nx                                                       | Known issue encountered, skipping the test                                                    |
|            | OP-TEE xtest 1008 -orin-agx & orin-nx                                                       | Known issue encountered, skipping the test                                                    |
|            | Check Camera Application -DELL                                                              | SSRCSP-6450                                                                                   |

## TAGs removed

| DATE SET   | TEST CASE                                         | TICKET / Additional Data.                                                              |
| ---------- | ------------------------------------------------- | -------------------------------------------------------------------------------------- |
| 4.12.2025  | Start Falcon AI and verify process started (Dell) | Test stucks with circle running on screen. Not relevant case for this HW target.       |
| 03.09.2025 | Performance/network suite (AGX)                   | SSRCSP-7160. Network-adapter usage had impact on results. Needs further investigation. |
| 03/2025    | Performance Network.robot - ‘orin-nx’             | SSRCSP-6372 - Works locally but problems when Jenkins used, fails all..                |
| 20.2.2026  | Test ballooning in chrome-vm / business-vm        | Ballooning feature was turned off in ghaf by PR#1770                                   |
