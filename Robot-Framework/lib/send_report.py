# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import paramiko
import time
import sys

passwd = sys.argv[1]
results_path = sys.argv[2]

def main():
    start_time = time.time()
    print('Sending ci-test-automation report files to chrome-vm:/tmp to be read with chrome app.')
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy)
    client.connect("chrome-vm", port=22, username='ghaf', password=passwd)
    chan = client.invoke_shell()

    print("Remove already existing report files on chrome-vm.")
    send_and_receive(chan, 'sudo rm /tmp/*.html /tmp/output.xml\n', 5, 999, 'password')
    send_and_receive(chan, 'ghaf\n', 5, 999)

    print("Sending files.")
    scp = client.open_sftp()
    scp.put(results_path + '/report.html', '/tmp/report.html')
    scp.put(results_path + '/log.html', '/tmp/log.html')
    scp.put(results_path + '/output.xml', '/tmp/output.xml')
    time.sleep(5)
    scp.close()

    print("Editing ownership.")
    send_and_receive(chan, 'sudo chown appuser:users /tmp/*.html /tmp/output.xml\n', 5, 999, 'password')
    send_and_receive(chan, 'ghaf\n', 5, 999)

    client.close()
    end_time = time.time()
    execution_time = end_time - start_time
    print("Elapsed time: " + str(execution_time))

def send_and_receive(chan, cmd, wait_time, recv_buffer, expected=''):

    chan.send(cmd)

    clock = 0
    while True:

        data = chan.recv_ready()
        if data:
            clock = 0
            resp = chan.recv(recv_buffer)
            output = resp.decode('utf-8')
            print(output)
            if output.find(expected) != -1:
                time.sleep(0.5)
                return True
        else:
            time.sleep(1)
            # print(clock)
            clock += 1
        if clock > wait_time:
            return False


main()
