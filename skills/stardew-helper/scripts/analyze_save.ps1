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
$TOTAL_FISH = 75           # 67 peixes pescáveis + 10 do covo + novidades 1.6 (Goby, etc.)
$TOTAL_COOKING = 80        # Total de receitas culinárias
$TOTAL_CRAFTING = 149      # Total de receitas de fabricação
$TOTAL_WALNUTS = 130       # Total de nozes douradas
$TOTAL_OBELISKS = 4        # 4 obeliscos
$TOTAL_VILLAGERS = 34      # Total de moradores com amizade

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
$friendList = @()
if ($farmer.friendshipData -and $farmer.friendshipData.item) {
    foreach ($item in $farmer.friendshipData.item) {
        $npc = $item.key.string
        $pts = [int]$item.value.Friendship.Points
        $hearts = [math]::Floor($pts / 250)
        if ($hearts -ge 8) {
            $maxFriends++
        }
        $friendList += [PSCustomObject]@{ NPC = $npc; Hearts = $hearts; Points = $pts }
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

# Centro Comunitário
Write-Host "`n[CENTRO COMUNITARIO - PACOTES]" -ForegroundColor Cyan
$bundleDefinitions = @{
    0 = @{ Name = "Coleta da Primavera (Pantry/Copa)"; Items = @("Raiz-forte Silvestre", "Narciso", "Alho-poro", "Dente-de-leao") }
    1 = @{ Name = "Coleta do Verao"; Items = @("Uva", "Fruto das Especiarias", "Ervilha-do-cepe") }
    2 = @{ Name = "Coleta do Outono"; Items = @("Amora", "Cogumelo Comum", "Avela", "Ameixa Selvagem") }
    3 = @{ Name = "Coleta do Inverno"; Items = @("Raiz de Inverno", "Fruta de Cristal", "Inhame de Neve", "Flor de Croco") }
    4 = @{ Name = "Construcao (Construction)"; Items = @("Madeira (99)", "Madeira (99)", "Pedra (99)", "Madeira de Lei (10)") }
    5 = @{ Name = "Coleta Exotica"; Items = @("Cogumelo Roxo", "Caramujo", "Cacto", "Flor de Coco", "Resina", "Xarope", "Alcatrao", "Cogumelo Vermelho") }
    6 = @{ Name = "Lavoura da Primavera (Pantry)"; Items = @("Chirivia", "Vagem", "Couve-flor", "Batata") }
    7 = @{ Name = "Lavoura do Verao"; Items = @("Tomate", "Pimenta", "Mirtilo", "Melao") }
    8 = @{ Name = "Lavoura do Outono"; Items = @("Milho", "Beringela", "Abobora", "Inhame") }
    9 = @{ Name = "Lavoura de Qualidade (Ouro)"; Items = @("Chirivia (5 Ouro)", "Melao (5 Ouro)", "Abobora (5 Ouro)", "Milho (5 Ouro)") }
    10 = @{ Name = "Animais (Animal Bundle)"; Items = @("Leite Grande", "Ovo Marrom Grande", "Ovo Branco Grande", "Leite Grande de Cabra", "La", "Pato (Pena)") }
    11 = @{ Name = "Artesao (Artisan Bundle)"; Items = @("Trufas", "Tecido", "Queijo de Cabra", "Queijo", "Mel", "Geleia", "Maca", "Damasco", "Laranja", "Pessego", "Roma", "Cereja") }
    13 = @{ Name = "Peixes do Rio (Fish Tank)"; Items = @("Truta Arco-Iris", "Truta", "Bagre", "Peixe-Sol") }
    14 = @{ Name = "Peixes do Lago"; Items = @("Perca", "Carp", "Peixe-Gato", "Truta Arco-Iris do Lago") }
    15 = @{ Name = "Peixes do Oceano"; Items = @("Sardinha", "Atum", "Pargo Vermelho", "Tilapia") }
    16 = @{ Name = "Peixes Noturnos"; Items = @("Picão-verde", "Enguia", "Brema") }
    17 = @{ Name = "Peixes do Covo (Crab Pot)"; Items = @("Lagosta", "Lagostim", "Caranguejo", "Mexilhao", "Amêijoa", "Ostra", "Caracol", "Búzio", "Mexilhão-castanho", "Camarão") }
    19 = @{ Name = "Peixes Especiais"; Items = @("Pufferfish", "Peixe-Fantasma", "Peixe-Areia", "Madeira-Flutuante") }
    20 = @{ Name = "Ferreiro (Boiler Room)"; Items = @("Barra de Cobre", "Barra de Ferro", "Barra de Ouro") }
    21 = @{ Name = "Geologo"; Items = @("Quartzo", "Cristal de Terra", "Lagrima Congelada", "Geodo de Fogo") }
    22 = @{ Name = "Aventureiro"; Items = @("Gosma (99)", "Asa de Morcego (10)", "Carvão Solar", "Carvão Noturno") }
    23 = @{ Name = "Cofre: 2.500g"; Items = @("2.500g") }
    24 = @{ Name = "Cofre: 5.000g"; Items = @("5.000g") }
    25 = @{ Name = "Cofre: 10.000g"; Items = @("10.000g") }
    26 = @{ Name = "Cofre: 25.000g"; Items = @("25.000g") }
    31 = @{ Name = "Cozinheiro (Bulletin Board)"; Items = @("Xarope de Acer", "Samambaia", "Trufa", "Papoila", "Maki Roll", "Ovo Frito") }
    32 = @{ Name = "Corante (Dye Bundle)"; Items = @("Cogumelo Vermelho", "Ourico-do-mar", "Girassol", "Pena de Pato", "Agua-marinha", "Repolho Roxo") }
    33 = @{ Name = "Campo (Field Research)"; Items = @("Flor de Dente", "Concha Nautilo", "Chub", "Geodo Congelado") }
    34 = @{ Name = "Feiticeiro (Fodder)"; Items = @("Trigo (10)", "Feno (10)", "Maca (3)") }
    35 = @{ Name = "Encantador (Enchanter)"; Items = @("Carvalho", "Vinho", "Romã", "Pé de Coelho") }
}

$loc = $xml.SaveGame.locations.GameLocation | Where-Object { $_.Name -eq 'CommunityCenter' }
if ($loc -and $loc.bundles -and $loc.bundles.item) {
    $completedBundles = 0
    $pendingBundles = 0
    $bundleItemsDetails = @()

    foreach ($b in $loc.bundles.item) {
        $bId = [int]$b.key.int
        $bools = @($b.value.ArrayOfBoolean.boolean) | ForEach-Object { [bool]::Parse($_) }
        $totalSlots = $bools.Count
        $filledSlots = ($bools | Where-Object { $_ -eq $true }).Count
        
        $info = $bundleDefinitions[$bId]
        $bName = if ($info) { $info.Name } else { "Conjunto ID $bId" }
        
        # Um bundle pode ser completado mesmo com slots livres (ex: Coleta Exotica precisa de 5 entre 8)
        $isComplete = ($filledSlots -ge 1 -and -not ($bools -contains $false)) -or ($bId -eq 0 -and $filledSlots -ge 4) -or ($bId -eq 13 -and $filledSlots -ge 4)
        
        if ($filledSlots -gt 0) {
            $bundleItemsDetails += [PSCustomObject]@{
                Id = $bId
                Name = $bName
                Filled = $filledSlots
                Slots = $totalSlots
                Status = if ($filledSlots -eq $totalSlots -or $isComplete) { "COMPLETO" } else { "EM PROGRESSO ($filledSlots entregues)" }
                Bools = $bools
            }
        }
    }

    Write-Host "Conjuntos com progresso iniciado:"
    foreach ($det in $bundleItemsDetails) {
        $color = if ($det.Status -like "*COMPLETO*") { "Green" } else { "Yellow" }
        Write-Host ("  * [{0}] {1}: {2}" -f $det.Id, $det.Name, $det.Status) -ForegroundColor $color
        
        $info = $bundleDefinitions[$det.Id]
        if ($info -and $det.Status -notlike "*COMPLETO*") {
            for ($idx = 0; $idx -lt $det.Bools.Count; $idx++) {
                $itName = if ($idx -lt $info.Items.Count) { $info.Items[$idx] } else { "Item #$($idx+1)" }
                $done = $det.Bools[$idx]
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
