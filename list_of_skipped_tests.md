# Add/Remove info when changes in SKIPs/Tags Added/Removed

## Active SKIPS

| DATE SET   | TEST CASE                                     | TICKET / Additional Data                                                | Error Log Context    |
| ---------- | --------------------------------------------- | ----------------------------------------------------------------------- | -------------------- |
| 26.08.2026 | Start COSMIC Settings via GUI (non-storeDisk) | SSRCSP-8856                                                             | Slow Cosmic Settings |
| 26.08.2026 | Verify Gala is loaded                         | SSRCSP-8855                                                             | Slow Gala            |
| 05.08.2026 | Ghaf Control Panel shows device information   | SSRCSP-8770 (GUI shows "unknown")                                       | Ghaf Control Panel   |
| 20.07.2026 | nvpmodel check test (Orins)                   | SSRCSP-8712                                                             | (Fails every time)   |
| 17.07.2026 | Shutdown from power menu (Lenovo X1)          | SSRCSP-8714                                                             | Slow shutdown        |
| 06.07.2026 | Open video with COSMIC Media Player           | SSRCSP-8367                                                             | Crash in media-vm    |
| 01.07.2026 | Account lockout after failed GUI login        | Test under development                                                  | Account lockout      |
| 13.05.2026 | Validate Forward Secure Sealing               | SSRCSP-8820                                                             | FSS test failed      |
| 30.04.2026 | Open PDF from VM                              | SSRCSP-8367                                                             | Crash in media-vm    |
| 17.03.2026 | OP-TEE xtest 1006                             | SSRCSP-8198                                                             | (Fails every time)   |
| 11.02.2026 | Check device id (storeDisk)                   | SSRCSP-7997                                                             | (Fails every time)   |
| 11.02.2026 | Check net-vm hostname (storeDisk)             | SSRCSP-7997                                                             | (Fails every time)   |
| 16.09.2025 | Check systemctl status in every VM            | [List of skips](/Robot-Framework/test-suites/functional-tests/vm.robot) | Systemctl status     |

## Old Dell 7330 skips

| DATE SET   | TEST CASE                            | TICKET / Additional Data                |
| ---------- | ------------------------------------ | --------------------------------------- |
| 15.06.2026 | VM memory usage snapshot (Dell 7330) | Dell has less memory than other targets |
| 22.05.2026 | Check logging rate (Dell)            | SSRCSP-8481                             |

## TAGs removed

| DATE SET   | TEST CASE (removed tag)                                  | TICKET / Additional Data                                              |
| ---------- | -------------------------------------------------------- | --------------------------------------------------------------------- |
| 24.04.2026 | Rebuild tests (regression)                               | Rebuild tests do not work properly with signed images                 |
| 27.02.2026 | Measure Soft Boot Time (darter-pro)                      | Test removed because the Enter finger causes inaccuracy to the result |
| 20.02.2026 | Test ballooning in chrome-vm / business-vm (performance) | SSRCSP-8127, ballooning feature was turned off in ghaf by PR#1770     |
| 03.09.2025 | Performance/network suite (all orin tags)                | iperf is not available on Orins                                       |

## Workarounds

| DATE SET   | TEST CASE / KEYWORD                   | TICKET / Additional Data                                                                               | Error Log Context       |
|------------| ------------------------------------- |--------------------------------------------------------------------------------------------------------|-------------------------|
| 04.09.2026 | Verify shutdown via network           | SSRCSP-8874, Shutdown time for orins increased and takes 160 seconds.                                  |                         |
| 27.08.2026 | VM memory usage snapshot              | Orin AGX ghaf-host has 0 total swap memory. Ignore swap low limit check in this case.                  |                         |
| 17.08.2026 | Select power menu option              | SSRCSP-8805, skipped on X1 if taskbar disappears                                                       | Taskbar disappeared     |
| 17.07.2026 | Log out with loginctl                 | Log out all testuser sessions if the are many on seat (controlling the screen) (probably a Cosmic bug) |                         |
| 15.07.2026 | Verify booting after restart by power | SSRCSP-8704, extra 90 seconds added for AGX boot                                                       |                         |
| 30.06.2026 | Unlock account and login              | Try to login twice after unlocking, first login after unlocking the account fails                      |                         |
| 22.06.2026 | Set RTC time                          | SSRCSP-8622, separate command for Lenovo X1                                                            |                         |
| 17.06.2026 | Verify service status                 | SSRCSP-8662, welcome check disabled                                                                    | (Failing part skipped)  |
| 29.01.2026 | Reboot Orin if ssh connection dropped | This keyword is a workaround for the SSH connection dropping on Orin, reboots and connect again        | Orin connection dropped |
| 27.01.2026 | Verify shutdown via serial            | Shutdown is checked via network if shutdown log was not found in serial output                         |                         |
