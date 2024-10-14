import paramiko
import socket
from concurrent.futures import ThreadPoolExecutor
import time
import subprocess
import os

# Function to fetch running EC2 instance IPs using AWS CLI
def fetch_ec2_ips():
    command = [
        'aws', 'ec2', 'describe-instances',
        '--filters', 'Name=instance-state-name,Values=running',
        '--query', 'Reservations[*].Instances[*].{PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}',
        '--output', 'text'
    ]
    
    # Run the AWS CLI command and capture the output
    result = subprocess.run(command, stdout=subprocess.PIPE, text=True)
    return result.stdout.strip()

# Function to write IPs to a text file
def write_ips_to_file(ips):
    with open('ec2_ips.txt', 'w') as file:
        file.write(ips)

# Function to check SSH connection to each IP
def check_ssh_connection(hostname, port=22, timeout=5):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # Automatically adds the host key
    try:
        ssh.connect(hostname, port=port, username=None, password=None, timeout=timeout)
        print(f"{hostname}: Username and password prompt received.")
    except paramiko.ssh_exception.NoValidConnectionsError:
        print(f"{hostname}: Connection timed out.")
    except paramiko.ssh_exception.AuthenticationException:
        print(f"{hostname}: Username and password prompt received.")
    except paramiko.ssh_exception.SSHException as e:
        print(f"{hostname}: SSH error occurred: {e}")
    except socket.timeout:
        print(f"{hostname}: Connection timed out.")
    except Exception as e:
        print(f"{hostname}: Error occurred: {e}")
    finally:
        ssh.close()

# Function to process IPs in parallel
def process_ips_in_parallel():
    with open('ec2_ips.txt', 'r') as file:
        ips = file.readlines()

    ips = [ip.strip() for ip in ips if ip.strip()]  # Clean up IPs

    # Create a ThreadPoolExecutor to run 10 parallel connections
    with ThreadPoolExecutor(max_workers=10) as executor:
        for ip in ips:
            executor.submit(check_ssh_connection, ip)

def main():
    # Fetch EC2 IPs and write them to a file
    ec2_ips = fetch_ec2_ips()
    if not ec2_ips:
        print("No running instances found.")
        return

    print("Writing IPs to file...")
    write_ips_to_file(ec2_ips)
    print("IPs written to ec2_ips.txt")

    # Process SSH connections in parallel
    print("Starting SSH checks in parallel...")
    process_ips_in_parallel()

if __name__ == "__main__":
    main()
