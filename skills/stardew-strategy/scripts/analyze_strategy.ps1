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

[xml]$xml = [System.IO.File]::ReadAllText($saveFilePath)
$farmer = $xml.SaveGame.player
$season = [string]$xml.SaveGame.currentSeason
$year = [int]$xml.SaveGame.year
$currentDay = [int]$xml.SaveGame.dayOfMonth
$daysRemainingInSeason = 28 - $currentDay
$deepestMine = [int]$xml.SaveGame.mine_lowestLevelReached
$backpack = [int]$farmer.maxItems
$money = [int64]$farmer.money
$weather = $xml.SaveGame.isRaining

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "     STARDEW VALLEY - STRATEGIC COMMAND & PRODUCTIVITY    " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Fazendeiro(a): $($farmer.name) | Fazenda: $($farmer.farmName) Farm" -ForegroundColor Cyan
Write-Host "Data Atual: Dia $currentDay de $season (Ano $year) | Dias p/ fim da estacao: $daysRemainingInSeason dias" -ForegroundColor Cyan
Write-Host "Clima Atual: $(if ($weather -eq 'true') { 'Chovendo' } else { 'Ensolarado' }) | Carteira: $money g" -ForegroundColor Cyan
Write-Host "Mochila: $backpack espacos | Mina mais profunda: Andar $deepestMine" -ForegroundColor Cyan

# 1. Mapear TODOS os itens que o jogador possui (Inventário + Todos os baús do mundo)
$allItems = @{}
$allItemsQuality = @{}
$allItemsById = @{}

function Add-ItemStock($name, $qty, $qual, $id) {
    if (-not $name) { return }
    if (-not $allItems.ContainsKey($name)) { $allItems[$name] = 0 }
    $allItems[$name] += $qty
    
    $keyQual = "$name#$qual"
    if (-not $allItemsQuality.ContainsKey($keyQual)) { $allItemsQuality[$keyQual] = 0 }
    $allItemsQuality[$keyQual] += $qty
    
    if ($id) {
        if (-not $allItemsById.ContainsKey($id)) { $allItemsById[$id] = @{ Name = $name; Count = 0 } }
        $allItemsById[$id].Count += $qty
    }
}

if ($farmer.items -and $farmer.items.Item) {
    foreach ($it in $farmer.items.Item) {
        if ($it -and $it.Name) {
            $st = if ($it.Stack) { [int]$it.Stack } else { 1 }
            $q = if ($it.Quality) { [int]$it.Quality } else { 0 }
            Add-ItemStock $it.Name $st $q $it.ItemId
        }
    }
}

foreach ($loc in $xml.SaveGame.locations.GameLocation) {
    if ($loc.objects -and $loc.objects.item) {
        foreach ($o in $loc.objects.item) {
            if ($o.value.Object.items) {
                foreach ($ci in $o.value.Object.items.Item) {
                    if ($ci -and $ci.Name) {
                        $st = if ($ci.Stack) { [int]$ci.Stack } else { 1 }
                        $q = if ($ci.Quality) { [int]$ci.Quality } else { 0 }
                        Add-ItemStock $ci.Name $st $q $ci.ItemId
                    }
                }
            }
        }
    }
}

# 2. MUSEU (GUNTHER) - Checagem de itens doados vs guardados
Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "1. MUSEU (GUNTHER) - DOAÇÕES PENDENTES GUARDADAS NO BAÚ" -ForegroundColor Magenta

$TOTAL_MUSEUM_PIECES = 95 # 42 artefatos + 53 minerais
$archLoc = $xml.SaveGame.locations.GameLocation | Where-Object { $_.Name -eq 'ArchaeologyHouse' }
$donatedIds = @()
if ($archLoc -and $archLoc.museumPieces -and $archLoc.museumPieces.item) {
    $archLoc.museumPieces.item | ForEach-Object { $donatedIds += $_.value.string }
}

$donatedCount = $donatedIds.Count
Write-Host ("Progresso Total do Museu: {0}/{1} itens doados (Faltam {2})" -f $donatedCount, $TOTAL_MUSEUM_PIECES, ($TOTAL_MUSEUM_PIECES - $donatedCount))

