--!strict

-- Services:

local ServerStorage     =   game:GetService("ServerStorage")
local ReplicatedStorage =   game:GetService("ReplicatedStorage")

-- Libraries:

local Astronomy =   require(ServerStorage["Algaerhythms"]["Astronomy"])
local Debug     =   require(ReplicatedStorage["Debug"])

-- Test:

--[[

            local x :(number)   =   sphereRadius * sin(theta) * cos(phi) + sphereRadius
            local y :(number)   =   sphereRadius * sin(theta) * sin(phi) + sphereRadius
            local z :(number)   =   sphereRadius * cos(theta) + sphereRadius

]]

local starsInBrightStarCatalog5 = Astronomy.GetStarsFromBrightStarCatalog5()
local starCount = #starsInBrightStarCatalog5

local degreesToRadians = math.pi / 180
local sin = math.sin
local cos = math.cos

local CA = CFrame.Angles
local CN = CFrame.new

local starSphereRadius = 700
local julianDate = 2460406.5024653

local starAdornee = Debug["Templates"]["Point"]:Clone()
starAdornee.Transparency = 1
starAdornee.CanCollide = false
starAdornee.CanTouch = false
starAdornee.CanQuery = false
starAdornee.CastShadow = false
starAdornee.CFrame = CFrame.identity
starAdornee.Parent = workspace

local starAdornmentTemplate = Instance.new("BoxHandleAdornment")
starAdornmentTemplate.Color3 = Color3.new(1000, 1000, 1000)
starAdornmentTemplate.Adornee = starAdornee
starAdornmentTemplate.AdornCullingMode = Enum.AdornCullingMode.Never
starAdornmentTemplate.Transparency = -1

for starIndex = 1, starCount do
    
    local star = starsInBrightStarCatalog5[starIndex]
    
    local rightAscensionRadians = star.RightAscension
    local declinationRadians = star.Declination
    local galacticLatitude = star.GalacticLatitude
    local galacticLongitude = star.GalacticLongitude

    -- Right here is a nice working line:
    -- local x, y, z = Astronomy.ConvertGeodedicLatitudeAndLongitudeToXYZ(galacticLatitude, galacticLongitude, 0, starSphereRadius)

    local azimuth, altitude, localSiderealTime, localHourAngle = Astronomy.RightAscensionAndDeclinationToAzimuthAndAltitude(
        rightAscensionRadians,
        declinationRadians,
        0,
        0,
        julianDate
    )
    
    local x, y, z = Astronomy.ConvertGeodedicLatitudeAndLongitudeToXYZ(altitude, azimuth, 0, starSphereRadius)

    local starAdornment = starAdornmentTemplate:Clone()
    starAdornment.CFrame = CN(x, y, z)
    starAdornment.Size = Vector3.one * 3
    starAdornment.Color3 = Color3.new(1000, 1000, 1000)
    starAdornment.Parent = starAdornee
    
    --task.wait()
end
