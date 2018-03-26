$path   = "input"
$output = "output"
$switch = 3
$with   = 0

cls

$bytes = [System.IO.File]::ReadAllBytes($path)
$newbytes = @()

Write-Host "Initialize new array..."
for ($i = 0; $i -lt $bytes.Length; $i++)
{
    $index = $i + 1
    $total = $bytes.Length
    Write-Host "Initializing $index / $total"
    $newbytes += 0
}

$spritescount = $bytes.Length / 16

# Process each sprite
for ($i = 0; $i -lt $spritescount; $i++)
{
    $sprite = $i + 1
    Write-Host "Processing sprite $sprite / $spritescount"
    $s = $i * 16

    # Process each row
    for ($j = 0; $j -lt 8; $j++)
    {
        # Grab the first byte
        $byte0 = $bytes[$s + $j]

        # Grab the byte 8 after that
        $byte1 = $bytes[$s + $j + 8]

        $newbyte0 = 0
        $newbyte1 = 0

        # Process each pixel
        for ($k = 7; $k -ge 0; $k--)
        {
            $bit0 = ($byte0 -shr $k) -band 1    # so it's either 00000000 or 00000001
            $bit1 = ($byte1 -shr $k) -band 1    # so it's either 00000000 or 00000001
            $val = $bit0 -bor ($bit1 -shl 1)    # so it's either 0, 1, 2 or 3
                                                
            if ($val -eq $switch)
            {                             
                $val = $with              
            }                             
            elseif ($val -eq $with)       
            {                             
                $val = $switch            
            }
                                                                
            $newbit0 = $val -band 1             # so it's either 00000000 or 00000001
            $newbit1 = ($val -band 2) -shr 1    # so it's either 00000000 or 00000001
                                                
            $newbyte0 = $newbyte0 -shl 1        # switch to the left
            $newbyte0 = $newbyte0 -bor $newbit0 # set the bit

            $newbyte1 = $newbyte1 -shl 1        # switch to the left
            $newbyte1 = $newbyte1 -bor $newbit1 # set the bit
         }

         $newbytes[$s + $j] = $newbyte0
         $newbytes[$s + $j + 8] = $newbyte1
    }
}

Write-Host 
Write-Host "Writing result..."
[System.IO.File]::WriteAllBytes($output, $newbytes)

Write-Host 
Write-Host "Done."