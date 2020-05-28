###
# s3 multipart and glacier vault: quick notes #
###

###
# https://docs.aws.amazon.com/cli/latest/reference/s3/ #
# mb        Makes an S3 bucket.
# presign   Generate a pre-signed URL for an Amazon S3 object. This allows anyone who receives the pre-signed URL to retrieve the S3 object with an HTTP GET request.
# rb        Removes an empty S3 bucket. A bucket must be completely empty of objects and versioned objects before it can be deleted. However, the --force parameter can be used to delete the non-versioned objects in the bucket before the bucket is deleted.
# rm        Removes an S3 object.
# sync      Syncs directories and S3 prefixes. Recursively copies new and updated files from the source directory to the destination. Only creates folders in the destination if they contain one or more files.
# website   Set the website configuration for a bucket.

# https://docs.aws.amazon.com/cli/latest/reference/s3api/ #
# get-object    Retrieves objects from Amazon S3. To use GET, you must have READ access to the object. If you grant READ access to the anonymous user, you can return the object without using an authorization header.
# put-object    Adds an object to a bucket. You must have WRITE permissions on a bucket to add an object to it.
###

# list:
$ aws s3 ls --profile gisblog --region us-east-1
# list file(s):
$ aws s3 ls s3://bucket0test/ --profile gisblog --region us-east-1
# copy: --acl public-read-write for public r/w
$ aws s3 cp file.zip s3://bucket0test/ --profile gisblog --region us-east-1
# ..or..
$ aws s3 cp file.zip s3://bucket0test/file.zip --profile gisblog --region us-east-1
	Completed 1 part(s) with ... file(s) remaining
# validate:
$ aws s3 ls s3://bucket0test/ --profile gisblog --region us-east-1

# multipart upload with upload id to avoid timeout during large uploads because of session timeouts: The largest single file that can be uploaded into an Amazon S3 Bucket in a single PUT operation is 5 GB. If you want to upload large objects (> 5 GB), you will consider using multipart upload API, which allows to upload objects from 5 MB up to 5 TB. #
# eg. ready multifile: create 200 parts (100 MB * 99 + 80 MB).
$ for i in {1..200}; do dd if=multifile.zip of=multifile"$i".zip bs=1024k skip=$[i*100 - 100] count=100; done # if (input file), of (output file), bs (part bytes)
# eg. ready multifile: create 2 parts.
$ for i in {1..2}; do dd if=multifile.zip of=multifile"$i".zip bs=6000k skip=$[i*2 - 2] count=2; done # 20mb -> Your proposed upload is smaller than the minimum allowed object size. Each part must be at least 5 MB in size, except the last part
# create multipart for upload id:
$ aws s3api create-multipart-upload --bucket bucket0test --key multifile.zip --profile gisblog --region us-east-1
	{
		"AbortDate": "Sun, 09 Feb 2020 00:00:00 GMT", # when the initiated multipart upload becomes eligible for an abort operation, per the bucket's lifecycle policy (AbortIncompleteMultipartUpload: DaysAfterInitiation: 1)
		"AbortRuleId": "s3bucketrule",
		"ServerSideEncryption": "aws:kms", # server-side encryption algorithm used
		"SSEKMSKeyId": "arn:aws:kms:us-east-1:123:key/123-02cb-45aa-8df7-64cf5b2e849d", # id of the aws kms symmetric cmk
		"UploadId": "Im03bSp2bXMSWo59HMhy3MgKmf4DP0b2l0B6LL584HKAzfzLtBmAzazEuL90_8pg476t_aqzDIoDXqN9L4z9DxqRmryx6Yyxd3El_n0o8uZGIqUV9cMcZGeOT69K9V9oxh9sn_c9qs1pMmZRBO9Meg--",
		"Bucket": "bucket0test",
		"Key": "multifile.zip"
	}
# upload each part: part-number 1
$ aws s3api upload-part --bucket bucket0test --key multifile.zip --upload-id Im03bSp2bXMSWo59HMhy3MgKmf4DP0b2l0B6LL584HKAzfzLtBmAzazEuL90_8pg476t_aqzDIoDXqN9L4z9DxqRmryx6Yyxd3El_n0o8uZGIqUV9cMcZGeOT69K9V9oxh9sn_c9qs1pMmZRBO9Meg-- --part-number 1 --body multifile1.zip --profile gisblog --region us-east-1 # -> 6bd07375c98e26d7896f3baa74ef9b7a
	{
		"ETag": "\"...\""
	}
# upload each part: part-number 2
$ aws s3api upload-part --bucket bucket0test --key multifile.zip --upload-id Im03bSp2bXMSWo59HMhy3MgKmf4DP0b2l0B6LL584HKAzfzLtBmAzazEuL90_8pg476t_aqzDIoDXqN9L4z9DxqRmryx6Yyxd3El_n0o8uZGIqUV9cMcZGeOT69K9V9oxh9sn_c9qs1pMmZRBO9Meg-- --part-number 2 --body multifile2.zip --profile gisblog --region us-east-1 # -> dae3f9f2a7c467a130195dabcd281699
	{
		"ETag": "\"...\""
	}
# create multipartupload.json:
	{
		"Parts": [
			{
				"ETag": "ETagValue1",
				"PartNumber": 1
			},
			{
				"ETag": "ba28b88d9a062505b0d3d9054910809c",
				"PartNumber": 2
			}
		]
	}
# complete multipart:
$ aws s3api complete-multipart-upload --bucket bucket0test --key multifile.zip --upload-id Im03bSp2bXMSWo59HMhy3MgKmf4DP0b2l0B6LL584HKAzfzLtBmAzazEuL90_8pg476t_aqzDIoDXqN9L4z9DxqRmryx6Yyxd3El_n0o8uZGIqUV9cMcZGeOT69K9V9oxh9sn_c9qs1pMmZRBO9Meg-- --multipart-upload file:///mnt/c/glacier/multipartupload.json --profile gisblog --region us-east-1 # -> error if small file
# ..or..
$ aws s3api complete-multipart-upload --bucket bucket0test --key multifile.zip --upload-id cQZ1JUNj7_27un2SYdixTC_aGpQFo.CcqLRzya_HnzB9PkVCVYPSHNpixM1Gmkmx3hbxf2z9bbYU26NtPOIpit1SOIc.PtVKb1pHhn0JRH7ClH7JjTGmrbRxiUkr52alfwQu7BhnkWJy3OcpBBYxSQ-- --multipart-upload "Parts=[{ETag=b21cb031b13896f8d7d8231346cdd214,PartNumber=1},{ETag=4a83379302722cd52b0e03356af839fb,PartNumber=2}]" --profile gisblog --region us-east-1 # -> error if small file
	{
		"ETag": "\"77ccb3fc7949e3646c2bb14aeb8fc006-2\""
	}
# validate multipart:
$ aws s3 ls s3://bucket0test/ --profile gisblog --region us-east-1

# list the sizes of an s3 bucket and its contents:
$ aws s3api list-objects --bucket bucket0test --output json --query "[sum(Contents[].Size), length(Contents[])]" --profile gisblog --region us-east-1
# query: see s3 select part of an obj using sql (~ athena lite)
$ aws s3api list-objects --bucket bucket0test --query "Contents[?contains(Key, 'grc', )]" --profile gisblog --region us-east-1
# make bucket:
$ aws s3 mb s3://bucket0test --profile gisblog --region us-east-1
# delete an empty bucket:
$ aws s3api delete-bucket --bucket bucket0test --profile gisblog --region us-east-1
# delete all objects in the bucket including the bucket itself:
$ aws s3 rb s3://bucket0test --force --profile gisblog --region us-east-1
# delete an s3 object:
$ aws s3 rm s3://bucket0test/file.zip --profile gisblog --region us-east-1

# cloudformation: see service catalog s3 product - https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-lifecycleconfig-rule-transition.html #
    StorageClass: String # The storage class to which you want the object to transition. Allowed Values: DEEP_ARCHIVE | GLACIER | INTELLIGENT_TIERING | ONEZONE_IA | STANDARD_IA
    TransitionDate: Timestamp # Indicates when objects are transitioned to the specified storage class. The date value must be in ISO 8601 format. The time is always midnight UTC.
    TransitionInDays: Integer # Indicates the number of days after creation when objects are transitioned to the specified storage class. The value must be a positive integer.

###
# https://docs.aws.amazon.com/cli/latest/reference/glacier/
# create-vault This operation creates a new vault with the specified name. The name of the vault must be unique within a region for an AWS account. You can create up to 1,000 vaults per account. * Names can be between 1 and 255 characters long. * Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), and '.' (period).
# describe-vault This operation returns information about a vault, including the vault's Amazon Resource Name (ARN). The number of archives and their total size are as of the last inventory generation. This means that if you add or remove an archive from a vault, and then immediately use Describe Vault, the change in contents will not be immediately reflected. If you want to retrieve the latest inventory of the vault, use InitiateJob. Amazon S3 Glacier generates vault inventories approximately daily.
# initiate-job This operation initiates a job of the specified type, which can be a select, an archival retrieval, or a vault retrieval.
# initiate-multipart-upload This operation initiates a multipart upload. S3 Glacier creates a multipart upload resource and returns its ID in the response. The multipart upload ID is used in subsequent requests to upload parts of an archive.
# upload-archive This operation adds an archive to a vault. This is a synchronous operation, and for a successful upload, your data is durably persisted. Amazon S3 Glacier returns the archive ID in the x-amz-archive-id header of the response.
# complete-multipart-upload You call this operation to inform Amazon S3 Glacier (Glacier) that all the archive parts have been uploaded and that Glacier can now assemble the archive from the uploaded parts. After assembling and saving the archive to the vault, Glacier returns the URI path of the newly created archive resource. Using the URI path, you can then access the archive. After you upload an archive, you should save the archive ID returned to retrieve the archive at a later point. You can also get the vault inventory to obtain a list of archive IDs in a vault.
# upload-multipart-part    This operation uploads a part of an archive. You can upload archive parts in any order. You can also upload them in parallel. You can upload up to 10,000 parts for a multipart upload.
###

# upload archive #
# create vault: vault name must be unique within a region for an aws a/c. you can create up to 1,000 vaults per a/c.
$ aws glacier create-vault --vault-name vault0test --account-id - --profile gisblog --region us-east-1 # if a/c id = -, then glacier uses the a/c id associated with creds used to sign the request
	{
		"location": "/123/vaults/vault0test"
	}
# directly upload archive to vault: synchronous operation
$ aws glacier upload-archive --account-id - --vault-name vault0test --body /mnt/c/glacier/archive.zip --profile gisblog --region us-east-1 # n/file:
	{
		"location": "/123/vaults/vault0test/archives/uwOmv-jts-thMwQm9J03LHc8y10aNt-Coo9XkPAoYo3P9GEiuaeW5crGmL9MxPWqkz9A7CmUEfpZbGcUnCQtpqWWtyaa_Om0jWaqNf_jpQJ7IwbKr4AM0kAi6GGAjx7dCEvAjuLgww",
		"checksum": "b81ed17197ef15bf8d3ebabb24516e486c64e4902d5dd1384fe47895683ee582",
		"archiveId": "uwOmv-jts-thMwQm9J03LHc8y10aNt-Coo9XkPAoYo3P9GEiuaeW5crGmL9MxPWqkz9A7CmUEfpZbGcUnCQtpqWWtyaa_Om0jWaqNf_jpQJ7IwbKr4AM0kAi6GGAjx7dCEvAjuLgww"
	}
# describe vault: returns vault arn, vault creation date, # of archives, size of archives (updated daily - If you want to retrieve the latest inventory of the vault, use InitiateJob)
$ aws glacier describe-vault --account-id 123456789012 --vault-name vault0test --profile gisblog --region us-east-1
# ..or..
$ aws glacier describe-vault --account-id - --vault-name vault0test --profile gisblog --region us-east-1
	{
		"VaultARN": "arn:aws:glacier:us-east-1:123:vaults/vault0test",
		"VaultName": "vault0test",
		"CreationDate": "2020-02-07T18:50:00.055Z",
		"LastInventoryDate": "2020-02-08T03:21:57.018Z",
		"NumberOfArchives": 1,
		"SizeInBytes": 91919
	}

