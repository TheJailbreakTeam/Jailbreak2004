@echo off

:: ============================================================================
:: Create Package
:: ============================================================================

echo Creating package...

cd ..\System
ucc pkg import sound ..\Sounds\JBVoiceFreak ..\JBVoiceFreak\Sounds

echo Done.


:: ============================================================================
:end