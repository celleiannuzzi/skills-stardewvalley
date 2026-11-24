param(
    [string]$TargetSave = "Dark",
    [switch]$Detailed
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

Write-Host "==================================================" -ForegroundColor Green
Write-Host "     STARDEW VALLEY PROGRESS & PERFECTION TRACKER " -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green
Write-Host "Analisando Save: $saveFolderName..."

[xml]$xml = [System.IO.File]::ReadAllText($saveFilePath)
$farmer = $xml.SaveGame.player

# Constantes da Perfeição (Stardew Valley 1.6)
$TOTAL_FISH = 75
$TOTAL_COOKING = 80
$TOTAL_CRAFTING = 149
$TOTAL_WALNUTS = 130
$TOTAL_OBELISKS = 4
$TOTAL_VILLAGERS = 34

$name = $farmer.name
$farmName = $farmer.farmName
$money = [int64]$farmer.money
$totalMoney = [int64]$farmer.totalMoneyEarned
$playedHours = [math]::Round([double]$farmer.millisecondsPlayed / 3600000, 1)
$season = $xml.SaveGame.currentSeason
$year = $xml.SaveGame.year
$day = $xml.SaveGame.dayOfMonth
$version = $xml.SaveGame.gameVersion

Write-Host "`n[DADOS GERAIS]" -ForegroundColor Cyan
Write-Host "Jogador: $name | Fazenda: $farmName | Versao: $version"
Write-Host "Calendario: Dia $day de $season (Ano $year) | Tempo Jogado: $playedHours h"
Write-Host "Ouro: $money g (Acumulado: $totalMoney g)"

# Habilidades
Write-Host "`n[HABILIDADES]" -ForegroundColor Cyan
Write-Host ("- Agricultura : {0}/10 (Faltam {1})" -f $farmer.farmingLevel, (10 - [int]$farmer.farmingLevel))
Write-Host ("- Mineracao   : {0}/10 (Faltam {1})" -f $farmer.miningLevel, (10 - [int]$farmer.miningLevel))
Write-Host ("- Coleta      : {0}/10 (Faltam {1})" -f $farmer.foragingLevel, (10 - [int]$farmer.foragingLevel))
Write-Host ("- Pesca       : {0}/10 (Faltam {1})" -f $farmer.fishingLevel, (10 - [int]$farmer.fishingLevel))
Write-Host ("- Combate     : {0}/10 (Faltam {1})" -f $farmer.combatLevel, (10 - [int]$farmer.combatLevel))

# Peixes
$caughtFishList = @()
if ($farmer.fishCaught -and $farmer.fishCaught.item) {
    $farmer.fishCaught.item | ForEach-Object { $caughtFishList += $_.key.string }
}
$fishCount = $caughtFishList.Count
Write-Host "`n[PEIXES]" -ForegroundColor Cyan
Write-Host ("- Capturados: {0}/{1} (Faltam {2})" -f $fishCount, $TOTAL_FISH, ($TOTAL_FISH - $fishCount))

# Culinaria
$cookedList = @()
if ($farmer.recipesCooked -and $farmer.recipesCooked.item) {
    $farmer.recipesCooked.item | ForEach-Object { $cookedList += $_.key.string }
}
$cookedCount = $cookedList.Count
Write-Host "`n[CULINARIA]" -ForegroundColor Cyan
Write-Host ("- Pratos Cozinhados: {0}/{1} (Faltam {2})" -f $cookedCount, $TOTAL_COOKING, ($TOTAL_COOKING - $cookedCount))

# Fabricação (Crafting)
$craftedList = @()
if ($farmer.craftingRecipes -and $farmer.craftingRecipes.item) {
    foreach ($item in $farmer.craftingRecipes.item) {
        if ([int]$item.value.int -gt 0) {
            $craftedList += $item.key.string
        }
    }
}
$craftCount = $craftedList.Count
Write-Host "`n[FABRICACAO (CRAFTING)]" -ForegroundColor Cyan
Write-Host ("- Itens Fabricados: {0}/{1} (Faltam {2})" -f $craftCount, $TOTAL_CRAFTING, ($TOTAL_CRAFTING - $craftCount))

# Amizades
$maxFriends = 0
if ($farmer.friendshipData -and $farmer.friendshipData.item) {
    foreach ($item in $farmer.friendshipData.item) {
        $pts = [int]$item.value.Friendship.Points
        $hearts = [math]::Floor($pts / 250)
        if ($hearts -ge 8) {
            $maxFriends++
        }
    }
}
Write-Host "`n[AMIZADES (8+ CORACOES)]" -ForegroundColor Cyan
Write-Host ("- Moradores no Maximo: {0}/{1} (Faltam {2})" -f $maxFriends, $TOTAL_VILLAGERS, ($TOTAL_VILLAGERS - $maxFriends))

# Nozes Douradas
$walnuts = 0
if ($xml.SaveGame.goldenWalnutsFound) {
    $walnuts = [int]$xml.SaveGame.goldenWalnutsFound
}
Write-Host "`n[NOZES DOURADAS (ILHA GENGIBRE)]" -ForegroundColor Cyan
Write-Host ("- Encontradas: {0}/{1} (Faltam {2})" -f $walnuts, $TOTAL_WALNUTS, ($TOTAL_WALNUTS - $walnuts))

# Obeliscos e Relógio
$buildings = @()
if ($xml.SaveGame.locations.GameLocation) {
    foreach ($loc in $xml.SaveGame.locations.GameLocation) {
        if ($loc.buildings -and $loc.buildings.Building) {
            $loc.buildings.Building | ForEach-Object { $buildings += $_.buildingType }
        }
    }
}
$obCount = 0
if ($buildings -contains "Earth Obelisk") { $obCount++ }
if ($buildings -contains "Water Obelisk") { $obCount++ }
if ($buildings -contains "Desert Obelisk") { $obCount++ }
if ($buildings -contains "Island Obelisk") { $obCount++ }
$goldClock = $buildings -contains "Gold Clock"

Write-Host "`n[TORRE DO MAGO & RELOGIO]" -ForegroundColor Cyan
Write-Host ("- Obeliscos Construidos: {0}/{1} (Faltam {2})" -f $obCount, $TOTAL_OBELISKS, ($TOTAL_OBELISKS - $obCount))
Write-Host ("- Relogio de Ouro (10M): " + ($(if ($goldClock) { "Construido [OK]" } else { "Pendente (Falta 1)" })))

# Dicionário oficial de nomes dos itens de Stardew Valley
$itemNameMap = @{
    "16" = "Raiz-forte Silvestre"; "18" = "Narciso"; "20" = "Alho-poro"; "22" = "Dente-de-leao"
    "24" = "Chirivia"; "188" = "Vagem"; "190" = "Couve-flor"; "192" = "Batata"
    "254" = "Melao"; "256" = "Tomate"; "258" = "Mirtilo"; "260" = "Pimenta"
    "270" = "Milho"; "272" = "Beringela"; "276" = "Abobora"; "280" = "Inhame"
    "186" = "Leite Grande"; "182" = "Ovo Marrom Grande"; "174" = "Ovo Branco Grande"; "438" = "Leite Grande de Cabra"; "440" = "La"; "442" = "Pena de Pato"
    "432" = "Trufa"; "428" = "Tecido"; "426" = "Queijo de Cabra"; "424" = "Queijo"; "340" = "Mel"; "344" = "Geleia"
    "388" = "Madeira (99)"; "390" = "Pedra (99)"; "709" = "Madeira de Lei (10)"
    "145" = "Peixe-Sol"; "143" = "Bagre"; "706" = "Savelha"; "699" = "Truta Tigre"
    "136" = "Largemouth Bass"; "142" = "Carp"; "700" = "Bullhead"; "698" = "Sturgeon"
    "131" = "Sardinha"; "130" = "Atum"; "150" = "Pargo Vermelho"; "701" = "Tilapia"
    "140" = "Walleye"; "132" = "Brema"; "148" = "Enguia"
    "334" = "Barra de Cobre"; "335" = "Barra de Ferro"; "336" = "Barra de Ouro"
    "80" = "Quartzo"; "86" = "Cristal de Terra"; "84" = "Lagrima Congelada"; "82" = "Geodo de Fogo"
    "766" = "Gosma (99)"; "767" = "Asa de Morcego (10)"; "768" = "Carvao Solar"; "769" = "Carvao Noturno"
}

# Parser inteligente do bundleData do próprio save
$bundleMeta = @{}
if ($xml.SaveGame.bundleData -and $xml.SaveGame.bundleData.item) {
    foreach ($entry in $xml.SaveGame.bundleData.item) {
        $parts = $entry.key.string -split '/'
        $room = $parts[0]
        $bId = [int]$parts[1]
        
        $fields = $entry.value.string -split '/'
        $bName = $fields[0]
        $rawItems = $fields[2] -split ' '
        
        $reqItems = @()
        for ($i = 0; $i -lt $rawItems.Count; $i += 3) {
            $itemId = $rawItems[$i]
            $itemCount = $rawItems[$i+1]
            $itemQual = $rawItems[$i+2]
            
            $iName = if ($itemNameMap.ContainsKey($itemId)) { $itemNameMap[$itemId] } else { "Item #$itemId" }
            if ($itemQual -eq "2") { $iName += " (Ouro)" }
            if ([int]$itemCount -gt 1 -and $iName -notmatch '\(') { $iName += " ($itemCount)" }
            $reqItems += $iName
        }
        
        $bundleMeta[$bId] = @{
            Room = $room
            Name = $bName
            Items = $reqItems
        }
    }
}

# Centro Comunitário
Write-Host "`n[CENTRO COMUNITARIO - PACOTES]" -ForegroundColor Cyan
$loc = $xml.SaveGame.locations.GameLocation | Where-Object { $_.Name -eq 'CommunityCenter' }
if ($loc -and $loc.bundles -and $loc.bundles.item) {
    foreach ($b in $loc.bundles.item) {
        $bId = [int]$b.key.int
        $bools = @($b.value.ArrayOfBoolean.boolean) | ForEach-Object { [bool]::Parse($_) }
        
        $info = $bundleMeta[$bId]
        if (-not $info) { continue }
        
        $reqCount = $info.Items.Count
        if ($reqCount -eq 0) { continue }
        
        # Verificar quantos dos itens requeridos estão true
        $filledCount = 0
        for ($idx = 0; $idx -lt $reqCount; $idx++) {
            if ($idx -lt $bools.Count -and $bools[$idx] -eq $true) {
                $filledCount++
            }
        }
        
        # Pacote completo se todos forem true (ou caso de 12 trues como no Spring Foraging)
        $isComplete = ($filledCount -ge $reqCount) -or ($bools[0..3] -notcontains $false)
        
        if ($isComplete) {
            Write-Host ("  * [{0}] {1} ({2}): COMPLETO! [OK]" -f $bId, $info.Name, $info.Room) -ForegroundColor Green
        } elseif ($filledCount -gt 0) {
            Write-Host ("  * [{0}] {1} ({2}): EM PROGRESSO ({3}/{4} entregues)" -f $bId, $info.Name, $info.Room, $filledCount, $reqCount) -ForegroundColor Yellow
            for ($idx = 0; $idx -lt $reqCount; $idx++) {
                $itName = $info.Items[$idx]
                $done = ($idx -lt $bools.Count -and $bools[$idx] -eq $true)
                if ($done) {
                    Write-Host ("      [X] Entregue: $itName") -ForegroundColor DarkGreen
                } else {
                    Write-Host ("      [ ] FALTANDO: $itName") -ForegroundColor Magenta
                }
            }
        }
    }
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "Relatorio detalhado gerado com sucesso!" -ForegroundColor Green
