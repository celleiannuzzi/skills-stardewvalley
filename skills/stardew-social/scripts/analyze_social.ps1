param(
    [string]$TargetSave = "Dark",
    [string]$CheckNPC = ""
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

# Domingo é o dia em que o contador de presentes da semana é resetado no Stardew Valley.
# Cada estação tem 28 dias. Dia 1 = Segunda, 7 = Domingo, 14 = Domingo, 21 = Domingo, 28 = Domingo.
$dayOfWeekNum = ($currentDay - 1) % 7 # 0 = Segunda, 6 = Domingo
$daysUntilReset = 7 - $dayOfWeekNum
$resetDay = $currentDay + $daysUntilReset

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   STARDEW VALLEY - SOCIAL & RELATIONSHIP TRACKER         " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Jogador: $($farmer.name) | Calendario: Dia $currentDay de $season (Ano $year)" -ForegroundColor Cyan
Write-Host "Semana atual reseta no Domingo (Dia $resetDay de $season - faltam $daysUntilReset dias)" -ForegroundColor Cyan

# Lista completa de aniversários no Stardew Valley
$birthdays = @(
    # Primavera
    @{ Name = "Kent"; Season = "spring"; Day = 4; Datable = $false },
    @{ Name = "Lewis"; Season = "spring"; Day = 7; Datable = $false },
    @{ Name = "Vincent"; Season = "spring"; Day = 10; Datable = $false },
    @{ Name = "Haley"; Season = "spring"; Day = 14; Datable = $true },
    @{ Name = "Pam"; Season = "spring"; Day = 18; Datable = $false },
    @{ Name = "Shane"; Season = "spring"; Day = 20; Datable = $true },
    @{ Name = "Pierre"; Season = "spring"; Day = 26; Datable = $false },
    # Verão
    @{ Name = "Jas"; Season = "summer"; Day = 4; Datable = $false },
    @{ Name = "Gus"; Season = "summer"; Day = 8; Datable = $false },
    @{ Name = "Maru"; Season = "summer"; Day = 10; Datable = $true },
    @{ Name = "Alex"; Season = "summer"; Day = 13; Datable = $true },
    @{ Name = "Sam"; Season = "summer"; Day = 17; Datable = $true },
    @{ Name = "Demetrius"; Season = "summer"; Day = 19; Datable = $false },
    @{ Name = "Dwarf"; Season = "summer"; Day = 22; Datable = $false },
    @{ Name = "Willy"; Season = "summer"; Day = 24; Datable = $false },
    @{ Name = "Leo"; Season = "summer"; Day = 26; Datable = $false },
    # Outono
    @{ Name = "Penny"; Season = "fall"; Day = 2; Datable = $true },
    @{ Name = "Elliott"; Season = "fall"; Day = 5; Datable = $true },
    @{ Name = "Jodi"; Season = "fall"; Day = 11; Datable = $false },
    @{ Name = "Abigail"; Season = "fall"; Day = 13; Datable = $true },
    @{ Name = "Sandy"; Season = "fall"; Day = 15; Datable = $false },
    @{ Name = "Marnie"; Season = "fall"; Day = 18; Datable = $false },
    @{ Name = "Robin"; Season = "fall"; Day = 21; Datable = $false },
    @{ Name = "George"; Season = "fall"; Day = 24; Datable = $false },
    # Inverno
    @{ Name = "Krobus"; Season = "winter"; Day = 1; Datable = $false },
    @{ Name = "Linus"; Season = "winter"; Day = 3; Datable = $false },
    @{ Name = "Caroline"; Season = "winter"; Day = 7; Datable = $false },
    @{ Name = "Sebastian"; Season = "winter"; Day = 10; Datable = $true },
    @{ Name = "Harvey"; Season = "winter"; Day = 14; Datable = $true },
    @{ Name = "Wizard"; Season = "winter"; Day = 17; Datable = $false },
    @{ Name = "Emily"; Season = "winter"; Day = 20; Datable = $true },
    @{ Name = "Clint"; Season = "winter"; Day = 26; Datable = $false },
    @{ Name = "Leah"; Season = "winter"; Day = 23; Datable = $true }
)

# Tabela de Presentes Amados e Gostados (Itens comuns e acessíveis no save)
$giftDb = @{
    "Abigail" = @{ Loves = @("Amethyst", "Pumpkin", "Chocolate Cake", "Spicy Eel", "Blackberry Cobbler"); Likes = @("Quartz", "Topaz", "Aquamarine", "Earth Crystal") }
    "Alex" = @{ Loves = @("Complete Breakfast", "Salmon Dinner"); Likes = @("Egg", "Parsnip", "Potato", "Kale") }
    "Elliott" = @{ Loves = @("Crab Cakes", "Duck Feather", "Lobster", "Pomegranate", "Squid Ink"); Likes = @("Daffodil", "Tulip", "Blue Jazz", "Amethyst", "Aquamarine") }
    "Emily" = @{ Loves = @("Amethyst", "Aquamarine", "Cloth", "Emerald", "Jade", "Ruby", "Topaz", "Survival Burger"); Likes = @("Daffodil", "Quartz", "Dandelion") }
    "Haley" = @{ Loves = @("Coconut", "Fruit Salad", "Pink Cake", "Sunflower"); Likes = @("Daffodil") }
    "Harvey" = @{ Loves = @("Coffee", "Pickles", "Super Meal", "Truffle Oil", "Wine"); Likes = @("Daffodil", "Dandelion", "Wild Horseradish", "Spring Onion", "Parsnip", "Potato") }
    "Leah" = @{ Loves = @("Goat Cheese", "Salad", "Truffle", "Vegetable Medley", "Wine"); Likes = @("Dandelion", "Daffodil", "Driftwood", "Spring Onion", "Wild Horseradish", "Earth Crystal") }
    "Maru" = @{ Loves = @("Battery Pack", "Diamond", "Gold Bar", "Iridium Bar", "Miner's Treat", "Rhubarb Pie", "Strawberry", "Cauliflower"); Likes = @("Copper Bar", "Iron Bar", "Quartz", "Amethyst", "Pine Cone", "Earth Crystal") }
    "Penny" = @{ Loves = @("Diamond", "Emerald", "Melon", "Poppy", "Poppyseed Muffin", "Red Plate", "Roots Platter", "Sandfish"); Likes = @("Dandelion", "Leek", "Daffodil") }
    "Sam" = @{ Loves = @("Cactus Fruit", "Maple Bar", "Pizza", "Tigerseye"); Likes = @("Joja Cola", "Egg") }
    "Sebastian" = @{ Loves = @("Frozen Tear", "Obsidian", "Pumpkin Soup", "Sashimi", "Void Egg"); Likes = @("Quartz", "Flounder") }
    "Shane" = @{ Loves = @("Beer", "Hot Pepper", "Pepper Poppers", "Pizza"); Likes = @("Egg") }
    "Pierre" = @{ Loves = @("Fried Calamari"); Likes = @("Daffodil", "Dandelion", "Parsnip", "Potato", "Cauliflower") }
    "Lewis" = @{ Loves = @("Autumn's Bounty", "Glazed Yams", "Green Tea", "Hot Pepper"); Likes = @("Parsnip", "Potato", "Cauliflower", "Dandelion") }
    "Robin" = @{ Loves = @("Goat Cheese", "Peach", "Spaghetti"); Likes = @("Hardwood", "Iron Bar", "Quartz", "Wood") }
    "Linus" = @{ Loves = @("Blueberry Tart", "Cactus Fruit", "Coconut", "Dish O' The Sea", "Yam"); Likes = @("Dandelion", "Daffodil", "Spring Onion", "Wild Horseradish", "Cave Carrot", "Salmonberry") }
    "Pam" = @{ Loves = @("Beer", "Cactus Fruit", "Glazed Yams", "Mead", "Pale Ale", "Parsnip"); Likes = @("Daffodil", "Wild Horseradish", "Potato", "Parsnip") }
    "Willy" = @{ Loves = @("Catfish", "Diamond", "Iridium Bar", "Mead", "Octopus", "Pumpkin", "Sea Cucumber", "Sturgeon"); Likes = @("River Jelly", "Sea Jelly", "Quartz") }
}

# 1. Checar Aniversariantes Próximos (do restante do mês e início do próximo)
Write-Host "`n🎂 ANIVERSARIANTES PRÓXIMOS (Presentes no Aniversário valem 8x MAIS pontos!):" -ForegroundColor Magenta
$upcomingBirthdays = $birthdays | Where-Object { 
    ($_.Season -eq $season -and $_.Day -ge $currentDay) -or 
    ($_.Season -eq "summer" -and $season -eq "spring" -and $_.Day -le 10) 
} | Sort-Object { if ($_.Season -eq $season) { $_.Day } else { $_.Day + 28 } }

foreach ($b in $upcomingBirthdays) {
    $diff = if ($b.Season -eq $season) { $b.Day - $currentDay } else { (28 - $currentDay) + $b.Day }
    $datableStr = if ($b.Datable) { "(Solteiro(a) / Paquera)" } else { "" }
    $dayStr = if ($diff -eq 0) { "É HOJE!" } elseif ($diff -eq 1) { "AMANHÃ!" } else { "em $diff dias" }
    Write-Host ("  * Dia {0} ({1}): {2} {3} - {4}" -f $b.Day, $b.Season, $b.Name, $datableStr, $dayStr) -ForegroundColor Yellow
}

# 2. Ler Amizades do Jogador
$friendships = @()
if ($farmer.friendshipData -and $farmer.friendshipData.item) {
    foreach ($item in $farmer.friendshipData.item) {
        $npcName = $item.key.string
        $fs = $item.value.Friendship
        $pts = [int]$fs.Points
        $hearts = [math]::Floor($pts / 250)
        $giftsWeek = [int]$fs.GiftsThisWeek
        $giftsToday = [int]$fs.GiftsToday
        $status = [string]$fs.Status
        
        $isDatable = ($birthdays | Where-Object { $_.Name -eq $npcName -and $_.Datable -eq $true }) -ne $null
        $maxHearts = if ($isDatable) { 8 } else { 10 } # Antes do buquê
        
        $friendships += [PSCustomObject]@{
            Name = $npcName
            Hearts = $hearts
            Points = $pts
            GiftsThisWeek = $giftsWeek
            CanGiftToday = ($giftsToday -eq 0 -and $giftsWeek -lt 2)
            GiftsRemainingThisWeek = [math]::Max(0, (2 - $giftsWeek))
            IsDatable = $isDatable
            Status = $status
        }
    }
}

Write-Host "`n----------------------------------------------------------" -ForegroundColor Gray
Write-Host "2. STATUS DE PRESENTES DA SEMANA (Limite de 2 por morador)" -ForegroundColor Cyan
Write-Host "Semana atual reseta no Dia $resetDay (Domingo)."

$candTable = @()
foreach ($f in ($friendships | Sort-Object Hearts, Points -Descending)) {
    $type = if ($f.IsDatable) { "Solteiro(a)" } else { "Morador" }
    $giftStatus = if ($f.GiftsRemainingThisWeek -gt 0) {
        if ($f.CanGiftToday) { "Pode dar presente HOJE ($($f.GiftsRemainingThisWeek) restantes na semana)" } else { "Ja deu presente hoje! (Ainda pode dar 1 outro dia)" }
    } else {
        "Limite atingido nesta semana (Aguarde domingo dia $resetDay)"
    }
    
    $candTable += [PSCustomObject]@{
        Personagem = $f.Name
        Tipo = $type
        Coracoes = "$($f.Hearts) ♥ ($($f.Points) pts)"
        PresentesEntregues = "$($f.GiftsThisWeek)/2"
        StatusPresente = $giftStatus
    }
}

$candTable | Format-Table -AutoSize | Out-String | Write-Host

# 3. Se um NPC específico foi consultado, cruzar com o inventário real
# Coletar itens reais do jogador (inventário + baús)
$allItemsInGame = @{}
if ($farmer.items -and $farmer.items.Item) {
    foreach ($it in $farmer.items.Item) {
        if ($it -and $it.Name) {
            if (-not $allItemsInGame.ContainsKey($it.Name)) { $allItemsInGame[$it.Name] = 0 }
            $st = if ($it.Stack) { [int]$it.Stack } else { 1 }
            $allItemsInGame[$it.Name] += $st
        }
    }
}
foreach ($loc in $xml.SaveGame.locations.GameLocation) {
    if ($loc.objects -and $loc.objects.item) {
        foreach ($o in $loc.objects.item) {
            if ($o.value.Object.items) {
                foreach ($ci in $o.value.Object.items.Item) {
                    if ($ci -and $ci.Name) {
                        if (-not $allItemsInGame.ContainsKey($ci.Name)) { $allItemsInGame[$ci.Name] = 0 }
                        $st = if ($ci.Stack) { [int]$ci.Stack } else { 1 }
                        $allItemsInGame[$ci.Name] += $st
                    }
                }
            }
        }
    }
}

if ($CheckNPC) {
    Write-Host "----------------------------------------------------------" -ForegroundColor Gray
    Write-Host "3. SUGESTÃO PERSONALIZADA DE PRESENTES PARA: $CheckNPC" -ForegroundColor Yellow
    $gInfo = $giftDb[$CheckNPC]
    if ($gInfo) {
        Write-Host "`n💖 PRESENTES AMADOS (Loved - +80 pontos):" -ForegroundColor Magenta
        $foundLove = $false
        foreach ($l in $gInfo.Loves) {
            if ($allItemsInGame.ContainsKey($l)) {
                $qty = $allItemsInGame[$l]
                Write-Host ("  [SIM! VOCE TEM NO BAU] {0} x{1}" -f $l, $qty) -ForegroundColor Green
                $foundLove = $true
            } else {
                Write-Host ("  [Nao possui] $l") -ForegroundColor DarkGray
            }
        }
        
        Write-Host "`n👍 PRESENTES GOSTADOS (Liked - +45 pontos):" -ForegroundColor Cyan
        $foundLike = $false
        foreach ($lk in $gInfo.Likes) {
            if ($allItemsInGame.ContainsKey($lk)) {
                $qty = $allItemsInGame[$lk]
                Write-Host ("  [SIM! VOCE TEM NO BAU] {0} x{1}" -f $lk, $qty) -ForegroundColor Green
                $foundLike = $true
            } else {
                Write-Host ("  [Nao possui] $lk") -ForegroundColor DarkGray
            }
        }
    } else {
        Write-Host "NPC '$CheckNPC' nao encontrado na base rapida ou digitado incorretamente."
    }
} else {
    Write-Host "----------------------------------------------------------" -ForegroundColor Gray
    Write-Host "💡 Quer saber exatamente quais presentes perfeitos você tem nos baús para alguém?" -ForegroundColor Cyan
    Write-Host "Basta me dizer o nome do personagem (ex: 'Quais opções eu tenho para a Leah?' ou 'E para o Pierre?')!" -ForegroundColor Yellow
}

Write-Host "`n==========================================================" -ForegroundColor Green
