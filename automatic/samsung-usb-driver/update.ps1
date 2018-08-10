import-module au

$releases = 'https://developer.samsung.com/galaxy/others/android-usb-driver-for-windows'

function global:au_GetLatest {
$download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing

$re  = ".*actId=(.+?)$"
$url = $download_page.links | ? href -match $re | select -First 1 -expand href

if ($url -match $re)
    {
        $downloadid = $matches[1]
    }

$url = 'https://developer.samsung.com/common/download.do?actId=' + $downloadid


$re  = '<span class="sd2_page_title_side">(.+?)</span>'
if ($download_page.Content -match $re)
    {
        $date = $matches[1]
    }

if (!(Test-Path "date.txt")) {
   'No date' | Out-File -filepath date.txt       
}
$packageDate = Get-Content date.txt


if ($date -ne $packageDate)
    {
        "Date mismatch: new version may be available"
        $date | Out-File -filepath date.txt
		git add date.txt
		git commit -m "Update samsung-usb-driver software release date"
		git push origin master
		

        "Downloading file to get version"
        if (Test-Path "$env:TEMP\au\file") {
          Remove-Item -path "$env:TEMP\aufile"
        }
        Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\aufile"

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        function Unzip
        {
            param([string]$zipfile, [string]$outpath)

            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
        }

        if (Test-Path "$env:TEMP\auoutdir") {
          Remove-Item -path "$env:TEMP\auoutdir" -recurse
        }
        Unzip "$env:TEMP\aufile" "$env:TEMP\auoutdir"

        $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$env:TEMP\auoutdir\SAMSUNG_USB_Driver_for_Mobile_Phones.exe").FileVersion

    }
    else{
    [xml]$nuspec = Get-Content 'samsung-usb-driver.nuspec'
    $version = $nuspec.package.metadata.version
    }
    @{
       URL32   = $url
       Version = $version
    }
}

function global:au_SearchReplace {
    @{
        ".\tools\chocolateyinstall.ps1" = @{
          "(url\s*=\s*)('.*')"      = "`$1'$($Latest.URL32)'"
		  "(checksum\s*=\s*)('.*')"      = "`$1'$($Latest.Checksum32)'"
        }
    }
}

update