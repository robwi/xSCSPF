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
		[System.String[]]
		$Servers
	)

    if(!(Get-Module spfadmin))
    {
        Import-Module spfadmin
    }
    if(Get-Module spfadmin)
    {
        if(Get-SCSpfStamp -Name $Name)
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

    if($Ensure -eq "Present")
    {
        if(!(Get-Module spfadmin))
        {
            Import-Module spfadmin
        }
        if(Get-Module spfadmin)
        {
            $StampServers = (Get-ScSpfStamp -Name $Name | Get-ScSpfServer).Name
        }
        foreach($Server in $Servers)
        {
            if($Ensure -eq "Present")
            {
                if(!($StampServers | Where-Object {$_ -eq $Server}))
                {
                    $Ensure = "Absent"
                    $Servers = $StampServers
                }
            }
        }
    }
    else
    {
        $Servers = $null
    }

	$returnValue = @{
		Ensure = $Ensure
		Name = $Name
        Servers = $Servers
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
		[System.String[]]
		$Servers
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
                $StampServers = @()
                foreach($Server in $Servers)
                {
                    $StampServers += Get-SCSpfServer -Name $Server
                }
                if(Get-ScSpfStamp -Name $Name)
                {
                    Set-SCSpfStamp -Stamp (Get-ScSpfStamp -Name $Name) -Servers $StampServers
                }
                else
                {
                    New-SCSpfStamp -Name $Name -Servers $StampServers
                }
            }
            "Absent"
            {
                Get-SCSPFStamp -Name $Name | Remove-SCSPFStamp
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
		[System.String[]]
		$Servers
	)

	$result = ((Get-TargetResource @PSBoundParameters).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource