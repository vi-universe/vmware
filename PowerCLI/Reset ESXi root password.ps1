<#    
Script Name:			Reset ESXi root password.ps1
Description:			Intern service script for Christian Kremer 
Data:					15/Jul/2022
Version:				1.0
Author:					Christian Kremer
Email:					christian@kremer.systems

Reset ESXi root password 
The esxi node must connected to the vcenter

#> 


write-host "Specify vCenter FQDN" -ForegroundColor Green 
$vCenter= Read-Host "Enter your vCenter FQDN" 

write-host "Specify ESXi IP adress or FQDN " -ForegroundColor Green 
$esxi= Read-Host "Enter your IP address or FQDN" 


Connect-VIServer $vCenter 


    $vmhosts = Get-VMHost $esxi

    $NewCredential = Get-Credential -UserName "root" -Message "Enter an existing ESXi username (not vCenter), and what you want their password to be reset to." 

    foreach ($vmhost in $vmhosts) {
		#Gain access to ESXCLI on the host
		$esxcli = get-esxcli -vmhost $vmhost -v2
	
		#Get Parameter list (Arguments)
		$esxcliargs = $esxcli.system.account.set.CreateArgs() 
	
		#Specify the user to reset
		$esxcliargs.id = $NewCredential.UserName
	
		#Specify the user to reset
		$esxcliargs.password = $NewCredential.GetNetworkCredential().Password
	
		#Specify the new password
		$esxcliargs.passwordconfirmation = $NewCredential.GetNetworkCredential().Password
	
		#Debug line so admin can see what's happening.
		Write-Host ("Resetting password for: " + $vmhost)
	
		#Run command, if returns "true" it was successful.
		$esxcli.system.account.set.Invoke($esxcliargs)
	}