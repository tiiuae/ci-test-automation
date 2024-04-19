import paramiko
import sys
import json
import os

if len(sys.argv) < 3:
    print("Usage: python script.py <device_name> <sudo_password>")
    sys.exit(1)

ssh_key_path = '~/.ssh/id_ed25519_autotests'
ssh_key_path = os.path.expanduser(ssh_key_path)
device_name = sys.argv[1]
password = sys.argv[2]


config_file_path = '../Testing/test_config.json'
try:
    with open(config_file_path, 'r') as file:
        data = json.load(file)
        ip_address = data[device_name]['device_ip_address']
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
    client.connect(hostname=ip_address, username='username', pkey=paramiko.RSAKey.from_private_key_file(ssh_key_path))
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

    # Handle outputs and inputs directly in the main block
    while True:
        output = stdout.readline().decode('utf-8')
        if output:
            print(output, end="")
            if "Device name [e.g. /dev/nvme0n1]: " in output:
                stdin.write('/dev/nvme0n1' + '\n')
                stdin.flush()
            elif "WARNING: Next command will destroy all previous data from your device, press Enter to proceed." in output:
                stdin.write('\n')
                stdin.flush()
            elif "Installation done. Please remove the installation media and reboot" in output:
                print("Installation completed successfully.")
                break

        stderr_output = stderr.readline().decode('utf-8')
        if stderr_output:
            print(stderr_output, end="")

finally:
    # Ensure the session and client are closed properly
    if session:
        session.close()
    client.close()
