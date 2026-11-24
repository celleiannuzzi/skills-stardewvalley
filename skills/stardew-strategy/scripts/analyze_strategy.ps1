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
$isRaining = ($weather -eq 'true')

$dayOfWeekIndex = ($currentDay - 1) % 7
$dayNames = @("Segunda-feira", "Terca-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sabado", "Domingo")
$dayOfWeek = $dayNames[$dayOfWeekIndex]

# Carrinho Viajante (Sextas e Domingos)
$isMerchantDay = ($dayOfWeekIndex -eq 4 -or $dayOfWeekIndex -eq 6)
$daysUntilMerchant = if ($isMerchantDay) { 0 } elseif ($dayOfWeekIndex -lt 4) { 4 - $dayOfWeekIndex } elseif ($dayOfWeekIndex -eq 5) { 1 } else { 5 }
$nextMerchantDay = $currentDay + $daysUntilMerchant

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "     STARDEW VALLEY - STRATEGIC COMMAND & PRODUCTIVITY    " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Fazendeiro(a): $($farmer.name) | Fazenda: $($farmer.farmName) Farm" -ForegroundColor Cyan
Write-Host "Data Atual: Dia $currentDay ($dayOfWeek) de $season (Ano $year)" -ForegroundColor Cyan
Write-Host "Clima Atual: $(if ($isRaining) { 'Chovendo 🌧️' } else { 'Ensolarado ☀️' }) | Carteira: $money g" -ForegroundColor Cyan
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
$isFishTankComplete = $false
$ccIsDone = ($farmer.mailReceived.string -contains "ccIsComplete")

