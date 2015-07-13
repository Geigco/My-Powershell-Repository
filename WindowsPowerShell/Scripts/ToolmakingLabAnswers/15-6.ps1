#The PSHTools module file

Function Get-ComputerData {

<#
.SYNOPSIS
Get computer related data

.DESCRIPTION
This command will query a remote computer and return a custom object
with system information pulled from WMI. Depending on the computer
some information may not be available.

.PARAMETER Computername
The name of a computer to query. The account you use to run this function
should have admin rights on that computer.

.PARAMETER ErrorLog
Specify a path to a file to log errors. The default is C:\Errors.txt

.EXAMPLE
PS C:\> Get-ComputerData Server01

Run the command and query Server01.

.EXAMPLE
PS C:\> get-content c:\work\computers.txt | Get-ComputerData -Errorlog c:\logs\errors.txt

This expression will go through a list of computernames and pipe each name
to the command. Computernames that can't be accessed will be written to
the log file.

#>

[cmdletbinding()]

 param(
 [Parameter(Position=0,ValueFromPipeline=$True)]
 [ValidateNotNullorEmpty()]
 [string[]]$ComputerName,
 [string]$ErrorLog="C:\Errors.txt"
 )

 Begin {
    Write-Verbose "Starting Get-Computerdata"
 }

Process {
    foreach ($computer in $computerName) {
        Write-Verbose "Getting data from $computer"
        Try {
            Write-Verbose "Win32_Computersystem"
            $cs = Get-WmiObject -Class Win32_Computersystem -ComputerName $Computer -ErrorAction Stop

            #decode the admin password status
            Switch ($cs.AdminPasswordStatus) {            
                1 { $aps="Disabled" }
                2 { $aps="Enabled" }
                3 { $aps="NA" }
                4 { $aps="Unknown" }
            }

            #Define a hashtable to be used for property names and values
            $hash=@{
                Computername=$cs.Name
                Workgroup=$cs.WorkGroup
                AdminPassword=$aps
                Model=$cs.Model
                Manufacturer=$cs.Manufacturer
            }

        } #Try

        Catch {

            #create an error message 
            $msg="Failed getting system information from $computer. $($_.Exception.Message)"
            Write-Error $msg 

            Write-Verbose "Logging errors to $errorlog"
            $computer | Out-File -FilePath $Errorlog -append
            
			} #Catch

        #if there were no errors then $hash will exist and we can continue and assume
        #all other WMI queries will work without error
        If ($hash) {
            Write-Verbose "Win32_Bios"
            $bios = Get-WmiObject -Class Win32_Bios -ComputerName $Computer 
            $hash.Add("SerialNumber",$bios.SerialNumber)

            Write-Verbose "Win32_OperatingSystem"
            $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer
            $hash.Add("Version",$os.Version)
            $hash.Add("ServicePackMajorVersion",$os.ServicePackMajorVersion)

            #create a custom object from the hash table
            $obj=New-Object -TypeName PSObject -Property $hash
			#add a type name to the custom object
        	$obj.PSObject.TypeNames.Insert(0,'MOL.ComputerSystemInfo')
			
			Write-Output $obj
            #remove $hash so it isn't accidentally re-used by a computer that causes
            #an error
            Remove-Variable -name hash
        } #if $hash
    } #foreach
} #process

 End {
    Write-Verbose "Ending Get-Computerdata"
 }
}