# Verificar se nos baús ou inventário existe algum mineral/artefato não doado
$museumItemsToDonate = @()

# Tabela de nomes e IDs comuns de doações
$allMuseumDonatable = @{
    "96" = "Dwarf Scroll I"; "97" = "Dwarf Scroll II"; "98" = "Dwarf Scroll III"; "99" = "Dwarf Scroll IV"
    "100" = "Chipped Amphora"; "101" = "Arrowhead"; "102" = "Ancient Doll"; "103" = "Elvish Jewelry"
    "104" = "Chewing Stick"; "105" = "Ornamental Fan"; "106" = "Dinosaur Egg"; "107" = "Rare Disc"
    "108" = "Ancient Sword"; "109" = "Rusty Spoon"; "110" = "Rusty Spur"; "111" = "Rusty Cog"
    "112" = "Chicken Statue"; "113" = "Ancient Seed"; "114" = "Prehistoric Tool"; "115" = "Dried Starfish"
    "116" = "Anchor"; "117" = "Glass Shards"; "118" = "Bone Flute"; "119" = "Prehistoric Handaxe"
    "120" = "Peking Man"; "121" = "Prehistoric Tibia"; "122" = "Prehistoric Skull"; "123" = "Skeletal Hand"
    "124" = "Prehistoric Rib"; "125" = "Prehistoric Vertebra"; "126" = "Skeletal Tail"; "127" = "Nautilus Fossil"
    "579" = "Amphibian Fossil"; "580" = "Palm Fossil"; "581" = "Trilobite"; "582" = "Star Shards"
    "583" = "Pyrite"; "584" = "Ocean Stone"; "585" = "Ghost Crystal"; "586" = "Tigerseye"
    "587" = "Jasper"; "588" = "Opal"; "589" = "Fire Opal"; "590" = "Celestine"
    "80" = "Quartz"; "86" = "Earth Crystal"; "84" = "Frozen Tear"; "82" = "Fire Quartz"
    "60" = "Emerald"; "62" = "Aquamarine"; "64" = "Ruby"; "66" = "Amethyst"; "68" = "Topaz"; "70" = "Jade"; "72" = "Diamond"; "74" = "Prismatic Shard"
}

foreach ($id in $allMuseumDonatable.Keys) {
    if (-not ($donatedIds -contains $id)) {
        # Não foi doado ainda. Temos no baú/inventário?
        if ($allItemsById.ContainsKey($id)) {
            $nameItem = $allItemsById[$id].Name
            $qty = $allItemsById[$id].Count
            $museumItemsToDonate += [PSCustomObject]@{ Id = $id; Name = $nameItem; Qty = $qty }
        } elseif ($allItems.ContainsKey($allMuseumDonatable[$id])) {
            $nameItem = $allMuseumDonatable[$id]
            $qty = $allItems[$nameItem]
            $museumItemsToDonate += [PSCustomObject]@{ Id = $id; Name = $nameItem; Qty = $qty }
        }
    }
}

if ($museumItemsToDonate.Count -gt 0) {
    Write-Host "🚨 ITENS NO SEU BAÚ QUE VOCÊ NUNCA DOOU AO MUSEU (Leve para o Gunther!):" -ForegroundColor Yellow
    foreach ($m in $museumItemsToDonate) {
        Write-Host ("  * [LEVAR AO MUSEU] {0} (voce tem {1} guardado)" -f $m.Name, $m.Qty) -ForegroundColor Green
    }
} else {
    Write-Host "  Nenhum mineral ou artefato pendente de doação encontrado nos seus baús no momento." -ForegroundColor DarkGray
}

# 3. CENTRO COMUNITÁRIO - Itens prontos para entregar
Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "2. ITENS NO SEU BAÚ/INVENTÁRIO PRONTOS PARA ENTREGAR NO CENTRO COMUNITÁRIO" -ForegroundColor Magenta

$locCC = $xml.SaveGame.locations.GameLocation | Where-Object { $_.Name -eq 'CommunityCenter' }
$ccReadyDeliveries = @()

