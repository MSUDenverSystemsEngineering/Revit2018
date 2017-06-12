Describe 'Testing against PSScriptAnalyzer rules' {
	Context 'PSScriptAnalyzer Standard Rules' {
		$analysis = Invoke-ScriptAnalyzer -Path 'Deploy-Application.ps1'
		$scriptAnalyzerRules = Get-ScriptAnalyzerRule
		forEach ($rule in $scriptAnalyzerRules) {
			It "Should pass $rule" {
				If ($analysis.RuleName -contains $rule) {
					$analysis | Where RuleName -EQ $rule -outvariable failures | Out-Default
					$failures.Count | Should Be 0
				}
			}
		}
	}
}
