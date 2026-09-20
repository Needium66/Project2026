param(
    [Parameter(Mandatory)][string]$ProjectId,
    [Parameter(Mandatory)][string]$GithubRepo,
    [string]$PoolId       = "github-pool",
    [string]$ProviderId   = "github-provider",
    [string]$DeployerName = "github-deployer"
)

Write-Host "`n-- Step 1: Check / create pool --" -ForegroundColor Cyan
$poolExists = gcloud iam workload-identity-pools describe $PoolId `
    --location=global --project=$ProjectId 2>$null
if ($poolExists) {
    Write-Host "Pool '$PoolId' already exists - skipping." -ForegroundColor Green
} else {
    gcloud iam workload-identity-pools create $PoolId `
        --location=global `
        --display-name="GitHub Actions Pool" `
        --project=$ProjectId
}

Write-Host "`n-- Step 2: Check / create provider --" -ForegroundColor Cyan
$providerExists = gcloud iam workload-identity-pools providers describe $ProviderId `
    --workload-identity-pool=$PoolId `
    --location=global --project=$ProjectId 2>$null
if ($providerExists) {
    Write-Host "Provider '$ProviderId' already exists - skipping." -ForegroundColor Green
} else {
    gcloud iam workload-identity-pools providers create-oidc $ProviderId `
        --location=global `
        --workload-identity-pool=$PoolId `
        --issuer-uri="https://token.actions.githubusercontent.com" `
        --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.actor=assertion.actor" `
        --attribute-condition="assertion.repository=='$GithubRepo'" `
        --project=$ProjectId
}

Write-Host "`n-- Step 3: Check / create deployer service account --" -ForegroundColor Cyan
$saEmail = "$DeployerName@$ProjectId.iam.gserviceaccount.com"
$saExists = gcloud iam service-accounts describe $saEmail `
    --project=$ProjectId 2>$null
if ($saExists) {
    Write-Host "Service account '$saEmail' already exists - skipping." -ForegroundColor Green
} else {
    gcloud iam service-accounts create $DeployerName `
        --display-name="GitHub Actions Deployer" `
        --project=$ProjectId
}

Write-Host "`n-- Step 4: Bind pool to service account --" -ForegroundColor Cyan
$ProjectNumber = gcloud projects describe $ProjectId --format="value(projectNumber)"
gcloud iam service-accounts add-iam-policy-binding $saEmail `
    --role="roles/iam.workloadIdentityUser" `
    --member="principalSet://iam.googleapis.com/projects/$ProjectNumber/locations/global/workloadIdentityPools/$PoolId/attribute.repository/$GithubRepo" `
    --project=$ProjectId

Write-Host "`n-- Outputs - paste these into GitHub secrets --" -ForegroundColor Yellow

$wifProvider = gcloud iam workload-identity-pools providers describe $ProviderId `
    --workload-identity-pool=$PoolId `
    --location=global `
    --project=$ProjectId `
    --format="value(name)"

Write-Host ""
Write-Host "WIF_PROVIDER        = $wifProvider"
Write-Host "WIF_SERVICE_ACCOUNT = $saEmail"
Write-Host ""
Write-Host "-- Done. Copy the two values above into GitHub Secrets --" -ForegroundColor Green