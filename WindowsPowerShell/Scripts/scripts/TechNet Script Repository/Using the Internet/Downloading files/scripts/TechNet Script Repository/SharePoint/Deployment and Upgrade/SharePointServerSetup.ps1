param([switch]$setWebPartProperties, [switch]$crawlSources, [switch]$createSources, [switch]$allSteps, [string]$configDir = "config")


function main()
{
    if($allSteps)
    {
        $setWebPartProperties = $true
        $crawlSources = $true
        $createSources = $true
    }

    $installEnv = $env:FS4SPINSTALLENV
    $FASTContentSSA = $env:FASTContentSSA
    if($FASTContentSSA.length -eq 0)
    {
        "You must setup the environment variable FASTContentSSA. Modify and execute the file SetupEnvironment.ps1"
        return
    }

    $FASTSearchCenter = $env:FASTSearchCenter
    if($FASTContentSSA.length -eq 0)
    {
        "You must setup the environment variable FASTSearchCenter. Modify and execute the file SetupEnvironment.ps1"
        return
    }

    if($installEnv.length -gt 0)
    {
        # Set the farm properties
        #cd ".\Scripts\TechNet Script Center\Deployment and Upgrade"
        #.\Set-FarmProperties.ps1 -ConfigurationFile ".\..\..\..\SharePoint\$configDir\Properties-$installEnv.config"
        #cd ..\..\..

        #Reload the BDC Model
        #cd ".\Scripts\SharePoint"
        #.\Import-BDCModel.ps1 -modelFilePath ".\..\..\SharePoint\$configDir\Model.xml" -serviceContextUrl "http://localhost" -entityNamespace "http://www.microsoft.com" -entityName "Entity1" -modelName "ModelName"
        #cd ..\..
        if($createSources)
        {
            cd ".\scripts\TechNet Script repository\SharePoint\Search Management"
            $contentSourceFile = "..\..\..\..\$configDir\SharePoint\ContentSources.xml"
            if (($contentSourceFile.length -gt 0) -and (test-path "$contentSourceFile"))
            {
                .\Import-SharePointEnterpriseCrawlerSettings.ps1 -importFile $contentSourceFile -SearchApplication $FASTContentSSA
                Write-Host "Sleep until content sources are created"
                Start-Sleep -m 20000
            }
            else
            {
                "Could not find content source file: $contentSourceFile"
            }
            cd ..\..\..\..

        }
        if($crawlSources)
        {
            cd ".\scripts\TechNet Script repository\SharePoint\Search Management"
            .\CrawlAllContentSources.ps1 -SearchServiceApplication $FASTContentSSA
            cd ..\..\..\..
            "Done starting crawl of content sources"
        }

        # If the content source exists then remove the content source on the Content SSA
        #cd ".\Scripts\SharePoint"
        #.\Remove-SPEnterpriseSearchCrawlContentSource.ps1 -SSAName "FAST Content SSA" -contentSourceName "Model Content Source"
        #cd ..\..

        # Create the content source on the Content SSA
        #cd ".\Scripts\SharePoint"
        #.\New-SPEnterpriseSearchCrawlContentSourceLOB.ps1 -SSAName "FAST Content SSA" -contentSourceName "Model Content Source" -LobSystemInstanceName "LOBInstanceName" -LobSystemName "LOBSystemName"
        #cd ..\..

        # Deploy the web part 
        #cd ".\Scripts\SharePoint"
        #.\RedeploySolution.ps1
        #cd ..\..
        if($setWebPartProperties)
        {
            "Starting setup of web part properties"
            cd ".\scripts\TechNet Script repository\SharePoint\Search Management"
            $webPartConfigFile = ".\..\..\..\..\$configDir\SharePoint\Set-WebPartProperties.xml"
            if (($webPartConfigFile.length -gt 0) -and (test-path "$webPartConfigFile"))
            {
                .\Set-WebPartProperties.ps1 -configfile $webPartConfigFile -sitenameinput $FASTSearchCenter
            }
            cd ..\..\..\..
        }
    }
    else
    {
        "You must run SetupEnvironment.ps1 first" 
    }
}

main 




# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOFmRauBCuaxhebCPSl5yONrs
# eyugggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDLl+HL9bGOy4fHY
# NH/R90UcvJjKMA0GCSqGSIb3DQEBAQUABIIBALwj/+1nFWma9XOfgda7IsP2fhqH
# lx7B3Mmr0aOdOyK7Q8eibZ9kK/PimNhgb8MnsWnYhu+w4fzbv8Vwc9sCV7AoPmyP
# JaZBvUkSD8a8cZ12MxX9Eh1qTYbzSssmwp2TZyFkTsoTWqo+y7rp04774sVcNc7O
# uYmpJPD6ni/NPoYT0d77dFd2IPuh+CHMh2nz4gWYD6+loz+gZyn1EF3D9/0qRUJg
# Epn1deAt1t6xRfIWd8gpzyJXZhipdjCVv+FOkkN4cGG6y1qIqCIveXRVGI/fguQ5
# RmwAMhm2OGVJ/oiT5rnKw6kTKYSpX2rzesvCnHzH89MqGiiDcKUqPEkU96s=
# SIG # End signature block
