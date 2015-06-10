Function Declare-First {

    Write-Log 'Test'

}

Function Write-Log {
    Get-Item | Add-Content
}

if ($false) {
    $a | ForEach-Object {
        foreach ($a in $b) {
            if($true) {

            }
        }
    }
}


If ($true) {
    foreach ($item in $items) {
        
    }

    do {
        If() {
            if ($c) {

            }
        } elseif ($a) {
            foreach ($b in $c) {

            }
        } else {
            foreach ($b in $c) {

            }
        }
    } until ($false)

    switch ($true) {
        {} {
            if ($a) {
                foreach ($b in $c) {

            }
            }
        }

        '' {
            if ($a) {
            }
        }

        default {
            if ($a) {
            }
        }

    }

} else {
    Declare-First
}