if ($locCC -and $locCC.bundles -and $locCC.bundles.item) {
    $bundleStatusMap = @{}
    foreach ($b in $locCC.bundles.item) {
        $bundleStatusMap[[int]$b.key.int] = @($b.value.ArrayOfBoolean.boolean) | ForEach-Object { [bool]::Parse($_) }
    }
    
    # Checar áreas desbloqueadas
    $craftsRoomDone = $bundleStatusMap[13][0..3] -notcontains $false -and $bundleStatusMap[14][0..2] -notcontains $false -and $bundleStatusMap[15][0..3] -notcontains $false -and $bundleStatusMap[16][0..3] -notcontains $false
    $boilerRoomUnlocked = $craftsRoomDone -or ($locCC.areasComplete -and [bool]::Parse($locCC.areasComplete.boolean[0]))
    
    # Checar Aquário (6 a 11)
    $fishBundlesDone = 0
    foreach ($fId in @(6,7,8,9,10,11)) {
        if ($bundleStatusMap[$fId]) {
            $b = $bundleStatusMap[$fId]
            if ($fId -eq 6 -and $b[0..3] -notcontains $false) { $fishBundlesDone++ }
            elseif ($fId -eq 7 -and $b[0..3] -notcontains $false) { $fishBundlesDone++ }
            elseif ($fId -eq 8 -and $b[0..3] -notcontains $false) { $fishBundlesDone++ }
            elseif ($fId -eq 9 -and $b[0..2] -notcontains $false) { $fishBundlesDone++ }
            elseif ($fId -eq 10 -and $b[0..3] -notcontains $false) { $fishBundlesDone++ }
            elseif ($fId -eq 11 -and ($b | Where-Object { $_ -eq $true }).Count -ge 5) { $fishBundlesDone++ }
        }
    }
    $isFishTankComplete = ($fishBundlesDone -ge 6)

    # 0 = Spring Crops
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
        }
    }
    
    # 3 = Quality Crops
    if ($bundleStatusMap[3]) {
        $b = $bundleStatusMap[3]
        Write-Host "`nPacote Lavouras de Qualidade (Quality Crops):" -ForegroundColor Cyan
        Write-Host ("  [{0}] 5 Chirivias Douradas" -f $(if ($b[0]) { "X" } else { " " })) -ForegroundColor $(if ($b[0]) { "Green" } else { "Yellow" })
        Write-Host ("  [{0}] 5 Meloes Dourados (Verao)" -f $(if ($b[1]) { "X" } else { " " })) -ForegroundColor DarkGray
        Write-Host ("  [{0}] 5 Aboboras Douradas (Outono)" -f $(if ($b[2]) { "X" } else { " " })) -ForegroundColor DarkGray
        Write-Host ("  [{0}] 5 Milhos Dourados (Verao/Outono)" -f $(if ($b[3]) { "X" } else { " " })) -ForegroundColor DarkGray
    }
    
    # 13 = Spring Foraging
    if ($bundleStatusMap[13]) {
        $b = $bundleStatusMap[13]
        $is13Complete = ($b[0..3] -notcontains $false)
        Write-Host "`nPacote Coleta da Primavera (Spring Foraging):" -ForegroundColor Cyan
        if ($is13Complete) {
            Write-Host "  [X] PACOTE 100% COMPLETO! (Todas as 4 plantas entregues)" -ForegroundColor Green
        }
    }
    
    # Checar se o jogador tem peixes no baú para entregar no Aquário
    # 6: River (145 Sunfish, 143 Catfish, 706 Shad, 699 Tiger Trout)
    if ($bundleStatusMap[6]) {
        if (-not $bundleStatusMap[6][0] -and $allItems.ContainsKey("Sunfish")) { $ccReadyDeliveries += "Aquario (Rio): Peixe-Sol (Sunfish) x1 [No bau!]" }
        if (-not $bundleStatusMap[6][1] -and $allItems.ContainsKey("Catfish")) { $ccReadyDeliveries += "Aquario (Rio): Bagre (Catfish) x1 [No bau!]" }
        if (-not $bundleStatusMap[6][2] -and $allItems.ContainsKey("Shad")) { $ccReadyDeliveries += "Aquario (Rio): Savelha (Shad) x1 [No bau!]" }
        if (-not $bundleStatusMap[6][3] -and $allItems.ContainsKey("Tiger Trout")) { $ccReadyDeliveries += "Aquario (Rio): Truta Tigre x1 [No bau!]" }
    }
    # 7: Lake (136 Largemouth Bass, 142 Carp, 700 Bullhead, 698 Sturgeon)
    if ($bundleStatusMap[7]) {
        if (-not $bundleStatusMap[7][0] -and $allItems.ContainsKey("Largemouth Bass")) { $ccReadyDeliveries += "Aquario (Lago): Achiga (Largemouth Bass) x1 [No bau!]" }
        if (-not $bundleStatusMap[7][1] -and $allItems.ContainsKey("Carp")) { $ccReadyDeliveries += "Aquario (Lago): Carpa (Carp) x1 [Voce tem no bau da Montanha!]" }
        if (-not $bundleStatusMap[7][2] -and $allItems.ContainsKey("Bullhead")) { $ccReadyDeliveries += "Aquario (Lago): Peixe-gato (Bullhead) x1 [No bau!]" }
        if (-not $bundleStatusMap[7][3] -and $allItems.ContainsKey("Sturgeon")) { $ccReadyDeliveries += "Aquario (Lago): Esturjao (Sturgeon) x1 [No bau!]" }
    }
    # 8: Ocean (131 Sardine, 130 Tuna, 150 Red Snapper, 701 Tilapia)
    if ($bundleStatusMap[8]) {
        if (-not $bundleStatusMap[8][0] -and $allItems.ContainsKey("Sardine")) { $ccReadyDeliveries += "Aquario (Oceano): Sardinha (Sardine) x1 [No bau!]" }
        if (-not $bundleStatusMap[8][1] -and $allItems.ContainsKey("Tuna")) { $ccReadyDeliveries += "Aquario (Oceano): Atum (Tuna) x1 [No bau!]" }
        if (-not $bundleStatusMap[8][2] -and $allItems.ContainsKey("Red Snapper")) { $ccReadyDeliveries += "Aquario (Oceano): Pargo Vermelho x1 [No bau!]" }
        if (-not $bundleStatusMap[8][3] -and $allItems.ContainsKey("Tilapia")) { $ccReadyDeliveries += "Aquario (Oceano): Tilapia x1 [No bau!]" }
    }
    # 9: Night (140 Walleye, 132 Bream, 148 Eel)
    if ($bundleStatusMap[9]) {
        if (-not $bundleStatusMap[9][0] -and $allItems.ContainsKey("Walleye")) { $ccReadyDeliveries += "Aquario (Noturno): Picao-verde (Walleye) x1 [No bau!]" }
        if (-not $bundleStatusMap[9][1] -and $allItems.ContainsKey("Bream")) { $ccReadyDeliveries += "Aquario (Noturno): Brema (Bream) x1 [No bau!]" }
        if (-not $bundleStatusMap[9][2] -and $allItems.ContainsKey("Eel")) { $ccReadyDeliveries += "Aquario (Noturno): Enguia (Eel) x1 [No bau!]" }
    }
    # 10: Specialty (128 Pufferfish, 156 Ghostfish, 164 Sandfish, 734 Woodskip)
    if ($bundleStatusMap[10]) {
        if (-not $bundleStatusMap[10][0] -and $allItems.ContainsKey("Pufferfish")) { $ccReadyDeliveries += "Aquario (Especial): Baiacu (Pufferfish) x1 [No bau!]" }
        if (-not $bundleStatusMap[10][1] -and $allItems.ContainsKey("Ghostfish")) { $ccReadyDeliveries += "Aquario (Especial): Peixe-fantasma x1 [No bau!]" }
        if (-not $bundleStatusMap[10][2] -and $allItems.ContainsKey("Sandfish")) { $ccReadyDeliveries += "Aquario (Especial): Peixe-areia x1 [No bau!]" }
        if (-not $bundleStatusMap[10][3] -and $allItems.ContainsKey("Woodskip")) { $ccReadyDeliveries += "Aquario (Especial): Madeira-flutuante x1 [No bau!]" }
    }
    # 11: Crab Pot
    if ($bundleStatusMap[11]) {
        $crabItems = @("Clam", "Cockle", "Mussel", "Oyster", "Crab", "Crayfish", "Lobster", "Shrimp", "Snail", "Periwinkle")
        foreach ($ci in $crabItems) {
            if ($allItems.ContainsKey($ci)) {
                $ccReadyDeliveries += "Aquario (Covo): $ci x1 [Voce tem $($allItems[$ci]) no bau!]"
            }
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

# 4. RADAR TÁTICO DE PESCA DO DIA (Clima, Estação, Centro Comunitário, Defumador e Receitas)
Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "3. GUIA TÁTICO DE PESCA DE HOJE (CLIMA: $(if ($isRaining) { 'CHUVA' } else { 'SOL' }) | ESTACAO: $season)" -ForegroundColor Cyan

# Catálogo mestre de peixes com estações, clima, local, horário, preço base, necessidade CC e receitas específicas
$fishMasterDb = @(
    # Primavera
    @{ Name = "Peixe-Sol (Sunfish)"; Seasons = @("spring", "summer"); Rain = $false; Sun = $true; Loc = "Rio (Cidade/Floresta)"; Time = "06h as 19h"; BaseSell = 30; CCBundle = "Peixes do Rio"; Recipe = "Nenhuma especifica" },
    @{ Name = "Bagre (Catfish)"; Seasons = @("spring", "fall"); Rain = $true; Sun = $false; Loc = "Rio / Pantano"; Time = "06h as 24h"; BaseSell = 200; CCBundle = "Peixes do Rio"; Recipe = "Nenhuma especifica" },
    @{ Name = "Savelha (Shad)"; Seasons = @("spring", "summer", "fall"); Rain = $true; Sun = $false; Loc = "Rio"; Time = "09h as 02h"; BaseSell = 60; CCBundle = "Peixes do Rio"; Recipe = "Nenhuma especifica" },
    @{ Name = "Carpa (Carp)"; Seasons = @("spring", "summer", "fall", "winter"); Rain = $true; Sun = $true; Loc = "Lago da Montanha / Bosque"; Time = "Qualquer hora"; BaseSell = 30; CCBundle = "Peixes do Lago"; Recipe = "Carpa Assada (Baked Carp - Carp + Caverna Cenoura)" },
    @{ Name = "Achiga (Largemouth Bass)"; Seasons = @("spring", "summer", "fall", "winter"); Rain = $true; Sun = $true; Loc = "Lago da Montanha"; Time = "06h as 19h"; BaseSell = 100; CCBundle = "Peixes do Lago"; Recipe = "Sopa de Peixe Fresco (Crispy Bass - Bass + Trigo + Oleo)" },
    @{ Name = "Peixe-gato (Bullhead)"; Seasons = @("spring", "summer", "fall", "winter"); Rain = $true; Sun = $true; Loc = "Lago da Montanha"; Time = "Qualquer hora"; BaseSell = 75; CCBundle = "Peixes do Lago"; Recipe = "Nenhuma especifica" },
    @{ Name = "Sardinha (Sardine)"; Seasons = @("spring", "fall", "winter"); Rain = $true; Sun = $true; Loc = "Oceano (Praia)"; Time = "06h as 19h"; BaseSell = 40; CCBundle = "Peixes do Oceano"; Recipe = "Prato do Mar (Dish O' The Sea - Sardinha x2 + Hashbrowns)" },
    @{ Name = "Brema (Bream)"; Seasons = @("spring", "summer", "fall", "winter"); Rain = $true; Sun = $true; Loc = "Rio"; Time = "18h as 02h"; BaseSell = 45; CCBundle = "Pesca Noturna"; Recipe = "Nenhuma especifica" },
    @{ Name = "Enguia (Eel)"; Seasons = @("spring", "fall"); Rain = $true; Sun = $false; Loc = "Oceano (Praia)"; Time = "16h as 02h"; BaseSell = 120; CCBundle = "Pesca Noturna"; Recipe = "Enguia Frita (Fried Eel - Eel + Oleo), Enguia Picante (Spicy Eel)" },
    @{ Name = "Peixe-fantasma (Ghostfish)"; Seasons = @("spring", "summer", "fall", "winter"); Rain = $true; Sun = $true; Loc = "Mina (Andar 20 e 60)"; Time = "Qualquer hora"; BaseSell = 45; CCBundle = "Peixes Especiais"; Recipe = "Nenhuma especifica" },
    @{ Name = "Madeira-flutuante (Woodskip)"; Seasons = @("spring", "summer", "fall", "winter"); Rain = $true; Sun = $true; Loc = "Bosque Secreto (Lago)"; Time = "Qualquer hora"; BaseSell = 75; CCBundle = "Peixes Especiais"; Recipe = "Nenhuma especifica" },
    # Verão
    @{ Name = "Esturjao (Sturgeon)"; Seasons = @("summer", "winter"); Rain = $true; Sun = $true; Loc = "Lago da Montanha"; Time = "06h as 19h"; BaseSell = 200; CCBundle = "Peixes do Lago"; Recipe = "Nenhuma (Gera Caviar no Pescador!)" },
    @{ Name = "Atum (Tuna)"; Seasons = @("summer", "winter"); Rain = $true; Sun = $true; Loc = "Oceano"; Time = "06h as 19h"; BaseSell = 100; CCBundle = "Peixes do Oceano"; Recipe = "Cacapeixe (Fish Taco - Tuna + Tortilha + Repolho Vermelho + Maionese)" },
    @{ Name = "Pargo Vermelho (Red Snapper)"; Seasons = @("summer", "fall"); Rain = $true; Sun = $false; Loc = "Oceano"; Time = "06h as 19h"; BaseSell = 50; CCBundle = "Peixes do Oceano"; Recipe = "Nenhuma especifica" },
    @{ Name = "Tilapia (Tilapia)"; Seasons = @("summer", "fall"); Rain = $true; Sun = $true; Loc = "Oceano"; Time = "06h as 14h"; BaseSell = 75; CCBundle = "Peixes do Oceano"; Recipe = "Nenhuma especifica" },
    @{ Name = "Baiacu (Pufferfish)"; Seasons = @("summer"); Rain = $false; Sun = $true; Loc = "Oceano"; Time = "12h as 16h"; BaseSell = 200; CCBundle = "Peixes Especiais"; Recipe = "Nenhuma especifica" },
    @{ Name = "Truta Arco-Iris (Rainbow Trout)"; Seasons = @("summer"); Rain = $false; Sun = $true; Loc = "Rio da Montanha / Cidade"; Time = "06h as 19h"; BaseSell = 65; CCBundle = "Nenhum"; Recipe = "Bolo de Truta (Trout Soup - Rainbow Trout)" },
    # Outono / Inverno
    @{ Name = "Truta Tigre (Tiger Trout)"; Seasons = @("fall", "winter"); Rain = $true; Sun = $true; Loc = "Rio"; Time = "06h as 19h"; BaseSell = 150; CCBundle = "Peixes do Rio"; Recipe = "Nenhuma especifica" },
    @{ Name = "Picao-verde (Walleye)"; Seasons = @("fall"); Rain = $true; Sun = $false; Loc = "Rio / Lago"; Time = "12h as 02h"; BaseSell = 105; CCBundle = "Pesca Noturna"; Recipe = "Nenhuma especifica" },
    @{ Name = "Lula (Squid)"; Seasons = @("winter"); Rain = $true; Sun = $true; Loc = "Oceano"; Time = "18h as 02h"; BaseSell = 80; CCBundle = "Nenhum"; Recipe = "Lula Frita (Fried Squid - Squid + Trigo + Oleo)" }
)

# Filtrar peixes disponíveis hoje (estação + clima)
$availableToday = $fishMasterDb | Where-Object { 
    $_.Seasons -contains $season -and 
    (($isRaining -and $_.Rain) -or (-not $isRaining -and $_.Sun))
}

$ccFishNeeded = @()
$moneyFish = @()

foreach ($f in $availableToday) {
    # Checar se ainda falta no CC
    $isNeededInCC = $false
    if (-not $isFishTankComplete) {
        if ($f.CCBundle -eq "Peixes do Rio" -and $bundleStatusMap[6] -and ($bundleStatusMap[6][0..3] -contains $false)) { $isNeededInCC = $true }
        elseif ($f.CCBundle -eq "Peixes do Lago" -and $bundleStatusMap[7] -and ($bundleStatusMap[7][0..3] -contains $false)) { $isNeededInCC = $true }
        elseif ($f.CCBundle -eq "Peixes do Oceano" -and $bundleStatusMap[8] -and ($bundleStatusMap[8][0..3] -contains $false)) { $isNeededInCC = $true }
        elseif ($f.CCBundle -eq "Pesca Noturna" -and $bundleStatusMap[9] -and ($bundleStatusMap[9][0..2] -contains $false)) { $isNeededInCC = $true }
        elseif ($f.CCBundle -eq "Peixes Especiais" -and $bundleStatusMap[10] -and ($bundleStatusMap[10][0..3] -contains $false)) { $isNeededInCC = $true }
    }
    
    # Cálculo Defumador 1.6 (Fish Smoker):
    # O defumador dobra o valor do peixe (2x Preço Base) e mantém a qualidade da estrela!
    # Consome 1 peixe + 1 carvão em ~50 minutos.
    $smokedPrice = $f.BaseSell * 2
    $roiAdvice = if ($f.BaseSell -ge 80) { "EXCELENTE NO DEFUMADOR (Venda defumado por $smokedPrice g+)" } else { "Venda Puro ou Isca (Peixe barato, nao gasta carvao)" }
    
    $fObj = [PSCustomObject]@{
        Nome = $f.Name
        Local = $f.Loc
        Horario = $f.Time
        PrecoBase = "$($f.BaseSell) g"
        PrecoDefumado = "$smokedPrice g"
        ConselhoROI = $roiAdvice
        ReceitaCulinaria = $f.Recipe
        CC = if ($isNeededInCC) { "[FALTA NO CC: $($f.CCBundle)]" } else { "Disponivel" }
    }
    
    if ($isNeededInCC) {
        $ccFishNeeded += $fObj
    } else {
        $moneyFish += $fObj
    }
}

if ($ccFishNeeded.Count -gt 0) {
    Write-Host "🚨 PEIXES QUE VOCÊ DEVE PESCAR HOJE PARA O CENTRO COMUNITÁRIO:" -ForegroundColor Yellow
    foreach ($cf in $ccFishNeeded) {
        Write-Host ("  * {0} | Local: {1} | Horario: {2}" -f $cf.Nome, $cf.Local, $cf.Horario) -ForegroundColor Green
        Write-Host ("    -> Meta: {0} | Lucro Defumado: {1} (Base: {2})" -f $cf.CC, $cf.PrecoDefumado, $cf.PrecoBase) -ForegroundColor DarkGreen
        if ($cf.ReceitaCulinaria -ne "Nenhuma especifica") {
            Write-Host ("    -> Receita da Perfeicao: {0}" -f $cf.ReceitaCulinaria) -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "✅ Todos os peixes do Centro Comunitario da estacao/clima de hoje ja foram entregues ou o Aquario esta concluido!" -ForegroundColor Green
}

Write-Host "`n💰 MELHORES PEIXES PARA LUCRO / DEFUMADOR HOJE (CLIMA ATUAL):" -ForegroundColor Cyan
$topMoney = $moneyFish | Sort-Object { [int]($_.PrecoBase -replace '\D') } -Descending | Select-Object -First 4
foreach ($mf in $topMoney) {
    Write-Host ("  * {0} ({1}) | {2} | {3}" -f $mf.Nome, $mf.PrecoBase, $mf.Local, $mf.Horario) -ForegroundColor Yellow
    Write-Host ("    -> Dica 1.6: {0}" -f $mf.ConselhoROI) -ForegroundColor DarkYellow
    if ($mf.ReceitaCulinaria -ne "Nenhuma especifica") {
        Write-Host ("    -> Receita Guardar: {0}" -f $mf.ReceitaCulinaria) -ForegroundColor DarkCyan
    }
}

# 5. Viabilidade de Construções (Robin)
Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "4. VIABILIDADE DE CONSTRUCOES COM SEUS MATERIAIS ATUAIS" -ForegroundColor Cyan

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

# 6. O que guardar das colheitas
Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "5. O QUE GUARDAR DA SUA COLHEITA PARA RECEITAS E CONQUISTAS" -ForegroundColor Yellow
Write-Host "  * Couve-flor: Guarde 1 para a Jodi + 1 para a receita Cheese Cauli."
Write-Host "  * Morangos: Guarde 15 a 20 no bau (Presente amado Maru + Gerador de Sementes). Venda os ~150 restantes!"
Write-Host "  * Batata: Guarde 1 para a receita Hashbrowns."
Write-Host "  * Vagem: Guarde 1 para a receita Bean Hotpot."
Write-Host "  * Chirivia: Guarde 1 para Parsnip Soup + 1 Farmer's Lunch. Venda as 60+ restantes!"

Write-Host "`n==========================================================" -ForegroundColor Green
