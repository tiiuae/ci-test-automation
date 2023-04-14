import re

def get_systemctl_status(output):
    match = re.search(r'State: (\w+)', output)

    if match:
        return match.group(1)
    else:
        raise Exception("Couldn't parse systemctl status")

def get_ip_address(output):
    if_is_found = False
    match = None
    for line in output.split('\n'):
        if if_is_found:
            match = re.search(r'inet\s+(\d+\.\d+\.\d+\.\d+)', output)
            break
        elif 'enp' in line:
            if_is_found = True
    if match:
        return match.group(1)
    else:
        raise Exception("Couldn't parse ip address")
