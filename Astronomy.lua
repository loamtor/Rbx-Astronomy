--!strict

local Astronomy = {}

local abs       =   math.abs
local floor     =   math.floor
local modf      =   math.modf
local pi        =   math.pi
local atan2     =   math.atan2
local sqrt      =   math.sqrt
local cos       =   math.cos
local sin       =   math.sin
local tan       =   math.tan
local asin      =   math.asin
local acos      =   math.acos

local tcreate   =   table.create
local tinsert   =   table.insert

-- convert number (in hours) to TimeOfDay string
-- because TimeOfDay doesn't cast numbers as expected (3.7 -> 03:07:00 instead of 3:42:00)
function Astronomy.NumberToTimeOfDay(n:number)
    n = n % 24
    local i,f = modf(n)
    local m = f*60
    local mi,mf = modf(m)
    local mString = tostring(abs(floor(m)))
    local s = tostring(abs(floor(mf*60)))
    return i..":"..string.rep("0",2-#mString)..mString..":"..string.rep("0",2-#s)..s
end

-- convert TimeOfDay string to number (in hours)
function Astronomy.NumberFromTimeOfDay(t:string)    :(number)
    
    local signed    :(any),
        _hours      :(any),
        _minutes    :(any),
        _seconds    :(any) = t:match("^(%-?)(%d+):(%d+):(%d+)$")
    
    local seconds   :(number) = tonumber(_seconds)::number/60
    local minutes   :(number) = tonumber(_minutes + seconds)::number/60
    local hours     :(number) = tonumber(_hours)::number + minutes
    
    return hours * (#signed > 0 and -1 or 1)
end

-- convert direction to latitude (as GeographicLatitude) and longitude (as TimeOfDay)

--[[

example usage:

    local lat, lon = Astronomy.DirectionToLatitudeLongitude(Mouse.UnitRay.Direction)

Lighting.GeographicLatitude = lat
Lighting.TimeOfDay = lon

]]

function Astronomy.DirectionToRobloxLatitudeAndTimeOfDay(d:Vector3)
    
    local d = Vector3.new(-d.X, -d.Y, d.Z) -- derp derp derp derp derp
    
    local latitude = atan2(d.Z, sqrt(d.X^2 + d.Y^2))
    local longitude = atan2(d.Y, d.X)

    latitude = latitude/pi*180 + 23.5

    local timeOfDay = Astronomy.NumberToTimeOfDay(longitude/pi*12 - 6)

    return latitude, timeOfDay -- timeOfDay => longitude
end

--[[

Note on pmRA:
    As usually assumed, the proper motion in RA is the projected
    motion (cos(DE).d(RA)/dt), i.e. the total proper motion is
    sqrt(pmRA^2^+pmDE^2^)

]]

-- [Public Domain] Greg Miller (gmiller@gregmiller.net) 2021
--All input and output angles are in radians, jd is Julian Date in UTC

Astronomy.EarthEquatorialRadius = 6378136.6
Astronomy.EarthFlatteningRatio = 1/298.25642

function Astronomy.GetEarthRotationAngle(julianDate :number)
    --IERS Technical Note No. 32

    local t = julianDate - 2451545.0;
    local f = julianDate%1;

    local theta = 2*pi * (f + 0.7790572732640 + 0.00273781191135448 * t); -- eq 14

    theta = theta % (2 * pi) -- order of operations

    if(theta<0) then
        theta = theta + 2 * pi
    end

    return theta;

end

function Astronomy.GetGreenwichMeanSiderealTime(julianDate :number)
    -- "Expressions for IAU 2000 precession quantities" N. Capitaine1,P.T.Wallace2, and J. Chapront
    local t = ((julianDate - 2451545.0)) / 36525.0;

    local gmst = Astronomy.GetEarthRotationAngle(julianDate)+(0.014506 + 4612.156534*t + 1.3915817*t*t - 0.00000044 *t*t*t - 0.000029956*t*t*t*t - 0.0000000368*t*t*t*t*t)/3600*pi/180;  -- eq 42

    gmst = gmst % (2 * pi)

    if(gmst<0) then
        gmst = gmst + 2 * pi
    end

    return gmst;
end

-- Julian date example (recent time): 2460406.5024653
function Astronomy.RightAscensionAndDeclinationToAzimuthAndAltitude(rightAscension, declination, latitude, longitude, julianDateUTC)
    -- Meeus 13.5 and 13.6, modified so West longitudes are negative and 0 is North
    local siderealTime = Astronomy.GetGreenwichMeanSiderealTime(julianDateUTC)

    local localSiderealTime = (siderealTime + longitude)%(2*pi)

    local localHourAngle = (localSiderealTime - rightAscension);

    if (localHourAngle < 0) then
        localHourAngle = localHourAngle + 2 * pi
    end

    if (localHourAngle > pi) then
        localHourAngle = localHourAngle - 2 * pi
    end

    local azimuth = (atan2(sin(localHourAngle), cos(localHourAngle)*sin(latitude) - tan(declination)*cos(latitude)))
    local altitude = (asin(sin(latitude)*sin(declination) + cos(latitude)*cos(declination)*cos(localHourAngle)))

    azimuth = azimuth - pi

    if (azimuth < 0) then
        azimuth = azimuth + 2 * pi
    end

    return azimuth, altitude, localSiderealTime, localHourAngle
end

--Convert Geodedic Lat Lon to geocentric XYZ position vector
--All angles are input as radians
function Astronomy.ConvertGeodedicLatitudeAndLongitudeToInternationalTerrestrialReferenceFrameXYZ(latitude, longitude, surfaceAltitude)
    -- Algorithm from Explanatory Supplement to the Astronomical Almanac 3rd ed. P294
    
    local earthEquatorialRadius = Astronomy.EarthEquatorialRadius
    local earthFlatteningRatio = Astronomy.EarthFlatteningRatio

    local C = sqrt(((cos(latitude)*cos(latitude)) + (1 - earthFlatteningRatio)*(1 - earthFlatteningRatio) * (sin(latitude)*sin(latitude))))

    local S = (1 - earthFlatteningRatio)*(1 - earthFlatteningRatio)*C

    return (earthEquatorialRadius*C+surfaceAltitude) * cos(latitude) * cos(longitude),
        (earthEquatorialRadius*C+surfaceAltitude) * cos(latitude) * sin(longitude),
        (earthEquatorialRadius*S+surfaceAltitude) * sin(latitude)
end

function Astronomy.ConvertGeodedicLatitudeAndLongitudeToXYZ(latitude, longitude, surfaceAltitude, radius:number)
    
    local earthFlatteningRatio = Astronomy.EarthFlatteningRatio

    local C = sqrt(((cos(latitude)*cos(latitude)) + (1 - earthFlatteningRatio)*(1 - earthFlatteningRatio) * (sin(latitude)*sin(latitude))))

    local S = (1 - earthFlatteningRatio)*(1 - earthFlatteningRatio)*C

    return (radius*C+surfaceAltitude) * cos(latitude) * cos(longitude),
        (radius*C+surfaceAltitude) * cos(latitude) * sin(longitude),
        (radius*S+surfaceAltitude) * sin(latitude)
end

--Converts Alt/Az to Hour Angle and Declination
--Modified from Meeus so that 0 Az is North
--All angles are in radians
function Astronomy.ConvertAzimuthAndAltitudeToHourAngleAndDeclination(lat, alt, az)
    local hourAngle = atan2(-sin(az), tan(alt)*cos(lat)-cos(az)*sin(lat))

    if (hourAngle < 0) then
        hourAngle = hourAngle + pi * 2
    end

    local declination = asin(sin(lat)*sin(alt) + cos(lat)*cos(alt)*cos(az));
    
    return hourAngle, declination
end

--[[

Angles must be in radians

Polar cooridnates:
    Theta is vertical pi/2 to -pi/2 (usually lattitude or declination)
    
Phi is horizontal 0 to 2pi, or -pi to pi (usually longitude or Right Ascension)
R is the radius in any units

Rectangular:
    x is left/right, y is forward/backward, z is up/down

]]

function Astronomy.PolarCoordinatesToRectangular(theta, phi, radius:number)
    -- theta = pi/2 - theta; --Convert range to 0deg to 180deg
    return radius*sin(theta)*cos(phi), radius*sin(theta)*sin(phi), radius*cos(theta)
end

--Angles returned in radians
function Astronomy.RectangularCoordinatesToPolar(x:number, y:number, z:number)
    local radius = sqrt(x * x + y * y + z * z)
    local longitude = atan2(y, x);
    local latitude = acos(z / radius);

    -- Make sure lon is positive, and lat is in range +/-90deg
    if (longitude < 0) then
        longitude = longitude + 2 * pi
    end
    
    latitude = .5 * pi - latitude;
    
    return latitude, longitude, radius
end

type star = {
    Name                        :(string),
    CatalogNumber               :(number),
    RightAscension              :(number),
    Declination                 :(number),
    GalacticLatitude            :(number),
    GalacticLongitude           :(number),
    --SpectralType                :(number),
    Magnitude                   :(number),
    RightAscensionProperMotion  :(number), 
    DeclinationProperMotion     :(number)
}

function Astronomy.GetStarsFromBrightStarCatalog5() :({star})
    
    local bigString = require(script["BrightStarCatalog5"])
    
    local getSubstring = string.sub
    local currentLineNumber = 1
    
    local stars :({star}) = tcreate(9110)
    
    local hoursToRadians = pi / 12
    local minutesToRadians = hoursToRadians / 60 -- denom. 720
    local secondsToRadians = minutesToRadians / 60 -- denominator 43200
    local degreesToRadians = pi / 180
    local arcminutesToRadians = degreesToRadians / 60
    local arcsecondsToRadians = arcminutesToRadians / 60
    
    -- Parse each line for star data:
    for line :(any),
        newline :(any) in bigString:gmatch'([^\r\n]*)([\r\n]*)' do
        
        local catalogNumber     :(number)   =   tonumber(getSubstring(line, 1, 4)) or 0 -- Harvard Revised Number = Bright Star Number
        
        local name  :(string)                       = getSubstring(line, 5, 14):gsub("%s+", "") -- Bayer and/or Flamsteed name
        --local durchmusterungIdentification          = getSubstring(line, 15, 25)
        --local durchmusterungZone                    = getSubstring(line, 17, 19)
        --local henryDraperCatalogNumber              = getSubstring(line, 26, 31)
        --local SAOCatalogNumber                      = getSubstring(line, 32, 37)
        --local FK5StarNumber                         = getSubstring(line, 38, 41)
        --local IRFlag                                = getSubstring(line, 42, 42) -- I if infrared source
        --local IRFlagCodedReference                  = getSubstring(line, 43, 43) -- coded reference for infrared source
        --local doubleOrMultipleStarCode              = getSubstring(line, 44, 44) -- [AWDIRS]
        --local aitkensDoubleStarCatalogDesignation   = getSubstring(line, 45, 49) -- ADS Designation
        --local aitkensDoubleStarNumberComponents     = getSubstring(line, 50, 51)
        --local variableStarIdentification            = getSubstring(line, 52, 60)
        --local hoursRightAscensionEquinoxB1900       = getSubstring(line, 61, 62)
        --local minutesRightAscensionEquinoxB1900     = getSubstring(line, 63, 64)
        --local secondsRightAscensionEquinoxB1900     = getSubstring(line, 65, 68)
        --local signDeclinationEquinoxB1900           = getSubstring(line, 69, 69)
        --local degreesDeclinationEquinoxB1900        = getSubstring(line, 70, 71)
        --local minutesDeclinationEquinoxB1900        = getSubstring(line, 72, 73)
        --local secondsDeclinationEquinoxB1900        = getSubstring(line, 74, 75)
        local hoursRightAscensionEquinoxJ2000   :(number)   =   tonumber(getSubstring(line, 76, 77)) or 0 -- h
        local minutesRightAscensionEquinoxJ2000 :(number)   =   tonumber(getSubstring(line, 78, 79)) or 0 -- min
        local secondsRightAscensionEquinoxJ2000 :(number)   =   tonumber(getSubstring(line, 80, 83)) or 0 -- s
        
        local signDeclinationEquinoxJ2000           = getSubstring(line, 84, 84)
        local degreesDeclinationEquinoxJ2000    :(number)   = tonumber(getSubstring(line, 85, 86)) or 0
        local arcminutesDeclinationEquinoxJ2000 :(number)   = tonumber(getSubstring(line, 87, 88)) or 0 -- arcmin
        local arcsecondsDeclinationEquinoxJ2000 :(number)   = tonumber(getSubstring(line, 89, 90)) or 0 -- arcsec
        
        local galacticLongitude :(number)           = tonumber(getSubstring(line, 91, 96)) or 0 -- in degrees
        local galacticLatitude  :(number)           = tonumber(getSubstring(line, 97, 102)) or 0 -- in degrees
        local visualMagnitude                       = getSubstring(line, 103, 107)
        --local visualMagnitudeCode                   = getSubstring(line, 108, 108)
        --local uncertaintyFlagOnV                    = getSubstring(line, 109, 109)
        --local BVColorInTheUBVSystem                 = getSubstring(line, 110, 114)
        --local uncertaintyFlagOnBV                   = getSubstring(line, 115, 115)
        --local UBColorInTheUBVSystem                 = getSubstring(line, 116, 120)
        --local uncertaintyFlagOnUB                   = getSubstring(line, 121, 121)
        --local magnitudeInRISystem                   = getSubstring(line, 122, 126)
        --local RISystemCode                          = getSubstring(line, 127, 127)
        --local spectralType                          = getSubstring(line, 128, 147)
        --local spectralTypeCode                      = getSubstring(line, 148, 148)
        local annualProperMotionInRightAscensionJ2000FK5System  = getSubstring(line, 149, 154) -- in arcsec/yr
        local annualProperMotionInDeclinationJ2000FK5System     = getSubstring(line, 155, 160) -- in arcsec/yr
        --local parallaxType                          = getSubstring(line, 161, 161) -- D indicates dynamic parallax, otherwise trigonometric parallax
        --local trigonometricParallax                 = getSubstring(line, 162, 166) -- in arcsec
        --local heliocentricRadialVelocity            = getSubstring(line, 167, 170) -- in km/s
        --local radialVelocityComments                = getSubstring(line, 171, 174)
        --local rotationalVelocityLimitCharacters     = getSubstring(line, 175, 176)
        --local rotationalVelocity                    = getSubstring(line, 177, 179) -- v sin i
        --local uncertaintyAndVariabilityFlagOnRotVel = getSubstring(line, 180, 180)
        --local magnitudeDifferenceOfDoubleOrBrightestMultiple = getSubstring(line, 181, 184)
        --local separationOfComponentsInDMagIfOccultationBinary = getSubstring(line, 185, 190)
        --local identificationsOfComponentsInDMag = getSubstring(line, 191, 194)
        --local numberOfComponentsAssignedToAMultiple = getSubstring(line, 195, 196)
        --local noteFlag = getSubstring(line, 197, 197) -- a star (*) indicates that there is a note
        
        -- note on multiple:
        
        --print(string.format("right ascension: %d:%d:%d", hoursRightAscensionEquinoxJ2000, minutesRightAscensionEquinoxJ2000, secondsRightAscensionEquinoxJ2000))
        --print(string.format("declination: %s%d°%d'%d\"", signDeclinationEquinoxJ2000, degreesDeclinationEquinoxJ2000, minutesDeclinationEquinoxJ2000, secondsDeclinationEquinoxJ2000))
        
        local rightAscension    :(number)   =   
            hoursRightAscensionEquinoxJ2000 * hoursToRadians + 
            minutesRightAscensionEquinoxJ2000 * minutesToRadians +
            secondsRightAscensionEquinoxJ2000 * secondsToRadians

        local declination       :(number)   =   degreesDeclinationEquinoxJ2000 * degreesToRadians +
            arcminutesDeclinationEquinoxJ2000 * arcminutesToRadians +
            arcsecondsDeclinationEquinoxJ2000 * arcsecondsToRadians

        if (signDeclinationEquinoxJ2000 ~= "+") then
            declination = -declination
        end
        
        galacticLatitude = galacticLatitude * degreesToRadians
        galacticLongitude = galacticLongitude * degreesToRadians
        
        -- rightAscension  =   tonumber(galacticLongitude) or 0
        --declination     =   tonumber(galacticLatitude) or 0
        
        local magnitude         :(number)   =   tonumber(visualMagnitude) or 0
        
        local rightAscensionProperMotion    :(number)   =   tonumber(annualProperMotionInRightAscensionJ2000FK5System) or 0
        local declinationProperMotion       :(number)   =   tonumber(annualProperMotionInDeclinationJ2000FK5System) or 0
        
        if (#name == 0) then
            name = "Unknown"
        end
        
        --[[
        if (rightAscension == 0) then print(string.format("Unable to parse right ascension for star %d", catalogNumber)) end
        if (declination == 0) then print(string.format("Unable to parse declination for star %d", catalogNumber)) end
        if (magnitude == 0) then print(string.format("Unable to parse magnitude for star %d", catalogNumber)) end
        if (rightAscensionProperMotion == 0) then print(string.format("Unable to parse rightAscensionProperMotion for star %d", catalogNumber)) end
        if (declinationProperMotion == 0) then print(string.format("Unable to parse declinationProperMotion for star %d", catalogNumber)) end
        ]]
        
        tinsert(stars, {
            Name                        =   name,           
            CatalogNumber               =   catalogNumber,
            RightAscension              =   rightAscension,
            Declination                 =   declination,
            GalacticLatitude            =   galacticLatitude,
            GalacticLongitude           =   galacticLongitude,
            Magnitude                   =   magnitude,
            RightAscensionProperMotion  =   rightAscensionProperMotion,
            DeclinationProperMotion     =   declinationProperMotion
        })
        
        -- if currentLineNumber > 50 then break end
    end
    
    return stars
end

function Astronomy.GeneratePointsFromBrightStarCatalog5(radius) :({number})
    
    local starsInBrightStarCatalog5 = Astronomy.GetStarsFromBrightStarCatalog5()
    local starCount = #starsInBrightStarCatalog5
    
    local points :({number}) = tcreate(starCount * 3)
    
    for starIndex = 1, starCount do
        
        local star = starsInBrightStarCatalog5[starIndex]

        local rightAscensionRadians = star.RightAscension
        local declinationRadians = star.Declination
        local galacticLatitude = star.GalacticLatitude
        local galacticLongitude = star.GalacticLongitude

        local x, y, z = Astronomy.ConvertGeodedicLatitudeAndLongitudeToXYZ(galacticLatitude, galacticLongitude, 0, radius)

        --[[

        local azimuth, altitude, localSiderealTime, localHourAngle = Astronomy.RightAscensionAndDeclinationToAzimuthAndAltitude(
            rightAscensionRadians,
            declinationRadians,
            0,
            0,
            julianDate
        )
        
        local x, y, z = Astronomy.ConvertGeodedicLatitudeAndLongitudeToXYZ(altitude, azimuth, 0, starSphereRadius)
        
        ]]

        tinsert(points, x)
        tinsert(points, y)
        tinsert(points, z)
        
    end

    return points

end

return Astronomy
