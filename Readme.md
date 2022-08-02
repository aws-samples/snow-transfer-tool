# SnowTransfer Manual

## Install SnowTransferTool

### Prerequisites 

Please make sure Python is installed.

### Mac & Linux

Open terminal and execute:

```
./install.sh
```

### Windows

Double click or open cmd or powershell to execute:

```
install.bat
```

For windows installation we will not add the command to your PATH environment variable. To be able to use it globally please manually add it to PATH.

## Using snowTransfer

snowTransfer tool provides two command: *gen_list* and *upload_sbe*


### gen_list

This command helps you separate large data set by total size. It traverses your src directory recursively and produces multiple manifest files. Each line of a manifest file is the absolute path of a file that stores inside your src directory. The sum of file size of one manifest file will not be larger that the max-size you configured. 

For example, consider directory  `/data` contains 10 file 1.txt, 2.txt, ..., 10.txt. Each .txt file has the file size of 10 mb. If we set the max-size to 30mb. The output will be 4 manifest file that have following contents:

Manifest1:

```
/data/1.txt
/data/2.txt
/data/3.txt
```

Manifest2:

```
/data/4.txt
/data/5.txt
/data/6.txt
```

Manifest3:

```
/data/7.txt
/data/8.txt
/data/9.txt
```

Manifest4:

```
/data/10.txt
```

During directory traversal, all the symlink and empty folders will be ignored. Only paths of file will be appended to the manifest files. If a file size is even larger than the the partition_size, there will also be a manifest file generated. This manifest file will contain only one line (the path of that file).

#### Configuration

##### Arguments

* **--filelist_dir: str**

  The destination of generated manifest files, e.g. /tmp/file_list/

* **--partition_size: int, str**

  Size limit for each partition, e.g. 1Gb or 1073741824. You can set this to a number representing total byte or a human readable value like '1Gib'. Strings like 1gb, 1Gib, 2MB and 0.5 gib are all supported. Please note the we consider 'b' the same as 'ib', which is defined as base 1024. If a file size is even larger than the the partition_size, there will also be a manifest file generated. This manifest file will contain only one line (the path of that file).

* **--src: str**

  Source directory, e.g. /data. The directoy for gen_list to traverse. 

* **--log_dir: str**

  Directory that stores log files, e.g. /tmp/log

* **--config_file: str**

  Path of the config file, e.g. ./config. If this argument is not present in command line, --src, --filelist_dir, --partition_size, and --log_dir are required

We provide two ways to configure the file: by using command line and by using config file.

##### Configure using command line

Example:

```
snowTransfer gen_list --filelist_dir = /tmp/output partition_size = 30Mb src = /data log_dir = /tmp/log/
```

##### Configure using configuration file

To make configuration simple and easy reusable, we could also provide a configuration file to configure program.

Example:

```
snowTransfer gen_list --config_file config
```

A template of config file is also provided. Please modify the arguments under '[GENLIST]' if you choose to use configuration file. Also please do not modify the any contents before "=". The program will not be able to identify them if the argument names are different.

Configuration file template:

```
[UPLOAD_SBE]
bucket_name = s3boostertest
src = /tmp/s3booster/fl_1.txt
endpoint = https://s3.us-east-2.amazonaws.com
profile_name = default
prefix_root = dir1/
max_process = 5
max_tarfile_size = 1Gb
extract_flag = True
target_file_prefix = zictest
log_dir = /tmp/log/s3booster/JID0001
compression = False
[GENLIST]
filelist_dir = /tmp/s3booster
partition_size = 30Mb
src = /Users/zic/Documents/zicTest
log_dir = /tmp/log/s3booster/JID0001
```

Please note that if a arguments was set in both command line and configuration file, the configuration file has predominance. 

#### Example Output

```bash
➜  AWSIE_SnowTransferTool git:(mainline) ✗ snowTransfer gen_list --config_file config_file
2022-07-13 21:57:35,961 : print_setting : [INFO] : 
Command: gen_list
src: /Users/zic/Documents/zicTest
filelist_dir: /tmp/s3booster
partition_size: 30.00 MiB
log_dir: /tmp/log/s3booster/JID0002
This operation will clean all the contents in: /tmp/s3booster. Continue? Y/N
y
2022-07-13 21:57:38,051 : gen_filelist : [INFO] : generating file list by size 31457280 bytes
2022-07-13 21:57:38,053 : gen_filelist : [INFO] : Part #1: size = 5652478
2022-07-13 21:57:38,053 : gen_filelist : [INFO] : Number of scanned file: 10, symlink and empty folders were ignored
2022-07-13 21:57:38,053 : gen_filelist : [INFO] : File lists are generated!!
2022-07-13 21:57:38,053 : gen_filelist : [INFO] : Check /tmp/s3booster
2022-07-13 21:57:38,053 : <module> : [INFO] : Program finished!
```

