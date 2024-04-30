@echo off
cd ..
cd backend
start /min cmd /c npm install
cd ..
cd frontend
start /min cmd /c npm install
cd ..
start /min cmd /c pip install requests
exit