<#    
Script Name:			VMware save ESXi configuration.ps1
Description:			Intern service script for Christian Kremer 
Data:					15/Jul/2022
Version:				1.0
Author:					Christian Kremer
Email:					christian@kremer.systems

Save ESXi configuration

#> 


write-host "Specify local backup destination path" -ForegroundColor Green 
$Path= Read-Host "Enter backup destination path on your local device" 


write-host "Specify vCenter FQDN or ESXi IP Adress" -ForegroundColor Green 
$vENV= Read-Host "Enter your vCenter FQDN or ESXi IP Adress" 


write-host "Connecting to vCenter or Host" -ForegroundColor Green
Connect-VIServer $vENV

Get-VMHost | Get-VMHostFirmware -BackupConfiguration -DestinationPath $Path