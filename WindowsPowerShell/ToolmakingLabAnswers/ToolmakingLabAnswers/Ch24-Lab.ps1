﻿#------------------------------------------------------------------------
# Source File Information (DO NOT MODIFY)
# Source ID: 4cd55487-c602-407f-b38f-de0135b0a339
# Source File: Ch24-Lab.pff
#------------------------------------------------------------------------
#========================================================================
# Code Generated By: SAPIEN Technologies, Inc., PowerShell Studio 2012 v3.0.6
# Generated On: 7/2/2012 4:57 PM
# Generated By:  Jeffery Hicks
# Organization:  http://jdhitsolutions.com/blog
#========================================================================
#----------------------------------------------
#region Application Functions
#----------------------------------------------

function OnApplicationLoad {
	#Note: This function is not called in Projects
	#Note: This function runs before the form is created
	#Note: To get the script directory in the Packager use: Split-Path $hostinvocation.MyCommand.path
	#Note: To get the console output in the Packager (Windows Mode) use: $ConsoleOutput (Type: System.Collections.ArrayList)
	#Important: Form controls cannot be accessed in this function
	#TODO: Add snapins and custom code to validate the application load
	
	return $true #return true for success or false for failure
}

function OnApplicationExit {
	#Note: This function is not called in Projects
	#Note: This function runs after the form is closed
	#TODO: Add custom code to clean up and unload snapins when the application exits
	
	$script:ExitCode = 0 #Set the exit code for the Packager
}

#endregion Application Functions

