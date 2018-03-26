cls
$path   = "input"
$file = [System.IO.File]::ReadAllText($path)
$match = ([regex]"\.rs\ (\d+)").match($file)

$count = 0
while ($match.Success)
{
    $count += $match.Groups[1].Value
    $match = $match.NextMatch()
}

$count
