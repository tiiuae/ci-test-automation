# Add/Remove info when changes in SKIPs/Tags Added/Removed

## Active SKIPS

| DATE SET   | TEST CASE                          | TICKET / Additional Data                                                              | Error Log Context  |
| ---------- | ---------------------------------- | ------------------------------------------------------------------------------------- | ------------------ |
| 23.10.2026 | Reboot from power menu             | SSRCSP-9085, skip if connect after reboot hits time limit after net-vm serial restart |                    |
| 19.10.2026 | GUI App tests                      | SSRCSP-9093                                                                           | Waypipe socket     |
| 26.08.2026 | Verify Gala is loaded              | SSRCSP-8855                                                                           | Slow Gala          |
| 20.07.2026 | nvpmodel check test (Orins)        | SSRCSP-8712                                                                           | (Fails every time) |
| 11.02.2026 | Check device id (storeDisk)        | SSRCSP-7997                                                                           | (Fails every time) |
| 11.02.2026 | Check net-vm hostname (storeDisk)  | SSRCSP-7997                                                                           | (Fails every time) |
| 16.09.2025 | Check systemctl status in every VM | [List of skips](/Robot-Framework/test-suites/functional-tests/vm.robot)               | Systemctl status   |

## TAGs removed

| DATE SET   | TEST CASE (removed tag)                   | TICKET / Additional Data                                              |
| ---------- | ----------------------------------------- | --------------------------------------------------------------------- |
| 24.04.2026 | Rebuild tests (regression)                | Rebuild tests do not work properly with signed images                 |
| 27.02.2026 | Measure Soft Boot Time (darter-pro)       | Test removed because the Enter finger causes inaccuracy to the result |
| 03.09.2025 | Performance/network suite (all orin tags) | iperf is not available on Orins                                       |

## Workarounds

| DATE SET   | TEST CASE / KEYWORD                    | TICKET / Additional Data                                                                               | Error Log Context       |
| ---------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------- |
| 16.10.2026 | Check If Device Is Available           | SSRCSP-9085, restart net-vm via serial when only serial is available after reboot, then retry SSH      | SSH recovery            |
| 16.10.2026 | Start screen recording                 | SSRCSP-9084, skip screen recording if it fails due to gpu initialization failure                       | GPU init                |
| 09.10.2026 | Get VM list                            | SSRCSP-9056, disp-vm is removed from the list if it is not available                                   | Disp-vm                 |
| 04.09.2026 | Account lockout after failed GUI login | Tolerate one missed faillock increment                                                                 | Account lockout         |
| 27.08.2026 | VM memory usage snapshot               | Orin AGX ghaf-host has 0 total swap memory. Ignore swap low limit check in this case.                  |                         |
| 17.07.2026 | Log out with loginctl                  | Log out all testuser sessions if the are many on seat (controlling the screen) (probably a Cosmic bug) | Multiple sessions       |
| 30.06.2026 | Unlock account and login               | Try to login twice after unlocking, first login after unlocking the account fails                      |                         |
| 22.06.2026 | Set RTC time                           | SSRCSP-8622, separate command for Lenovo X1                                                            |                         |
| 17.06.2026 | Verify service status                  | SSRCSP-8662, welcome check disabled                                                                    | (Failing part skipped)  |
| 29.01.2026 | Reboot Orin if ssh connection dropped  | This keyword is a workaround for the SSH connection dropping on Orin, reboots and connect again        | Orin connection dropped |
| 27.01.2026 | Verify shutdown via serial             | Shutdown is checked via network if shutdown log was not found in serial output                         |                         |
