# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing App Store
Force Tags          app-store  darter-pro

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Run Keyword If   "storeDisk" not in "${JOB}"   SKIP   App Store tests can only be executed with a storeDisk image.
Test Setup          Run Keywords   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}  AND   Start screen recording
Test Teardown       Run Keywords   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}  AND   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}
Test Timeout        10 minutes


*** Test Cases ***

Install Firefox
    [Documentation]    Install and launch Firefox from App Store
    [Tags]    SP-T335
    Launch App Store app   firefox

Install Onlyoffice
    [Documentation]    Install and launch Onlyoffice from App Store
    [Tags]    SP-T355
    Launch App Store app   onlyoffice

*** Keywords ***

Launch App Store app
    [Documentation]   Install app from App Store, launch the app from the app menu and uninstall the app
    [Arguments]    ${app_name}   ${process_name}=${app_name}
    [Setup]   Verify app is not preinstalled via flatpak   ${app_name}

    Open App Store

    # Search for app page and open it
    Type string and press enter   ${app_name}[:-1]   enter=False  # Last letter removed to not disturb text recognition
    Sleep   1
    Locate and click   text   ${app_name}   wiggle=True
    Tab and enter      tabs=1    # Close the sidebar

    # Install app
    Locate and click   text   nstall   scale=3   wiggle=True   #Typo intentional, "I" is sometimes not recognized by the text recognition
    Move cursor to corner
    Wait until flatpak app is installed    ${app_name}

    # Close App Store
    Close app via GUI   ${FLATPAK_VM}  cosmic-store  window-close-neg.png

    # Launch app from app menu, verify and kill it
    Start app via GUI   ${FLATPAK_VM}   ${process_name}   ${app_name}
    Switch to vm   ${FLATPAK_VM}
    Kill process by name   ${process_name}   sudo=True

    Open App Store
    Uninstall app in App Store   ${app_name}
    Close app via GUI   ${FLATPAK_VM}  cosmic-store  window-close-neg.png

    [Teardown]   Run Keywords   Switch to vm   ${FLATPAK_VM}
    ...    AND   Kill App By Name   cosmic-store   sudo=True
    ...    AND   Kill App By Name   ${process_name}   sudo=True

Verify app is not preinstalled via flatpak
    [Arguments]    ${app_name}
    [Setup]   Switch to vm   ${FLATPAK_VM}
    ${flatpak_app_id}    Get flatpak app id   ${app_name}
    IF   '${flatpak_app_id}' != ''
        ${error_message}    Catenate    SEPARATOR=\n
        ...    App ${app_name} is already installed (${flatpak_app_id}).
        ...    This test does not remove preinstalled apps to avoid data loss.
        ...    Remove it manually first, then rerun this test.
        FAIL   ${error_message}
    END
    Log    ${app_name} is not installed via flatpak    console=True
    [Teardown]   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}

Wait until flatpak app is installed
    [Arguments]    ${app_name}   ${range}=100
    [Setup]   Switch to vm   ${FLATPAK_VM}
    Log To Console   Waiting for the app to install...   no_newline=true
    FOR   ${i}   IN RANGE   ${range}
        ${flatpak_app_id}    Get flatpak app id    ${app_name}  switch_to_vm=False
        IF   '${flatpak_app_id}' != ''
            Log    Done    console=True
            Log    ${app_name} is installed as ${flatpak_app_id}    console=True
            RETURN
        END
        Log To Console   ${i}.  no_newline=true
    END
    FAIL    App ${app_name} is not installed via flatpak.
    [Teardown]   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}

Get flatpak app id
    [Arguments]   ${app_name}   ${switch_to_vm}=True
    [Setup]       Run Keyword if   ${switch_to_vm}   Switch to vm   ${FLATPAK_VM}
    ${flatpak_app_id}   Run Command    sh -c "flatpak list --app --columns=application,name | grep -i '${app_name}' | head -n 1 | cut -f1"   sudo=True
    # For debugging
    Run Command   flatpak list   sudo=True
    RETURN        ${flatpak_app_id}
    [Teardown]    Run Keyword if   ${switch_to_vm}   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}

Open App Store
    Start application in VM   "App Store"   ${FLATPAK_VM}   cosmic-store   always_check_vm=True
    Switch to vm   ${GUI_VM}  user=${USER_LOGIN}
    # Wait for the window to be active and fullscreen it
    Locate on screen   text   Editor   iterations=20
    Press Key(S)       LEFTMETA+M

Uninstall app in App Store
    [Documentation]   Uninstall app via GUI and verify
    [Arguments]    ${app_name}
    Log     Uninstalling ${app_name}   console=True
    Locate and click   text   nstalled      scale=2   wiggle=True  #Typo intentional, "I" is sometimes not recognized by the text recognition
    Locate and click   text   ${app_name}   wiggle=True
    # Uninstall app
    Locate and click   text   Uninstall     scale=3   wiggle=True
    Locate and click   text   Permanently   scale=2   wiggle=True
    Run ydotool command   mousemove -x 340 -y 70
    Run ydotool command   click 0xC0
    Sleep  1
    Locate and click   text   Back   scale=3   wiggle=True
    # Verify uninstallation via GUI
    ${is_installed}    Run Keyword And Return Status   Locate on screen   text   ${app_name}   iterations=3   expected_result=FAIL
    IF   ${is_installed}   FAIL   App ${app_name} is still shown as installed in App Store
    # Verify uninstallation via flatpak
    ${flatpak_app_id}   Get flatpak app id   ${app_name}
    Should Be Empty     ${flatpak_app_id}    App ${app_name} is still installed via flatpak (${flatpak_app_id})
    Log   ${app_name} is now uninstalled   console=True
