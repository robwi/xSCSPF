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
		$Ensure,

		[System.String]
		$SourcePath = "$PSScriptRoot\..\..\",

		[System.String]
		$SourceFolder = "Source",

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SetupCredential,

		[System.Management.Automation.PSCredential]
		$SourceCredential,

		[System.Boolean]
		$SuppressReboot,

		[System.Boolean]
		$ForceReboot,

        [System.String]
        $SendCEIPReports = "False",

        [System.String]
        $UseMicrosoftUpdate = "False",

        [System.Boolean]
        $SpecifyCertificate = $false,

        [System.String]
        $CertificateName = ($env:COMPUTERNAME + "." + (Get-WmiObject -Class Win32_ComputerSystem).Domain),

        [Parameter(Mandatory=$true)]
        [System.String]
        $DatabaseServer,

        [System.UInt16]
        $DatabasePortNumber,

        [System.String]
        $DatabaseName = "SCSPFDB",

        [System.UInt16]
        $WebSitePortNumber = 8090,

        [System.Management.Automation.PSCredential]
        $SCVMM,
        
        [System.Management.Automation.PSCredential]
        $SCAdmin = $SCVMM,
        
        [System.Management.Automation.PSCredential]
        $SCProvider = $SCVMM,
        
        [System.Management.Automation.PSCredential]
        $SCUsage = $SCVMM
	)

    Import-Module $PSScriptRoot\..\..\xPDT.psm1
        
    if($SourceCredential)
    {
        NetUse -SourcePath $SourcePath -Credential $SourceCredential -Ensure "Present"
    }
    $Path = Join-Path -Path (Join-Path -Path $SourcePath -ChildPath $SourceFolder) -ChildPath "\setup.exe"
    $Path = ResolvePath $Path
    $Version = (Get-Item -Path $Path).VersionInfo.ProductVersion
    if($SourceCredential)
    {
        NetUse -SourcePath $SourcePath -Credential $SourceCredential -Ensure "Absent"
    }

    $IdentifyingNumber = GetxPDTVariable -Component "SCSPF" -Version $Version -Role "Server" -Name "IdentifyingNumber"
    Write-Verbose "IdentifyingNumber is $IdentifyingNumber"

    if($IdentifyingNumber -and (Get-WmiObject -Class Win32_Product | Where-Object {$_.IdentifyingNumber -eq $IdentifyingNumber}))
    {
        $DatabaseServer = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation" -Name "DatabaseServer").DatabaseServer
        
        $DatabasePort = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation" -Name "DatabasePort").DatabasePort
        if($DatabasePort -eq -1)
        {
            $DatabasePortNumber = 0
        }
        else
        {
            $DatabasePortNumber = $DatabasePort
        }
        $DatabaseName = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation" -Name "DatabaseName").DatabaseName
        $WebSitePortNumber = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation" -Name "PortNumber").PortNumber
        $SCVMMUsername = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation\VMM" -Name "AppPoolDomain").AppPoolDomain + "\" + (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation\VMM" -Name "AppPoolUserName").AppPoolUserName
        $SCAdminUsername = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation\Admin" -Name "AppPoolDomain").AppPoolDomain + "\" + (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation\Admin" -Name "AppPoolUserName").AppPoolUserName
        $SCProviderUsername = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation\Provider" -Name "AppPoolDomain").AppPoolDomain + "\" + (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation\Provider" -Name "AppPoolUserName").AppPoolUserName
        $SCUsageUsername = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation\Usage" -Name "AppPoolDomain").AppPoolDomain + "\" + (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Service Provider Foundation\Usage" -Name "AppPoolUserName").AppPoolUserName
        $SPFGroups = @("VMM","Admin","Provider","Usage")

        $returnValue = @{
		    Ensure = "Present"
		    SourcePath = $SourcePath
		    SourceFolder = $SourceFolder
            DatabaseServer = $DatabaseServer
            DatabasePortNumber = $DatabasePortNumber
            DatabaseName = $DatabaseName
            WebSitePortNumber = $WebSitePortNumber
            SCVMMUsername = $SCVMMUsername
            SCAdminUsername = $SCAdminUsername
            SCProviderUsername = $SCProviderUsername
            SCUsageUsername = $SCUsageUsername
        }
    }
    else
    {
        $returnValue = @{
		    Ensure = "Absent"
		    SourcePath = $SourcePath
		    SourceFolder = $SourceFolder
        }
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
		$Ensure,

		[System.String]
		$SourcePath = "$PSScriptRoot\..\..\",

		[System.String]
		$SourceFolder = "Source",

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SetupCredential,

		[System.Management.Automation.PSCredential]
		$SourceCredential,

		[System.Boolean]
		$SuppressReboot,

		[System.Boolean]
		$ForceReboot,

        [System.String]
        $SendCEIPReports = "False",

        [System.String]
        $UseMicrosoftUpdate = "False",

        [System.Boolean]
        $SpecifyCertificate = $false,

        [System.String]
        $CertificateName = ($env:COMPUTERNAME + "." + (Get-WmiObject -Class Win32_ComputerSystem).Domain),

        [Parameter(Mandatory=$true)]
        [System.String]
        $DatabaseServer,

        [System.UInt16]
        $DatabasePortNumber,

        [System.String]
        $DatabaseName = "SCSPFDB",

        [System.UInt16]
        $WebSitePortNumber = 8090,

        [System.Management.Automation.PSCredential]
        $SCVMM,
        
        [System.Management.Automation.PSCredential]
        $SCAdmin = $SCVMM,
        
        [System.Management.Automation.PSCredential]
        $SCProvider = $SCVMM,
        
        [System.Management.Automation.PSCredential]
        $SCUsage = $SCVMM
	)

    Import-Module $PSScriptRoot\..\..\xPDT.psm1
        
    if($SourceCredential)
    {
        NetUse -SourcePath $SourcePath -Credential $SourceCredential -Ensure "Present"
        $TempFolder = [IO.Path]::GetTempPath()
        & robocopy.exe (Join-Path -Path $SourcePath -ChildPath $SourceFolder) (Join-Path -Path $TempFolder -ChildPath $SourceFolder) /e
        $SourcePath = $TempFolder
        NetUse -SourcePath $SourcePath -Credential $SourceCredential -Ensure "Absent"
    }
    $Path = Join-Path -Path (Join-Path -Path $SourcePath -ChildPath $SourceFolder) -ChildPath "\setup.exe"
    $Path = ResolvePath $Path
    $Version = (Get-Item -Path $Path).VersionInfo.ProductVersion
    Write-Verbose "Path: $Path"

    switch($Ensure)
    {
        "Present"
        {
            # Set defaults, if they couldn't be set in param due to null configdata input
            if($WebSitePortNumber -eq 0)
            {
                $WebSitePortNumber = 8090
            }
            if($SendCEIPReports -ne "True")
            {
                $SendCEIPReports = "False"
            }
            if($UseMicrosoftUpdate -ne "True")
            {
                $UseMicrosoftUpdate = "False"
            }

            # Create install arguments
            $TempFile = [IO.Path]::GetTempFileName()
            $Arguments = "-Silent $TempFile"
            $AnswerFile = @()
            $AnswerFileVars = @(
                "SendCEIPReports",
                "UseMicrosoftUpdate",
                "DatabaseServer",
                "DatabasePortNumber",
                "DatabaseName",
                "WebSitePortNumber",
                "SpecifyCertificate"
            )
            # If SpecifyCertificate = True, get serial number
            if($SpecifyCertificate)
            {
                $Certificates = @(Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {($_.Subject -eq "CN=$CertificateName") -and ($_.Issuer -ne "CN=$CertificateName")} | Where-Object {$_.EnhancedKeyUsageList.ObjectId -eq "1.3.6.1.5.5.7.3.1"})
                if($Certificates.Count -eq 0)
                {
                    $Certificates = @(Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {$_.Subject -eq "CN=$CertificateName"} | Where-Object {$_.EnhancedKeyUsageList.ObjectId -eq "1.3.6.1.5.5.7.3.1"})
                }
                if($Certificates.Count -eq 0)
                {
                    $null = New-SelfSignedCertificate -DnsName $CertificateName -CertStoreLocation "Cert:\LocalMachine\My"
                    $Certificates = @(Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {$_.Subject -eq "CN=$CertificateName"} | Where-Object {$_.EnhancedKeyUsageList.ObjectId -eq "1.3.6.1.5.5.7.3.1"})
                }
                $CertificateSerialNumber = $Certificates[0].SerialNumber
                $AnswerFileVars += @("CertificateSerialNumber")
            }
            foreach($AnswerFileVar in $AnswerFileVars)
            {
                if(!([String]::IsNullOrEmpty((Get-Variable -Name $AnswerFileVar).Value)) -and ((Get-Variable -Name $AnswerFileVar).Value -ne 0))
                {
                    $AnswerFile += "-$AnswerFileVar " + (Get-Variable -Name $AnswerFileVar).Value
                }
            }
            $AccountVars = @("SCVMM","SCAdmin","SCProvider","SCUsage")
            foreach($AccountVar in $AccountVars)
            {
                if($PSBoundParameters.ContainsKey("SCVMM") -or $PSBoundParameters.ContainsKey("$AccountVar"))
                {
                    $AnswerFile += "-$AccountVar`NetworkServiceSelected False"
                    $AnswerFile += "-$AccountVar`UserName " + (Get-Variable -Name $AccountVar).Value.GetNetworkCredential().UserName
                    $AnswerFile += "-$AccountVar`Password " + (Get-Variable -Name $AccountVar).Value.GetNetworkCredential().Password
                    $AnswerFile += "-$AccountVar`Domain " + (Get-Variable -Name $AccountVar).Value.GetNetworkCredential().Domain
                }
                else
                {
                    $AnswerFile += "-$AccountVar`NetworkServiceSelected True"
                }
            }

            Write-Verbose "AnswerFile: $TempFile"
            foreach($Line in $AnswerFile)
            {
                Add-Content -Path $TempFile -Value $Line -Encoding Ascii
                # Replace sensitive values for verbose output
                $LogLine = $Line
                if($LogLine.Contains("Password"))
                {
                    $LogLine = $LogLine.Split(" ")[0] + " ********"
                }
                Write-Verbose $LogLine
            }
        }
        "Absent"
        {
            # Create uninstall arguments
            $Arguments = "-Silent -Uninstall"
        }
    }

    Write-Verbose "Arguments: $Arguments"
    
    $Process = StartWin32Process -Path $Path -Arguments $Arguments -Credential $SetupCredential
    Write-Verbose $Process
    WaitForWin32ProcessEnd -Path $Path -Arguments $Arguments -Credential $SetupCredential

    # Clean up
    if(Test-Path -Path $TempFile)
    {
        Remove-Item -Path $TempFile
    }

    if($ForceReboot -or ((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue) -ne $null))
    {
	    if(!($SuppressReboot))
        {
            $global:DSCMachineStatus = 1
        }
        else
        {
            Write-Verbose "Suppressing reboot"
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
		$Ensure,

		[System.String]
		$SourcePath = "$PSScriptRoot\..\..\",

		[System.String]
		$SourceFolder = "Source",

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SetupCredential,

		[System.Management.Automation.PSCredential]
		$SourceCredential,

		[System.Boolean]
		$SuppressReboot,

		[System.Boolean]
		$ForceReboot,

        [System.String]
        $SendCEIPReports = "False",

        [System.String]
        $UseMicrosoftUpdate = "False",

        [System.Boolean]
        $SpecifyCertificate = $false,

        [System.String]
        $CertificateName = ($env:COMPUTERNAME + "." + (Get-WmiObject -Class Win32_ComputerSystem).Domain),

        [Parameter(Mandatory=$true)]
        [System.String]
        $DatabaseServer,

        [System.UInt16]
        $DatabasePortNumber,

        [System.String]
        $DatabaseName = "SCSPFDB",

        [System.UInt16]
        $WebSitePortNumber = 8090,

        [System.Management.Automation.PSCredential]
        $SCVMM,
        
        [System.Management.Automation.PSCredential]
        $SCAdmin = $SCVMM,
        
        [System.Management.Automation.PSCredential]
        $SCProvider = $SCVMM,
        
        [System.Management.Automation.PSCredential]
        $SCUsage = $SCVMM
	)

	$result = ((Get-TargetResource @PSBoundParameters).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource