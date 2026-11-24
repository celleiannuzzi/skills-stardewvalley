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

$dayOfWeekIndex = ($currentDay - 1) % 7
$dayNames = @("Segunda-feira", "Terca-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sabado", "Domingo")
$dayOfWeek = $dayNames[$dayOfWeekIndex]

# Carrinho Viajante (Sextas e Domingos: dias 5, 7, 12, 14, 19, 21, 26, 28)
$isMerchantDay = ($dayOfWeekIndex -eq 4 -or $dayOfWeekIndex -eq 6)
$daysUntilMerchant = if ($isMerchantDay) { 0 } elseif ($dayOfWeekIndex -lt 4) { 4 - $dayOfWeekIndex } elseif ($dayOfWeekIndex -eq 5) { 1 } else { 5 }
$nextMerchantDay = $currentDay + $daysUntilMerchant

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "     STARDEW VALLEY - STRATEGIC COMMAND & PRODUCTIVITY    " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Fazendeiro(a): $($farmer.name) | Fazenda: $($farmer.farmName) Farm" -ForegroundColor Cyan
Write-Host "Data Atual: Dia $currentDay ($dayOfWeek) de $season (Ano $year)" -ForegroundColor Cyan
Write-Host "Clima Atual: $(if ($weather -eq 'true') { 'Chovendo' } else { 'Ensolarado' }) | Carteira: $money g" -ForegroundColor Cyan
Write-Host "Mochila: $backpack espacos | Mina mais profunda: Andar $deepestMine" -ForegroundColor Cyan

if ($isMerchantDay) {
    Write-Host "[CARRINHO VIAJANTE] ESTA NA FLORESTA HOJE! (06h as 20h)" -ForegroundColor Magenta
    Write-Host "   (Visite a floresta ao sul da fazenda para checar itens raros do Centro Comunitario e Semente Rara!)" -ForegroundColor Yellow
} else {
    Write-Host ("* Carrinho Viajante: Proxima visita em {0} dias (Dia {1} - {2})" -f $daysUntilMerchant, $nextMerchantDay, $dayNames[($nextMerchantDay - 1) % 7]) -ForegroundColor DarkCyan
}

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
Write-Host "1. MUSEU (GUNTHER) - DOACOES PENDENTES GUARDADAS NO BAU" -ForegroundColor Magenta

$TOTAL_MUSEUM_PIECES = 95
$archLoc = $xml.SaveGame.locations.GameLocation | Where-Object { $_.Name -eq 'ArchaeologyHouse' }
$donatedIds = @()
if ($archLoc -and $archLoc.museumPieces -and $archLoc.museumPieces.item) {
    $archLoc.museumPieces.item | ForEach-Object { $donatedIds += $_.value.string }
}

$donatedCount = $donatedIds.Count
Write-Host ("Progresso Total do Museu: {0}/{1} itens doados (Faltam {2})" -f $donatedCount, $TOTAL_MUSEUM_PIECES, ($TOTAL_MUSEUM_PIECES - $donatedCount))

$museumItemsToDonate = @()
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
    Write-Host "ITENS NO SEU BAU QUE VOCE NUNCA DOOU AO MUSEU (Leve para o Gunther!):" -ForegroundColor Yellow
    foreach ($m in $museumItemsToDonate) {
        Write-Host ("  * [LEVAR AO MUSEU] {0} (voce tem {1} guardado)" -f $m.Name, $m.Qty) -ForegroundColor Green
    }
} else {
    Write-Host "  Nenhum mineral ou artefato pendente de doacao encontrado nos seus baus no momento." -ForegroundColor DarkGray
}

# 3. CENTRO COMUNITÁRIO - Parser exato do estado dos pacotes
Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "2. STATUS PRECISO DO CENTRO COMUNITÁRIO" -ForegroundColor Magenta

$locCC = $xml.SaveGame.locations.GameLocation | Where-Object { $_.Name -eq 'CommunityCenter' }
$ccReadyDeliveries = @()