if ($locCC -and $locCC.bundles -and $locCC.bundles.item) {
    $bundleStatusMap = @{}
    foreach ($b in $locCC.bundles.item) {
        $bundleStatusMap[[int]$b.key.int] = @($b.value.ArrayOfBoolean.boolean) | ForEach-Object { [bool]::Parse($_) }
    }
    
    # Bundle 0: Coleta Primavera
    if ($bundleStatusMap[0] -and -not $bundleStatusMap[0][1] -and $allItems.ContainsKey("Daffodil")) {
        $ccReadyDeliveries += "Pacote Coleta da Primavera: Narciso (Daffodil) x1 [Voce tem $($allItems['Daffodil']) no bau! Completa o pacote!]"
    }
    # Bundle 6: Lavouras Primavera
    if ($bundleStatusMap[6]) {
        if (-not $bundleStatusMap[6][0] -and $allItems.ContainsKey("Parsnip")) {
            $ccReadyDeliveries += "Pacote Lavouras da Primavera: Chirívia (Parsnip) x1 [Voce tem $($allItems['Parsnip']) no bau!]"
        }
        if (-not $bundleStatusMap[6][2] -and $allItems.ContainsKey("Cauliflower")) {
            $ccReadyDeliveries += "Pacote Lavouras da Primavera: Couve-flor (Cauliflower) x1 [Voce tem $($allItems['Cauliflower']) no bau!]"
        }
        if (-not $bundleStatusMap[6][3] -and $allItems.ContainsKey("Potato")) {
            $ccReadyDeliveries += "Pacote Lavouras da Primavera: Batata (Potato) x1 [Voce tem $($allItems['Potato']) no bau!]"
        }
    }
    # Bundle 9: Qualidade (Parsnip 5 Ouro)
    if ($bundleStatusMap[9] -and -not $bundleStatusMap[9][0]) {
        $parsnipGold = if ($allItemsQuality.ContainsKey("Parsnip#2")) { $allItemsQuality["Parsnip#2"] } else { 0 }
        if ($parsnipGold -ge 5) {
            $ccReadyDeliveries += "Pacote Lavouras de Qualidade: 5 Chirivias Douradas [Voce tem $parsnipGold no bau!]"
        }
    }
    # Bundle 20: Ferreiro
    if ($bundleStatusMap[20]) {
        if (-not $bundleStatusMap[20][0] -and $allItems.ContainsKey("Copper Bar")) {
            $ccReadyDeliveries += "Pacote Ferreiro: Barra de Cobre x1 [Voce tem $($allItems['Copper Bar']) no bau!]"
        }
        if (-not $bundleStatusMap[20][1] -and $allItems.ContainsKey("Iron Bar")) {
            $ccReadyDeliveries += "Pacote Ferreiro: Barra de Ferro x1 [Voce tem $($allItems['Iron Bar']) no bau!]"
        }
    }
    # Bundle 21: Geólogo
    if ($bundleStatusMap[21]) {
        if (-not $bundleStatusMap[21][0] -and $allItems.ContainsKey("Quartz")) {
            $ccReadyDeliveries += "Pacote Geologo: Quartzo x1 [Voce tem $($allItems['Quartz']) no bau!]"
        }
        if (-not $bundleStatusMap[21][1] -and $allItems.ContainsKey("Earth Crystal")) {
            $ccReadyDeliveries += "Pacote Geologo: Cristal de Terra x1 [Voce tem $($allItems['Earth Crystal']) no bau!]"
        }
    }
}

if ($ccReadyDeliveries.Count -gt 0) {
    foreach ($del in $ccReadyDeliveries) {
        Write-Host ("  [ENTREGAR JA] " + $del) -ForegroundColor Green
    }
} else {
    Write-Host "  Nenhum item pendente do Centro Comunitario encontrado nos baus no momento." -ForegroundColor DarkGray
}

# 4. Viabilidade de Construções (Robin)
Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "3. VIABILIDADE DE CONSTRUÇÕES COM SEUS MATERIAIS ATUAIS" -ForegroundColor Cyan

