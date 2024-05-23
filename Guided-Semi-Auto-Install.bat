@echo off

REM Check for admin rights
net session >nul 2>nul
if %errorlevel% neq 0 (
    powershell -Command "Start-Process \"%0\" -Verb RunAs"
    exit /b
)

echo "___________                  .__          _____         .__    .___ "
echo "\_   _____/__________  _____ |__| ____   /  _  \   ____ |__| __| _/ "
echo   "|    __)/  _ \_  __ \/     \|  |/ ___\ /  /_\  \_/ ___\|  |/ __ |"
echo   "|     \(  <_> )  | \/  Y Y  \  \  \___/    |    \  \___|  / /_/ |" 
echo   "\___  / \____/|__|  |__|_|  /__|\___  >____|__  /\___  >__\____ |  "
echo       "\/                    \/        \/        \/     \/        \/ " 
echo "           __________             .___                              "
echo  "          \______   \_____     __| _/____ _______                  "
echo             "|       _/\__  \   / __ |\__  \\_  __ \  "               
echo             "|    |   \ / __ \_/ /_/ | / __ \|  | \/ "                
echo             "|____|_  /(____  /\____ |(____  /__| "                   
echo                    "\/      \/      \/     \/"                        
echo       ".___                 __         .__  .__               "       
echo       "|   | ____   _______/  |______  |  | |  |   ___________  "     
echo       "|   |/    \ /  ___/\   __\__  \ |  | |  | _/ __ \_  __ \"      
echo       "|   |   |  \\___ \  |  |  / __ \|  |_|  |_\  ___/|  | \/ "     
echo       "|___|___|  /____  > |__| (____  /____/____/\___  >__| "        
echo               " \/     \/            \/               \/ "            


rem Intro Screen
echo ======================================================
echo      Welcome to the FormicRadar Installer Script
echo         Made by: awdev (Reviewed by: beaniii_)
echo        Auto QuietInstall and UAC by DangerChamp
echo ======================================================
echo.

:mainmenu
echo.........................................................
echo:                      Option Menu                      :
echo:.......................................................:
echo: 1. Open YouTube Tutorial                              :
echo: 2. Continue With Integrated Step-by-Step installation :
echo:.......................................................:
choice /C:12 >nul

if %errorlevel% equ 1 goto openytvideo
if %errorlevel% equ 2 goto setup

:quit
exit /b

:openytvideo
rem Replace with actual youtube tutorial link once you have a video up again
rem as vision closed his channel and the videos are unavailable lol
start "" https://www.youtube.com/watch?v=LYUFJBMxizM
goto quit

:setup
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
REM Check for Node.js
where node >nul 2>nul
if %errorlevel% equ 0 (
    echo Node.js is installed
) else (
    echo Node.js is not installed
    echo Installing Node.js...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://nodejs.org/dist/v22.0.0/node-v22.0.0-x64.msi', 'node_installer.msi')"
    start "" /wait node_installer.msi /qn INSTALLDIR="C:\Nodejs"
    del node_installer.msi
    PAUSE
)

REM Check for Python 3.10
python --version >nul 2>nul
if %errorlevel% equ 0 (
    python --version | findstr "3.10" >nul
    if %errorlevel% equ 0 (
        echo Python 3.10 is installed
    ) else (
        echo Python 3.10 is not installed
        echo Downloading Python installer...
        powershell -Command "(New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe', 'python_installer310.exe')"
        echo Installing Python 3.10...
        start "" /wait python_installer310.exe /quiet InstallAllUsers=1 TargetDir="C:\Python310" PrependPath=1
        del python_installer310.exe
        PAUSE
    )
) else (
    echo Python is not installed
    echo Downloading Python installer...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe', 'python_installer310.exe')"
    echo Installing Python 3.10...
    start "" /wait python_installer310.exe /quiet InstallAllUsers=1 TargetDir="C:\Python310" PrependPath=1
    del python_installer310.exe
    PAUSE
)

echo Both Node.js and Python 3.10 are installed.
echo.
echo.
echo.
echo.
echo.
echo "Open OBS, go to the top toolbar and click tools, scripts, Python Settings, and import this following file path:"
echo "C:/Users/REPLACE THIS WITH YOUR WINDOWS USERNAME/AppData/Local/Programs/Python/Python310 (you will need to click the 'Browse' button and insert the path thru the top large search bar)"
PAUSE 
echo .
echo "Next click apply and go to Tools, Websocket Server Settings, Enable Websocket Server, set port to 4455, and Disable Authentication, Click apply and ur done with that part."
PAUSE
echo .
echo "Next Open the Scenes folder by clicking any button. When this opens you will need to open the scenes folder in the radar folder. Then copy those json files to the obs scenes folder"
PAUSE
echo .
start %UserProfile%\AppData\Roaming\obs-studio\basic\scenes
PAUSE
echo .
echo "once done run init.bat in /(radarfolder)/scripts you should only need to run init once."
PAUSE
echo .
echo "Now run start.bat in the same folder and open 'radar-control.exe' in the main radar folder here. Be sure to open obs if you closed it"
PAUSE
echo .
echo "When you have opened radar control, go to obs and Click Scene Collection and select any airport. Restart radar control."
PAUSE
echo .
echo "Congrats! You have installed Formic's Radar. Enjoy."
PAUSE
exit