#----------------------------------------------
# Generated Form Function
#----------------------------------------------
function Call-Ch24-Lab_pff {

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load("mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formServiceReporter = New-Object 'System.Windows.Forms.Form'
	$groupbox1 = New-Object 'System.Windows.Forms.GroupBox'
	$radiobuttonAll = New-Object 'System.Windows.Forms.RadioButton'
	$radiobuttonStopped = New-Object 'System.Windows.Forms.RadioButton'
	$radiobuttonRunning = New-Object 'System.Windows.Forms.RadioButton'
	$labelComputername = New-Object 'System.Windows.Forms.Label'
	$Computername = New-Object 'System.Windows.Forms.TextBox'
	$buttonOK = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	
	
	
	
	
	
	$FormEvent_Load={
		#TODO: Initialize Form Controls here
		$Computername.Text=$env:COMPUTERNAME
	}
	
	Function Get-ServiceData {
	[cmdletbinding()]
	Param(
	[parameter(Position=0,Mandatory=$True,HelpMessage="Enter a computername")]
	[ValidateNotNullorEmpty()]
	[string]$Computername,
	[Parameter(Position=1)]
	[ValidateSet("Running","Stopped","All","%")]
	[string]$Filter="All"
	)
	
	Try {
	    Write-Verbose "Getting $filter services from $computername"
	    if ($Filter -eq "All") {
	        $filter='%'
	        Write-Verbose "Using WMI filter: state Like '$Filter'"
	    }
	    $services=Get-WmiObject -Class Win32_Service -ComputerName $Computername -filter "State Like '$Filter'"
	   	Write-Verbose "Found $($services.count) matching services"
		#write selected results to the pipeline
	 	$services | Select Name,Displayname,State,StartMode,StartName
	}
	Catch {
	    Write-Warning "Failed to get services from $Computername. $_.Exception.Message"
	}
	
	} #end function
	
	$buttonOK_Click={
		#check radio buttons to figure out what type of services to query
		if ($radiobuttonAll.Checked) {
			$filter="%"	
		}
		elseif ($radiobuttonRunning.Checked) {
			$filter="Running"	
		}
		elseif ($radiobuttonStopped.Checked) {
			$filter="Stopped"	
		}
			
		#run the command and send results to the pipeline
		Get-ServiceData -Computername $Computername.Text -Filter $filter | Out-String | Write-Host
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formServiceReporter.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonOK.remove_Click($buttonOK_Click)
			$formServiceReporter.remove_Load($FormEvent_Load)
			$formServiceReporter.remove_Load($Form_StateCorrection_Load)
			$formServiceReporter.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	#
	# formServiceReporter
	#
	$formServiceReporter.Controls.Add($groupbox1)
	$formServiceReporter.Controls.Add($labelComputername)
	$formServiceReporter.Controls.Add($Computername)
	$formServiceReporter.Controls.Add($buttonOK)
	$formServiceReporter.AcceptButton = $buttonOK
	$formServiceReporter.ClientSize = '284, 191'
	$formServiceReporter.FormBorderStyle = 'FixedDialog'
	$formServiceReporter.MaximizeBox = $False
	$formServiceReporter.MinimizeBox = $False
	$formServiceReporter.Name = "formServiceReporter"
	$formServiceReporter.StartPosition = 'CenterScreen'
	$formServiceReporter.Text = "Service Reporter"
	$formServiceReporter.add_Load($FormEvent_Load)
	#
	# groupbox1
	#
	$groupbox1.Controls.Add($radiobuttonAll)
	$groupbox1.Controls.Add($radiobuttonStopped)
	$groupbox1.Controls.Add($radiobuttonRunning)
	$groupbox1.Location = '13, 42'
	$groupbox1.Name = "groupbox1"
	$groupbox1.Size = '239, 94'
	$groupbox1.TabIndex = 3
	$groupbox1.TabStop = $False
	$groupbox1.Text = "Status Filter"
	#
	# radiobuttonAll
	#
	$radiobuttonAll.Location = '17, 60'
	$radiobuttonAll.Name = "radiobuttonAll"
	$radiobuttonAll.Size = '104, 24'
	$radiobuttonAll.TabIndex = 2
	$radiobuttonAll.Text = "All"
	$radiobuttonAll.UseVisualStyleBackColor = $True
	#
	# radiobuttonStopped
	#
	$radiobuttonStopped.Location = '17, 39'
	$radiobuttonStopped.Name = "radiobuttonStopped"
	$radiobuttonStopped.Size = '104, 24'
	$radiobuttonStopped.TabIndex = 1
	$radiobuttonStopped.Text = "Stopped"
	$radiobuttonStopped.UseVisualStyleBackColor = $True
	#
	# radiobuttonRunning
	#
	$radiobuttonRunning.Checked = $True
	$radiobuttonRunning.Location = '17, 20'
	$radiobuttonRunning.Name = "radiobuttonRunning"
	$radiobuttonRunning.Size = '104, 24'
	$radiobuttonRunning.TabIndex = 0
	$radiobuttonRunning.TabStop = $True
	$radiobuttonRunning.Text = "Running"
	$radiobuttonRunning.UseVisualStyleBackColor = $True
	#
	# labelComputername
	#
	$labelComputername.ImageAlign = 'MiddleRight'
	$labelComputername.Location = '13, 8'
	$labelComputername.Name = "labelComputername"
	$labelComputername.Size = '83, 23'
	$labelComputername.TabIndex = 2
	$labelComputername.Text = "Computername"
	$labelComputername.TextAlign = 'MiddleRight'
	#
	# Computername
	#
	$Computername.Location = '102, 8'
	$Computername.Name = "Computername"
	$Computername.Size = '150, 20'
	$Computername.TabIndex = 1
	#
	# buttonOK
	#
	$buttonOK.Anchor = 'Bottom, Right'
	$buttonOK.Location = '177, 156'
	$buttonOK.Name = "buttonOK"
	$buttonOK.Size = '75, 23'
	$buttonOK.TabIndex = 0
	$buttonOK.Text = "OK"
	$buttonOK.UseVisualStyleBackColor = $True
	$buttonOK.add_Click($buttonOK_Click)
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formServiceReporter.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formServiceReporter.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formServiceReporter.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formServiceReporter.ShowDialog()

} #End Function

#Call OnApplicationLoad to initialize
if((OnApplicationLoad) -eq $true)
{
	#Call the form
	Call-Ch24-Lab_pff | Out-Null
	#Perform cleanup
	OnApplicationExit
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmq/MYPHwfM9x/YU/3VNC+YJS
# M9egggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMdMuNLCt6chvV5D
# h0YMaf2jkaZdMA0GCSqGSIb3DQEBAQUABIIBAMQpnBeSP14J5l67vGQveLEMGPYf
# Swa7WhoCRbQEb+fQq1wviKZw86W292ZuhCNXQAp3NvtqVSg6FXKgLUEg2CymozIY
# dqH/Cx3iEXZ6TbVx8sq1s1+KodeZ58eO719wsj7I6m05CICbiXVArsNWTfTHDx/j
# 69XnKTqXG/KF+WL0hZ8KutKzVGuwZHcJG9CiuPWDhix2KSm/8pbnTsO3HhqdWVbH
# zBLLwaMcu3JHoRrLJvObCjFIPQY9L4FvJAOyHisP0F0c+9E7p2TF0fngNl9pZESS
# ocDIWvSkNAg4qM0qYW8pFWHNVwTg4R0/zsLjk11tfkLbi5928zVUpSkyWIc=
# SIG # End signature block
