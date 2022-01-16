Citizen.CreateThread(function()
	while true do
		print('^1CaponeSec ~ ^2[~INFO~] ^7CAPONE-WEATHERSYNC IS RUNNING~')
		Citizen.Wait(3600000)
	end
end)

local AvailableWeatherTypes = {
    'EXTRASUNNY', 
    'CLEAR', 
    'NEUTRAL', 
    'SMOG', 
    'FOGGY', 
    'OVERCAST', 
    'CLOUDS', 
    'CLEARING', 
    'RAIN', 
    'THUNDER', 
    'SNOW', 
    'BLIZZARD', 
    'SNOWLIGHT', 
    'XMAS', 
    'HALLOWEEN',
}

local AvailableTimeTypes = {
    'MORNING',
    'NOON',
    'EVENING',
    'NIGHT',
}

local CurrentWeather = "EXTRASUNNY"
local DynamicWeather = false
local baseTime = 0
local timeOffset = 0
local freezeTime = false
local blackout = false

--- Main ---

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('capone-weathersync:server:RequestStateSync')
AddEventHandler('capone-weathersync:server:RequestStateSync', function()
    TriggerClientEvent('capone-weathersync:client:SyncWeather', -1, CurrentWeather, blackout)
    TriggerClientEvent('capone-weathersync:client:SyncTime', -1, baseTime, timeOffset, freezeTime)
end)

function FreezeElement(element)
    if element == 'weather' then
        DynamicWeather = not DynamicWeather
    else
        freezeTime = not freezeTime
    end
end

RegisterServerEvent('capone-weathersync:server:setWeather')
AddEventHandler('capone-weathersync:server:setWeather', function(type)
    CurrentWeather = string.upper(type)
    TriggerEvent('capone-weathersync:server:RequestStateSync')
end)

RegisterServerEvent('capone-weathersync:server:toggleBlackout')
AddEventHandler('capone-weathersync:server:toggleBlackout', function()
    ToggleBlackout()
end)

RegisterServerEvent('capone-weathersync:server:setTime')
AddEventHandler('capone-weathersync:server:setTime', function(hour, minute)
    SetExactTime(hour, minute)
end)

function SetWeather(type)
    CurrentWeather = string.upper(type)
    TriggerEvent('capone-weathersync:server:RequestStateSync')
end

function SetTime(type)
    if type:upper() == AvailableTimeTypes[1] then
        ShiftToMinute(0)
        ShiftToHour(9)
        TriggerEvent('capone-weathersync:server:RequestStateSync')
    elseif type:upper() == AvailableTimeTypes[2] then
        ShiftToMinute(0)
        ShiftToHour(12)
        TriggerEvent('capone-weathersync:server:RequestStateSync')
    elseif type:upper() == AvailableTimeTypes[3] then
        ShiftToMinute(0)
        ShiftToHour(18)
        TriggerEvent('capone-weathersync:server:RequestStateSync')
    else
        ShiftToMinute(0)
        ShiftToHour(23)
        TriggerEvent('capone-weathersync:server:RequestStateSync')
    end
end

function SetExactTime(hour, minute)
    local argh = tonumber(hour)
    local argm = tonumber(minute)
    if argh < 24 then
        ShiftToHour(argh)
    else
        ShiftToHour(0)
    end
    if argm < 60 then
        ShiftToMinute(argm)
    else
        ShiftToMinute(0)
    end
    local newtime = math.floor(((baseTime+timeOffset)/60)%24) .. ":"
    local minute = math.floor((baseTime+timeOffset)%60)
    if minute < 10 then
        newtime = newtime .. "0" .. minute
    else
        newtime = newtime .. minute
    end
    TriggerEvent('capone-weathersync:server:RequestStateSync')
end

function ToggleBlackout()
    blackout = not blackout
    TriggerEvent('capone-weathersync:server:RequestStateSync')
end

function ShiftToMinute(minute)
    timeOffset = timeOffset - ( ( (baseTime+timeOffset) % 60 ) - minute )
end

function ShiftToHour(hour)
    timeOffset = timeOffset - ( ( ((baseTime+timeOffset)/60) % 24 ) - hour ) * 60
end

function NextWeatherStage()
    if CurrentWeather == "CLEAR" or CurrentWeather == "CLOUDS" or CurrentWeather == "EXTRASUNNY"  then
        local new = math.random(1,2)
        if new == 1 then
            CurrentWeather = "CLEARING"
        else
            CurrentWeather = "OVERCAST"
        end
    elseif CurrentWeather == "CLEARING" or CurrentWeather == "OVERCAST" then
        local new = math.random(1,6)
        if new == 1 then
            if CurrentWeather == "CLEARING" then CurrentWeather = "FOGGY" else CurrentWeather = "RAIN" end
        elseif new == 2 then
            CurrentWeather = "CLOUDS"
        elseif new == 3 then
            CurrentWeather = "CLEAR"
        elseif new == 4 then
            CurrentWeather = "EXTRASUNNY"
        elseif new == 5 then
            CurrentWeather = "SMOG"
        else
            CurrentWeather = "FOGGY"
        end
    elseif CurrentWeather == "THUNDER" or CurrentWeather == "RAIN" then
        CurrentWeather = "CLEARING"
    elseif CurrentWeather == "SMOG" or CurrentWeather == "FOGGY" then
        CurrentWeather = "CLEAR"
    end
    TriggerEvent("capone-weathersync:server:RequestStateSync")
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local newBaseTime = os.time(os.date("!*t"))/2 + 360
        if freezeTime then
            timeOffset = timeOffset + baseTime - newBaseTime			
        end
        baseTime = newBaseTime
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        TriggerClientEvent('capone-weathersync:client:SyncTime', -1, baseTime, timeOffset, freezeTime)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)
        TriggerClientEvent('capone-weathersync:client:SyncWeather', -1, CurrentWeather, blackout)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1800000)
        if DynamicWeather then
            NextWeatherStage()
        end
    end
end)

--{Commands}--
ESX.RegisterCommand('blackout', 'admin', function(xPlayer, args, showError)
	ToggleBlackout()
end, true, {help = ('Black Mode')})

ESX.RegisterCommand('clock', 'admin', function(xPlayer, args, showError)
    if tonumber(args[1]) ~= nil and tonumber(args[2]) ~= nil then
        SetExactTime(args[1], args[2])
    end
end, true, {help = ('Change the time : 12 00 (Example)')})

ESX.RegisterCommand('time', 'admin', function(xPlayer, args, showError)
	for _, v in pairs(AvailableTimeTypes) do
        if args[1]:upper() == v then
            SetTime(args[1])
            return
        end
    end
end, true, {help = ('Change the time: Morning, Noon, Evening and Night')})

ESX.RegisterCommand('weather', 'admin', function(xPlayer, args, showError)
	for _, v in pairs(AvailableWeatherTypes) do
        if args[1]:upper() == v then
            SetWeather(args[1])
            return
        end
    end
end, true, {help = ('Change the weather')})

ESX.RegisterCommand('freezeall', 'admin', function(xPlayer, args, showError)
	if args[1]:lower() == 'weather' or args[1]:lower() == 'time' then
        FreezeElement(args[1])
    end
end, true, {help = ('Freeze the weather and time')})
--{Commands}--