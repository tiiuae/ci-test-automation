# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       BAT tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Suite Setup         Initialize Variables, Connect And Start Logging
Suite Teardown      End Logging And Close Connections


*** Keywords ***

End Logging And Close Connections
    IF  ${CONNECTION}
        Connect
        Log journctl
    END
    Close All Connections
