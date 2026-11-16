
# AI Customer Support Automation
# Example: Successful billing inquiry
# Expected: HTTP 201, category billing, team Finance

$webhookUrl = "http://localhost:5678/webhook-test/ai-support-capstone-v1"

# Use a fresh ticket ID for each new test.
$ticketId = "DEMO-BILLING-001"

$body = @{
    ticket_id = $ticketId
    customer_name = "Demo Customer"
    message = "I was charged twice for my monthly subscription."
} | ConvertTo-Json

Write-Host "Submitting ticket: $ticketId"

try {
    $response = Invoke-WebRequest `
        -Uri $webhookUrl `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -ErrorAction Stop

    Write-Host "HTTP Status:" $response.StatusCode
    Write-Host "Response:"
    Write-Host $response.Content

} catch {
    Write-Host "Request failed:" $_.Exception.Message

    if ($_.Exception.Response) {
        Write-Host "HTTP Status:" [int]$_.Exception.Response.StatusCode
    }
}
