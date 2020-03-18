Bootstrap

```sh
# Use the ansible-galaxy command to initialize a new role called apache-simple.
$ ansible-galaxy init apache-simple

# install ansible tower: http://redhatgov.io/workshops/ansible_tower/
$ curl -O https://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-latest.tar.gz
$ tar xvfz ./ansible-tower-setup-latest.tar.gz
$ cd ./ansible-tower-setup-*/

# Please set rabbitmq_password in the inventory file before running setup" # "rabbitmq_password"
$ nano inventory

# Ubuntu 16.04 is not a supported OS for a Tower installation.  Supported OSes include Red Hat Enterprise Linux 7.4+ and CentOS 7.4+.
$ sudo ./setup.sh
```
