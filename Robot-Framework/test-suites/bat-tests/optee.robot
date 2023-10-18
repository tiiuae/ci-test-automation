# SPDX-FileCopyrightText: 2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Test OP-TEE PKCS#11 through pkcs11-tool wrappers
Force Tags          pkcs11
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Suite Setup         Connect
Suite Teardown      Close All Connections


*** Test Cases ***


Basic pkcs11-tool-optee test
    [Documentation]   Test OP-TEE PKCS#11 through pkcs11-tool-optee wrapper.
    ...               Basic test which initalizes key slots, by directly
    ...               calling OP-TEE.
    [Tags]            optee  SP-T666  orin-agx  orin-nx

    ${tool}=    Set Variable    "pkcs11-tool-optee"
    List key slots    ${tool}
    Initialize slot    ${tool}
    Test Public Key usage    ${tool}    keyid=1    keylabel=rsakey0    mechanism=SHA256-RSA-PKCS-PSS
    Test Public Key usage    ${tool}    keyid=2    keylabel=eckey0    mechanism=ECDSA-SHA256
    List key slots    ${tool}
    List objects    ${tool}


# These two tests are for the ghaf-caml-crush, which is not included in the
# default build, but the tests are included here for convenience.

Check caml-crush service is running
    [Documentation]  Checks if the systemd service for caml-crush is running.
    # Tags should be really: optee orin-agx  orin-nx
    # but caml-crush is not included in basic ghaf builds
    [Tags]  caml-crush

    ${status}  ${state}=    Verify service status  service="caml-crush.service"  expected_status=active  expected_state=running


Basic pkcs11-tool-caml-crush test
    [Documentation]   Test OP-TEE PKCS#11 through pkcs11-tool-caml-crush
    ...               wrapper. Basic test which initalizes key slots, by
    ...               calling OP-TEE through caml-crush's pkcs11proxyd.
    # Tags should be really: optee  orin-agx  orin-nx
    # but caml-crush is not included in basic ghaf builds
    [Tags]  caml-crush

    ${tool}=    Set Variable    "pkcs11-tool-caml-crush-optee"
    List key slots    ${tool}
    Initialize slot    ${tool}
    Test Public Key usage    ${tool}    keyid=1    keylabel=rsakey0    mechanism=SHA256-RSA-PKCS-PSS
    Test Public Key usage    ${tool}    keyid=2    keylabel=eckey0    mechanism=ECDSA-SHA256
    List key slots    ${tool}
    List objects    ${tool}


*** Keywords ***


List key slots
    [Documentation]    List all key slots
    [Arguments]        ${tool}

    ${cmd}=    Set Variable    ${tool} -L
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    sudo=True    sudo_password=${PASSWORD}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0


List objects
    [Documentation]    List all key slots
    [Arguments]        ${tool}

    ${cmd}=    Set Variable    ${tool} --list-objects
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    sudo=True    sudo_password=${PASSWORD}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0


Initialize slot
    [Documentation]    Initialize Key Slot
    [Arguments]        ${tool}

    ${cmd}=    Set Variable    ${tool} --init-token --label mytoken --so-pin 1234
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    sudo=True    sudo_password=${PASSWORD}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0

    ${cmd}=    Set Variable    ${tool} --label mytoken --login --so-pin 1234 --init-pin --pin 0000
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    sudo=True    sudo_password=${PASSWORD}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0

    ${cmd}=    Set Variable    ${tool} --token-label mytoken --pin 0000 --keypairgen --key-type RSA:2048 --id 1 --label rsakey0
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    sudo=True    sudo_password=${PASSWORD}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0

    ${cmd}=    Set Variable    ${tool} --token-label mytoken --pin 0000 --keypairgen --key-type EC:secp256r1 --id 2 --label eckey0
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    sudo=True    sudo_password=${PASSWORD}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0


Test Public Key usage
    [Documentation]    Test Public Key usage
    [Arguments]        ${tool}    ${keyid}    ${keylabel}    ${mechanism}

    ${content_file}=    Set Variable    /tmp/pkcs11test_content
    ${signature_file}=    Set Variable    /tmp/pkcs11test_signature

    ${cmd}=    Set Variable    dd if=/dev/random of=${content_file} count=1 bs=32
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    sudo=True    sudo_password=${PASSWORD}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0

    ${cmd}=    Set Variable    ${tool} --token-label mytoken --pin 0000 --id ${keyid} --label ${keylabel} --sign -m ${mechanism} --input-file ${content_file} --output-file ${signature_file}
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    sudo=True    sudo_password=${PASSWORD}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0

    ${cmd}=    Set Variable    ${tool} --token-label mytoken --pin 0000 --id ${keyid} --label ${keylabel} --verify -m ${mechanism} --signature-file ${signature_file} --input-file ${content_file}
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    sudo=True    sudo_password=${PASSWORD}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${stdout}    Signature is valid
    Should Not Contain    ${stdout}    Invalid signature
