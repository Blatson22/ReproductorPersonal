$base = "http://localhost:8000"

$reg = Invoke-RestMethod -Uri "$base/auth/register" -Method Post -ContentType "application/json" `
    -Body (@{ username = "ana"; password = "secreto" } | ConvertTo-Json)
$token = $reg.token
Write-Output "Token: $token"

$headers = @{ Authorization = "Bearer $token" }

Invoke-RestMethod -Uri "$base/auth/me" -Headers $headers | Format-List

Invoke-RestMethod -Uri "$base/favorites" -Method Post -ContentType "application/json" -Headers $headers `
    -Body (@{ id = "fJ9rUzIMcZQ"; title = "Bohemian Rhapsody"; uploader = "Queen" } | ConvertTo-Json)

Invoke-RestMethod -Uri "$base/favorites" -Headers $headers | Format-Table

Invoke-RestMethod -Uri "$base/history" -Method Post -ContentType "application/json" -Headers $headers `
    -Body (@{ id = "HgzGwKwLmgM"; title = "Dont Stop Me Now"; uploader = "Queen" } | ConvertTo-Json)

Invoke-RestMethod -Uri "$base/history" -Headers $headers | Format-Table