$wood = if ($allItems.ContainsKey("Wood")) { $allItems["Wood"] } else { 0 }
$stone = if ($allItems.ContainsKey("Stone")) { $allItems["Stone"] } else { 0 }
$clay = if ($allItems.ContainsKey("Clay")) { $allItems["Clay"] } else { 0 }
$copperBar = if ($allItems.ContainsKey("Copper Bar")) { $allItems["Copper Bar"] } else { 0 }
$ironBar = if ($allItems.ContainsKey("Iron Bar")) { $allItems["Iron Bar"] } else { 0 }

Write-Host ("Materiais em estoque: Madeira: {0} | Pedra: {1} | Argila: {2} | Cobre: {3} | Ferro: {4} | Carteira: {5} g" -f $wood, $stone, $clay, $copperBar, $ironBar, $money)

$buildingsPlan = @(
    @{ Name = "Silo"; Gold = 100; Stone = 100; Clay = 10; Copper = 5; Wood = 0; Desc = "Essencial para estocar feno ao cortar grama antes de comprar animais" },
    @{ Name = "Galinheiro (Coop)"; Gold = 4000; Wood = 300; Stone = 100; Clay = 0; Copper = 0; Desc = "Permite criar galinhas para o pacote de animais do Centro Comunitario" },
    @{ Name = "Celeiro (Barn)"; Gold = 6000; Wood = 350; Stone = 150; Clay = 0; Copper = 0; Desc = "Permite criar vacas para leite grande no pacote de animais" },
    @{ Name = "Melhoria da Casa 1 (Cozinha)"; Gold = 10000; Wood = 450; Stone = 0; Clay = 0; Copper = 0; Desc = "Desbloqueia a cozinha para as receitas culinarias da Perfeicao" },
    @{ Name = "Mochila Grande (24 espacos)"; Gold = 2000; Wood = 0; Stone = 0; Clay = 0; Copper = 0; Desc = "Pierre Store - Dobra a capacidade de carregar itens" }
)

foreach ($b in $buildingsPlan) {
    $canGold = ($money -ge $b.Gold)
    $canWood = ($wood -ge $b.Wood)
    $canStone = ($stone -ge $b.Stone)
    $canClay = ($clay -ge $b.Clay)
    $canCopper = ($copperBar -ge $b.Copper)
    
    $ready = ($canGold -and $canWood -and $canStone -and $canClay -and $canCopper)
    if ($ready) {
        Write-Host ("  [PRONTO PARA CONSTRUIR/COMPRAR] {0} ({1}g) - {2}" -f $b.Name, $b.Gold, $b.Desc) -ForegroundColor Green
    } else {
        $missing = @()
        if (-not $canGold) { $missing += "$($b.Gold - $money)g" }
        if (-not $canWood) { $missing += "$($b.Wood - $wood) madeiras" }
        if (-not $canStone) { $missing += "$($b.Stone - $stone) pedras" }
        if (-not $canClay) { $missing += "$($b.Clay - $clay) argilas" }
        if (-not $canCopper) { $missing += "$($b.Copper - $copperBar) barras cobre" }
        Write-Host ("  [PENDENTE MATERIAIS] {0}: Falta {1}" -f $b.Name, ($missing -join ", ")) -ForegroundColor DarkYellow
    }
}

# 5. O que guardar das colheitas
Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "4. O QUE GUARDAR DA SUA COLHEITA PARA RECEITAS E CONQUISTAS" -ForegroundColor Yellow
Write-Host "  * Couve-flor: Guarde 1 para o CC + 1 para a Jodi + 1 para a receita Cheese Cauli."
Write-Host "  * Morangos: Guarde 15 a 20 no baú (Presente amado Maru + Gerador de Sementes). Venda os ~150 restantes!"
Write-Host "  * Batata: Guarde 1 para o CC + 1 para a receita Hashbrowns."
Write-Host "  * Vagem: Guarde 1 para o CC + 1 para a receita Bean Hotpot."
Write-Host "  * Chirívia: Guarde 1 normal + 1 para Parsnip Soup + 1 Farmer's Lunch. Venda as 60+ restantes!"

Write-Host "`n==========================================================" -ForegroundColor Green
