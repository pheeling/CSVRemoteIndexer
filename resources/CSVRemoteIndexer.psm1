function Get-NewCSVRemoteIndexer(){
    return [CSVRemoteIndexer]::new()
}

class CSVRemoteIndexer {

    CSVRemoteIndexer(){
    
    }

    [System.Object] importFile([String] $file){
        return import-csv -path $file -Delimiter "," -Header "Values"
    }

    [Array] getDomainsFromSourceFile($file){
        [System.Collections.ArrayList]$exportFile = @()
        $csvIndexDomains += $file | where-object {
            $_.Values -Match "(?:^@)([A-Za-z0-9.-]+\.[A-Za-z]{2,}\b)"
        }

        for ($i=0; $i -le ($csvIndexDomains.Count-1); $i++) {
            $exportFile.Add(($i,($csvIndexDomains[$i]).Values.Replace("@","")))
        }
        
        return $exportFile
    }

    [Array] getEmailsFromSourceFile($file){
        [System.Collections.ArrayList]$exportFile = @()
        $csvIndexEmails = $file | where-object {
            $_.Values -Match "^(?!this_is_the)^(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b)" 
        }
        for ($i=0; $i -le ($csvIndexEmails.Count-1); $i++) {
            $exportFile.Add(($i,($csvIndexEmails[$i]).Values))
        }
        
        return $exportFile
    }

    indexer($input, $indexProfileName, $indexDestinationFolder){
        $cmdoutput = $input | & 'd:\' "profile='$indexProfileName.edm'" "-ignore_date" "-result=$indexDestinationFolder" "-verbose" > $Global:logFile 2>&1
        $outputsplit = $cmdoutput.split("[")
        $outputsplit = $outputsplit.split("],")
        $outputsplit = $outputsplit.split(";")

        $outputLog = $outputsplit[0] , $outputsplit[1]

        Write-Output $outputLog | set-content "$Global:resourcespath\Result_$indexProfileName.log"
    }
}
