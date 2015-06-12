Function Get-Tokenization {
    <#
        .NOTES
            Author  : Richard LAZARO
            Email   : richardlazaro@think-ms.net
            Version : 00.09

            Changes tracker :
                00.09 - 2015/06/10 - Script creation

        .SYNOPSIS

        .DESCRIPTION

        .PARAMETER <Parameter-Name>

        .EXAMPLE

        .INPUTS

        .OUTPUTS

        .LINK

        .COMPONENT
    #>

    [CmdletBinding(DefaultParametersetName='All')]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ParameterSetName='FilePath')]
        [String] $FilePath,
        [Parameter(Mandatory=$True, ParameterSetName='FileAST')]
        [System.Management.Automation.Language.Ast] $FileAST
    )

    Begin {
        $FctName = $MyInvocation.MyCommand.Name

        If ($PSBoundParameters.Debug) {
            $DebugPreference = 'Continue'
        }

        If ($PSBoundParameters.Verbose) {
            $VerbosePreference = 'Continue'
        }

        If (![String]::IsNullOrEmpty($PSBoundParameters.ErrorAction)) {
            $ErrorActionPreference = $PSBoundParameters.ErrorAction
        } Else {
            $ErrorActionPreference = 'Stop'
        }

        $StatementKey  = @()
        $StatementKey += 'IfStatementAst'
        $StatementKey += 'SwitchStatementAst'
        $StatementKey += 'ForStatementAst'
        $StatementKey += 'ForEachStatementAst'
        $StatementKey += 'DoUntilStatementAst'
        $StatementKey += 'DoWhileStatementAst'
        $StatementKey += 'WhileStatementAst'

        #$Stack = New-Object System.Collections.Stack
        $Stack = @()
    }

    Process {
        Write-Verbose -Message "$FctName : <Start>"
        Write-Debug -Message "$FctName : <Start>"

        Write-Debug -Message "$FctName :   ParameterSetName = $($PSCmdlet.ParameterSetName)"
        Switch ($PSCmdlet.ParameterSetName) {
            'FilePath' {$AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)}
            'FileAST'  {$AST = $FileAST}
        }
        
        # TODO
        $Predicate = {$true}

        $AST.FindAll({$true}, $False) | ForEach-Object {
            $ObjAST = $_
            $ObjASTTypeName = $ObjAST.GetType().Name

            # TODO : Lie au predicate, objet attendu pour traitement simplification du switch

            switch ($ObjASTTypeName) {
                # All : FunctionDefinition - Cmdlet/Function - Statement
                {('FunctionDefinitionAst' -eq $_) -or ($_ -eq 'CommandAst' -and $ObjAST.InvocationOperator -ne 'Dot') -or ($StatementKey -contains $_)} {
                    Write-Debug "$FctName : $ObjASTTypeName"

                    $Token = New-Object ThinkMS.PowerShell.PSAnalysis.Token
                    $Token.StartLineNbr = $ObjAST.Extent.StartLineNumber
                    $Token.EndLineNbr = $ObjAST.Extent.EndLineNumber
                    $Token.StartColumnNbr = $ObjAST.Extent.StartColumnNumber
                    $Token.EndColumnNbr = $ObjAST.Extent.EndColumnNumber
                }

                # FunctionDefinition
                'FunctionDefinitionAst' {
                    $ObjASTName = $ObjAST.Name

                    $Token.Name = $ObjASTName
                    $Token.Type = 'FunctionDefinition'
                    
                    $ChildToken = (Get-Tokenization -FileAST $ObjAST.Body) -as [ThinkMS.PowerShell.PSAnalysis.Token[]]
                    If ($ChildToken.Count -gt 0) {$Token.Childs.AddRange($ChildToken)}
                }

                # Cmdlet/Function
                {$_ -eq 'CommandAst' -and $ObjAST.InvocationOperator -ne 'Dot'} {
                    $ObjASTName = $ObjAST.CommandElements[0].Value

                    $Token.Name = $ObjASTName
                    If ($InstanciedCommand -contains $ObjASTName) {$Token.Type = 'Command'} Else {$Token.Type = 'Function'}
                    
                    If ('ForEach-Object', 'Where-Object' -contains $ObjASTName) {
                        $ChildToken = (Get-Tokenization -FileAST $ObjAST.CommandElements[1].ScriptBlock) -as [ThinkMS.PowerShell.PSAnalysis.Token[]]
                        If ($ChildToken.Count -gt 0) {$Token.Childs.AddRange($ChildToken)}
                    }
                }

                # Statement
                {$StatementKey -contains $_} {
                    $Token.Name = $_.Replace('StatementAst','')
                    $Token.Type = 'Statement'
                    
                }

                # All : FunctionDefinition - Cmdlet/Function - Statement
                {('FunctionDefinitionAst' -eq $_) -or ($_ -eq 'CommandAst' -and $ObjAST.InvocationOperator -ne 'Dot') -or ($StatementKey -contains $_)} {
                    $Stack += $Token
                }
            }
        }
    }

    End {
        # TODO : Childs Item automatiquement ajouté à l'indice zero ??
        :loopStack for ($i = ($Stack.Count-1);$i -ge 0;$i--) {
            $Token = $Stack[$i]

            :loopToken for ($j = ($i -1);$j -ge 0;$j--) {
                $TokenParent = $Stack[$j]

                If (($Token.StartLineNbr -lt $TokenParent.EndLineNbr) -or ($Token.StartLineNbr -eq $TokenParent.EndLineNbr -and $Token.StartColumnNbr -lt $TokenParent.EndColumnNbr)) {
                    :loopList for ($k = 0;$k -lt $TokenParent.Childs.Count; $k++) {
                        If (($Token.StartLineNbr -lt $TokenParent.Childs[$k].StartLineNbr) -or ($Token.StartLineNbr -eq $TokenParent.Childs[$k].StartLineNbr -and $Token.StartColumnNbr -eq $TokenParent.Childs[$k].StartColumnNbr)) {
                            $TokenParent.Childs.Insert($k, $Token)
                            $Stack[$i] = $null
                            continue loopStack
                        }
                    }
                    
                    $TokenParent.Childs.Add($Token)
                    $Stack[$i] = $null
                    continue loopStack
                }
            }
        }

        Write-Output ($Stack | Where-Object {$_ -ne $null})
        Write-Debug -Message "$FctName : <End>"
    }
}