### upload_sbe 

This command helps you batch and upload your files to snowball automatically. The batching and uploading are happened in your hosts' memory so there is no extra disk space needed. 

During the file traversal, all the symlinks and empty folders will be ignored.

#### Configuration

##### Arguments

* **bucket_name: str**

  Your bucket name, e.g. sbe-bucket-a. (Please do not add the 's3://' prefix)

* **src: str**

  This can be a source directory, e.g. /data, or a manifest file, e.g. /manifest_file. Files inside the src directory and manifest file will be batched to a larger tar and be uploaded. 

* **endpoint: str**

  Snowball http endpoint, e.g.  http://10.10.10.10:8080

* **log_dir: str** 

  Directory that stores log files, e.g. /tmp/log

* **profile_name: str** (default 'default')

  AWS profile name, e.g. sbe1

* **prefix_root: str** (default "")

  Prefix root, e.g. dir1/. The root you want to add before all files when uploading to snowball. For example, if you set src to '/data' and prefix_root to 'dir1/', the file path for file '/data/file1' will be '/dir1/data/file1' in snowball and eventually in you s3 bucket.

* **max_process, int** (default 5)

  Max number of process for batching and uploading.

* **max_tarfile_size: str, int ** (default 1gb)

  Size limit of a single batched file, e.g. 1Gb. or 1073741824. You can set this to a number representing total byte or a human readable value like '1Gib'.Strings like 1gb, 1Gib, 2MB and 0.5 gib are all supported. Please note the we consider 'b' the same as 'ib', which is defined as base 1024. If a file size is even larger than the the max_tarfile_size, the file will not be batched and will be directly uploaded to snowball.

* **extract_flag: bool** (default True)

  True|False; We will help you extract all the files **batched by this tool** if you set this to True. All files that originally in the format of tar will be untouched.

* **target_file_prefix: str** (default "")

  The prefix of the tar file this tool creates. e.g. If you set this to "snowJobTest", the tar file created will be something like: 'snowJobTestsnowball-20220713_222749-HBSZ5D.tar'

* **compression: bool** (default False)

  True|False. This tool will compress the batched files to "gz" format by setting this to True

* **--config_file: str**

  Path of the config file, e.g. ./config. If this argument is not present in command line, --src, --bucket_name, --endpoint, and --log_dir are required. 

We provide two ways to configure the file: by using command line and by using config file.

##### Configure using command line

Example:

```
snowTransfer upload_sbe src = /data --bucket_name = mybucketname --endpoint = http://10:10:10:10:8080 log_dir = /tmp/log/ 
```

##### Configure using configuration file

To make configuration simple and easy reusable, we could also provide a configuration file to configure program.

Example:

```
snowTransfer gen_list --config_file config
```

A template of config file is also provided. Please modify the arguments under '[UPLOAD_SBE]' if you choose to use configuration file. Also please do not modify the any contents before "=". The program will not be able to identify them if the argument names are different.

Configuration file template:

```
[UPLOAD_SBE]
bucket_name = s3boostertest
src = /tmp/s3booster/fl_1.txt
endpoint = https://s3.us-east-2.amazonaws.com
profile_name = default
prefix_root = dir1/
max_process = 5
max_tarfile_size = 1Gb
extract_flag = True
target_file_prefix = zictest
log_dir = /tmp/log/s3booster/JID0001
compression = False
[GENLIST]
filelist_dir = /tmp/s3booster
partition_size = 30Mb
src = /Users/zic/Documents/zicTest
log_dir = /tmp/log/s3booster/JID0001
```

Please note that if a arguments was set in both command line and configuration file, the configuration file has predominance. 

#### Example Output

**Uploading from src directory:**

