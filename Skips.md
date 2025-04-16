
# Add/Remove info when changes in SKIPs/Tags Added/Removed

## Active SKIPS

| DATE SET | TEST CASE                                      | TICKET                                                                                      |
|:---------|:-----------------------------------------------|:--------------------------------------------------------------------------------------------|
|          | Start and close Falcon AI via GUI on LenovoX1  | SSRCSP-6482                                                                                 | 
|          | Start Gala on LenovoX1 -DELL                   | SSRCSP-6434                                                                                 |
|          | Check Camera Application -DELL                 | SSRCSP-6450                                                                                 |
|          | Check systemctl status -DELL                   | SSRCSP-6450                                                                                 |
|          | Check systemctl status -Orin AGX               | SSRCSP-6303                                                                                 |
|          | Check systemctl status -Generic                | SSRCSP-4632                                                                                 |
|          | NetVM is wiped after restarting  -Orin AGX     | SSRCSP-5662                                                                                 |
|          | Verify NetVM PCI device passthrough -Orin AGX  | SSRCSP-5662                                                                                 |
|          | OP-TEE xtest 1008 -orin-agx & orin-nx          | Known issue encountered, skipping the test                                                  |
|          | OP-TEE xtest 1033 -orin-agx & orin-nx          | Known issue encountered, skipping the test                                                  |
|          | Measure Soft Boot Time                         | The searched journalctl line is sometimes(randomly)n not there. Didn't find it this time.                                                   |
|          | Measure Hard Boot Time                         | The searched journalctl line is sometimes(randomly)n not there. Didn't find it this time.                                             |
|          |                         |                                             |

## TAGs removed

| DATE      | Suite/test & removed Tag              | TICKET/comment                                                                  |
|:----------|:--------------------------------------|:--------------------------------------------------------------------------------|
| 03/2025   | Performance Network.robot - ‘orin-nx’ | SSRCSP-6372 - Works locally but problems when Jenkins used                      |
| 22.1.2025 | Start Firefox - ‘nuc, orin-agx        | Firefox is temporarily disabled from SW                                                                                |
