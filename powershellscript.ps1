
#GLOLBALE PARAMETERS
#----------------------------------------------------
# Apps script link op te halen via het appsscript bestandje > Publiceren > Implementeren als webapp > Execute app as me & Anyone has access even anonymous >> Link kopiëren en hieronder plakken die begint met "https://script..." en eindigt met "...../exec" Let er op dat de link tussen aanhalingstekens staat.

$appsScriptLink = 'PLAK-HIER-DE-GEPUBLICEERDE-LINK'


#Haal in de adminconsole het "token" op van de Organisatie waarin je de windows toestellen wil "beheren".
# Google Admin > Apparaten > Beheerde browsers > Organisatie-eenheid kiezen > Gele plusje onderaan rechts, "inschrijftoken" kopieren en hieronder tussen de aanhanlingstekens plakken.

$inschrijfToken = 'PLAK-HIER-HET-INSCHRIJVINGSTOKEN'



#Maak hieronder (tussen de aanhalingstekens) een kommagescheiden opsomming van domeinnamen die mogen gebruikt worden om in te loggen op de windowstoestellen.

#VB van een kommagescheiden lijst met domeinnamen: 'school.be,lkr.school.be,lln.school.be'
$domainListCommaSeparated = 'TYP HIER KOMMAGESCHEIDENLIJST MET DOMEINNAMEN'


#-------------------Vanaf hier start het eigenlijke script------------------------------------
#Maak het scherm leeg.
clear
#Maak map 'c:/temp' indien die nog niet bestaat
$folderExists = Test-Path C:\temp
if(!$folderExists){
New-Item -Path 'C:\temp' -ItemType Directory
Write-Host 'C:\temp werd gemaakt...'
}
else{
Write-Host 'C:\temp bestond wellicht al...'
}
#-------------------------------------------------------------------------------
#Download bestand Credential provider (installatie bestandje van Google)
$url = "https://dl.google.com/credentialprovider/gcpwstandaloneenterprise64.msi"
$outpath = "c:/temp/googlecredentialprovider.msi"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $outpath)
Write-Host 'Bestand wordt gedownload...'
$args = @("/quiet")
Start-Process -Filepath "c:/temp/googlecredentialprovider.msi" -ArgumentList $args
Write-Host 'Credential provider werd geïnstalleerd...'
Write-Host '---------------------------'
#-------------------------------------------------------------------------------
#Maak een registery key in Windows om in te stellen welke domeinen mogen inloggen op de computer -- Domains allowed to login :
$registryPath = 'HKEY_LOCAL_MACHINE\Software\Google\GCPW'
$regName = 'domains_allowed_to_login'
$domainList = $domainListCommaSeparated
[microsoft.win32.registry]::SetValue($registryPath, $regName, $domainList)
Write-Host 'Registersleutel met toegestane domeinnamen werd gemaakt'
Write-Host '---------------------------'
#-------------------------------------------------------------------------------
#Wil je een bestaande Windows gebruiker koppelen aan een GSuite account?
$linkExistingUser = Read-Host -Prompt 'Wil je een bestaand Windowsprofiel koppelen aan een GSuite user? (y/n)'
if ($linkExistingUser -eq 'y'){
#opvragen van SID van een bestaande account om die te koppelen aan een Google Account
WMIC useraccount get name,sid
$parentPath = 'HKEY_LOCAL_MACHINE\Software\Google\GCPW\'
$sid = Read-Host -Prompt 'Kopieer SID van gebruiker en plak hier'
$un = Read-Host -Prompt 'Kopieer USERNAME (windows) van gebruiker en plak hier'
$registryPath = $parentPath + $sid.Trim()
$regName = 'email'
$email = Read-Host -Prompt  'Geef GSuite email van gebruiker op'
[microsoft.win32.registry]::SetValue($registryPath, $regName, $email)
Write-Host '---------------------------'
Write-Host 'Profiel'  $sid  ' wordt gekoppeld met '  $email ' via een registersleutel.'
Write-Host '---------------------------'
$serial = (gwmi win32_bios).SerialNumber
$link = "${appsScriptLink}?email=${email}&un=${un}&sn=${serial}"
Start-Process "chrome.exe" $link
Write-Host 'Normaal wordt Chrome geopend en wordt er een aangepast kenmerk gemaakt in Google Admin via het Apps Script bestand.'
Write-Host 'Als het niet werkt, maak dan zelf een Aangepast Kenmerk in Google Admin voor de gebruiker in kwestie met als inhoud:'
Write-Host "un:${un},sn:${serial}"
Write-Host '---------------------------'
}
else{
Write-Host '---------------------------'
Write-Host "Er worden geen bestaande windowsprofielen gekoppeld. (Er worden enkel nieuwe profielen aangemaakt op Windows.)"}
#-------------------------------------------------------------------------------
#Zorg ervoor dat het toestel verschijnt in admin.google.com bij "Beheerde Browsers"
$registryPath = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome'
$regName = 'CloudManagementEnrollmentToken'
$enrollmentToken = $inschrijfToken
[microsoft.win32.registry]::SetValue($registryPath,$regName, $enrollmentToken )
Write-Host 'Registersleutel werd gemaakt om beheerde browser in te stellen...'
Write-Host '---------------------------'
#-------------------------------------------------------------------------------
# Wil je Google File Stream installeren op dit toestel?
$filestream = Read-Host -Prompt  'FileStream installeren? (y/n)'
if ($filestream -eq 'y'){
#Download and install Google Drive Filestream
#Maak map 
$folderExists = Test-Path C:\temp
if(!$folderExists){
New-Item -Path 'C:\temp' -ItemType Directory
Write-Host 'C:\temp werd gemaakt...'
}
else{
Write-Host 'C:\temp bestond al...'
}
#Download bestand
$url = "https://dl.google.com/drive-file-stream/GoogleDriveFSSetup.exe"
$outpath = "c:/temp/drivefilestream.exe"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $outpath)
#Gedownload bestand uitvoeren
$args = @("--silent","--desktop_shortcut")
Start-Process -Filepath "c:/temp/drivefilestream.exe" -ArgumentList $args
Write-Host 'Filestream werd geïnstalleerd...'
}
Write-Host '---------------------------'
$reboot = Read-Host -Prompt  'Klaar om te rebooten? (y/n)'
if ($reboot -eq 'y'){
Restart-Computer -Force}
else{
Write-Host 'Klaar! Dit venstertje mag je sluiten.'
}
