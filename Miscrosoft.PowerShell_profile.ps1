oh-my-posh init pwsh --config 'YOUR OH MY POSH THEME LOCATION PATH' | Invoke-Expression

Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell) -join "`n"
})

$whoami = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$username = $whoami.Split('\')[-1]
Write-Host "Hi, $username" -ForegroundColor Black -BackgroundColor DarkCyan
$length = $username.Length
$equalString = "=" * ($length + 4)
Write-Host "$equalString`n" -ForegroundColor Black -BackgroundColor DarkCyan


$apiKey = "YOUR API KEY" #Create it by sign in to api.api-ninjas.com
$url = "https://api.api-ninjas.com/v1/quotes"
$headers = @{ "X-Api-Key" = $apiKey }

$categoryColors = @{
    "age"            = "Gray"
    "alone"          = "DarkBlue"
    "amazing"        = "Yellow"
    "anger"          = "Red"
    "architecture"   = "DarkGray"
    "art"            = "Magenta"
    "attitude"       = "DarkMagenta"
    "beauty"         = "Cyan"
    "best"           = "Green"
    "birthday"       = "DarkYellow"
    "business"       = "DarkBlue"
    "car"            = "Red"
    "change"         = "DarkYellow"
    "communication"  = "Cyan"
    "computers"      = "DarkGreen"
    "cool"           = "DarkCyan"
    "courage"        = "DarkMagenta"
    "dad"            = "DarkBlue"
    "dating"         = "Red"
    "death"          = "Gray"
    "design"         = "Blue"
    "dreams"         = "Blue"
    "education"      = "Green"
    "environmental"  = "Green"
    "equality"       = "White"
    "experience"     = "Gray"
    "failure"        = "DarkRed"
    "faith"          = "White"
    "family"         = "Green"
    "famous"         = "Yellow"
    "fear"           = "DarkRed"
    "fitness"        = "DarkGreen"
    "food"           = "Yellow"
    "forgiveness"    = "Cyan"
    "freedom"        = "Blue"
    "friendship"     = "Cyan"
    "funny"          = "DarkCyan"
    "future"         = "Blue"
    "god"            = "White"
    "good"           = "Green"
    "government"     = "DarkBlue"
    "graduation"     = "Blue"
    "great"          = "Yellow"
    "happiness"      = "Yellow"
    "health"         = "Green"
    "history"        = "Gray"
    "home"           = "DarkYellow"
    "hope"           = "Blue"
    "humor"          = "Magenta"
    "imagination"    = "Magenta"
    "inspirational"  = "Yellow"
    "intelligence"   = "DarkBlue"
    "jealousy"       = "Green"
    "knowledge"      = "Blue"
    "leadership"     = "DarkBlue"
    "learning"       = "Green"
    "legal"          = "DarkGray"
    "life"           = "Green"
    "love"           = "Red"
    "marriage"       = "Magenta"
    "medical"        = "Red"
    "men"            = "Blue"
    "mom"            = "Magenta"
    "money"          = "Green"
    "morning"        = "Yellow"
    "movies"         = "DarkBlue"
    "success"        = "Green"
}

try {
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    $quote    = $response[0].quote
    $author   = $response[0].author
    $category = $response[0].category
} catch {
    $quote    = "Jangan Lupa Baca Bismillah!"
    $author   = "Unknown"
    $category = "default"
}

if ([string]::IsNullOrEmpty($category)) {
    $category = "default"
}

if ($categoryColors.ContainsKey($category)) {
    $bgColor = $categoryColors[$category]
} else {
    $bgColor = "White"
}

Write-Host "`"$quote`" - " -ForegroundColor $bgColor -BackgroundColor Black -NoNewLine
Write-Host "$author" -ForegroundColor Black -BackgroundColor $bgColor

$logFile = "$HOME\quotes.txt"
$newQuote = @{
    quote    = $quote
    author   = $author
    category = $category
}

if (Test-Path $logFile) {
    $jsonContent = Get-Content -Path $logFile -Raw
    if (-not [string]::IsNullOrWhiteSpace($jsonContent)) {
        $temp = $jsonContent | ConvertFrom-Json
        if ($temp -is [array]) {
            $quoteArray = $temp
        } else {
            $quoteArray = @($temp)
        }
    } else {
        $quoteArray = @()
    }
} else {
    $quoteArray = @()
}

$quoteArray = @($quoteArray) + @($newQuote)
$jsonOutput = $quoteArray | ConvertTo-Json -Depth 3

if ($jsonOutput.TrimStart()[0] -ne "[") {
    $jsonOutput = "[" + $jsonOutput + "]"
}

Set-Content -Path $logFile -Value $jsonOutput

Add-Type -AssemblyName System.Device
$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
$GeoWatcher.Start()

while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
    Start-Sleep -Milliseconds 100
}

if ($GeoWatcher.Permission -eq 'Denied') {
    Write-Error 'Access Denied for Location Information'
    exit
} else {
    $location = $GeoWatcher.Position.Location
    $lat = $location.Latitude
    $lon = $location.Longitude
}

$culture = [System.Globalization.CultureInfo]::GetCultureInfo("id-ID")

$apiKey = "YOUR API KEY" #Create it on api.openweathermap.org
$forecastUrl = "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric"

try {
    $forecastResponse = Invoke-RestMethod -Uri $forecastUrl -Method Get

    $cityName = $forecastResponse.city.name
    $country = $forecastResponse.city.country
    Write-Host "`nForecast untuk $cityName, $country [$lat, $lon]:" -ForegroundColor Cyan

    $desiredHours = @(6, 12, 18)
    $today = (Get-Date).Date
    $besok = $today.AddDays(1)
    $lusa = $today.AddDays(2)
    $datesToShow = @($today, $besok, $lusa)

    $filteredForecasts = $forecastResponse.list | Where-Object {
        $dt = [datetime]$_.dt_txt
        ($datesToShow -contains $dt.Date) -and ($desiredHours -contains $dt.Hour)
    }

    $groupedForecasts = $filteredForecasts | Group-Object { ([datetime]$_.dt_txt).ToString("yyyy-MM-dd") }

    foreach ($group in $groupedForecasts) {
        $groupDate = [datetime]$group.Name
        if ($groupDate -eq $today) {
            $label = "Hari Ini"
        }
        elseif ($groupDate -eq $besok) {
            $label = "Besok"
        }
        elseif ($groupDate -eq $lusa) {
            $label = "Lusa"
        }
        else {
            $label = $groupDate.ToString("dddd", $culture)
        }
        $dateFormatted = $groupDate.ToString("dd-MM-yyyy", $culture)
        Write-Host "`n${label}: $($groupDate.ToString("dddd", $culture)), $dateFormatted" -ForegroundColor Yellow


        foreach ($item in $group.Group) {
            $dt = [datetime]$item.dt_txt
            $time = $dt.ToString("HH:mm")
            $degree = [char]0x00B0
            $temp = [math]::Round($item.main.temp, 1)
            $tempString = "{0:N1}{1}C" -f $temp, $degree
            $description = $item.weather[0].description
            Write-Host "Pukul $time - Temp: $tempString, Kondisi: $description"
        }
    }
}
catch {
    Write-Error "Gagal mengambil informasi forecast: $_"
}
Write-Host ""
