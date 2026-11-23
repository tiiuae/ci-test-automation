# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Tests for GUI application headers state

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource

Test Setup          Start screen recording

Test Tags           gui-app-headers  lenovo-x1  darter-pro


*** Variables ***
${HEADER_HEIGHT}        48
${BORDERS_HEIGHT}       10


*** Test Cases ***
New Window Header Follows Focus
    [Documentation]    Open app, header should be active with white text
    ...                Open new app, previous app header should become inactive with light gray text in it
    ...                New app header should become active
    ...                Open third app, new app header should become active, both previous ones - inactive
    [Tags]    SP-T538  lenovo-x1  darter-pro
    [Setup]   GUI App Test Setup
    ${apps}    Create list
    ${screen_before_apps}       Take Remote Screenshot And Download     to=${GUI_OUTPUT_DIR}/new_window_title_bars_follow_focus.jpeg

    Start App And Check Stack Headers  ${Gala}              ${apps}     ${screen_before_apps}
    Start App And Check Stack Headers  ${Zoom}              ${apps}     ${screen_before_apps}
    Start App And Check Stack Headers  ${Google Chrome}     ${apps}     ${screen_before_apps}

    [Teardown]    Teardown New Window Header


*** Keywords ***
Start App And Check Stack Headers
    [Arguments]    ${app}   ${apps}    ${screen_before_apps}
    Start App in VM         ${app}
    Append to list          ${apps}                 ${app}
    ${states}   Get Header Stack States     ${screen_before_apps}   ${apps}
    Check Headers Stack States     ${apps}  ${states}

Get Header Stack States
    [Arguments]     ${screen_before_apps}   ${apps}
    ${cropped}    Capture Changes Since Screenshot    ${screen_before_apps}    headers_stack
    ${apps_quantity}    Get Length    ${apps}
    ${states}       Create list

    FOR  ${index}    ${app}    IN ENUMERATE    @{apps}
        ${header}    Crop Header From Stack     ${screen_before_apps}   ${index}    ${GUI_OUTPUT_DIR}/${app['display_name']}_header.png
        ${state}     Detect Header State        ${header}
        Append to list    ${states}     ${state}
    END
    RETURN    ${states}

Check Headers Stack States
    [Arguments]    ${apps}  ${states}
    ${apps_quantity}    Get Length    ${apps}
    ${error_found}    Set variable    ${EMPTY}

    FOR    ${index}   IN RANGE  ${apps_quantity}-1
        IF  '${states[${index}]}' != 'inactive'
            ${error_found}    Set variable    ${error_found}Header state of the '${apps[${index}]['display_name']}' app is '${states[${index}]}', expected 'inactive'.\n
        END
    END
    IF  '${states[-1]}' != 'active'
            ${error_found}    Set variable    ${error_found}Header state of the '${apps[-1]['display_name']}' app is '${states[-1]}', expected 'active'.\n
        END

    Should Be Empty    ${error_found}    msg=${error_found}

Teardown New Window Header
    Kill App in VM    ${Google Chrome}    status=PASS    require_exists=False
    Kill App in VM    ${Zoom}             status=PASS    require_exists=False
    Kill App in VM    ${Gala}             status=PASS    require_exists=False

    Remove Captured Screenshots
    Switch to vm    ${GUI_VM}    user=${USER_LOGIN}
    Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}
    IF    $test_status == 'FAIL'
        SKIP    Known issue: SSRCSP-9281 (App title bars do not update their active/inactive appearance)
    END

Crop Header From Stack
    [Documentation]    Crop one title bar from the changed area of the screenshot.
    ...    COSMIC cascades floating windows 48 pixels down, leaving earlier title bars visible.
    ...    The crop trims 10 pixels from each end of the 48-pixel band to keep border pixels out of the state check.
    ...    Unmaximized windows are about 950 pixels wide and shift left and right as COSMIC cascades them.
    ...    Cropping horizontally from x=200 to x=700 keeps the analysis within the overlap and excludes background.
    [Arguments]    ${screen_before_apps}    ${position_in_stack}     ${output_path}
    ${cropped}    Capture Changes Since Screenshot    ${screen_before_apps}    header
    ${top}        Evaluate    ${BORDERS_HEIGHT} + ${position_in_stack} * ${HEADER_HEIGHT}
    ${bottom}     Evaluate    (${position_in_stack} + 1) * ${HEADER_HEIGHT} - ${BORDERS_HEIGHT}
    ${header_path}    Crop Image    ${cropped}    top=${top}    bottom=${bottom}
    ...    left=${200}    right=${700}    output_path=${output_path}
    Add To The Screenshot List      ${header_path}

    RETURN    ${header_path}