if ($locCC -and $locCC.bundles -and $locCC.bundles.item) {
    $bundleStatusMap = @{}
    foreach ($b in $locCC.bundles.item) {
        $bundleStatusMap[[int]$b.key.int] = @($b.value.ArrayOfBoolean.boolean) | ForEach-Object { [bool]::Parse($_) }
    }
    
    # Checar áreas desbloqueadas
    # areasComplete: 0: Crafts Room, 1: Pantry, 2: Fish Tank, 3: Boiler Room, 4: Vault, 5: Bulletin Board
    $craftsRoomDone = $bundleStatusMap[13][0..3] -notcontains $false -and $bundleStatusMap[14][0..2] -notcontains $false -and $bundleStatusMap[15][0..3] -notcontains $false -and $bundleStatusMap[16][0..3] -notcontains $false
    $boilerRoomUnlocked = $craftsRoomDone -or ($locCC.areasComplete -and [bool]::Parse($locCC.areasComplete.boolean[0]))
    
    # 0 = Spring Crops (0: Parsnip, 1: Green Bean, 2: Cauliflower, 3: Potato)
    if ($bundleStatusMap[0]) {
        $b = $bundleStatusMap[0]
        $is0Complete = ($b[0..3] -notcontains $false)
        Write-Host "Pacote Lavouras da Primavera (Spring Crops):" -ForegroundColor Cyan
        if ($is0Complete) {
            Write-Host "  [X] PACOTE 100% COMPLETO! (Todas as 4 lavouras entregues)" -ForegroundColor Green
        } else {
            Write-Host ("  [{0}] Chirivia" -f $(if ($b[0]) { "X" } else { " " })) -ForegroundColor $(if ($b[0]) { "Green" } else { "Yellow" })
            Write-Host ("  [{0}] Vagem (Green Bean)" -f $(if ($b[1]) { "X" } else { " " })) -ForegroundColor $(if ($b[1]) { "Green" } else { "Magenta" })
            Write-Host ("  [{0}] Couve-flor" -f $(if ($b[2]) { "X" } else { " " })) -ForegroundColor $(if ($b[2]) { "Green" } else { "Yellow" })
            Write-Host ("  [{0}] Batata" -f $(if ($b[3]) { "X" } else { " " })) -ForegroundColor $(if ($b[3]) { "Green" } else { "Yellow" })
            
            if (-not $b[1] -and $allItems.ContainsKey("Green Bean")) {
                $ccReadyDeliveries += "Pacote Lavouras da Primavera: Vagem x1 [Voce tem no bau!]"
            }
        }
    }
    
    # 3 = Quality Crops (0: Parsnip 5 Gold, 1: Melon 5 Gold, 2: Pumpkin 5 Gold, 3: Corn 5 Gold)
    if ($bundleStatusMap[3]) {
        $b = $bundleStatusMap[3]
        Write-Host "`nPacote Lavouras de Qualidade (Quality Crops):" -ForegroundColor Cyan
        Write-Host ("  [{0}] 5 Chirivias Douradas" -f $(if ($b[0]) { "X" } else { " " })) -ForegroundColor $(if ($b[0]) { "Green" } else { "Yellow" })
        Write-Host ("  [{0}] 5 Meloes Dourados (Verao)" -f $(if ($b[1]) { "X" } else { " " })) -ForegroundColor DarkGray
        Write-Host ("  [{0}] 5 Aboboras Douradas (Outono)" -f $(if ($b[2]) { "X" } else { " " })) -ForegroundColor DarkGray
        Write-Host ("  [{0}] 5 Milhos Dourados (Verao/Outono)" -f $(if ($b[3]) { "X" } else { " " })) -ForegroundColor DarkGray
    }
    
    # 13 = Spring Foraging (0: Wild Horseradish, 1: Daffodil, 2: Leek, 3: Dandelion)
    if ($bundleStatusMap[13]) {
        $b = $bundleStatusMap[13]
        $is13Complete = ($b[0..3] -notcontains $false)
        Write-Host "`nPacote Coleta da Primavera (Spring Foraging):" -ForegroundColor Cyan
        if ($is13Complete) {
            Write-Host "  [X] PACOTE 100% COMPLETO! (Todas as 4 plantas entregues)" -ForegroundColor Green
        }
    }
    
    if (-not $boilerRoomUnlocked) {
        Write-Host "`n[BLOQUEADO] Sala da Caldeira (Boiler Room): AINDA BLOQUEADA" -ForegroundColor DarkGray
        Write-Host "  (Sera liberada pelos Junimos assim que voce completar a Sala de Artesanato/Crafts Room)." -ForegroundColor DarkGray
    }
}

if ($ccReadyDeliveries.Count -gt 0) {
    Write-Host "`nITENS PRONTOS NO SEU BAU PARA ENTREGAR AGORA:" -ForegroundColor Yellow
    foreach ($del in $ccReadyDeliveries) {
        Write-Host ("  * " + $del) -ForegroundColor Green
    }
}

# 4. Viabilidade de Construções (Robin)
Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "3. VIABILIDADE DE CONSTRUCOES COM SEUS MATERIAIS ATUAIS" -ForegroundColor Cyan

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
Write-Host "  * Couve-flor: Guarde 1 para a Jodi + 1 para a receita Cheese Cauli."
Write-Host "  * Morangos (Colhendo no Dia 25): Guarde 15 a 20 no bau (Presente amado Maru + Gerador de Sementes). Venda os ~150 restantes!"
Write-Host "  * Batata: Guarde 1 para a receita Hashbrowns."
Write-Host "  * Vagem (colhendo dia 25): Guarde 1 para o Centro Comunitario (completa o pacote!) + 1 para Bean Hotpot."
Write-Host "  * Chirivia: Guarde 1 para Parsnip Soup + 1 Farmer's Lunch. Venda as 60+ restantes!"

Write-Host "`n==========================================================" -ForegroundColor Green
