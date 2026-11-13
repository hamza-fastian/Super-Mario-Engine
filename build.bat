@echo off
nasm -f bin mario.asm -o MARIO.COM
if errorlevel 1 (
    echo BUILD FAILED
    exit /b 1
)
echo BUILD OK