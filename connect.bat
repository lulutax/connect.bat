@echo off 
setlocal enabledelayedexpansion

SETLOCAL
::set AWS_SECRET_ACCESS_KEY=<MY SECRET>  configurate tramite 'aws configure'
::set AWS_ACCESS_KEY_ID=<MY ACCESS KEY>   configurate tramite 'aws configure'
set AWS_REGION=eu-central-1
set RDSHOST=%1
set RDSDBNAME=%2
set RDSUSER=%3

echo "Stai accedendo al cluster: %RDSHOST%"
echo "DB: %RDSDBNAME%"
echo "Username: %RDSUSER%"

for /f "tokens=1 delims=." %%a in ("%RDSHOST%") do set "clusterpg=%%a"


for /F %%a in ('aws rds generate-db-auth-token --hostname %RDSHOST% --port 5432 --region %AWS_REGION% --username %RDSUSER%' ) do set BS=%%a

set "Find=:"
set "Replace=\:"

call set "TOKEN=%%BS:%Find%=%Replace%%%"

set "newtoken=%RDSHOST%:5432:%RDSDBNAME%:%RDSUSER%:%TOKEN%"
set "newtoken=%newtoken:"=%"
set pgdir=%userprofile%\AppData\Roaming\postgresql
if not exist %pgdir% mkdir %pgdir%
set pgpass=%pgdir%\pgpass.conf



:echo !newtoken! >> %pgpass%

FINDSTR /B %clusterpg% %pgpass%


::returns the correct line - works well
FOR /f "tokens=*" %%i IN (
 'FINDSTR /B %clusterpg% %pgpass%
') do set "line=%%i"

echo "%line%"
copy NUL temp.txt
if "%line%"=="" (

   ::Token non presente, lo aggiunge direttamente
   echo !newtoken! >> %pgpass%

) else (

    ::Trovato token, lo cerca per sostituirlo
    FOR /F "usebackqdelims=" %%G IN (%pgpass%) DO (
        if "%%G"=="%line%" (
            
            echo !newtoken! >> temp.txt
            
        ) ELSE (

            echo %%G >> temp.txt

        )    
    )

    ::Svuota il file pgpass e lo ripopola con il token aggiornato (i precedenti token non si perdono)
    copy NUL %pgpass%
    FOR /F "usebackqdelims=" %%G IN (temp.txt) DO (

            echo %%G >> %pgpass%

        )
)

del temp.txt

ENDLOCAL
