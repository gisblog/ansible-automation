Because you should -

1. CREATE FILE
Save your credentials in a YML file as "key: value" pairs.
You can organize your credentials in multiple files as the projects expand.
As a best practice, save this file under vars/, say ansible.com:/home/ansible/playbooks/vars,
and prefix its name with "vault_".

2. ENCRYPT FILE
Run the following command to encrypt your YML file -
$ ansible-vault encrypt vault_file.yml
New Vault password:
Confirm New Vault password:

3. REFERENCE FILE AND CREDENTIALS
In your ansible script, reference your vault_ file, like so -
	vars_files:
	   - vars/vault_file.yml
Reference the key whose value you want, like so -
	msg: "{{ key }}"

4. RUN FILE
Execute your playbook and enter your vault password when prompted.
$ ansible-playbook /home/ansible/playbooks/ansible-vault-script.yml --vault-id @prompt

5. OPTIONALLY
* You may save your vault password only in a secure location as clear text.
In that case, simply point to it at run time, like so -
$ ansible-playbook /home/ansible/playbooks/ansible-vault-script.yml --vault-id vault.yml
* You can also include the encrypted vault_ file inline in your script, like so (just make sure you reassign it to another var before applying filters) -
	vars:
		vault_keynames: !vault |
		  $ANSIBLE_VAULT;1.1;AES256
		  13306263353861616230363439623463623864366632343763613839396136373164363961336532
