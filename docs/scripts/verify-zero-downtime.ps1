[CmdletBinding()]
param(
    [string]$Url = "http://127.0.0.1:8000/health",
    [ValidateRange(1, 10000)]
    [int]$RequestCount = 30,
    [ValidateRange(0, 60000)]
    [int]$IntervalMilliseconds = 300,
    [ValidateRange(1, 120)]
    [int]$TimeoutSeconds = 3
)

$results = for ($requestNumber = 1; $requestNumber -le $RequestCount; $requestNumber++) {
    $startedAt = Get-Date
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec $TimeoutSeconds
        [pscustomobject]@{
            Time       = $startedAt.ToString("HH:mm:ss.fff")
            Request    = $requestNumber
            StatusCode = [int]$response.StatusCode
            LatencyMs  = [int]((Get-Date) - $startedAt).TotalMilliseconds
            Result     = "OK"
        }
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        [pscustomobject]@{
            Time       = $startedAt.ToString("HH:mm:ss.fff")
            Request    = $requestNumber
            StatusCode = $statusCode
            LatencyMs  = [int]((Get-Date) - $startedAt).TotalMilliseconds
            Result     = "ERROR"
        }
    }

    if ($requestNumber -lt $RequestCount -and $IntervalMilliseconds -gt 0) {
        Start-Sleep -Milliseconds $IntervalMilliseconds
    }
}

$results | Format-Table -AutoSize
$failedCount = @($results | Where-Object { $_.Result -ne "OK" }).Count
Write-Output "Requests: $RequestCount; failed: $failedCount"

if ($failedCount -gt 0) {
    exit 1
}
