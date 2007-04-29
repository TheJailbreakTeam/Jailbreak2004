@echo off

echo ===============================================================================
echo Full Installer
echo ===============================================================================
echo.
perl make-distribution.pl --version="c" --skip-keypress --zip zip

if errorlevel 1 goto :END

echo.
echo.
echo ===============================================================================
echo Patch
echo ===============================================================================
echo.
perl make-distribution.pl --version="c-Patch" --reference-file="Jailbreak2004-reference.txt" --reference-version=100 --skip-rebuild --zip 7z


:END