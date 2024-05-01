@echo off
cd ..
cd backend
start /min cmd /c node .
cd ..
cd frontend
start /min cmd /c npm run dev
cd ..
python overlay.py
exit
