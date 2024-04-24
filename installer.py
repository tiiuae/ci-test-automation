from paramiko import Ed25519Key
import paramiko
import sys
import json
import os
import time

if len(sys.argv) < 3:
    print("Usage: python3 installer.py <device_name> <sudo_password>")
    sys.exit(1)

ssh_key_path = '~/.ssh/id_ed25519_autotests'
ssh_key_path = os.path.expanduser(ssh_key_path)
device_name = sys.argv[1]
password = sys.argv[2]


config_file_path = '../test_config.json'
try:
    with open(config_file_path, 'r') as file:
        data = json.load(file)
        ip_address = data["addresses"][device_name]['device_ip_address']
except FileNotFoundError:
    print(f"Error: The configuration file '{config_file_path}' was not found.")
    sys.exit(1)
except KeyError:
    print(f"Error: Device '{device_name}' not found in configuration file.")
    sys.exit(1)
except json.JSONDecodeError:
    print("Error: JSON file is malformed.")
    sys.exit(1)

# SSH Client setup
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
try:
    key = Ed25519Key.from_private_key_file(ssh_key_path)
    client.connect(hostname=ip_address, username='nixos', pkey=key)
    print(f"Successfully connected to {ip_address}")

    session = client.get_transport().open_session()
    session.get_pty()
    session.exec_command('sudo ghaf-installer.sh')

    stdin = session.makefile('wb', -1)
    stdout = session.makefile('rb', -1)
    stderr = session.makefile_stderr('rb', -1)

    # Send the sudo password
    stdin.write(password + '\n')
    stdin.flush()

    while True:
        if session.recv_ready():
            output = stdout.readline()  # Reading line by line
            if not output:
                break
            print(output.decode('utf-8'), end='')

        if session.recv_stderr_ready():
            error_output = stderr.readline()
            if not error_output:
                break
            print(error_output.decode('utf-8'), end='', file=sys.stderr)

        # Exit the loop if the command has completed
        if session.exit_status_ready():
            break

        time.sleep(0.1)  # Avoid tight loop

except Exception as e:
    print(f"An error occurred: {e}")
    session = None
finally:
    if session:
        session.close()
    client.close()
