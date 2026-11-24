param(
    [string]$TargetSave = "Dark"
)

$saveRoot = Join-Path $env:APPDATA "StardewValley\Saves"
if (-not (Test-Path $saveRoot)) {
    Write-Error "Pasta de saves nao encontrada em: $saveRoot"
    exit 1
}

$saveDirs = Get-ChildItem -Path $saveRoot -Directory
if ($TargetSave) {
    $selected = $saveDirs | Where-Object { $_.Name -like "*$TargetSave*" } | Select-Object -First 1
} else {
    $selected = $saveDirs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

if (-not $selected) {
    Write-Host "Nenhum save encontrado para '$TargetSave'."
    exit 1
}

$saveFolderName = $selected.Name
$saveFilePath = Join-Path $selected.FullName $saveFolderName

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   STARDEW VALLEY - CROPS, HARVEST & ROI ADVISOR (1.6)    " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green

[xml]$xml = [System.IO.File]::ReadAllText($saveFilePath)
$farmer = $xml.SaveGame.player
$season = $xml.SaveGame.currentSeason
$year = [int]$xml.SaveGame.year
$currentDay = [int]$xml.SaveGame.dayOfMonth
$daysRemainingInSeason = 28 - $currentDay

Write-Host "Fazendeiro(a): $($farmer.name) | Fazenda: $($farmer.farmName) Farm" -ForegroundColor Cyan
Write-Host "Data Atual: Dia $currentDay de $season (Ano $year) | Dias restantes: $daysRemainingInSeason dias" -ForegroundColor Cyan

# 1. Contabilizar Máquinas no Save (Colocadas no mapa, no inventário ou em baús)
$machineCounts = @{
    "Keg" = 0
    "Preserves Jar" = 0
    "Dehydrator" = 0
}

foreach ($loc in $xml.SaveGame.locations.GameLocation) {
    if ($loc.objects -and $loc.objects.item) {
        foreach ($it in $loc.objects.item) {
            $name = $it.value.Object.name
            if ($machineCounts.ContainsKey($name)) {
                $machineCounts[$name]++
            }
            if ($it.value.Object.items -and $it.value.Object.items.Item) {
                foreach ($cItem in $it.value.Object.items.Item) {
                    if ($cItem -and $machineCounts.ContainsKey($cItem.Name)) {
                        $stack = if ($cItem.Stack) { [int]$cItem.Stack } else { 1 }
                        $machineCounts[$cItem.Name] += $stack
                    }
                }
            }
        }
    }
}

if ($farmer.items -and $farmer.items.Item) {
    foreach ($inv in $farmer.items.Item) {
        if ($inv -and $machineCounts.ContainsKey($inv.Name)) {
            $stack = if ($inv.Stack) { [int]$inv.Stack } else { 1 }
            $machineCounts[$inv.Name] += $stack
        }
    }
}

Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "1. PARQUE INDUSTRIAL ATUAL (SUAS MAQUINAS)" -ForegroundColor Cyan
Write-Host ("  * Jarras de Conserva (Geleia/Picles) : {0} maquinas" -f $machineCounts["Preserves Jar"])
Write-Host ("  * Barris (Vinho/Suco)                : {0} maquinas" -f $machineCounts["Keg"])
Write-Host ("  * Desidratadores (Frutas Secas 1.6)  : {0} maquinas" -f $machineCounts["Dehydrator"])

# Base de Dados de Culturas
$cropsDb = @{
    "400" = @{ Name = "Morango (Strawberry)"; SeedCost = 100; BaseSell = 120; Type = "Fruit"; RegrowDays = 4 }
    "190" = @{ Name = "Couve-flor (Cauliflower)"; SeedCost = 80; BaseSell = 175; Type = "Vegetable"; RegrowDays = 0 }
    "188" = @{ Name = "Vagem (Green Bean)"; SeedCost = 60; BaseSell = 40; Type = "Vegetable"; RegrowDays = 3 }
    "24"  = @{ Name = "Chirivia (Parsnip)"; SeedCost = 20; BaseSell = 35; Type = "Vegetable"; RegrowDays = 0 }
    "192" = @{ Name = "Batata (Potato)"; SeedCost = 50; BaseSell = 80; Type = "Vegetable"; RegrowDays = 0 }
    "248" = @{ Name = "Alho (Garlic)"; SeedCost = 40; BaseSell = 60; Type = "Vegetable"; RegrowDays = 0 }
    "250" = @{ Name = "Couve (Kale)"; SeedCost = 70; BaseSell = 110; Type = "Vegetable"; RegrowDays = 0 }
    "252" = @{ Name = "Ruibarbo (Rhubarb)"; SeedCost = 100; BaseSell = 220; Type = "Fruit"; RegrowDays = 0 }
}

$farm = $xml.SaveGame.locations.GameLocation | Where-Object { $_.Name -eq 'Farm' }
$cropsTerrain = @()
if ($farm -and $farm.terrainFeatures -and $farm.terrainFeatures.item) {
    $cropsTerrain = $farm.terrainFeatures.item | Where-Object { $_.value.TerrainFeature.crop }
}

Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "2. STATUS DAS PLANTAS & PROJEÇÃO DE VALOR" -ForegroundColor Cyan

$readyGroups = @()
$growthGroups = @()

foreach ($group in ($cropsTerrain | Group-Object { $_.value.TerrainFeature.crop.indexOfHarvest })) {
    $harvestId = [string]$group.Name
    $count = $group.Count
    $sampleCrop = $group.Group[0].value.TerrainFeature.crop
    $info = $cropsDb[$harvestId]
    $cropName = if ($info) { $info.Name } else { "Cultura ID $harvestId" }
    $basePrice = if ($info) { $info.BaseSell } else { 50 }
    $type = if ($info) { $info.Type } else { "Vegetable" }
    
    $phases = @($sampleCrop.phaseDays.int)
    $maxPhase = $phases.Count - 1
    $currPhase = [int]$sampleCrop.currentPhase
    $dayOfPhase = [int]$sampleCrop.dayOfCurrentPhase
    $isFullGrown = ($sampleCrop.fullGrown -eq 'true')
    
    $isReadyToHarvest = $false
    $daysRemaining = 0
    
    if ($info.RegrowDays -gt 0 -and $isFullGrown) {
        # Planta com rebrotamento (ex: Morango, Vagem)
        # dayOfPhase conta quantos dias desde a última colheita. Quando dayOfPhase <= 0 ou atinge RegrowDays ela fica pronta.
        $regrowTarget = $info.RegrowDays
        if ($dayOfPhase -le 0 -or $dayOfPhase -ge $regrowTarget) {
            $isReadyToHarvest = $true
            $daysRemaining = 0
        } else {
            $isReadyToHarvest = $false
            $daysRemaining = $regrowTarget - $dayOfPhase
        }
    } else {
        # Planta em ciclo inicial de crescimento
        if ($currPhase -ge $maxPhase) {
            $isReadyToHarvest = $true
            $daysRemaining = 0
        } else {
            $isReadyToHarvest = $false
            $daysLeft = 0
            for ($p = $currPhase; $p -lt $maxPhase; $p++) {
                $daysLeft += [int]$phases[$p]
            }
            $daysRemaining = [math]::Max(1, ($daysLeft - $dayOfPhase))
        }
    }

    $unitJelly = (2 * $basePrice) + 50
    $unitKeg = if ($type -eq "Fruit") { 3 * $basePrice } else { [math]::Floor(2.25 * $basePrice) }
    $unitDried = if ($type -eq "Fruit") { [math]::Floor((1.5 * $basePrice) + 5) } else { 0 }
    
    $itemSummary = [PSCustomObject]@{
        Nome = $cropName
        Qtd = $count
        Previsao = if ($isReadyToHarvest) { "MADURA HOJE!" } else { "Faltam $daysRemaining dias (Dia $($currentDay + $daysRemaining))" }
        VendaPura = "$($count * $basePrice) g"
        JarraConserva = "$($count * $unitJelly) g"
        Barril = "$($count * $unitKeg) g"
        Desidratador = if ($type -eq "Fruit") { "$($count * $unitDried) g" } else { "N/A" }
    }

    if ($isReadyToHarvest) {
        $readyGroups += $itemSummary
    } else {
        $growthGroups += $itemSummary
    }
}

Write-Host "PRONTAS PARA COLHEITA HOJE:" -ForegroundColor Yellow
if ($readyGroups.Count -gt 0) {
    $readyGroups | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Green
} else {
    Write-Host "  Nenhuma planta madura exatamente para colher hoje." -ForegroundColor DarkGray
}

Write-Host "`nEM CRESCIMENTO / REBROTAMENTO (PRECISAM DE REGA):" -ForegroundColor Yellow
if ($growthGroups.Count -gt 0) {
    $growthGroups | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Cyan
} else {
    Write-Host "  Nenhuma planta em crescimento." -ForegroundColor DarkGray
}

Write-Host "----------------------------------------------------------" -ForegroundColor Gray
Write-Host "3. O QUE AINDA DA TEMPO DE PLANTAR HOJE?" -ForegroundColor Cyan
Write-Host "Dias restantes antes da virada do mes (Verao): $daysRemainingInSeason dias"
Write-Host "  * Chirivia (Parsnip) : 4 dias -> Colheita no Dia 27 (Lucro: +15g/un)" -ForegroundColor Green
Write-Host "  * Cenoura (Carrot)   : 3 dias -> Colheita no Dia 26 (Lucro: 100% puro)" -ForegroundColor Green
Write-Host "  * Outras sementes    : Nao plante sem fertilizante acelerador!" -ForegroundColor DarkGray

Write-Host "`n==========================================================" -ForegroundColor Green
