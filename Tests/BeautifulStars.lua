--!strict

-- Services:

local ServerStorage     =   game:GetService("ServerStorage")
local ReplicatedStorage =   game:GetService("ReplicatedStorage")

-- Libraries:

local Astronomy =   require(ServerStorage["Algaerhythms"]["Astronomy"])
local Debug     =   require(ReplicatedStorage["Debug"])

-- Test:

local BSC5JSON = Astronomy["BSC5JSON"]
local starCount = #BSC5JSON

local CA = CFrame.Angles
local CN = CFrame.new

local starSphereRadius = 2048
local julianDate = 2460406.5024653

local starAdornee = Debug["Templates"]["Point"]:Clone()
starAdornee.Name = "StarAdornee"
starAdornee.Transparency = 1
starAdornee.CanCollide = false
starAdornee.CanTouch = false
--starAdornee.CanQuery = false
starAdornee.CastShadow = false
starAdornee.CFrame = CFrame.identity
starAdornee.Parent = workspace

local starAdornmentTemplate = Instance.new("SphereHandleAdornment")
starAdornmentTemplate.Color3 = Color3.new(1000, 1000, 1000)
starAdornmentTemplate.Adornee = starAdornee
starAdornmentTemplate.AdornCullingMode = Enum.AdornCullingMode.Never

local visualMagnitudeMin = 0
local visualMagnitudeMax = 0

local starAdornments = {}

local minMag = 0
local maxMag = 0

for starIndex = 1, starCount do

    local star = BSC5JSON[starIndex]

    local rightAscensionHours = tonumber(star["RAh"]) or 0
    local rightAscensionMinutes = tonumber(star["RAm"]) or 0
    local rightAscensionSeconds = tonumber(star["RAs"]) or 0

    local rightAscensionRadians = Astronomy.Convert.HoursToRadians(rightAscensionHours) +
        Astronomy.Convert.MinutesToRadians(rightAscensionMinutes) +
        Astronomy.Convert.SecondsToRadians(rightAscensionSeconds)

    local declinationDegrees = tonumber(star["DEd"]) or 0
    local declinationArcminutes = tonumber(star["DEm"]) or 0
    local declinationArcseconds = tonumber(star["DEs"]) or 0

    local declinationRadians = Astronomy.Convert.DegreesToRadians(declinationDegrees) +
        Astronomy.Convert.ArcminutesToRadians(declinationArcminutes) +
        Astronomy.Convert.ArcsecondsToRadians(declinationArcseconds)

    local galacticLatitude = Astronomy.Convert.DegreesToRadians(tonumber(star["GLAT"]) or 0)
    local galacticLongitude = Astronomy.Convert.DegreesToRadians(tonumber(star["GLON"]) or 0)

    local visualMagnitude = tonumber(star["Vmag"]) or 0

    local trigonometricParallax = tonumber(star["Parallax"]) or 0 -- in arcseconds

    --print("trigonometric parallax: ", trigonometricParallax)

    local absoluteMagnitude = Astronomy.GetAbsoluteMagnitude(visualMagnitude, trigonometricParallax)

    local normalizedVisualMagnitude = 1 - (visualMagnitude + 1.46) / 9.42
    local compoundedVisualMagnitude = math.pow(normalizedVisualMagnitude, 2)

    local normalizedAbsoluteMagnitude = absoluteMagnitude / 8.5

    local x, y, z = Astronomy.ConvertGeodedicLatitudeAndLongitudeToXYZ(galacticLatitude, galacticLongitude, 0, starSphereRadius)

    local starName = star["BayerF"] or "Unknown"
    local starCommonName = star["Common"]
    local starConstellation = star["Constellation"] or "Unknown"

    local starFullName

    if (starCommonName) then
        starFullName = string.format("Name: %s (%s), Constellation: %s", starName, starCommonName, starConstellation)
    else
        starFullName = string.format("Name: %s, Constellation: %s", starName, starConstellation)
    end

    local UBColorInTheUBVSystem = tonumber(star["U-B"]) or 0 -- max value found : 7.4
    local colorStrength = math.abs(UBColorInTheUBVSystem)/7.4

    colorStrength = math.min(3.7 * colorStrength, 1)

    local apparentColor = Color3.new(1, 1, 1)

    if (UBColorInTheUBVSystem < 0) then
        -- redder
        apparentColor = apparentColor:Lerp(Color3.new(1, 0.5, 0.5), colorStrength)
    else
        -- bluer
        apparentColor = apparentColor:Lerp(Color3.new(0.5, 0.5, 1), colorStrength)
    end

    local starAdornment = starAdornmentTemplate:Clone()
    starAdornment.Name = starFullName
    starAdornment.CFrame = CN(x, y, z)
    starAdornment.Radius = normalizedVisualMagnitude * normalizedVisualMagnitude * 20
    starAdornment.Transparency = 0.9 - normalizedVisualMagnitude * normalizedVisualMagnitude
    starAdornment.Color3 = apparentColor
    starAdornment.Parent = starAdornee

    starAdornments[starIndex] = starAdornment

end

print("max UB: ", maxMag)
print("min UB: ", minMag)

local dipperTest = {
    4141, 4295, 4554, 4660, 4905, 4931, 5054, 5062
}

for i = 1, #dipperTest do
    local testAdornment = starAdornments[dipperTest[i]]
    --testAdornment.Radius = 10
    --testAdornment.Color3 = Color3.new(0, 1, 0)
    --testAdornment.Transparency = 0
end



--[[

starAdornments[2491].Color3 = Color3.new(0, 1, 0)
starAdornments[2491].Transparency = 0
starAdornments[2491].Radius = 10

]]
