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
		$ServerName,

		[parameter(Mandatory = $true)]
		[ValidateSet("DatabaseConnectionString","EndPointConnectionString")]
		[System.String]
		$SettingType,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Value
	)

    if(!(Get-Module spfadmin))
    {
        Import-Module spfadmin
    }
    if(Get-Module spfadmin)
    {
        $SpfSetting = Get-SCSpfSetting -ServerName $ServerName -SettingType $SettingType | Where-Object {$_.Name -eq $Name}
        if($SpfSetting.Value -eq $Value)
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
		ServerName = $ServerName
		Name = $Name
		Value = $SpfSetting.Value
		SettingType = $SettingType
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
		$ServerName,

		[parameter(Mandatory = $true)]
		[ValidateSet("DatabaseConnectionString","EndPointConnectionString")]
		[System.String]
		$SettingType,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Value
	)

    if(!(Get-Module spfadmin))
    {
        Import-Module spfadmin
    }
    if(Get-Module spfadmin)
    {
        if(Get-SCSpfSetting -ServerName $ServerName -SettingType $SettingType | Where-Object {$_.Name -eq $Name})
        {
            Get-SCSpfSetting -ServerName $ServerName -SettingType $SettingType | Where-Object {$_.Name -eq $Name} | Remove-SCSpfSetting
        }
        if($Ensure -eq "Present")
        {
            New-SCSpfSetting -ServerName $ServerName -SettingType $SettingType -Name $Name -Value $Value.ToLower()
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
		$ServerName,

		[parameter(Mandatory = $true)]
		[ValidateSet("DatabaseConnectionString","EndPointConnectionString")]
		[System.String]
		$SettingType,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Value
	)

	$result = ((Get-TargetResource @PSBoundParameters).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource