echo Downing necessary python packages...
set dir=C:\Users\.support\bin
python -m pip install --upgrade pip
python -m pip install "boto3"
python -m pip install "botocore"
python -m pip install "configparser"
python -m pip install "humanfriendly"
python -m pip install "tqdm"
echo creating support dir %dir%
if not exist %dir% (mkdir %dir%) 
ren snowTransfer. snowTransfer.py
xcopy /f .\snowTransfer.py %dir%
echo.%PATHEXT% | findstr /C:".py">nul && (echo .py already in PATHEXT) || (setx /m PATHEXT "%PATHEXT%;.py")
echo SnowTransfer tool successfully installed. Try execute 'snowTransfer --help' in your terminal
echo snowTransfer command was added in %dir%, add %dir% to the PATH environment variable to run the command globally. 
pause