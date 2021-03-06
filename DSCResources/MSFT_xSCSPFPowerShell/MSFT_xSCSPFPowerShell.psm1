# DSC resource to copy and modify SPF PowerShell module from an SPF server

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
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$SPFServer,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$Credential        
	)

    if(
        (Test-Path -Path "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin\SPFAdmin.psd1") -and
        (Test-Path -Path "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin\Microsoft.SystemCenter.Foundation.SpfDbApi.dll.config")
    )
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

	$returnValue = @{
		Ensure = $Ensure
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$SPFServer,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$Credential        
	)

    switch($Ensure)
    {
        'Present'
        {
            try
            {
                New-PSDrive -Name 'SPF' -PSProvider FileSystem -Root "\\$SPFServer\c$" -Credential $Credential -ErrorAction Stop
                if(Test-Path -Path "SPF:\Program Files\Common Files\Microsoft System Center 2012 R2\Service Provider Foundation")
                {
                    & robocopy.exe "\\$SPFServer\c$\Program Files\Common Files\Microsoft System Center 2012 R2\Service Provider Foundation" "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin" /e /purge
                    if(Test-Path -Path "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin\SPFAdmin\SPFAdmin.psd1")
                    {
                        Move-Item -Path "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin\SPFAdmin\SPFAdmin.psd1" -Destination "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin"
                        (Get-Content "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin\SPFAdmin.psd1").Replace("RequiredAssemblies = @('..\Microsoft.SystemCenter.Foundation.Cmdlet.dll')","RequiredAssemblies = @('Microsoft.SystemCenter.Foundation.Cmdlet.dll')") | Set-Content "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin\SPFAdmin.psd1"
                    }
                    if(Test-Path -Path "\\$SPFServer\c$\inetpub\SPF\Web.Config")
                    {
                        Copy-Item -Path "\\$SPFServer\c$\inetpub\SPF\Web.Config" -Destination "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin\Microsoft.SystemCenter.Foundation.SpfDbApi.dll.config"
                    }
                }
            }
            catch
            {
                throw New-TerminatingError -ErrorType FailedToCopySPFModule -FormatArgs @("\\$SPFServer\c$")
            }
            finally
            {
                Remove-PSDrive -Name 'SPF'
            }
        }
        'Absent'
        {
            Remove-Item -Path "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\SPFAdmin" -Recurse
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
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$SPFServer,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$Credential        
	)

	$result = ((Get-TargetResource @PSBoundParameters).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource