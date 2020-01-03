Param(
    [Parameter(Mandatory=$true, HelpMessage = "Please enter CSV Input Directory e.g. C:\Temp")]
    [String]$csvInputFolder,

    [Parameter(Mandatory=$true, HelpMessage = "Please enter File Path Indexing Destination?")]
    [String]$indexDestinationFolder
)

$Global:srcPath = split-path -path $MyInvocation.MyCommand.Definition 
$Global:mainPath = split-path -path $srcPath
$Global:resourcespath = join-path -path "$mainPath" -ChildPath "resources"
$Global:errorVariable = "Stop"
$Global:logFile = "$resourcespath\processing.log"

<#Requirementcheck PartnerCenter Module
if (!(Get-Module -ListAvailable -Name PartnerCenter)) {
    try {
        Install-Module -Name PartnerCenter
    } catch {
        Write-Host "Error while installing Partner Center Module"
        exit
    }
}#>

Import-Module -Force "$resourcespath\ErrorHandling.psm1"
Import-Module -Force "$resourcespath\CSVRemoteIndexer.psm1"

"$(Get-Date) [START] script" >> $Global:logFile

$csvIndexing = Get-NewCSVRemoteIndexer
$csv = $csvIndexing.importFile($csvInputFolder)
$inputDomains = $csvIndexing.getDomainsFromSourceFile($csv)
$inputEmails = $csvIndexing.getEmailsFromSourceFile($csv)
$csvIndexing.indexer($inputDomains, "DomainExceptions", $indexDestinationFolder)
$csvIndexing.indexer($inputEmails, "EmailExceptions", $indexDestinationFolder)
$csvIndexing.csvFileRetention($csvInputFolder)

"$(Get-Date) [STOP] script" >> $Global:logFile

