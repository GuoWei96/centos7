import paramiko
import time
import os
hosts: list = [
    {"hostname": "192.168.31.201", "port": 22, "username": "root", "password": "root"},
    {"hostname": "192.168.31.69", "port": 22, "username": "root", "password": "root"},
    {"hostname": "192.168.31.77", "port": 22, "username": "root", "password": "root"},
    {"hostname": "192.168.31.147", "port": 22, "username": "root", "password": "root"}
]

class GetKey():
    def __init__(self, **kwargs):
        self.hostname = kwargs["hostname"]
        self.port = kwargs["port"]
        self.username = kwargs["username"]
        self.password = kwargs["password"]
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.ssh.connect(hostname=self.hostname, port=self.port, username=self.username, password=self.password)
    def check_key_add_keys(self):
        stdin, stdout, stderr = self.ssh.exec_command("ls ~/.ssh/")
        if "id_rsa.pub" in stdout.read().decode("utf-8"):
            stdin, stdout, stderr = self.ssh.exec_command("cat ~/.ssh/id_rsa.pub")
            print(f"{self.hostname} 密钥存在")
            key = stdout.read().decode("utf-8")
        else:
            self.ssh.exec_command("ssh-keygen -f ~/.ssh/id_rsa -P '' -q")
            time.sleep(0.5)
            stdin, stdout, stderr = self.ssh.exec_command("cat ~/.ssh/id_rsa.pub")
            print(f"{self.hostname} 密钥不存在,已经创建")
            key = stdout.read().decode("utf-8")
        return key
    def save_key_to_txt(self):
        with open(".hosts_key.txt", "a", encoding="utf-8") as f:
            f.write(self.check_key_add_keys())
        self.ssh.close()
    def ssh_copy_id(self):
        """
        所有主机之间都可以免密登录
        :return: 
        """
        with open(".hosts_key.txt", "r", encoding="utf-8") as f:
            all_ssh_id = f.read()
        self.ssh.exec_command(f"echo '{all_ssh_id}' >> ~/.ssh/authorized_keys")
        self.ssh.close()

for host in hosts:
    host1 = GetKey(**host)
    host1.save_key_to_txt()
    
# 所有主机之间免密登录
for host in hosts:
    host1 = GetKey(**host)
    host1.ssh_copy_id()
    
# server端可以免密登录agent端


