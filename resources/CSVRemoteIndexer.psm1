function Get-NewCSVRemoteIndexer(){
    return [CSVRemoteIndexer]::new()
}

class CSVRemoteIndexer {

    CSVRemoteIndexer(){
    
    }

    [System.Object] importFile([String] $inputFolder){
        try{
            $file = Get-ChildItem -Path $inputFolder | 
            Where-Object {($_.Name -match (Get-Date -Format yyyyMMdd) -and ($_.Extension -like ".csv"))}
            if ($file.count -gt 1){
                exit 1
                "$(Get-Date) [ImportFile] $PSitem too many CSV Files with current date in name" >> $Global:logFile
            }
            return import-csv -path $file.FullName -Delimiter "," -Header "Values"
        } catch {
            "$(Get-Date) [ImportFile] $PSitem error with File import" >> $Global:logFile
            return $null
        }
    }

    [Array] getDomainsFromSourceFile($file){
        [System.Collections.ArrayList]$exportFile = @()
        $csvIndexDomains += $file | where-object {
            $_.Values -Match "(?:^@)([A-Za-z0-9.-]+\.[A-Za-z]{2,}\b)"
        }

        for ($i=0; $i -le ($csvIndexDomains.Count-1); $i++){
            $exportFile.Add([PSCustomObject]@{
                                ID = $i
                                Value = ($csvIndexDomains[$i]).Values.Replace("@","")
            })
        }

        return $exportfile | convertto-csv -notypeinformation -Delimiter "|" | ForEach-Object {$_ -replace '"',''} 
    }

    [Array] getEmailsFromSourceFile($file){
        [System.Collections.ArrayList]$exportFile = @()
        $csvIndexEmails = $file | where-object {
            $_.Values -Match "^(?!this_is_the)^(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b)" 
        }
        for ($i=0; $i -le ($csvIndexEmails.Count-1); $i++){
            $exportFile.Add([PSCustomObject]@{
                                ID = $i
                                Value = ($csvIndexEmails[$i]).Values.Replace("@","")
            })
        }

        return $exportfile | convertto-csv -notypeinformation -Delimiter "|" | ForEach-Object {$_ -replace '"',''} 
    }

    indexer($input, $indexProfileName, $indexDestinationFolder){
        $cmdoutput = $input | & 'D:\app\SymantecDLP\Protect\bin\RemoteEDMIndexer.exe' "profile='$indexProfileName.edm'" "-ignore_date" "-result=$indexDestinationFolder" "-verbose" > $Global:logFile 2>&1
        $outputsplit = $cmdoutput.split("[")
        $outputsplit = $outputsplit.split("],")
        $outputsplit = $outputsplit.split(";")

        $outputLog = $outputsplit[0] , $outputsplit[1]

        Write-Output $outputLog | set-content "$Global:resourcespath\Result_$indexProfileName.log"
    }
}
