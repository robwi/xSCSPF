# NOTE: This resource requires WMF5 and PsDscRunAsCredential

$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSCSPFHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[ValidateSet("VMM","OM","DPM","OMDW","RDGateway","Orchestrator","None")]
		[System.String]
		$ServerType
	)

    if(!(Get-Module spfadmin))
    {
        Import-Module spfadmin
    }
    if(Get-Module spfadmin)
    {
        if(Get-SCSpfServer -Name $Name | Where-Object {$_.ServerType.ToString() -eq $ServerType})
        {
            $Ensure = "Present"
        }
        else
        {
            $Ensure = "Absent"
        }
    }
    else
    {
        $Ensure = "Absent"
    }

	$returnValue = @{
		Ensure = $Ensure
		Name = $Name
        ServerType = $ServerType
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[ValidateSet("VMM","OM","DPM","OMDW","RDGateway","Orchestrator","None")]
		[System.String]
		$ServerType
	)

    if(!(Get-Module spfadmin))
    {
        Import-Module spfadmin
    }
    if(Get-Module spfadmin)
    {
        switch($Ensure)
        {
            "Present"
            {
                New-SCSpfServer -Name $Name -ServerType $ServerType
            }
            "Absent"
            {
                Get-SCSpfServer -Name $Name | Remove-SCSPFServer
            }
        }
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[ValidateSet("VMM","OM","DPM","OMDW","RDGateway","Orchestrator","None")]
		[System.String]
		$ServerType
	)

	$result = ((Get-TargetResource @PSBoundParameters).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource