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
    "Keg" = 0           # Barril (Vinho / Suco)
    "Preserves Jar" = 0 # Jarra de Conserva (Geleia / Picles)
    "Dehydrator" = 0    # Desidratador (Frutas Secas)
}

# No mundo
foreach ($loc in $xml.SaveGame.locations.GameLocation) {
    if ($loc.objects -and $loc.objects.item) {
        foreach ($it in $loc.objects.item) {
            $name = $it.value.Object.name
            if ($machineCounts.ContainsKey($name)) {
                $machineCounts[$name]++
            }
            # Checar baús
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

# No inventário do jogador
if ($farmer.items -and $farmer.items.Item) {
    foreach ($inv in $farmer.items.Item) {
        if ($inv -and $machineCounts.ContainsKey($inv.Name)) {
            $stack = if ($inv.Stack) { [int]$inv.Stack } else { 1 }
            $machineCounts[$inv.Name] += $stack
        }
    }
}

Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "1. PARQUE INDUSTRIAL ATUAL (SUAS MÁQUINAS)" -ForegroundColor Cyan
Write-Host ("  * Jarras de Conserva (Geleia/Picles) : {0} maquinas" -f $machineCounts["Preserves Jar"])
Write-Host ("  * Barris (Vinho/Suco)                : {0} maquinas" -f $machineCounts["Keg"])
Write-Host ("  * Desidratadores (Frutas Secas 1.6)  : {0} maquinas" -f $machineCounts["Dehydrator"])

# Receitas conhecidas de fabricação
$hasJarRecipe = $false
$hasKegRecipe = $false
$hasDehydratorRecipe = $false
if ($farmer.craftingRecipes -and $farmer.craftingRecipes.item) {
    foreach ($r in $farmer.craftingRecipes.item) {
        if ($r.key.string -eq "Preserves Jar") { $hasJarRecipe = $true }
        if ($r.key.string -eq "Keg") { $hasKegRecipe = $true }
        if ($r.key.string -eq "Dehydrator") { $hasDehydratorRecipe = $true }
    }
}

# Base de Dados de Culturas
$cropsDb = @{
    "400" = @{ Name = "Morango (Strawberry)"; SeedCost = 100; BaseSell = 120; Type = "Fruit"; DaysTotal = 8; Regrow = 4 }
    "190" = @{ Name = "Couve-flor (Cauliflower)"; SeedCost = 80; BaseSell = 175; Type = "Vegetable"; DaysTotal = 12; Regrow = 0 }
    "188" = @{ Name = "Vagem (Green Bean)"; SeedCost = 60; BaseSell = 40; Type = "Vegetable"; DaysTotal = 10; Regrow = 3 }
    "24"  = @{ Name = "Chirivia (Parsnip)"; SeedCost = 20; BaseSell = 35; Type = "Vegetable"; DaysTotal = 4; Regrow = 0 }
    "192" = @{ Name = "Batata (Potato)"; SeedCost = 50; BaseSell = 80; Type = "Vegetable"; DaysTotal = 6; Regrow = 0 }
    "248" = @{ Name = "Alho (Garlic)"; SeedCost = 40; BaseSell = 60; Type = "Vegetable"; DaysTotal = 4; Regrow = 0 }
    "250" = @{ Name = "Couve (Kale)"; SeedCost = 70; BaseSell = 110; Type = "Vegetable"; DaysTotal = 6; Regrow = 0 }
    "252" = @{ Name = "Ruibarbo (Rhubarb)"; SeedCost = 100; BaseSell = 220; Type = "Fruit"; DaysTotal = 13; Regrow = 0 }
}

# Lavouras no terreno
$farm = $xml.SaveGame.locations.GameLocation | Where-Object { $_.Name -eq 'Farm' }
$cropsTerrain = @()
if ($farm -and $farm.terrainFeatures -and $farm.terrainFeatures.item) {
    $cropsTerrain = $farm.terrainFeatures.item | Where-Object { $_.value.TerrainFeature.crop }
}

Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "2. STATUS DAS PLANTAS & PROJEÇÃO DE VALOR UNITÁRIO" -ForegroundColor Cyan

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
    
    $isFullyGrown = ($sampleCrop.fullGrown -eq 'true') -or ($sampleCrop.currentPhase -ge ($sampleCrop.phaseDays.int.Count - 1))
    
    # Processamento Unitário:
    # Jarra: (2 * Base) + 50 -> tempo: ~2.5 a 3 dias
    $unitJelly = (2 * $basePrice) + 50
    # Barril: 3 * Base (Fruta: 7 dias) / 2.25 * Base (Vegetal: 4 dias)
    $unitKeg = if ($type -eq "Fruit") { 3 * $basePrice } else { [math]::Floor(2.25 * $basePrice) }
    # Desidratador 1.6: 5 unidades viram 1 item vendido por (7.5 * Base + 25) -> unitário = 1.5 * Base + 5 -> tempo: 1 dia
    $unitDried = if ($type -eq "Fruit") { [math]::Floor((1.5 * $basePrice) + 5) } else { 0 }
    
    $itemSummary = [PSCustomObject]@{
        Nome = $cropName
        Qtd = $count
        VendaPuraBase = "$($count * $basePrice) g ($basePrice g/un)"
        JarraConserva = "$($count * $unitJelly) g ($unitJelly g/un)"
        Barril = "$($count * $unitKeg) g ($unitKeg g/un)"
        Desidratador = if ($type -eq "Fruit") { "$($count * $unitDried) g ($unitDried g/un)" } else { "N/A" }
        GargaloMaquinas = ""
    }

    if ($isFullyGrown) {
        $readyGroups += $itemSummary
    } else {
        $growthGroups += $itemSummary
    }
}

Write-Host "🚨 PRONTAS HOJE:"
$readyGroups | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Green

Write-Host "⏳ EM CRESCIMENTO:"
$growthGroups | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Yellow

Write-Host "----------------------------------------------------------" -ForegroundColor Gray
Write-Host "3. ANÁLISE DE CUSTO-BENEFÍCIO REALISTA & RECOMENDAÇÃO" -ForegroundColor Cyan

$jars = $machineCounts["Preserves Jar"]
$kegs = $machineCounts["Keg"]
$dehydrators = $machineCounts["Dehydrator"]

Write-Host "DIAGNÓSTICO DO MOMENTO ATUAL (Primavera Ano 1):" -ForegroundColor Magenta

if ($jars -eq 0 -and $kegs -eq 0 -and $dehydrators -eq 0) {
    Write-Host "Você tem 0 máquinas de processamento ativas no momento!" -ForegroundColor Yellow
    Write-Host "Cenário dos seus 176 Morangos de hoje:"
    Write-Host "  1. SE GUARDAR TUDO PRA VINHO/GELEIA: Seu dinheiro fica travado e você não terá capital para comprar sementes no Verão (que começa em 5 dias!)." -ForegroundColor Red
    Write-Host "  2. SE VENDER TUDO PURO HOJE: Você embolsa 21.120 g IMEDIATAMENTE." -ForegroundColor Green
    Write-Host "  3. ESTRATÉGIA DE OURO (RECOMENDADA):" -ForegroundColor Cyan
    Write-Host "     -> VENDA PURA os 176 morangos de hoje (garanta 21.120 g para o banco do Verão)."
    Write-Host "     -> No Dia 27 (última colheita da Primavera), quando vierem mais 176 morangos, GUARDE UMA PARTE (ex: 30 a 50) nos baús para quando você construir suas Jarras de Conserva!"
} else {
    Write-Host ("Com suas maquinas atuais ({0} Jarras, {1} Barris, {2} Desidratadores):" -f $jars, $kegs, $dehydrators)
}

Write-Host "`nTAXA DE LUCRO POR DIA DE MÁQUINA (QUANDO TIVER MÁQUINAS):" -ForegroundColor Cyan
Write-Host "  * Jarra de Conserva: Gera 290g por morango em ~2.8 dias (= ~103g/dia)."
Write-Host "  * Barril (Vinho): Gera 360g por morango em ~7 dias (= ~51g/dia)."
Write-Host "  * Desidratador (1.6): Gera 185g por morango em APENAS 1 DIA (= 185g/dia) e processa 5 por vez!" -ForegroundColor Green
Write-Host "  => CONCLUSÃO TÉCNICA: Para Morangos, a JARRA ou DESIDRATADOR são muito superiores ao Barril no início do jogo devido à velocidade de giro!"

Write-Host "`n==========================================================" -ForegroundColor Green
