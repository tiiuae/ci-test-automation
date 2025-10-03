# Add/Remove info when changes in SKIPs/Tags Added/Removed

## Active SKIPS

| DATE SET   | TEST CASE                                         | TICKET / Additional Data.                                                                       |
| ---------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| 24.09.2025 | Control audio volume with keyboard shortcuts      | SSRCSP-7294 (Lenovo installer)                                                                  |
| 16.09.2025 | Check systemctl status in every VM                | SSRCSP-7234, SSRCSP-7306, SSRCSP-7321                                                           |
| 09.09.2025 | Start Falcon AI (Lenovo-x1, Darter-PRO)           | SSRCSP-6769                                                                                     |
| 27.06.2025 | Measure UDP Bidir Throughput Small Packets (Dell) | SSRCSP-6774                                                                                     |
| 13.06.2025 | Record Video With Camera (Dell)                   | SSRCSP-6694                                                                                     |
| 05.06.2025 | Measure UDP Bidir Throughput Big Packets(AGX)     | SSRCSP-6623                                                                                     |
| 27.05.2025 | TimeSynch (AGX)                                   | SSRCSP-6423. Unrecoverable error detected. #PR333                                               |
|            | Measure Hard Boot Time                            | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time        |
|            | Measure Soft Boot Time -Dell                      | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time.       |
|            | OP-TEE xtest 1033 -orin-agx & orin-nx             | Known issue encountered, skipping the test                                                      |
|            | OP-TEE xtest 1008 -orin-agx & orin-nx             | Known issue encountered, skipping the test                                                      |
|            | Verify NetVM PCI device passthrough -Orin AGX     | SSRCSP-5662, SSRCSP-6423                                                                        |
|            | Check systemctl status                            | [Full list of skips in the test case](/Robot-Framework/test-suites/functional-tests/host.robot) |
|            | Check Camera Application -DELL                    | SSRCSP-6450                                                                                     |

## TAGs removed

| DATE SET   | TEST CASE                             | TICKET / Additional Data.                                                             |
| ---------- | ------------------------------------- | ------------------------------------------------------------------------------------- |
| 03.09.2025 | Performance/network suite (AGX)       | SSRCSP-7160. Network-adapter usage had impact on results Needs further investigation. |
| 03/2025    | Performance Network.robot - ‘orin-nx’ | SSRCSP-6372 - Works locally but problems when Jenkins used, fails all..               |
