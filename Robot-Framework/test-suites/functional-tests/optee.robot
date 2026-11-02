# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Test OP-TEE PKCS#11 through pkcs11-tool wrappers

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Switch to vm   ${HOST}

Test Tags           optee  bat  orin-agx  orin-agx-64  orin-nx


*** Test Cases ***
OP-TEE xtest
    [Documentation]   Runs OP-TEE's xtest
    [Tags]            SP-T122  optee-xtest

    Run Command       xtest   sudo=True   timeout=400

Basic pkcs11-tool-optee test
    [Documentation]   Test OP-TEE PKCS#11 through pkcs11-tool-optee wrapper.
    ...               Basic test which initalizes key slots, by directly
    ...               calling OP-TEE. Then it generates RSA 2048-bit and ECDSA
    ...               secp256r1 keys, for which signing and signature
    ...               verification operations are tested.
    [Tags]            SP-T106

    ${tool}    Set Variable    "pkcs11-tool-optee"
    List key slots     ${tool}
    Initialize slot    ${tool}
    Test Public Key usage    ${tool}    keyid=1    keylabel=rsakey0    mechanism=SHA256-RSA-PKCS-PSS
    Test Public Key usage    ${tool}    keyid=2    keylabel=eckey0    mechanism=ECDSA-SHA256
    List key slots    ${tool}
    List objects      ${tool}


*** Keywords ***
List key slots
    [Documentation]    List all key slots
    [Arguments]        ${tool}
    Run Command        ${tool} -L    sudo=True

List objects
    [Documentation]    List all key slots
    [Arguments]        ${tool}
    Run Command        ${tool} --list-objects    sudo=True

Initialize slot
    [Documentation]    Initialize Key Slot
    [Arguments]        ${tool}
    Run Command   ${tool} --init-token --label mytoken --so-pin 1234                     sudo=True
    Run Command   ${tool} --label mytoken --login --so-pin 1234 --init-pin --pin 0000    sudo=True
    Run Command   ${tool} --token-label mytoken --pin 0000 --keypairgen --key-type RSA:2048 --id 1 --label rsakey0       sudo=True
    Run Command   ${tool} --token-label mytoken --pin 0000 --keypairgen --key-type EC:secp256r1 --id 2 --label eckey0    sudo=True

Test Public Key usage
    [Documentation]    Test Public Key usage
    [Arguments]        ${tool}    ${keyid}    ${keylabel}    ${mechanism}

    ${content_file}     Set Variable    /tmp/pkcs11test_content
    ${signature_file}   Set Variable    /tmp/pkcs11test_signature

    Run Command    dd if=/dev/random of=${content_file} count=1 bs=32    sudo=True
    Run Command    ${tool} --token-label mytoken --pin 0000 --id ${keyid} --label ${keylabel} --sign -m ${mechanism} --input-file ${content_file} --output-file ${signature_file}    sudo=True

    ${output}    Run Command    ${tool} --token-label mytoken --pin 0000 --id ${keyid} --label ${keylabel} --verify -m ${mechanism} --signature-file ${signature_file} --input-file ${content_file}    sudo=True
    Should Contain        ${output}    Signature is valid
    Should Not Contain    ${output}    Invalid signature
