$Stack = New-Object System.Collections.Stack

            $tokens = @()
            $errors = @()

$Statements  = @()
$Statements += 'IfStatementAst'
$Statements += 'SwitchStatementAst'
$Statements += 'ForStatementAst'
$Statements += 'ForEachStatementAst'
$Statements += 'DoUntilStatementAst'
$Statements += 'DoWhileStatementAst'
$Statements += 'WhileStatementAst'

$Output = @()

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Text;

namespace ThinkMS.PowerShell.PSAnalysis
{
    
    
    public enum TokenType
    {
        Unknown = 0,
        Script = 1,
        FunctionDefinition = 2,
        Function = 3,
        Command = 4,
        Statement = 5
    }

    public class Token
    {
        public TokenType Type;
        public string Name;
        public int StartLineNbr;
        public int EndLineNbr;
        public int StartColumnNbr;
        public int EndColumnNbr;
        public List<Token> Childs;

        public Token() {
            this.Childs = new List<Token>();
            this.Type = TokenType.Unknown;
        }

        public Token(TokenType type, string name) {
            this.Childs = new List<Token>();
            this.Type = TokenType.Unknown;
            this.Type = type;
            this.Name = name;
        }

        public Token(TokenType type, string name, int startLineNbr, int endLineNbr, int startColumnNbr, int endColumnNbr) {
            this.Childs = new List<Token>();
            this.Type = TokenType.Unknown;
            this.Type = type;
            this.Name = name;
            this.StartLineNbr = startLineNbr;
            this.EndLineNbr = endLineNbr;
            this.StartColumnNbr = startColumnNbr;
            this.EndColumnNbr = endColumnNbr;
        }
    }
}
"@

Function Analyse-PowerShell {
    Param (
        [String[]] $Path
    )

    Begin {
        $AllCommands = Get-Command -All | Select-Object -ExpandProperty Name
    }

    Process {
        $Path | Get-Item -Include '*.ps1', '*.psm1'  | ForEach-Object {
            $ScriptPath = $_.FullName
            $ScriptName = $_.Name

            

            $Output += (New-Object ThinkMS.PowerShell.PSAnalysis.Token -ArgumentList ('Script', $ScriptPath))

            $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)

            $AST

            Write-Host $ScriptPath -ForegroundColor Green

            $Output.Childs.AddRange((Analyse-PSFunction -AST $AST))
        }
    }

    End {
        $Output
    }
}

Function Analyse-PSFunction {
    Param (
        $AST,
        $Depth = 1
    )

    $AST.FindAll({$true}, $false) `
    | ForEach-Object {
        $ObjectAST = $_
        $Output = $null

        Switch ($ObjectAST.GetType().Name) {
            {($Statements -contains $_) -or ($_ -eq 'FunctionDefinitionAst') -or ($_ -eq 'CommandAst' -and $ObjectAST.InvocationOperator -ne 'Dot')} {
                $Output = (New-Object ThinkMS.PowerShell.PSAnalysis.Token -ArgumentList ('Unknown', 'Null', $ObjectAST.Extent.StartLineNumber, $ObjectAST.Extent.EndLineNumber, $ObjectAST.Extent.StartColumnNumber, $ObjectAST.Extent.EndColumnNumber))
            }

            'FunctionDefinitionAst' {
                #Function
                $Output.Type = 'FunctionDefinition'
                $Output.Name = $ObjectAST.Name
                Write-Host "$('  ' * ($Depth+$Stack.Count))$($ObjectAST.Name)" -ForegroundColor Red
                $Output.Childs.AddRange((Analyse-PSFunction -AST $ObjectAST.Body -Depth ($Depth + 1)))
            }

            {$_ -eq 'CommandAst' -and $ObjectAST.InvocationOperator -ne 'Dot'} {
                $CommandName = $ObjectAST.CommandElements[0]
                $Output.Name = $CommandName.Value

                If ($AllCommands -contains $CommandName) {
                    # Loaded cmdlet
                    $Output.Type = 'Command'
                    Write-Host "$('  ' * ($Depth+$Stack.Count))$CommandName" -ForegroundColor Gray 
                } Else {
                    # External cmdlet/function
                    $Output.Type = 'Function'
                
                    Write-Host "$('  ' * ($Depth+$Stack.Count))$CommandName" -ForegroundColor Magenta
                }

                If ($CommandName.Value -eq 'ForEach-Object' -or $CommandName.Value -eq 'Where-Object') {
                    $Output.Childs.AddRange((Analyse-PSFunction -AST $ObjectAST.CommandElements[1].ScriptBlock -Depth ($Depth + 1)))
                }

                $Stack.Peek().Childs.Add($Output)    
            }

            {$Statements -contains $_} {
                # Statement (if/switch/for/foreach/while/dowhile/dountil)
                $Output.Type = 'Statement'
                $Output.Name = $_.Replace('StatementAst','')

                While ($Stack.Count -ne 0 -and ($Stack.Peek().EndLineNbr -lt $ObjectAST.Extent.StartLineNumber)) {
                    $Stack.Pop() | Out-Null   
                }
                
                Write-Host "$("  " * (($Depth + $Stack.Count)))$($_.Replace('StatementAst',''))"
                $Stack.Push($Output)
                
                
                
                #@($ObjectAST.Extent.StartLineNumber, $ObjectAST.Extent.EndLineNumber, $ObjectAST.Extent.StartColumnNumber, $ObjectAST.Extent.EndColumnNumber)})
            }
        }

        $Output
    }
}

#Analyse-PowerShell -Path C:\Users\ng4f669\Documents\Projects\LDAPGen\Sources\LDAPGen_v0.6.2_TestAnalysis\*
#Analyse-PowerShell -Path 'C:\Users\richardl\Documents\Exakis\AIRBUS\LDAP Gen\LDAP Gen v0.6.2\Run-LDAPGenerator.ps1'
Analyse-PowerShell -Path 'C:\Users\richardl\Documents\Personal\GitHub\PSAnalysis\test.ps1'