@echo off

echo ===============================================================================
echo Full Installer (zip)
echo ===============================================================================
echo.
perl make-distribution.pl --version="c" --skip-keypress --zip zip

if errorlevel 1 goto :ERROR

echo.
echo.
echo ===============================================================================
echo Patch
echo ===============================================================================
echo.
perl make-distribution.pl --version="c-Patch" --reference-file="Jailbreak2003-reference.txt" --reference-version=100 --skip-rebuild --zip zip

goto :END
:ERROR
pause
:END