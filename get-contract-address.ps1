# Script to get contract address from deployment and set it in frontend .env

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "Contract Address Helper" -ForegroundColor Cyan
Write-Host "==================================================`n" -ForegroundColor Cyan

$contractAddress = $null

# Check Foundry broadcast directory
$broadcastPath = "broadcast\DeployDonationPlatform.s.sol\44787\run-latest.json"
if (Test-Path $broadcastPath) {
    Write-Host "Found Foundry deployment files..." -ForegroundColor Green
    try {
        $broadcast = Get-Content $broadcastPath -Raw | ConvertFrom-Json
        # Try to find contract address in transactions
        foreach ($tx in $broadcast.transactions) {
            if ($tx.contractAddress) {
                $contractAddress = $tx.contractAddress
                break
            }
        }
        # Also check in receipts
        if (!$contractAddress -and $broadcast.receipts) {
            foreach ($receipt in $broadcast.receipts) {
                if ($receipt.contractAddress) {
                    $contractAddress = $receipt.contractAddress
                    break
                }
            }
        }
    } catch {
        Write-Host "Error reading broadcast file: $_" -ForegroundColor Yellow
    }
}

# Check Hardhat deployments
if (!$contractAddress -and (Test-Path "deployments")) {
    $deploymentFiles = Get-ChildItem -Path "deployments" -Filter "*.json"
    if ($deploymentFiles.Count -gt 0) {
        $deploymentFile = $deploymentFiles[0]
        Write-Host "Found Hardhat deployment file: $($deploymentFile.Name)" -ForegroundColor Green
        try {
            $deployment = Get-Content $deploymentFile.FullName | ConvertFrom-Json
            if ($deployment.contractAddress) {
                $contractAddress = $deployment.contractAddress
            }
        } catch {
            Write-Host "Error reading deployment file: $_" -ForegroundColor Yellow
        }
    }
}

if ($contractAddress) {
    Write-Host "`n✅ Contract Address: $contractAddress" -ForegroundColor Green
    Write-Host ""
    
    $envPath = "frontend\.env"
    $envExists = Test-Path $envPath
    
    if ($envExists) {
        Write-Host "Updating $envPath..." -ForegroundColor Yellow
        $envContent = Get-Content $envPath
        $envContent = $envContent | Where-Object { $_ -notmatch "^VITE_CONTRACT_ADDRESS=" }
        $envContent += "VITE_CONTRACT_ADDRESS=$contractAddress"
        $envContent | Set-Content $envPath
        Write-Host "✅ Updated $envPath" -ForegroundColor Green
    } else {
        Write-Host "Creating $envPath..." -ForegroundColor Yellow
        "VITE_CONTRACT_ADDRESS=$contractAddress" | Out-File -FilePath $envPath -Encoding utf8
        Write-Host "✅ Created $envPath" -ForegroundColor Green
    }
    
    Write-Host "`n⚠️  IMPORTANT: Restart your frontend dev server for changes to take effect!`n" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ No deployment found!`n" -ForegroundColor Red
    Write-Host "Please deploy the contract first:" -ForegroundColor Yellow
    Write-Host "  ./deploy.sh" -ForegroundColor White
    Write-Host "  OR" -ForegroundColor White
    Write-Host "  forge script script/DeployDonationPlatform.s.sol:DeployDonationPlatform --rpc-url alfajores --broadcast -vvvv" -ForegroundColor White
    Write-Host ""
    Write-Host "After deployment, run this script again to update frontend/.env`n" -ForegroundColor Yellow
}
