
# AI Customer Support Automation
# Conflicting submission test
#
# Request 1: HTTP 201 created
# Request 2: HTTP 409 conflict
#
# Expected: Original ticket remains unchanged.

$webhookUrl = "http://localhost:5678/webhook/ai-support-capstone-v1"

# Use a fresh ID not present in either Data Table.
$ticketId = "DEMO-CONFLICT-001"

function Send-Ticket {
    param(
        [string]$Label,
        [string]$Message
    )

    $body = @{
        ticket_id = $ticketId
        customer_name = "Conflict Test Customer"
        message = $Message
    } | ConvertTo-Json

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

Send-Ticket `
    -Label "Request 1: Create original ticket" `
    -Message "I was charged twice for my subscription."

Send-Ticket `
    -Label "Request 2: Submit conflicting ticket" `
    -Message "My package has not arrived."
