#!/usr/bin/env bash
echo "Downing necessary python packages..."
SUCCESS="SnowTransfer tool successfully installed. Try execute 'snowTransfer --help' in your terminal"
python3 -m pip install --upgrade pip
python3 -m pip install "boto3" 2> /dev/null
if [ $? -ne 0 ] 
then
  echo "Could not download python packages, please make sure that python and pip module were installed" >&2 
  exit 1
fi
python3 -m pip install "botocore"
python3 -m pip install "configparser"
python3 -m pip install "humanfriendly"
python3 -m pip install "tqdm"
DIR=~/.support/bin
# program starts
echo "creating support dir ${DIR}"
mkdir -p ${DIR}

# Mac OSx creates .folder as root, resulting in permission denied
if [ $(uname) == "Darwin" ]; then
    name=$(id -u -n)
    chown -R ${name} ${DIR}
fi

chmod +x snowTransfer
if [ $? -ne 0 ] 
then
  echo "Please make sure that snowTransfer file is in the current folder!" >&2 
  exit 1
fi
cp snowTransfer ${DIR}

# add generated tools to PATH
if [[ "$PATH" =~ $DIR ]]; then
	echo "transfer tool already in path"
    echo $SUCCESS
else
	echo "setting path"
	echo "export PATH=$DIR:$PATH" >> ~/.zshrc
	echo "export PATH=$DIR:$PATH" >> ~/.bash_profile
    source ~/.bash_profile
    echo $SUCCESS
    if [ -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
        zsh
        source ~/.zshrc
    fi
fi