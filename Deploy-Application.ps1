<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {Write-Error -Message "Unable to set the PowerShell Execution Policy to Bypass for this process."}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'Autodesk'
	[string]$appName = 'Revit'
	[string]$appVersion = '2018'
	[string]$appArch = 'x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '06/09/2017'
	[string]$appScriptAuthor = 'Truong Nguyen'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.9'
	[string]$deployAppScriptDate = '02/12/2017'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps 'acad, revit' -CheckDiskSpace -PersistPrompt

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Installation tasks here>
     
		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}

		## <Perform Installation tasks here>

        # Install AutoCAD Simulation Mechanical 2017
		Execute-Process -Path "$dirFiles\Img\Setup.exe" -Parameters '/W /Q /I Revit2018' -WindowStyle 'Hidden' -PassThru

        # Install AutoCAD 2018
		#Execute-Process -Path "$dirFiles\Img\Setup.exe" -Parameters '/W /Q /I AutoCAD2018.ini' -WindowStyle 'Hidden' -PassThru
        # Install AutoCAD Civil 3D 2018
		#Execute-Process -Path "$dirFiles\Img\Setup.exe" -Parameters '/W /Q /I AutoCADCivil3D2018.ini' -WindowStyle 'Hidden' -PassThru
        # Install AutoCAD Electrical 2018
		#Execute-Process -Path "$dirFiles\Img\Setup.exe" -Parameters '/W /Q /I AutoCADElectrical2018.ini' -WindowStyle 'Hidden' -PassThru
        # Install AutoCAD Mechanical 2018
		#Execute-Process -Path "$dirFiles\Img\Setup.exe" -Parameters '/W /Q /I AutoCADMechanical2018.ini' -WindowStyle 'Hidden' -PassThru


		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>

		## Display a message at the end of the install
		If (-not $useDefaultMsi) {Show-InstallationPrompt -Message ‘'$appVendor' '$appName' '$appVersion' has been Sucessfully Installed.’ -ButtonRightText ‘OK’ -Icon Information -NoWait}
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'acad, revit' -CloseAppsCountdown 60

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Uninstallation tasks here>


		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}

		# <Perform Uninstallation tasks here>

        # Uninstall Revit 2018
        Execute-MSI -Action Uninstall -Path '{7346B4A0-1800-0510-0000-705C0D862004}'
        # Uninstall Autodesk Collaboration for Revit 2018
        Execute-MSI -Action Uninstall -Path '{AA384BE4-1800-0010-0000-97E7D7D00B17}'
        # Uninstall Personal Accelerator for Revit
        Execute-MSI -Action Uninstall -Path '{7C317DB0-F399-4024-A289-92CF4B6FB256}'
        # Uninstall Batch Print for Autodesk Revit 2018
        Execute-MSI -Action Uninstall -Path '{82AF00E4-1800-0010-0000-FCE0F87063F9}'
        # Uninstall eTransmit for Autodesk Revit 2018
        Execute-MSI -Action Uninstall -Path '{4477F08B-1800-0010-0000-9A09D834DFF5}'
        # Uninstall Autodesk Revit Model Review 2018
        Execute-MSI -Action Uninstall -Path '{715812E8-1800-0010-0000-BBB894911B46}'
        # Uninstall Worksharing Monitor for Autodesk Revit 2018
        Execute-MSI -Action Uninstall -Path '{5063E738-1800-0010-0000-7B7B9AB0B696}'
        # Uninstall Dynamo Revit 1.2.2
        Execute-MSI -Action Uninstall -Path '{0FF47E28-76A5-44BA-8EEF-58824252F528}'

        # Uninstall Autodesk Material Library 2018
        #Execute-MSI -Action Uninstall -Path '{7847611E-92E9-4917-B395-71C91D523104}'
        # Uninstall Autodesk Material Library Base Resolution Image Library 2018
        #Execute-MSI -Action Uninstall -Path '{FCDED119-A969-4E48-8A32-D21AD6B03253}'
        # Uninstall Autodesk Advanced Material Library Image Library 2018
        #Execute-MSI -Action Uninstall -Path '{177AD7F6-9C77-4E50-BA53-B7259C5F282D}'
        # Uninstall AutoCAD 2018
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1001-0000-0102-CF3F3A09B77D}'
        # Uninstall AutoCAD 2018 Language Pack - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1001-0409-1102-CF3F3A09B77D}'
        # Uninstall ACA & MEP 2018 Object Enabler
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1004-0000-5102-CF3F3A09B77D}'
        # Uninstall ACAD Private
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1001-0000-3102-CF3F3A09B77D}'
        # Uninstall AutoCAD 2018 - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1001-0409-2102-CF3F3A09B77D}'
        # Uninstall Autodesk AutoCAD Civil 3D 2018
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1000-0000-0102-CF3F3A09B77D}'
        # Uninstall Autodesk AutoCAD Civil 3D 2018 Language Pack - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1000-0409-1102-CF3F3A09B77D}'
        # Uninstall AutoCAD Architecture 2018 Shared
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1004-0000-4102-CF3F3A09B77D}'
        # Uninstall AutoCAD Architecture 2018 Language Shared - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1004-0409-4102-CF3F3A09B77D}'
        # Uninstall Autodesk AutoCAD Map 3D 2018 Core
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1002-0000-0102-CF3F3A09B77D}'
        # Uninstall Autodesk AutoCAD Map 3D 2018 Language Pack - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1002-0409-1102-CF3F3A09B77D}'
        # Uninstall Autodesk Vehicle Tracking 2018 (64 bit) Core
        #Execute-MSI -Action Uninstall -Path '{9BB641F3-24B1-427E-A850-1C02157219EC}'
        # Uninstall Autodesk AutoCAD Civil 3D 2018 Private Pack
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1000-0000-3102-CF3F3A09B77D}'
        # Uninstall Autodesk AutoCAD Civil 3D 2018 - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1000-0409-2102-CF3F3A09B77D}'
        # Uninstall AutoCAD Electrical 2018
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1007-0000-0102-CF3F3A09B77D}'
        # Uninstall AutoCAD Electrical 2018 Language Pack - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1007-0409-1102-CF3F3A09B77D}'
        # Uninstall ACADE Private
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1007-0000-3102-CF3F3A09B77D}'
        # Uninstall AutoCAD Electrical 2018 Content Pack
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1007-0000-5102-CF3F3A09B77D}'
        # Uninstall AutoCAD Electrical 2018 Content Language Pack - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1007-0409-6102-CF3F3A09B77D}'
        # Uninstall AutoCAD Electrical 2018 - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1007-0409-2102-CF3F3A09B77D}'
        # Uninstall AutoCAD Mechanical 2018
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1005-0000-0102-CF3F3A09B77D}'
        # Uninstall AutoCAD Mechanical 2018 Language Pack - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1005-0409-1102-CF3F3A09B77D}'
        # Uninstall ACM Private
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1005-0000-3102-CF3F3A09B77D}'
        # Uninstall AutoCAD Mechanical 2018 - English
        #Execute-MSI -Action Uninstall -Path '{28B89EEF-1005-0409-2102-CF3F3A09B77D}'



		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		## <Perform Post-Uninstallation tasks here>


	}

	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
