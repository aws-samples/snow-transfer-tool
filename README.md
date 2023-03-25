# Snow Transfer Tool
## Introduction
Migrating large amounts of small files to the cloud is challenging because of the increased transfer time and cost implications. [AWS Snowball] (https://aws.amazon.com/snowball/) is commonly used by customers for bulk data migration to the cloud when facing connectivity limitations, bandwidth constraints, and high network costs. The transfer of large amounts of small files to any system can result in performance issues, to which one solution  is to batch them. To enhance copy performance to Snowball devices, this tool is created using Yongki Kim's [s3booster] (https://github.com/aws-samples/s3booster-snowball) script and automates the batching of small files.

## Install

### Prerequisites 

Python 3.

### On Mac/Linux

Run `install.sh`:

```
./install.sh
```

### On Windows

Double click or execute `install.bat` in cmd/powershell:

```
install.bat
```

For Windows installation, the command is not added to your PATH environment variable by default. To use the command globally, please manually add it to PATH.

## Using snowTransfer

snowTransfer tool offers two command: *gen_list* and *upload*.

### gen_list

This command groups large datasets of small files by a preconfigured size. It traverses the source directory recursively and produces multiple file partition lists. Each line of a partition file is the absolute path of a file that is stored inside your src directory. The size of a single partition file will not exceed the configured maximum size limit.

For example, say the directory  `/data` has 10 files: 1.txt, 2.txt, ..., 10.txt. Each .txt file is of 10 MB size. If we set the max size to 30 MB, the output will be 4 partition files as follows:

File partition 1:

```
/data/1.txt
/data/2.txt
/data/3.txt
```

File partition 2:

```
/data/4.txt
/data/5.txt
/data/6.txt
```

File partition 3:

```
/data/7.txt
/data/8.txt
/data/9.txt
```

File partition 4:

```
/data/10.txt
```

During directory traversal, all the symlinks and empty folders will be ignored. Only the paths of actual files will be appended to the partition list. If a file size is larger than the partition_size, there will also be a file partition list generated. This partition file will contain only one line (the path of that file).

This command also provides a way to help divide large datasets by device size, which makes it possible to transfer files into multiple snowballs in parallel without worrying about exceeding device capacity. For example, if there is 240TB of data to be uploaded to Snowball Edge Storage Optimized devices (80TB capacity), you can set the device_capacity to 80TB. After running the gen_list command, there will be 3 or 4 sub folders under the filelist_dir. The total size of all partitions inside one sub folder will be less or equal to 80TB.

#### Configuration

##### Arguments

* **--filelist_dir: str**

  The destination of generated file partition lists, e.g. /tmp/file_list/

* **--partition_size: int, str** (default '10GB')

  Size limit for each partition, e.g. 1GB or 1073741824 Bytes. You can set this to a number representing total bytes or a human-readable value like '1Gib'. Strings like 1gb, 1Gib, 2MB and 0.5 gib are all supported. Please note that we consider 'b' the same as 'ib', which is defined as base 1024. If a file size is larger than the partition_size, there will also be a partition file generated. This partition file will contain only one line (the path of that file).

* **--device_capacity: int, str** (default '80TB')

  Size limit for a snowball device. You can set this to a number representing total byte or a human-readable value like '80TB'. Strings like 10tb, 10Tib, 20TB and 0.5 tib are all supported. Please note that we consider 'b' the same as 'ib', which is defined as base 1024. Set this option correctly if you have a dataset with size larger than the capacity of a single snowball.

* **--src: str**

  Source directory, e.g. /data. The directory for gen_list to traverse. 

* **--log_dir: str**

  Directory that stores log files, e.g. /tmp/log

* **--config_file: str**

  Path to the config file, e.g. ./config. There are two ways to configure the command: using command line argument or a config file. If a config file is not specified via this argument in command line, all the following arguments are required: --src, --filelist_dir, --partition_size, and --log_dir. 

  

##### Configure using command line

Example:

```
snowTransfer gen_list --filelist_dir = /tmp/output --partition_size = 30Mb src = /data --log_dir = /tmp/log/ --device_capacity = 10TB
```

##### Configure using configuration file

To make configuration simple and easily reusable, we could also use a configuration file.

Example:

```
snowTransfer gen_list --config_file config_file
```

See below for a config file template. Please modify the arguments under `[GENLIST]` if you choose to use a configuration file. Do not modify anything before `=`. The program will not be able to identify them if the argument names are different.

Configuration file template:

```
[UPLOAD]
bucket_name = snowball_bucket_name
src = /share1
endpoint = http://snowball_ip:8080
profile_name = snowball1
aws_access_key_id = 
aws_secret_access_key = 
prefix_root = share1/
max_process = 5
partition_size = 1Gb
max_files = 100000
extract_flag = True
target_file_prefix =
log_dir = /home/logs/snowball1
compression = False
upload_logs = True
ignored_path_prefix =
[GENLIST]
filelist_dir = /home/listfiles/snowball1
partition_size = 30Mb
device_capacity = 80TB
src = /share1
log_dir = /home/logs/snowball1
```

Please note that if an argument is set both through command line and in a configuration file, the configuration file value takes precedence. 

#### Example Output

```bash
➜ snowTransfer gen_list --config_file config_file
2022-09-14 10:54:30,275 : print_setting : [INFO] : 
Command: gen_list
src: /share1
filelist_dir: /home/listfiles/snowball1
partition_size: 30.00 MiB
device_capacity: 80TB
log_dir: /home/logs/snowball1
2022-09-14 10:54:30,276 : gen_filelist : [INFO] : generating file list by size 31457280 bytes
2022-09-14 10:54:30,278 : gen_filelist : [INFO] : Part #1: size = 5652478
2022-09-14 10:54:30,278 : gen_filelist : [INFO] : Number of scanned file: 10, symlink and empty folders were ignored
2022-09-14 10:54:30,278 : gen_filelist : [INFO] : File lists are generated!!
2022-09-14 10:54:30,278 : gen_filelist : [INFO] : Check /home/listfiles/snowball1
2022-09-14 10:54:30,278 : <module> : [INFO] : Program finished!
```

### upload 

This command helps batch and upload files to snowball automatically. The batching and uploading happen in the host memory so no extra disk space is needed. However, the number of processes times the partition_size must be less than the provisioned memory size: `number of processes provisioned ✕ partition_size < provisioned memory size`.

During file traversal, all symlinks and empty folders are ignored.

#### Configuration

##### Arguments

* **bucket_name: str**

  Bucket name, e.g. sbe-bucket-a. (Please do not add the 's3://' prefix.)

* **src: str**

  This can be a source directory, e.g. /data, or a partition file, e.g. /manifest_file. Files inside the src directory or partition file will be batched to a larger tar and uploaded. 

* **endpoint: str**

  Snowball http endpoint, e.g. http://10.10.10.10:8080.

* **log_dir: str** 

  Directory that stores log files, e.g. /tmp/log.

* **profile_name: str** (default 'default')

  AWS profile name, e.g. sbe1. The script will use **aws_access_key_id** and **aws_secret_access_key** to create S3 client if they are not empty.

* **aws_access_key_id: str** (default '')

  aws_access_key_id.

* **aws_secret_access_key: str** (default '')

  aws_secret_access_key. 

* **prefix_root: str** (default "")

  Prefix root, e.g. dir1/. The root to add before all files when uploaded to snowball. For example, if src is set to '/data' and prefix_root to 'dir1/', the file path for file '/data/file1' will be '/dir1/data/file1' in snowball and similarly in the destination s3 bucket.

* **max_process, int** (default 5)

  Max number of processes for batching and uploading.

* **max_tarfile_size: str, int** (default 1gb)

  Size limit of a single batched file, e.g. 1Gb. or 1073741824. You can set this to a number representing total byte or a human-readable value like '1Gib'.Strings like 1gb, 1Gib, 2MB and 0.5 gib are all supported. Please note that we consider 'b' the same as 'ib', which is defined as base 1024. If a file size is larger than the max_tarfile_size, the file will not be batched and will be directly uploaded to snowball. Configure **max_tarfile_size** and the **max_files** options together to control how files are batched.

* **max_files, int** (default 100000)

  Max number of files that each tar file will contain. Configure **max_tarfile_size** and the **max_files** options together to control how files are batched.

* **extract_flag: bool** (default True)

  True|False; All files **batched by this tool** will be extracted if this is set to True. All files that are originally in tar format will be uploaded as tar files.

* **target_file_prefix: str** (default "")

  The prefix of the tar files created by the tool. For example, if it is set to "snowJobTest", the tar file generated will be something like the following: snowJobTestsnowball-20220713_222749-HBSZ5D.tar.

* **compression: bool** (default False)

  True|False. Setting this to True will compress the batched files to `gz` format.

* **upload_logs: bool** (default False)

  True|False. Setting this to True will upload all the logs generated by this tool to Snowball and your S3 bucket.

* **ignored_path_prefix: str** (default "")

  This option is only useful when you choose to use a partition file as the source. This option can be used in combination with the **prefix_root** option to set the directory for the object to be uploaded to Snowball. For example, suppose inside a partition file, an absolute path is this: "/Users/user/Documents/testfile.txt"; if the **prefix_root** is set to "/dir" and the **ignored_path_prefix** is set to "/Users/user/", the file path will be "/dir/Documents/testfile.txt" in a Snowball device. 

* **config_file: str**

  Path to the config file, e.g. ./config. There are two ways to configure the command: using command line argument or a config file. If a config file is not specified via this argument in command line, all the following  arguments are required: --src, --bucket_name, --endpoint, and --log_dir.

##### Configure using command line

Example:

```
snowTransfer upload src = /data --bucket_name = mybucketname --endpoint = http://10:10:10:10:8080 --log_dir = /tmp/log/ 
```

##### Configure using configuration file

To make configuration simple and easy reusable, we could also provide a configuration file to configure program.

Example:

```
snowTransfer upload --config_file config_file
```

See below for a config file template. Please modify the arguments under `[UPLOAD]` if you choose to use a configuration file. Do not modify anything  before `=`. The program will not be able to identify them if the argument names are different.

Configuration file template:

```
[UPLOAD]
bucket_name = snowball_bucket_name
src = /share1
endpoint = http://snowball_ip:8080
profile_name = snowball1
aws_access_key_id = 
aws_secret_access_key = 
prefix_root = share1/
max_process = 5
max_tarfile_size = 1Gb
max_files = 100000
extract_flag = True
target_file_prefix =
log_dir = /home/logs/snowball1
compression = False
upload_logs = True
ignored_path_prefix =
[GENLIST]
filelist_dir = /home/listfiles/snowball1
partition_size = 30Mb
device_capacity = 80TB
src = /share1
log_dir = /home/logs/snowball1
```

Please note that if an argument is set both through command line and in a configuration file, the configuration file value takes precedence.

#### Example Output

**Uploading from src directory:**

```
➜ snowTransfer upload --config_file config_file  
2022-09-14 11:22:34,682 : print_setting : [INFO] : 
command: upload
src: /share1
endpoint: http://snowball_ip:8080
bucket_name: snowball_bucket_name
log_dir: /home/logs/snowball1
profile_name: default
prefix_root: share1/
max_process: 5
max_tarfile_size: 5.00 MiB
max_files: 100000
compression: False
target_file_prefix: 
extract_flag: True
upload_log: False
ignored_path_prefix: 
2022-09-14 11:22:34,682 : <module> : [INFO] : Batching and uploading files...
zictestsnowball-20220914_112234-SPBJVR.tar: 100%|██████████████████████████████████████████████████| 3/3
zictestsnowball-20220914_112234-I9079T.tar: 100%|██████████████████████████████████████████████████| 6/6
2022-09-14 11:22:36,289 : copy_to_snowball : [INFO] : zictestsnowball-20220914_112234-SPBJVR.tar was uploaded
2022-09-14 11:22:36,382 : copy_to_snowball : [INFO] : zictestsnowball-20220914_112234-I9079T.tar was uploaded
2022-09-14 11:22:45,335 : copy_to_snowball : [INFO] : /share1/Netty was uploaded
2022-09-14 11:22:45,342 : batch_and_upload : [INFO] : 9 out of 10 files were batched into 2 tar files
2022-09-14 11:22:45,343 : batch_and_upload : [INFO] : Total size: 5.39 MiB
2022-09-14 11:22:45,343 : batch_and_upload : [INFO] : Total size after batching: 50.00 KiB
2022-09-14 11:22:45,343 : batch_and_upload : [INFO] : Avg file size before: 552.00 KiB
2022-09-14 11:22:45,344 : batch_and_upload : [INFO] : Avg file size after: 1.80 MiB
2022-09-14 11:22:45,344 : batch_and_upload : [INFO] : 3 files were uploaded
2022-09-14 11:22:45,354 : <module> : [INFO] : Program finished!
```

**Uploading from partition file**

The content of an example partition file: 

```bash
/Users/Documents/test/testf1 4811
/Users/Documents/test/testf2 39
/Users/Documents/test/testf3 53
/Users/Documents/test/testf4 6148
/Users/Documents/test/testf5 75
/Users/Documents/test/testf6 8
/Users/Documents/test/testf7 5635188
/Users/Documents/test/testf8 0
/Users/Documents/test/testf9 8
/Users/Documents/test/testf10 6148
```

The program will only consider the first string split by space as the file path, so the file_size here is not pertinent to the transfer operation, which means you can use other tool e.g. fpart, to split data and then upload.

```
➜ snowTransfer upload --config_file config_file
2022-09-14 11:24:35,786 : print_setting : [INFO] : 
command: upload
src: /home/listfiles/snowball1/fl_1.txt
endpoint: http://snowball_ip:8080
bucket_name: snowball_bucket_name
log_dir: /home/logs/snowball1
profile_name: default
prefix_root: dir1/
max_process: 5
max_tarfile_size: 5.00 MiB
max_files: 100000
compression: False
target_file_prefix:
extract_flag: True
upload_log: False
ignored_path_prefix: 
2022-09-14 11:24:35,786 : <module> : [INFO] : Batching and uploading files...
2022-09-14 11:24:35,812 : upload_get_files : [INFO] : Uploading from partition file, please make sure the partition file contains your files' absolute path
zictestsnowball-20220914_112435-00F8U0.tar: 100%|██████████████████████████████████████████████████| 3/3
zictestsnowball-20220914_112435-OVN157.tar: 100%|██████████████████████████████████████████████████| 6/6
2022-09-14 11:24:37,231 : copy_to_snowball : [INFO] : zictestsnowball-20220914_112435-00F8U0.tar was uploaded
2022-09-14 11:24:37,537 : copy_to_snowball : [INFO] : zictestsnowball-20220914_112435-OVN157.tar was uploaded
2022-09-14 11:24:45,726 : copy_to_snowball : [INFO] : /Users/Documents/test/testf7 was uploaded
2022-09-14 11:24:45,732 : batch_and_upload : [INFO] : 9 out of 10 files were batched into 2 tar files
2022-09-14 11:24:45,733 : batch_and_upload : [INFO] : Total size: 5.39 MiB
2022-09-14 11:24:45,733 : batch_and_upload : [INFO] : Total size after batching: 50.00 KiB
2022-09-14 11:24:45,733 : batch_and_upload : [INFO] : Avg file size before: 552.00 KiB
2022-09-14 11:24:45,734 : batch_and_upload : [INFO] : Avg file size after: 1.80 MiB
2022-09-14 11:24:45,734 : batch_and_upload : [INFO] : 3 files were uploaded
2022-09-14 11:24:45,744 : <module> : [INFO] : Program finished!
```

## Performance Comparison

We compared the performance between using snowTransferTool and `aws s3 cp`. Note that performance may vary with different configurations. Here, we used an EC2 (c4.8xlarge) as the transfer engine to move data from an EBS (gp2) to a Snowball Edge device.

Dataset:

* No. of files: 10,000,000
* Total Capacity: 1 TB
* Avg File Size: 100 KB

|                                              | EBS -> Snowball Time |
|----------------------------------------------|----------------------|
| Using snowTransferTool (max_tar_size == 1GB) | 45 min (~370 MB/s)   |
| Uploading individually (1 process)           | 1786 min (~10 MB/s)  |


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.

