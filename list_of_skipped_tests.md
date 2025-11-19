# Add/Remove info when changes in SKIPs/Tags Added/Removed

## Active SKIPS

| DATE SET   | TEST CASE                                              | TICKET / Additional Data.                                                                       |
| ---------- | ------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| 18.11.2025 | Check Grafana logs (any logs from the last 10 minutes) | SSRCSP-7612                                                                                     |
| 07.11.2025 | Measure time to launch COSMIC Settings                 | SSRCSP-7518                                                                                     |
| 06.11.2025 | Check Grafana logs (net-vm)                            | SSRCSP-7542                                                                                     |
| 23.10.2025 | Save host journalctl/Verify NetVM is started           | SSRCSP-7453                                                                                     |
| 16.09.2025 | Check systemctl status in every VM                     | [Full list of skips in the test case](/Robot-Framework/test-suites/functional-tests/vm.robot)   |
| 27.06.2025 | Measure UDP Bidir Throughput Small Packets (Dell)      | SSRCSP-6774                                                                                     |
| 13.06.2025 | Record Video With Camera (Dell)                        | SSRCSP-6694                                                                                     |
| 05.06.2025 | Measure UDP Bidir Throughput Big Packets(AGX)          | SSRCSP-6623                                                                                     |
|            | Measure Hard Boot Time                                 | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time        |
|            | Measure Soft Boot Time -Dell                           | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time.       |
|            | OP-TEE xtest 1033 -orin-agx & orin-nx                  | Known issue encountered, skipping the test                                                      |
|            | OP-TEE xtest 1008 -orin-agx & orin-nx                  | Known issue encountered, skipping the test                                                      |
|            | Check systemctl status                                 | [Full list of skips in the test case](/Robot-Framework/test-suites/functional-tests/host.robot) |
|            | Check Camera Application -DELL                         | SSRCSP-6450                                                                                     |

## TAGs removed

| DATE SET   | TEST CASE                             | TICKET / Additional Data.                                                              |
| ---------- | ------------------------------------- | -------------------------------------------------------------------------------------- |
| 03.11.2025 | Change keyboard layout                | Default English-Arabic-Finnish shortcut was removed. Testcase needs refactoring.       |
| 28.10.2025 | Verify brightness persisted           | Works locally but not in the lab. Needs further investigation.                         |
| 03.09.2025 | Performance/network suite (AGX)       | SSRCSP-7160. Network-adapter usage had impact on results. Needs further investigation. |
| 03/2025    | Performance Network.robot - ‘orin-nx’ | SSRCSP-6372 - Works locally but problems when Jenkins used, fails all..                |
