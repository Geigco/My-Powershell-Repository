#requires -version 2.0
if (!(Test-Path alias:streams)) {Set-Alias streams Get-Streams}

function Get-Streams {
  <#
    .SYNOPSIS
        Enumerates alternate NTFS data streams.
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$Path,
    
    [Parameter(Position=1)]
    [Switch]$Delete
  )
  
  begin {
    [accelerators]::Add('Marshal', [Runtime.InteropServices.Marshal])
    #CreateFile and DeleteFile
    [Object].Assembly.GetType('Microsoft.Win32.Win32Native').GetMethods(
      [Reflection.BindingFlags]40
    ) | ? { $_.Name -match '\A(Create|Delete)File\Z'} | % {
      Set-Variable $_.Name $_
    }
    
    $IO_STATUS_BLOCK = struct IO_STATUS_BLOCK {
      UInt32 'Status';
      UInt64 'Information';
    }
    
    $FILE_STREAM_INFORMATION = struct FILE_STREAM_INFORMATION {
      UInt32 'NextEntryOffset';
      UInt32 'StreamNameLength';
      UInt64 'StreamSize';
      UInt64 'StreamAllocationSize';
      Byte[] 'StreamName ByValArray 2';
    }
    
    $NtQueryInformationFile = delegate ntdll.dll NtQueryInformationFile Int32 @(
      [Microsoft.Win32.SafeHandles.SafeFileHandle], $IO_STATUS_BLOCK.MakeByRefType(),
      [IntPtr], [UInt32], [UInt32]
    )
    
    $RtlNtStatusToDosError = delegate ntdll.dll RtlNtStatusToDosError Int32 @([Int32])
    
    $GetLastError = {
      param([Int32]$status)
      
      (New-Object ComponentModel.Win32Exception(
        $(switch ($status -eq 0) {
          $true  { [Marshal]::GetLastWin32Error() }
          $false { $RtlNtStatusToDosError.Invoke($status) }
        })
      )).Message
    }
    
    $FileStreamInformation      = 0x00000016
    $GENERIC_READ               = 0x80000000
    $FILE_FLAG_BACKUP_SEMANTICS = 0x02000000
    $STATUS_SUCCESS             = 0x00000000
    $STATUS_BUFFER_OVERFLOW     = 0x80000005
    
    $Path = Convert-Path $Path
    $ntstatus = $STATUS_BUFFER_OVERFLOW
    $block = 1024 * 16
  }
  process {
    $sfh = $CreateFile.Invoke($null, @(
      $Path, $GENERIC_READ, 3, $null, 3, $FILE_FLAG_BACKUP_SEMANTICS, [IntPtr]::Zero
    ))
    if ($sfh.IsInvalid) {
      $GetLastError.Invoke(0)
      return
    }
    
    $isb = [Activator]::CreateInstance($IO_STATUS_BLOCK)
    
    while ($ntstatus -eq $STATUS_BUFFER_OVERFLOW) {
      $buf = New-Object "Byte[]" $block
      
      $ptr = [Marshal]::UnsafeAddrOfPinnedArrayElement($buf, 0)
      $ntstatus = $NtQueryInformationFile.Invoke($sfh, [ref]$isb, $ptr, $block, $FileStreamInformation)
      if ($ntstatus -eq $STATUS_BUFFER_OVERFLOW) {
        $block *= 2
      }
      else { break }
    } #while
    
    if ($ntstatus -eq $STATUS_SUCCESS) {
      $printed = $false #file name is already printed
      while ($true) {
        $fsi = $ptr -as $FILE_STREAM_INFORMATION
        $itm = [IntPtr]([Marshal]::OffsetOf($fsi.GetType(), 'StreamName').ToInt64() + $ptr.ToInt64())
        $nam = [Marshal]::PtrToStringUni($itm, [Int32]($fsi.StreamNameLength / 2))
        #ignore standard data
        if (!$nam.Equals('::$DATA') -and $fsi.StreamNameLength -ne 0) {
          if (!$printed) {
            $Path + ':'
            $printed = $true
          }
          #delete streams
          if ($Delete) {
            if ($DeleteFile.Invoke($null, @($Path + $nam))) {
              "`tDeleted {0}" -f $nam
            }
            else { $GetLastError.Invoke(0) }
          }
          else { "`t{0} {1}" -f $nam, $fsi.StreamSize }
        }
        if ($fsi.NextEntryOffset -eq 0) { break }
        $ptr = [IntPtr]($ptr.ToInt64() + $fsi.NextEntryOffset)
      } #while
    }
    else { $GetLastError.Invoke($ntstatus) }
    
    $sfh.Close()
  }
  end {
    [void][accelerators]::Remove('Marshal')
  }
}

Export-ModuleMember -Alias streams -Function Get-Streams

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU73NrRORW6XUs0bUZVENznH7i
# 0FOgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAN0ZOWCIOEyhtxA/koB0azqKK40Pw3fa8GLif/ZM0cXJWGawkVgxOMbejeJW
# YCqXgEHF2MX/cJY8svCmLlX8M7AdjXYgtAS+C+cEHxrGAMMzj3/9EOu6DjzxIcwL
# l1GKoUwy8X3/GRGk3sBWT5CwKYRJdh9goWy74ltZN+sTKKeDHqpfuvxye6c++PC7
# 86wzm4MwfOIuPE9StFeo/0nKheEukfK9cpthlE5dUHpW0OjmJdX/g0mEdIjm2/Q2
# 50fzQyLQXOuMVIJ4Qk2comMDNRvZZvSPOBwWZ6fAR4tXfZwlpUcLv3wBbIjslhT7
# XasCm73TdBj+ZFDx2tUtpWguP/0CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBS+FASXsrRle2tLXdkVyoT1Dbw7
# QDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAbhjcmv+WCZwWCIYQwiEsH94SesBr0cPqWjEtJrBefqU9zFdB
# u5oc/WytxdCkEj5bxkoN9aJmuDAZnHNHBwIYeUz0vNByZRz6HsPzNPxLxThajJTe
# YOHlSTMI/XzBhJ7VzCb3YFhkD5f9gcJ5n+Z94ebd/1SoIvc9iwC3tTf5x2O7aHPN
# iyoWLTV4+PgDntCy/YDj11+uviI9sUUjAajYPEDvoiWinyT+7RlbStlcEuBwqvqT
# nLaiRsK17rjawW87Nkq/jB8rymUR/fzluIpHmPA4P0NazH4v5f62mpMFqdk0osMU
# QJ/qqACQ+2+/eAw7Gr6igNvlsxQpPfxsPNtUkTCCBTAwggQYoAMCAQICEAQJGBtf
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
# Q0ECEAYOIt5euYhxb7GIcjK8VwEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJPcUzX/n6D3gExX
# E+67UEGcyfxoMA0GCSqGSIb3DQEBAQUABIIBAEsTxg9gi4ZJ2sFHriLxpZ/yly17
# kAQcd4fTsUa+70659Ms+9tlO9CYIhoCdX65BxJYwu7TrsD4xtZ292yJEpAvcoJtl
# A/5yE8TyvjDeV559Rl1K/DuI575aEUb2WKXrxxt9E3IzMUyvN7ThfXEV9NGzzdZp
# U43XVSse0CH4tYijRWD4tgE1KY3I4fih1Bbmu715ErK8nZ3gWOC016lf02iaJhDy
# xu0tyHNrg3WzYZ8zz5PG1YnTYvB4DGDk3xH8kYmguxrnLJrJkRuxu210PK2HJvUU
# 3UTIxIN+cMlaxRxfb9vWOLuhu150G6kdN/YFJ+7Lf600pyA8//2m6ewT8wk=
# SIG # End signature block
