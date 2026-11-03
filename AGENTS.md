  ## Working Style
  - Be concise and factual.
  - Prefer minimal, targeted changes.
  - Do not refactor unrelated code.

  ## Code Changes
  - Preserve existing code style.
  - Avoid overlap in functions and keywords. Reuse functions and keywords if possible with small changes.
  - Add comments only when logic is not obvious.
  - Do not 'git add' or 'git commit'.
  - Avoid longer than 121 chars lines if possible.
  - Apply 'robotidy --diff Robot-Framework' to the changed files. Conform to suggested changes by robotidy if they are correct.

  ## Review requests
  - Ensure passwords are not leaked to test reports or journalctl.
  - Try to find bugs and potential issues with edge cases.
  - Notify if some change could be done in much cleaner or simple way.

  ## Testing
  - Run the smallest relevant test if possible.

  ## Safety
  - Do not delete files or revert unrelated changes.
  - Ask and warn before making destructive changes.

  ## Project Notes
  - Keep in mind the environment where this code will be used: Robot Framework running on NixOS machine.
  - Do not treat the code or repository as the only source of truth. 
  - Cross-check with Robot Framework documentation, especially in case of debugging problems or making changes to the code.
