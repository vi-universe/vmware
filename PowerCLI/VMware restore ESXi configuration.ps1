<#    
Script Name:			VMware restore ESXi configuration.ps1
Description:			Intern service script for Christian Kremer 
Data:					15/Jul/2022
Version:				1.0
Author:					Christian Kremer
Email:					christian@kremer.systems

Restore ESXi configuration 
!!! Important !!! ESXi take a reboot !!!     

#> 
write-host "Specify local backup destination path and the config file" -ForegroundColor Green 
$Path= Read-Host "Enter backup destination path on your local device" 


write-host "Specify ESXi IP" -ForegroundColor Green 
$ESXiHost= Read-Host "Enter your ESXi IP" 


write-host "Connecting to Host" -ForegroundColor Green
Connect-VIServer $ESXiHost

Get-VMHost | Set-VMHost -State Maintenance

Get-VMHost | Set-VMHostFirmware -Restore -Force -SourcePath $Path