Function Get-VolumeInfo {

<#
.SYNOPSIS
Get information about fixed volumes

.DESCRIPTION
This command will query a remote computer and return information about fixed
volumes. The function will ignore network, optical and other removable drives.

.PARAMETER Computername
The name of a computer to query. The account you use to run this function
should have admin rights on that computer.

.PARAMETER ErrorLog
Specify a path to a file to log errors. The default is C:\Errors.txt

.EXAMPLE
PS C:\> Get-VolumeInfo Server01

Run the command and query Server01.

.EXAMPLE
PS C:\> get-content c:\work\computers.txt | Get-VolumeInfo -errorlog c:\logs\errors.txt

This expression will go through a list of computernames and pipe each name
to the command. Computernames that can't be accessed will be written to
the log file.

#>
[cmdletbinding()]

 param(
 [Parameter(Position=0,ValueFromPipeline=$True)]
 [ValidateNotNullorEmpty()]
 [string[]]$ComputerName,
 [string]$ErrorLog="C:\Errors.txt",
  [switch]$LogErrors
 )

Begin {
    Write-Verbose "Starting Get-VolumeInfo"
 }

Process {
    foreach ($computer in $computerName) {
        Write-Verbose "Getting data from $computer"
        Try {
            $data = Get-WmiObject -Class Win32_Volume -computername $Computer -Filter "DriveType=3" -ErrorAction Stop
                
            Foreach ($drive in $data) {
				Write-Verbose "Processing volume $($drive.name)"
                #format size and freespace
                $Size="{0:N2}" -f ($drive.capacity/1GB)
                $Freespace="{0:N2}" -f ($drive.Freespace/1GB)

                #Define a hashtable to be used for property names and values
                $hash=@{
                    Computername=$drive.SystemName
                    Drive=$drive.Name
                    FreeSpace=$Freespace
                    Size=$Size
                }

                #create a custom object from the hash table
                $obj=New-Object -TypeName PSObject -Property $hash
				#Add a type name to the object
				$obj.PSObject.TypeNames.Insert(0,'MOL.DiskInfo')
			
				Write-Output $obj
				
            } #foreach

            #clear $data for next computer
            Remove-Variable -Name data

        } #Try

        Catch {
            #create an error message 
            $msg="Failed to get volume information from $computer. $($_.Exception.Message)"
            Write-Error $msg 

            Write-Verbose "Logging errors to $errorlog"
            $computer | Out-File -FilePath $Errorlog -append
        }
    } #foreach computer
} #Process

 End {
    Write-Verbose "Ending Get-VolumeInfo"
 }
}

Function Get-ServiceInfo {

<#
.SYNOPSIS
Get service information

.DESCRIPTION
This command will query a remote computer for running services and write
a custom object to the pipeline that includes service details as well as
a few key properties from the associated process. You must run this command
with credentials that have admin rights on any remote computers.

.PARAMETER Computername
The name of a computer to query. The account you use to run this function
should have admin rights on that computer.

.PARAMETER ErrorLog
Specify a path to a file to log errors. The default is C:\Errors.txt

.PARAMETER LogErrors
If specified, computer names that can't be accessed will be logged 
to the file specified by -Errorlog.

.EXAMPLE
PS C:\> Get-ServiceInfo Server01

Run the command and query Server01.

.EXAMPLE
PS C:\> get-content c:\work\computers.txt | Get-ServiceInfo -logerrors

This expression will go through a list of computernames and pipe each name
to the command. Computernames that can't be accessed will be written to
the log file.

#>

[cmdletbinding()]

 param(
 [Parameter(Position=0,ValueFromPipeline=$True)]
 [ValidateNotNullorEmpty()]
 [string[]]$ComputerName,
 [string]$ErrorLog="C:\Errors.txt",
 [switch]$LogErrors
 )

 Begin {
    Write-Verbose "Starting Get-ServiceInfo"

    #if -LogErrors and error log exists, delete it.
    if ( (Test-Path -path $errorLog) -AND $LogErrors) {
        Write-Verbose "Removing $errorlog"
        Remove-Item $errorlog
    }
 }

 Process {

    foreach ($computer in $computerName) {
		Write-Verbose "Getting services from $computer"
       
        Try {
            $data = Get-WmiObject -Class Win32_Service -computername $Computer -Filter "State='Running'" -ErrorAction Stop

            foreach ($service in $data) {
				Write-Verbose "Processing service $($service.name)"
                $hash=@{
                Computername=$data[0].Systemname
                Name=$service.name
                Displayname=$service.DisplayName
                }

                #get the associated process
                Write-Verbose "Getting process for $($service.name)"
                $process=Get-WMIObject -class Win32_Process -computername $Computer -Filter "ProcessID='$($service.processid)'" -ErrorAction Stop
                $hash.Add("ProcessName",$process.name)
                $hash.add("VMSize",$process.VirtualSize)
                $hash.Add("PeakPageFile",$process.PeakPageFileUsage)
                $hash.add("ThreadCount",$process.Threadcount)

                #create a custom object from the hash table
                $obj=New-Object -TypeName PSObject -Property $hash
				#add a type name to the custom object
        		$obj.PSObject.TypeNames.Insert(0,'MOL.ServiceProcessInfo')
			
				Write-Output $obj

            } #foreach service
                
            }
        Catch {
            #create an error message 
            $msg="Failed to get service data from $computer. $($_.Exception.Message)"
            Write-Error $msg 

            if ($LogErrors) {
				Write-Verbose "Logging errors to $errorlog"
            	$computer | Out-File -FilePath $Errorlog -append
            }
        }
                   
    } #foreach computer

} #process

End {
    Write-Verbose "Ending Get-ServiceInfo"
 }
    
}