```
➜  AWSIE_SnowTransferTool git:(mainline) ✗ snowTransfer upload_sbe --config_file config_file
2022-07-13 22:17:17,588 : print_setting : [INFO] :
command: upload_sbe
src: /Users/zic/Documents/zicTest
endpoint: https://s3.us-east-2.amazonaws.com
bucket_name: s3boostertest
log_dir: /tmp/log/s3booster/JID0001
profile_name: default
prefix_root: dir1/
max_process: 5
max_tarfile_size: 5.00 MiB
compression: False
target_file_prefix: zictest
extract_flag: True
2022-07-13 22:17:17,588 : <module> : [INFO] : Batching and uploading files...
zictestsnowball-20220713_221717-1ZYYFT.tar: 100%|██████████████████████████████████████████████████| 3/3
zictestsnowball-20220713_221717-1CVU7X.tar: 100%|██████████████████████████████████████████████████| 6/6
2022-07-13 22:17:18,715 : copy_to_snowball : [INFO] : zictestsnowball-20220713_221717-1CVU7X.tar was uploaded
2022-07-13 22:17:18,795 : copy_to_snowball : [INFO] : zictestsnowball-20220713_221717-1ZYYFT.tar was uploaded
2022-07-13 22:17:27,399 : copy_to_snowball : [INFO] : /Users/zic/Documents/zicTest/Netty was uploaded
2022-07-13 22:17:27,405 : batch_and_upload : [INFO] : 9 out of 10 files were batched into 2 tar files
2022-07-13 22:17:27,406 : batch_and_upload : [INFO] : Total size: 5.39 MiB
2022-07-13 22:17:27,406 : batch_and_upload : [INFO] : Total size after batching: 50.00 KiB
2022-07-13 22:17:27,407 : batch_and_upload : [INFO] : Avg file size before: 552.00 KiB
2022-07-13 22:17:27,407 : batch_and_upload : [INFO] : Avg file size after: 1.80 MiB
2022-07-13 22:17:27,407 : batch_and_upload : [INFO] : 3 files were uploaded
2022-07-13 22:17:27,417 : <module> : [INFO] : Program finished!
```

**Uploading from manifest file**

The manifest file will be like: 

```bash
/Users/zic/Documents/zicTest/Olaf.md 4811
/Users/zic/Documents/zicTest/testf3 39
/Users/zic/Documents/zicTest/testf4 53
/Users/zic/Documents/zicTest/.DS_Store 6148
/Users/zic/Documents/zicTest/testf5 75
/Users/zic/Documents/zicTest/testf2 8
/Users/zic/Documents/zicTest/Netty 5635188
/Users/zic/Documents/zicTest/a$ 0
/Users/zic/Documents/zicTest/testf1 8
/Users/zic/Documents/zicTest/level2/.DS_Store 6148
```

The program will only consider the first string split by space as the file path, so the file_size here are useless, which means users can use other tool e.g. fpart to split their data and then upload.

```
➜  AWSIE_SnowTransferTool git:(mainline) ✗ snowTransfer upload_sbe --config_file config_file
2022-07-13 22:27:49,164 : print_setting : [INFO] :
command: upload_sbe
src: /tmp/s3booster/fl_1.txt
endpoint: https://s3.us-east-2.amazonaws.com
bucket_name: s3boostertest
log_dir: /tmp/log/s3booster/JID0001
profile_name: default
prefix_root: dir1/
max_process: 5
max_tarfile_size: 5.00 MiB
compression: False
target_file_prefix: zictest
extract_flag: True
2022-07-13 22:27:49,165 : <module> : [INFO] : Batching and uploading files...
It appears that you are using a file instead of a directory as src, please set the file path prefix that you want to ignore when uploading to snowball:
/Users/zic/Documents
zictestsnowball-20220713_222749-HBSZ5D.tar: 100%|██████████████████████████████████████████████████| 3/3
zictestsnowball-20220713_222749-VIOAB6.tar: 100%|██████████████████████████████████████████████████| 6/6
2022-07-13 22:28:07,425 : copy_to_snowball : [INFO] : zictestsnowball-20220713_222749-HBSZ5D.tar was uploaded
2022-07-13 22:28:07,461 : copy_to_snowball : [INFO] : zictestsnowball-20220713_222749-VIOAB6.tar was uploaded
2022-07-13 22:28:35,535 : copy_to_snowball : [INFO] : /Users/zic/Documents/zicTest/Netty was uploaded
2022-07-13 22:28:35,541 : batch_and_upload : [INFO] : 9 out of 10 files were batched into 2 tar files
2022-07-13 22:28:35,542 : batch_and_upload : [INFO] : Total size: 5.39 MiB
2022-07-13 22:28:35,542 : batch_and_upload : [INFO] : Total size after batching: 50.00 KiB
2022-07-13 22:28:35,542 : batch_and_upload : [INFO] : Avg file size before: 552.00 KiB
2022-07-13 22:28:35,543 : batch_and_upload : [INFO] : Avg file size after: 1.80 MiB
2022-07-13 22:28:35,543 : batch_and_upload : [INFO] : 3 files were uploaded
2022-07-13 22:28:35,551 : <module> : [INFO] : Program finished!
```


