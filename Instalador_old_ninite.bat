@echo off

bitsadmin.exe /transfer "DescargaScriptPowershell" https://----------/s/CSkNDHGYosrHYgF/download %USERPROFILE%\Downloads\script_ninite_ocs_domain.ps1

Powershell.exe -executionpolicy remotesigned -File %USERPROFILE%\Downloads\script_ninite_ocs_domain.ps1
