@echo off




echo "___________                  .__          _____         .__    .___ __________             .___              .___                 __         .__  .__  "              
echo "\_   _____/__________  _____ |__| ____   /  _  \   ____ |__| __| _/ \______   \_____     __| _/____ _______  |   | ____   _______/  |______  |  | |  |   ___________ "
echo " |    __)/  _ \_  __ \/     \|  |/ ___\ /  /_\  \_/ ___\|  |/ __ |   |       _/\__  \   / __ |\__  \\_  __ \ |   |/    \ /  ___/\   __\__  \ |  | |  | _/ __ \_  __ \"
echo " |     \(  <_> )  | \/  Y Y  \  \  \___/    |    \  \___|  / /_/ |   |    |   \ / __ \_/ /_/ | / __ \|  | \/ |   |   |  \\___ \  |  |  / __ \|  |_|  |_\  ___/|  | \/"
echo " \___  / \____/|__|  |__|_|  /__|\___  >____|__  /\___  >__\____ |   |____|_  /(____  /\____ |(____  /__|    |___|___|  /____  > |__| (____  /____/____/\___  >__|   "
echo "     \/                    \/        \/        \/     \/        \/          \/      \/      \/     \/                 \/     \/            \/               \/       "


rem Intro Screen
echo ======================================================
echo      Welcome to the FormicRadar Installer Script
echo                Made by: awdev 
echo ======================================================
echo.
echo IF YOU WOULD RATHER FOLLOW A VIDEO GO TO BEANI'S CHANNEL VIA THE LINK POSTED IN THE PTFS TOOLS Server
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
echo.
echo.
echo.
rem Check for Node.js
where node >nul 2>nul
if %errorlevel% equ 0 (
    echo Node.js is installed
) else (
    echo Node.js is not installed
    echo Install Node.js by running the installer, then click Yes on the UAC Prompt
    start node-v21.7.1-x64.msi
    PAUSE
)

rem Check for Python 3.10
python --version >nul 2>nul
if %errorlevel% equ 0 (
    python --version | findstr "3.10" >nul
    if %errorlevel% equ 0 (
        echo Python 3.10 is installed
    ) else (
        echo Python 3.10 is not installed
        echo Install Python 3.10 by running the installer, then click Yes on the UAC Prompt
        cd _redist
        start python-3.10.0-amd64.exe
        PAUSE
        echo You might need to install from the microsoft store. So install both and go the the microsoft store and search for python 3.1 and you should be fine
    )
) else (
    echo Python is not installed
    echo Install Python 3.10 by running the installer, then click Yes on the UAC Prompt
    cd _redist
    start python-3.10.0-amd64.exe
    PAUSE
    echo You might need to install from the microsoft store. So install both and go the the microsoft store and search for python 3.1 and you should be fine
)

echo Both Node.js and Python 3.10 are now (hopefully) installed.
echo.
echo.
echo.
echo.
echo.
echo "Open OBS, go to the top toolbar and click tools, scripts, Python Settings, and import this following file path:"
echo "C:/Users/REPLACE THIS WITH YOUR WINDOWS USERNAME/AppData/Local/Programs/Python/Python310 (you will need to click the 'browse' button and insert the path thru the top large search bar)"
PAUSE 
echo "Next click apply and go to Scripts, Websocket Server Settings, Enable Websocket Server, set port to 4455, and Disable Authentication, Click apply and ur done with that part."
PAUSE
echo "Next Open the Scenes folder by clicking any button. When this opens you will need to open the scenes folder in the radar folder. Then copy those json files to the obs scenes folder"
PAUSE
start %UserProfile%\AppData\Roaming\obs-studio\basic\scenes
PAUSE
echo "once done run init.bat in /(radarfolder)/scripts you should only need to run init once."
PAUSE
echo "Now run start.bat in the same folder and open 'radar-control.exe' in the main radar folder here. Be sure to open obs if you closed it"
PAUSE
echo "When you have opened radar control, go to obs and Click Scene Collect and select any airport. Restart radar control."
PAUSE
echo "Congrats! You have installed Formic's Radar. Enjoy."
PAUSE
exit