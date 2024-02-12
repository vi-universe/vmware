<#    
Script Name:		ShowVMBiosUUID.ps1
Description:		Intern service script for Christian Kremer 
Data:				15/Jul/2022
Version:			1.0
Author:				Christian Kremer
Email:				christian@kremer.systems

TSM >>> ESXi Shell              
TSM-SSH >>> SSH         


#> 


#Add vCenter FQDN
$vCenterFQDN="vCenterFQDN"
#Add VM-Name
$VMName="VM-Name"

Connect-VIServer $vCenterFQDN
Get-VM $VMName | %{(Get-View $_.Id).config.uuid}