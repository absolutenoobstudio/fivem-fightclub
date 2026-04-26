local insideArena = false
local inQueue = false
local inMatch = false
local debugSoloMode = false

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

                        TriggerEvent('chat:addMessage', {
                            color = {0, 255, 0},
                            args = {'FightClub', 'You joined the queue. Waiting for another fighter...'}
                        })
                    else
                        inQueue = false
                        TriggerServerEvent('fightclub:leaveQueue')

                        TriggerEvent('chat:addMessage', {
                            color = {255, 100, 100},
                            args = {'FightClub', 'You left the queue.'}
                        })
                    end
                end

        if insideArena or inMatch then
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        end

        if inMatch and IsEntityDead(ped) then
            if debugSoloMode then
                TriggerEvent('chat:addMessage', {
                    color = {255, 0, 0},
                    args = {'FightClub', 'Solo debug match ended. You died.'}
                })

                inMatch = false
                inQueue = false
                insideArena = false
                debugSoloMode = false
                Wait(3000)
            else
                TriggerServerEvent('fightclub:playerDied')
                inMatch = false
                inQueue = false
                insideArena = false
                Wait(3000)
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('fightclub:startCountdown', function(seconds, enemyServerId)
    CreateThread(function()
        for i = seconds, 1, -1 do
            BeginTextCommandPrint('STRING')
            AddTextComponentSubstringPlayerName(('Fight starts in %d...'):format(i))
            EndTextCommandPrint(1000, true)
            Wait(1000)
        end
    end)
end)

RegisterNetEvent('fightclub:matchStarted', function(enemyServerId)
    inMatch = true
    inQueue = false
    insideArena = true

    TriggerEvent('chat:addMessage', {
        color = {255, 80, 80},
        args = {'FightClub', 'Your fight has started. Melee only.'}
    })
end)

RegisterNetEvent('fightclub:matchEnded', function(data)
    local myServerId = GetPlayerServerId(PlayerId())

    if data.winner == myServerId then
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {'FightClub', 'You won the fight!'}
        })
    elseif data.loser == myServerId then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'FightClub', 'You lost the fight.'}
        })
    end

    inMatch = false
    inQueue = false
    insideArena = false
    debugSoloMode = false
end)

RegisterCommand('testgun', function()
    GiveWeaponToPed(PlayerPedId(), `WEAPON_PISTOL`, 250, false, true)
    print('[FightClub] Test pistol given')
end, false)

RegisterCommand('mycoords', function()
    local coords = GetEntityCoords(PlayerPedId())
    print(string.format('vector3(%.2f, %.2f, %.2f)', coords.x, coords.y, coords.z))
end, false)

RegisterCommand('fighttest', function()
    if inMatch then
        TriggerEvent('chat:addMessage', {
            color = {255, 200, 0},
            args = {'FightClub', 'You are already in a match.'}
        })
        return
    end

    debugSoloMode = true
    insideArena = true
    inQueue = false

    TriggerEvent('chat:addMessage', {
        color = {0, 200, 255},
        args = {'FightClub', 'Solo debug match starting...'}
    })

    CreateThread(function()
        for i = Config.Match.countdown, 1, -1 do
            BeginTextCommandPrint('STRING')
            AddTextComponentSubstringPlayerName(('Solo debug fight starts in %d...'):format(i))
            EndTextCommandPrint(1000, true)
            Wait(1000)
        end

        inMatch = true

        BeginTextCommandPrint('STRING')
        AddTextComponentSubstringPlayerName('SOLO DEBUG FIGHT STARTED')
        EndTextCommandPrint(3000, true)

        print('[FightClub] Solo debug fight started')
    end)
end, false)

RegisterCommand('endfighttest', function()
    inMatch = false
    inQueue = false
    insideArena = false
    debugSoloMode = false

    TriggerEvent('chat:addMessage', {
        color = {255, 100, 100},
        args = {'FightClub', 'Solo debug fight ended.'}
    })
end, false)