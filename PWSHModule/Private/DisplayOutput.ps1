function DisplayOutput {
	PARAM($arg)
	$index = 0
	$NLenght = ($arg | ForEach-Object {$_.name.length} | Sort-Object -Descending)[0] + 3
	$VLenght = ($arg | ForEach-Object {$_.version.length} | Sort-Object -Descending)[0] + 3
	$DescLength = $Host.UI.RawUI.WindowSize.Width - 30 - $($NLenght)

	Write-Host ('{0,2})' -f 'I') -NoNewline -ForegroundColor Gray
	Write-Host ("{0,-$($VLenght)}" -f 'Version') -NoNewline -ForegroundColor DarkRed
	Write-Host ("{0,-$($NLenght)}" -f 'Name') -NoNewline -ForegroundColor Cyan
	Write-Host ('{0}' -f 'Description') -ForegroundColor DarkYellow

	foreach ($module in $arg) {
		Write-Host ('{0,2})' -f $index) -NoNewline -ForegroundColor Gray
		Write-Host ("{0,-$($VLenght)}" -f "[$($module.Version)]") -NoNewline -ForegroundColor DarkRed
		Write-Host ("{0,-$($NLenght)}" -f $module.Name) -NoNewline -ForegroundColor Cyan
		Write-Host ('{0}...' -f ($module.Description[0..$($DescLength)] | Join-String)) -ForegroundColor DarkYellow
		$index++
	}
}