Function Get-RemoteSMBShare {

<#
.SYNOPSIS
Get SMB share information
.DESCRIPTION
This command uses the SMBShare module that is available on Windows 8 and
Windows Server 2012 to query for shared folders. This command uses
PowerShell remoting. Any remote computer you query must have remoting
enabled and be running Windows 8 or Windows Server 2012.
.PARAMETER Computername
The name of the remote computer to query. This parameter has an
alias of 'Hostname'.
.PARAMETER ErrorFile
The filename and path to log failed computers. The default is C:\Errors.txt
.EXAMPLE
PS C:\> Get-RemoteSMBShare -Computer SERVER12

Get SMBShares from SERVER12
.EXAMPLE
PS C:\> get-content computers.txt | Get-SMBRemoteShare

Pipe names from computers.txt to the command and list remote SMB
shares.

#>

[cmdletbinding()]


Param (
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a computername",
ValueFromPipeline=$True)]
[ValidateCount(1,5)]
[Alias('Hostname')]
[string[]]$ComputerName,
[string]$ErrorFile="C:\Errors.txt"
)

Begin {
    Write-Verbose "Starting Get-RemoteSMBShare"
}
Process {

    Foreach ($computer in $computername) {
        Write-Verbose "Processing $computer"
        Try {
            $shares = Invoke-Command -scriptblock {Get-SMBShare} -computername $computer -ErrorAction Stop
            $shares | Select-Object @{Name="Computername";Expression={$_.PSComputername}},
            Name,Path,Description -ErrorAction Stop
        }
        Catch {
            Write-Verbose "Logging errors to $ErrorFile"
            $Computer | Out-File -FilePath $ErrorFile -Append
            Write-Warning "Failed to retrieve SMBShares from $Computer"
        }

    } #foreach

}

End {
    Write-Verbose "Starting Get-RemoteSMBShare"
}

}

#Define some aliases for the functions
New-Alias -Name gcd -Value Get-ComputerData
New-Alias -Name gvi -Value Get-VolumeInfo
New-Alias -Name gsi -Value Get-ServiceInfo

#Export the functions and aliases
Export-ModuleMember -Function * -Alias *

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxtpKXiqhZJqwbRKq3Q6upe3d
# l6WgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFG+QAGTSP2cxM9ob
# yoVQY52PSpW1MA0GCSqGSIb3DQEBAQUABIIBAAuvT2qEajUsvy4p1ew8EZeR6ChG
# evhqtRPTk8CGVe9W2wyt7yncu7GS9DrmiBqZRyVO+v4Zb3p2VYbXLJGXdC5bZmrx
# Kbogs9gKt8tymmM5fflYxBaexY8lbqGPM+ypbCZFOXQOgLgP+7Ivr9eC2mX6DhAH
# ERSz0FPgXuHDeYl1N+bD/XRu8HNBqneZaXJ6JOufpFx5KEAH2uj63dgd5XS9iw3g
# f5TknSoSL95jaRjqm6Dk2LxGt/qQ+H1GWVixFFVfjxJYqeXTg0EL56TFVoEK8NBy
# 7s6BIaUp7CsxSQ+SgO9+2kH5jtvtRxYD52jQ4kSeDSsX7JBrlk5nBKECgpM=
# SIG # End signature block
