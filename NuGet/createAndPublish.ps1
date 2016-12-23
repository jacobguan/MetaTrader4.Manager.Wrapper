PARAM 
(
	[Parameter(Mandatory=$true)]
	[string] $ApiKey
)

Write-Host 'Copying missing files...'
Copy-Item ..\Libraries\mtmanapi\*.dll
Copy-Item ..\src\Release\*.dll
Copy-Item ..\src\Release\*.xml

$version = (Get-Item P23.MetaTrader4.Manager.ClrWrapper.dll).VersionInfo.FileVersion

Write-Host 'Updating MetaTrader4.Manager.Wrapper.nuspec file...'
$wrapperNuspecFile = 'MetaTrader4.Manager.Wrapper.nuspec'
[xml]$nuspec = Get-Content $wrapperNuspecFile
$nuspec.package.metadata.version = $version
$contractsDependency = $nuspec.package.metadata.dependencies.dependency | where { $_.id -eq "MetaTrader4.Manager.Contracts" }
$contractsDependency.setAttribute('version', $version)
$nuspec.Save("$pwd\$wrapperNuspecFile")

Write-Host 'Updating MetaTrader4.Manager.Contracts.nuspec file...'
$contractsNuspecFile = 'MetaTrader4.Manager.Contracts.nuspec'
[xml]$nuspec = Get-Content $contractsNuspecFile
$nuspec.package.metadata.version = $version
$nuspec.Save("$pwd\$contractsNuspecFile")

Write-Host 'Updating targets file...'
$targetsFile = 'MetaTrader4.Manager.Wrapper.targets'
[xml]$targets = Get-Content $targetsFile
$includeValue = "`$(SolutionDir)\packages\MetaTrader4.Manager.Wrapper.$version\unmanaged\*.dll"
$targets.Project.Target.ItemGroup.MyPackageSourceFile.Include = $includeValue
$targets.Save("$pwd\$targetsFile")

Write-Host 'Publishing package...'
.\nuget.exe pack $contractsNuspecFile
.\nuget.exe pack $wrapperNuspecFile
.\nuget.exe setapikey $ApiKey
.\nuget.exe push "MetaTrader4.Manager.Contracts.$version.nupkg"
.\nuget.exe push "MetaTrader4.Manager.Wrapper.$version.nupkg"

Write-Host 'Removing files...'
Remove-Item *.dll
Remove-Item *.xml
Remove-Item *.nupkg

Write-Host 'Done'