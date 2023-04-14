import re

def get_systemctl_status(output):
    match = re.search(r'State: (\w+)', output)

    if match:
        return match.group(1)
    else:
        raise Exception("Couldn't parse systemctl status")

def get_ip_address(output):
    match = re.search(r'^enp.*\n\s+inet\s+(\d+\.\d+\.\d+\.\d+)', output)

    if match:
        return match.group(1)
    else:
        raise Exception("Couldn't parse ip address")
