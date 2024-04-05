<#
Script Name:        running-task.ps1
Description:        Intern service script Christian Kremer
Data:               19/March/2024
Version:            1.0
Author:             Christian Kremer
Email:              christian@kremer.systems
#>

Import-Module VMware.VimAutomation.Core
$vcsaparams = @{
	#vcsa fqdn or ip address
	Server        = ""
	#vcenter user
	Username       = ""
	# password for vcenter user
	Password       = ""
}

$teamsparams = @{
	# Teams weebhook uri
	URI         = ''
	Method      = 'POST'
	ContentType = 'application/json'
}
Function Get-RunningTask {
	param(
		[CmdletBinding(SupportsShouldProcess = $False)]
		[parameter(Mandatory = $true, HelpMessage = 'vcsaparameters')]
		[ValidateNotNullorEmpty()]
		[hashtable] $vcsaparameters,
		[parameter(Mandatory = $true, HelpMessage = 'Teamsparameters')]
		[ValidateNotNullorEmpty()]
		[hashtable] $Teamsparameters
	)

	Connect-VIServer @vcsaparams
	do {
		start-sleep -Seconds "10"
		$runningtask = Get-Task | where-object { $_.name -like "*vmotion*" } | select-object -Property Name, PercentComplete, State, StartTime

		$textbody = @()
		foreach ($t in $runningtask) {
			$txt += "Name: $($t.Name), State: $($t.State), Complete: $($t.PercentComplete), StartTime: $($t.StartTime)"
		}

		write-output $textbody

		$TeamsBody = [PSCustomObject][Ordered]@{
			"@type"      = "MessageCard"
			"@context"   = "<http://schema.org/extensions>"
			"summary"    = "vMotion operation progress"
			"themeColor" = '0078D7'
			"title"      = "vMotion operation progress"
			"text"       = $textbody -join "<br>"
		}

		$Teamsparameters += @{"Body"=$Teamsbody | ConvertTo-Json}

		Invoke-RestMethod @Teamsparameters
	} while ($null -ne $runningtask)
}

Get-RunningTask -vcs $vcsaparams -Teamsparameters $teamsparams