# download archive #
# initiate inventory retrieval: initiates job of the specified type (select, archival retrieval or inventory retrieval), and returns jobid
$ aws glacier initiate-job --account-id - --vault-name vault0test --job-parameters "{\"Type\": \"inventory-retrieval\"}" --profile gisblog --region us-east-1
	{
		"location": "/123/vaults/vault0test/jobs/IA7G2K6iSu-m4BrAxMnUFX1z2akIfo9RRwi6ou9okwI7iUK3Hv8K71SJ7MjlvmImo2BWNK693Rt7yvusD1mwULTm_9No",
		"jobId": "IA7G2K6iSu-m4BrAxMnUFX1z2akIfo9RRwi6ou9okwI7iUK3Hv8K71SJ7MjlvmImo2BWNK693Rt7yvusD1mwULTm_9No"
	}
# check job status: returns job status etc (use jobid from above)
$ aws glacier describe-job --account-id - --vault-name vault0test --job-id "IA7G2K6iSu-m4BrAxMnUFX1z2akIfo9RRwi6ou9okwI7iUK3Hv8K71SJ7MjlvmImo2BWNK693Rt7yvusD1mwULTm_9No" --profile gisblog --region us-east-1
	{
		"JobId": "IA7G2K6iSu-m4BrAxMnUFX1z2akIfo9RRwi6ou9okwI7iUK3Hv8K71SJ7MjlvmImo2BWNK693Rt7yvusD1mwULTm_9No",
		"Action": "InventoryRetrieval",
		"VaultARN": "arn:aws:glacier:us-east-1:123:vaults/vault0test",
		"CreationDate": "2020-02-14T17:00:30.286Z",
		"Completed": false,
		"StatusCode": "InProgress",
		"InventoryRetrievalParameters": {
			"Format": "JSON"
		}
	}
# when job is available for download, get inventory list: downloads job output (either archive content or vault inventory). saves vault inventory as json (inc list of archive ids in vault)
$ aws glacier get-job-output --account-id - --vault-name vault0test --job-id "IA7G2K6iSu-m4BrAxMnUFX1z2akIfo9RRwi6ou9okwI7iUK3Hv8K71SJ7MjlvmImo2BWNK693Rt7yvusD1mwULTm_9No" output-from-vault-inventory-job.json --profile gisblog --region us-east-1
	{
		"VaultARN": "arn:aws:glacier:us-east-1:0123456789012:vaults/my-vault",
		"InventoryDate": "2015-04-07T00:26:18Z",
		"ArchiveList": [
			{
				"ArchiveId": "kKB7ymWJVpPSwhGP6ycSOAekp9ZYe_--zM_mw6k76ZFGEIWQX-ybtRDvc2VkPSDtfKmQrj0IRQLSGsNuDp-AJVlu2ccmDSyDUmZwKbwbpAdGATGDiB3hHO0bjbGehXTcApVud_wyDw",
				"ArchiveDescription": "multipart upload test",
				"CreationDate": "2015-04-06T22:24:34Z",
				"Size": 3145728,
				"SHA256TreeHash": "9628195fcdbcbbe76cdde932d4646fa7de5f219fb39823836d81f0cc0e18aa67"
			}
		]
	}
# list job to see any previously completed jobs: in-progress and recently finished jobs
$ aws glacier list-jobs --account-id - --vault-name vault0test --profile gisblog --region us-east-1
# initiate inventory retrieval: (use ArchiveId from output-from-vault-inventory-job.json above)
$ aws glacier initiate-job --account-id - --vault-name vault-test --job-parameters /mnt/c/glacier/output-from-vault-inventory-job.json --profile gisblog --region us-east-1
# ..or..
$ aws glacier initiate-job --account-id - --vault-name vault0test --job-parameters "{\"Type\": \"inventory-retrieval\"}" --profile gisblog --region us-east-1
# when job is available for download (in 3-5 hours), retrieve archive:
$ aws glacier initiate-job --account-id - --vault-name vault-test --job-parameters '{"Type": "archive-retrieval", "ArchiveId": "..."}' --profile gisblog --region us-east-1
	{
		"location": "...",
		"jobId": "..."
	}
# when job is available for download, download archive: downloads job output (either archive content or vault inventory)
$ aws glacier get-job-output --account-id - --vault-name vault0test --job-id "..." FILE-NAME.FILE-EXTENSION --profile gisblog --region us-east-1
	{
		"status": 200,
		"acceptRanges": "bytes",
		"contentType": "application/json"
	}