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
        $csvIndex = @()
        $i = 0
        $file | where-object {
            $_.Values -Match "(?<=^@)[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b" | 
            foreach-Object{
                if($_ -ne $false){
                    $csvIndex += [PSCustomObject]@{
                        Name = $i
                        Value = $Matches[0]
                    }
                    $i++
                }
            }
        }
        return $csvIndex | convertto-csv -notypeinformation -Delimiter "|" | ForEach-Object {$_ -replace '"',''} 
    }

    [Array] getEmailsFromSourceFile($file){
        $csvIndex = @()
        $i = 0
        $file | where-object {
            $_.Values -Match "^(?!this_is_the)^(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b)" | 
            foreach-Object{
                if($_ -ne $false){
                    $csvIndex += [PSCustomObject]@{
                        Name = $i
                        Value = $Matches[0]
                    }
                    $i++
                }
            }
        }
        return $csvIndex | convertto-csv -notypeinformation -Delimiter "|" | ForEach-Object {$_ -replace '"',''}
    }

    indexer($input, $indexProfileName, $indexDestinationFolder){
        $cmdoutput = $input | & 'D:\app\SymantecDLP\Protect\bin\RemoteEDMIndexer.exe' "-profile='$indexProfileName'" "-ignore_date" "-result='$indexDestinationFolder'" "-verbose" 2>&1
        $outputsplit = $cmdoutput.split("[")
        $outputsplit = $outputsplit.split("],")
        $outputsplit = $outputsplit.split(";")

        $outputLog = $outputsplit[0]

        $indexProfileName = ($indexProfileName.Replace("\","-")).Replace(":","-")
        Write-Output $outputLog | set-content "$Global:resourcespath\Result_$indexProfileName.log"
    }
}
