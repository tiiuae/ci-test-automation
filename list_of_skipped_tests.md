# Add/Remove info when changes in SKIPs/Tags Added/Removed

## Active SKIPS
| DATE SET   | TEST CASE                                     | TICKET / Additional Data.
|------------|-----------------------------------------------| ---
| 27.05.2025 | TimeSynch (AGX)                               | SSRCSP-6423. Unrecoverable error detected. #PR333
| 08.05.2025 | GUI Reboot (Cosmic)                           | The X1 in the lab gets stuck when a reboot is attempted. Needs further investigation.
| 08.05.2025 | GUI Suspend and wake up  (Cosmic)             | The X1 in the lab gets stuck when a suspension is attempted. Needs further investigation.
|            | Measure Hard Boot Time                        | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time
|            | Measure Soft Boot Time -Dell                  | The searched journalctl line is sometimes (randomly) not there. Didn't find it this time.
|            | OP-TEE xtest 1033 -orin-agx & orin-nx         | Known issue encountered, skipping the test
|            | OP-TEE xtest 1008 -orin-agx & orin-nx         | Known issue encountered, skipping the test
|            | Verify NetVM PCI device passthrough -Orin AGX | SSRCSP-5662, SSRCSP-6423
|            | NetVM is wiped after restarting  -Orin AGX    | SSRCSP-5662,SSRCSP-6423
|            | Check systemctl status -Generic               | SSRCSP-4632
|            | Check systemctl status -Orin AGX              | SSRCSP-6303
|            | Check systemctl status -DELL                  | SSRCSP-6450
|            | Check Camera Application -DELL                | SSRCSP-6450
|            | Start Gala on LenovoX1 -DELL & LenovoX1       | SSRCSP-6434



## TAGs removed
| DATE SET | TEST CASE    | TICKET / Additional Data.
|------------------------------------------------|-----------------------------------------------| ---
| 03/2025   | Performance Network.robot - ‘orin-nx’ | SSRCSP-6372 - Works locally but problems when Jenkins used, fails all..
| 22.1.2025 | Start Firefox - ‘nuc, orin-agx        | Firefox is temporarily disabled from SW
