FrameworkBridge = {}
FrameworkBridge.name = 'standalone'

local ESX = nil
local QBCore = nil
local standaloneBalances = {}

local function debugPrint(msg)
    if Config.Debug then
        print(('[FightClub Bridge] %s'):format(msg))
    end
end

local function detectFramework()
    if Config.Framework ~= 'auto' then
        FrameworkBridge.name = Config.Framework
        debugPrint(('Framework forced to %s'):format(FrameworkBridge.name))
        return
    end

    if GetResourceState('es_extended') == 'started' then
        FrameworkBridge.name = 'esx'
        debugPrint('Detected ESX')
        return
    end

    if GetResourceState('qb-core') == 'started' then
        FrameworkBridge.name = 'qbcore'
        debugPrint('Detected QBCore/Qbox bridge')
        return
    end

    FrameworkBridge.name = 'standalone'
    debugPrint('No framework detected, using standalone')
end

CreateThread(function()
    detectFramework()

    if FrameworkBridge.name == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
    elseif FrameworkBridge.name == 'qbcore' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end)

function FrameworkBridge.GetName()
    return FrameworkBridge.name
end

function FrameworkBridge.GetPlayerMoney(source)
    if FrameworkBridge.name == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return 0 end

        if Config.MoneyType == 'bank' then
            local account = xPlayer.getAccount('bank')
            return account and account.money or 0
        else
            local account = xPlayer.getAccount('money')
            return account and account.money or 0
        end
    elseif FrameworkBridge.name == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return 0 end
        return Player.Functions.GetMoney(Config.MoneyType) or 0
    else
        standaloneBalances[source] = standaloneBalances[source] or 5000
        return standaloneBalances[source]
    end
end

function FrameworkBridge.RemoveMoney(source, amount)
    if amount <= 0 then return true end

    if FrameworkBridge.name == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end

        if Config.MoneyType == 'bank' then
            local account = xPlayer.getAccount('bank')
            if not account or account.money < amount then return false end
            xPlayer.removeAccountMoney('bank', amount, 'fightclub-entry')
            return true
        else
            local account = xPlayer.getAccount('money')
            if not account or account.money < amount then return false end
            xPlayer.removeAccountMoney('money', amount, 'fightclub-entry')
            return true
        end
    elseif FrameworkBridge.name == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end

        local balance = Player.Functions.GetMoney(Config.MoneyType) or 0
        if balance < amount then return false end

        return Player.Functions.RemoveMoney(Config.MoneyType, amount, 'fightclub-entry')
    else
        standaloneBalances[source] = standaloneBalances[source] or 5000
        if standaloneBalances[source] < amount then return false end
        standaloneBalances[source] = standaloneBalances[source] - amount
        return true
    end
end

function FrameworkBridge.AddMoney(source, amount)
    if amount <= 0 then return true end

    if FrameworkBridge.name == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end

        if Config.MoneyType == 'bank' then
            xPlayer.addAccountMoney('bank', amount, 'fightclub-win')
        else
            xPlayer.addAccountMoney('money', amount, 'fightclub-win')
        end

        return true
    elseif FrameworkBridge.name == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end

        return Player.Functions.AddMoney(Config.MoneyType, amount, 'fightclub-win')
    else
        standaloneBalances[source] = standaloneBalances[source] or 5000
        standaloneBalances[source] = standaloneBalances[source] + amount
        return true
    end
end

AddEventHandler('playerDropped', function()
    standaloneBalances[source] = nil
end)