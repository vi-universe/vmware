<#
Script Name:        running-task.ps1
Description:        Intern service script Christian Kremer
Data:               19/March/2024
Version:            1.0
Author:             Christian Kremer
Email:              christian@kremer.systems
#>

Import-Module VMware.VimAutomation.Core
$params = @{
	#vcsa fqdn or ip address
	vcsa        = ""
	#vcenter user
	user        = ""
	# password for vcenter user
	pass        = ""
	# refreshtimer
	refreshtime = "10"
	# URI incoming webhook teams channel
	uri         = ""
}

Function Get-RunningTask {
	param(
		[parameter(Mandatory = $true, HelpMessage = "vcsa ip address or fqdn")]
		[ValidateNotNullorEmpty()]
		[string] $vcsa,
		[parameter(Mandatory = $true, HelpMessage = "@vsphere.local user")]
		[ValidateNotNullorEmpty()]
		[string] $user,
		[parameter(Mandatory = $true, HelpMessage = "@vsphere.local user password")]
		[ValidateNotNullorEmpty()]
		[string]$pass,
		[parameter(Mandatory = $true, HelpMessage = "refresh timer")]
		[ValidateNotNullorEmpty()]
		[string]$refreshtime,
		[parameter(Mandatory = $true, HelpMessage = "teams incoming webhook url")]
		[ValidateNotNullorEmpty()]
		[string]$uri
	)

	Connect-VIServer -Server $vcsa -user $user -pass $pass
	do {
		start-sleep -Seconds $refreshtime
		$runningtask = Get-Task | where-object { $_.name -like "*vmotion*" } | select-object -Property Name, PercentComplete, State, StartTime

		$textbody = @()
		foreach ($t in $runningtask) {
			$txt += "Name: $($t.Name), State: $($t.State), Complete: $($t.PercentComplete), StartTime: $($t.StartTime)"
		}

		write-output $textbody

		$JSONBody = [PSCustomObject][Ordered]@{
			"@type"      = "MessageCard"
			"@context"   = "<http://schema.org/extensions>"
			"summary"    = "vMotion operation progress"
			"themeColor" = '0078D7'
			"title"      = "vMotion operation progress"
			"text"       = $textbody -join "<br>"
		}

		$TeamsTextBody = ConvertTo-Json $JSONBody

		$parameters = @{
			"URI"         = $uri
			"Method"      = 'POST'
			"Body"        = $TeamsTextBody
			"ContentType" = 'application/json'
		}

		Invoke-RestMethod @parameters
	} while ($null -ne $runningtask)
}

Get-RunningTask @params
