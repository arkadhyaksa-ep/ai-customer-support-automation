
# AI Customer Support Automation
# Duplicate-submission / idempotency test
#
# First request:  HTTP 201 created
# Second request: HTTP 200 already_exists
# Expected: Exactly one main-table record

$webhookUrl = "http://localhost:5678/webhook-test/ai-support-capstone-v1"

# Change this ID if it has already been used.
$ticketId = "DEMO-REPLAY-001"

$body = @{
    ticket_id = $ticketId
    customer_name = "Replay Test Customer"
    message = "I was charged twice for my subscription."
} | ConvertTo-Json

function Send-TestRequest {
    param(
        [string]$Label
    )

    Write-Host "`n$Label"

    try {
        $response = Invoke-WebRequest `
            -Uri $webhookUrl `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -ErrorAction Stop

        Write-Host "HTTP Status:" $response.StatusCode
        Write-Host "Response:" $response.Content

    } catch {
        Write-Host "Request failed:" $_.Exception.Message

        if ($_.Exception.Response) {
            Write-Host "HTTP Status:" ([int]$_.Exception.Response.StatusCode)
        }
    }
}

Send-TestRequest -Label "Request 1: Create ticket"
Send-TestRequest -Label "Request 2: Replay identical ticket"
