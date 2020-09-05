function Get-NewCSVRemoteIndexer(){
    return [CSVRemoteIndexer]::new()
}

class CSVRemoteIndexer {

    CSVRemoteIndexer(){
    
    }

    [System.Object] importFile([String] $inputFolder){
        try{
            $file = Get-ChildItem -Path $inputFolder | 
            Where-Object {($_.Name -match "BEKBDLP" -and ($_.Extension -like ".csv"))} | 
            Sort-Object LastWriteTime |
            Select-Object -last 1
            if ($file.count -gt 1){
                exit 1
                "$(Get-Date) [ImportFile] $PSitem too many CSV Files with current date in name" >> $Global:logFile
            }
            return import-csv -path $file.FullName -Delimiter "," -Header "Values"
        } catch {
            "$(Get-Date) [ImportFile] $PSitem error with File import" >> $Global:logFile
            exit 1
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
            $_.Values -Match "^(?!this_is_the)^(\b[\u0370-\u03FF\u0400-\u04FFA-Za-z0-9._%+-]+@[_A-Za-z0-9.-]+\.[A-Za-z]{2,}\b)" | 
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
        try{
            $cmdoutput = $input | & 'D:\app\SymantecDLP\SymantecDLP15.1\Indexers\15.1\Protect\bin\RemoteEDMIndexer.exe' "-profile='$Global:resourcespath\$indexProfileName.edm'" "-ignore_date" "-result='$indexDestinationFolder'" "-verbose" 2>&1
            $outputsplit = $cmdoutput.split("[")
            $outputsplit = $outputsplit.split("],")
            $outputsplit = $outputsplit.split(";")

            $outputLog = $outputsplit[0]

            $indexProfileName = ($indexProfileName.Replace("\","-")).Replace(":","-")
            "$(Get-Date) [Indexing] $indexProfileName :: $outputlog" >> $Global:logfile
        } catch {
            "$(Get-Date) [Indexing] $PSitem error with File indexing" >> $Global:logfile
        }
    }

    csvFileRetention($inputFolder){
        try{
            foreach ($file in (get-childitem -path $inputFolder | Where-Object {$_.lastwritetime -lt ( (get-date).adddays(-30))} )) {
                "$(Get-Date) [Retention]  Purging old inputfile:: $file" >> $Global:logFile 
                Remove-item -path $file.Fullname
            }
        } catch {
            "$(Get-Date) [Retention] $PSitem error with File retention" >> $Global:logFile
        }
    }
}
