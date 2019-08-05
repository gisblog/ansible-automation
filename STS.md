## STS - Standard Operating Procedure

The purpose of this document is to demonstrate the use of STS to request temp, limited-privilege creds for IAM/federated users for infrastructure provisioning.
Because IAM Roles ~ Best Practice.

The scope of this document is on temp creds using STS.
It assumes a basic understanding of AWS CLI, and access to a service broker like Cloudtamer.
A trust relationship between the account and the role-to-assume is a prereq.

#### STS (AWS Security Token Service)

<h3 id="procedure">Procedure</h3>

1. LOGIN TO THE SERVICE BROKER LIKE CLOUDTAMER

2. GENERATE TEMP ACCESS KEYS

Click on *Projects* to select your particular project, then click on *Account Access > Account Name > Select Cloud Access Role > Temporary Access Keys*.
From the keys page, follow one of the options below on your Windows laptop to access AWS resources using your temp keys:

*#1 Set AWS environment VARs to specify config and creds options*
<br />
This changes the value of the key used until the end of the current command prompt session, or until you reset VAR.
If you use SETX instead, it changes the value used in both the current command prompt session and all command prompt sessions that you create after running the command.
By current Cloudtamer default, the temp keys are valid for only 60 minutes.
``` shell
SET AWS_ACCESS_KEY_ID=...
SET AWS_SECRET_ACCESS_KEY=...
SET AWS_SESSION_TOKEN=...
```

*#2 Add a profile*
<br />
AWS CLI supports using multiple named profiles stored in the config and creds files.
So, in *%USERPROFILE%\.aws\credentials*, add -
``` shell
[PROFILE-NAME]
aws_access_key_id=...
aws_secret_access_key=...
aws_session_token=...
```

3. START USING STS

Now you are all set to use your temp creds, like so -
``` shell
# example:
$ aws ec2 describe-images --query "Images[?CreationDate >= '2019-06-14'][]" --profile PROFILE-NAME --region us-east-1
```

4. W/O SERVICE BROKER

In the event Cloudtamer or a similar $$$ervice broker is unavailable, you can use the command below to generate temp creds after you substitute ARN and SAML with your values.
This gives you the option to modify the duration during which the key is valid.
For example, below it is set for 1,800 seconds or 30 minutes (recommended).
``` shell
# User ---LOGIN---> App <---SAML REQUEST/ASSERTION---> IdP:
$ aws sts assume-role-with-saml --role-arn arn:aws:iam::###:role/name --principal-arn arn:aws:iam::###:saml-provider/NAME --duration-seconds=1800 --profile default --saml-assertion {base64 SAMLResponse}
	>
	{
		"Credentials": {
			"AccessKeyId": "...",
			"SecretAccessKey": "...",
			"SessionToken": "...",
			"Expiration": "2019-06-02T12:08:38Z"
		},
		"AssumedRoleUser": {
			"AssumedRoleId": "...",
			"Arn": "..."
		}
	}
# first, verify your assumed role:
$ aws sts get-caller-identity
# then, update env VARs using one of the options above, and you are all set...
```
Now you can run playbooks locally using the assumed role.
Happy provisioning!
