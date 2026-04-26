local insideArena = false
local inQueue = false
local inFight = false
local debugFight = false
local opponentServerId = nil

local function notify(nType, title, message, duration)
    SendNUIMessage({
        action = 'notify',
        type = nType or 'info',
        title = title or 'Fight Club',
        message = message or '',
        duration = duration or 3000
    })
end

RegisterNetEvent('fightclub:notify', function(data)
    notify(data.type, data.title, data.message, data.duration)
end)

local function forceUnarmed()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
end

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local dist = #(playerCoords - Config.Arena.coords)

        insideArena = dist < Config.Arena.radius

        if dist < 25.0 then
            sleep = 0

            DrawMarker(
                1,
                Config.Arena.coords.x, Config.Arena.coords.y, Config.Arena.coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                Config.Arena.radius * 2.0, Config.Arena.radius * 2.0, 1.0,
                255, 0, 0, 80,
                false, false, 2, false, nil, nil, false
            )

            if dist < Config.Arena.joinDistance then
                BeginTextCommandDisplayHelp('STRING')
                if not inQueue then
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to join the fight queue')
                else
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to leave the fight queue')
                end
                EndTextCommandDisplayHelp(0, false, true, -1)

                if IsControlJustPressed(0, 38) then
                    if not inQueue then
                        inQueue = true
                        TriggerServerEvent('fightclub:joinQueue')

                        notify('success', 'Fight Club', 'You joined the queue. Waiting for another fighter.', 4000)
                    else
                        inQueue = false
                        TriggerServerEvent('fightclub:leaveQueue')

                        notify('warning', 'Fight Club', 'You left the queue.', 3000)
                    end
                end
            end

            if insideArena or inFight then
                forceUnarmed()
            end

            if inFight and IsEntityDead(ped) then
                if debugFight then
                    notify('error', 'Fight Club', 'Solo debug match ended. You died.', 4000)

                    inFight = false
                    inQueue = false
                    insideArena = false
                    debugFight = false
                    opponentServerId = nil
                    Wait(3000)
                else
                    TriggerServerEvent('fightclub:playerDied')
                    inFight = false
                    inQueue = false
                    insideArena = false
                    Wait(3000)
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('fightclub:startCountdown', function(seconds, enemyServerId)
    CreateThread(function()
        for i = seconds, 1, -1 do
            notify('info', 'Fight Club', ('Fight starts in %d...'):format(i), 1000)
            Wait(1000)
        end
    end)
end)

RegisterNetEvent('fightclub:matchStarted', function(opponentId)
    inFight = true
    inQueue = false
    debugFight = false
    opponentServerId = opponentId

    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    forceUnarmed()

    notify('warning', 'Fight Started', 'Melee only. Weapons are disabled.', 3500)
end)

RegisterNetEvent('fightclub:matchEnded', function(data)
    local myServerId = GetPlayerServerId(PlayerId())

    if data.winner == myServerId then
        notify('success', 'Victory', 'You won the fight!', 4000)
    elseif data.loser == myServerId then
        notify('error', 'Defeat', 'You lost the fight!', 4000)
    end

    inFight = false
    debugFight = false
    opponentServerId = nil
end)

RegisterCommand('testgun', function()
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, `WEAPON_PISTOL`, 20, false, true)
    notify('info', 'Weapon Test', 'Pistol given. Start a fight to confirm removal.', 3500)
end, false)

RegisterCommand('mycoords', function()
    local coords = GetEntityCoords(PlayerPedId())
    print(string.format('vector3(%.2f, %.2f, %.2f)', coords.x, coords.y, coords.z))
end, false)

RegisterCommand('fighttest', function()
    if inFight then
        notify('error', 'Fight Club', 'You are already in a fight.', 3000)
        return
    end

    debugFight = true

    CreateThread(function()
        for i = Config.Match.countdown, 1, -1 do
            notify('info', 'Debug Match', ('Starting in %d...'):format(i), 900)
            Wait(1000)
        end

        inFight = true
        forceUnarmed()
        notify('warning', 'Debug Fight', 'Debug fight started. Melee only.', 3000)
    end)
end, false)

RegisterCommand('endfighttest', function()
    inFight = false
    debugFight = false
    opponentServerId = nil
    notify('info', 'Debug Fight', 'Debug fight ended.', 2500)
end, false)

local lastHudPayload = nil

local function updateFightHud(payload)
    if not payload or type(payload) ~= 'table' then
        return
    end
    if payload.action == 'updateFightHud' and payload.visible == false then
        lastHudPayload = nil
    else
        lastHudPayload = payload
    end
    SendNUIMessage(payload)
end

local isQueued = false

RegisterNetEvent('fightclub:setQueued', function(state)
    isQueued = state
end)

RegisterCommand('fightclub_leavequeue', function()
    if isQueued and not inFight then
        TriggerServerEvent('fightclub:leaveQueue')
        notify('warning', 'Fight Club', 'You left the queue.', 2500)
        isQueued = false
        inQueue = false
        return
    end

    if debugFight then
        inFight = false
        debugFight = false
        opponentServerId = nil
        lastHudPayload = nil
        updateFightHud({ action = 'updateFightHud', visible = false })
        notify('info', 'Debug Fight', 'Debug fight ended.', 2500)
    end
end, false)

RegisterKeyMapping('fightclub_leavequeue', 'Fight Club: Leave queue / end debug fight', 'keyboard', 'BACK')

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
