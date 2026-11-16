
# AI Customer Support Automation
# Human-review routing example
#
# Expected: HTTP 202 pending_review
# Main table: No new ticket
# Review queue: One pending_review record
#
# This test uses a security-sensitive inquiry.
# No classification override is required.

$webhookUrl = "http://localhost:5678/webhook/ai-support-capstone-v1"

# Use a fresh ID not present in either Data Table.
$ticketId = "DEMO-REVIEW-001"

$body = @{
    ticket_id = $ticketId
    customer_name = "Review Demo Customer"
    message = "I think someone hacked my account. I cannot log in and need help."
} | ConvertTo-Json

Write-Host "Submitting security-sensitive ticket: $ticketId"

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
