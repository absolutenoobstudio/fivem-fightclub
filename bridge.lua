FrameworkBridge = {}
FrameworkBridge.name = 'standalone'

local ESX = nil
local QBCore = nil
local vRP = nil
local Proxy = nil
local Tunnel = nil
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

    if GetResourceState('vrp') == 'started' then
        FrameworkBridge.name = 'vrp'
        debugPrint('Detected vRP')
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
    elseif FrameworkBridge.name == 'vrp' then
        Tunnel = module('vrp', 'lib/Tunnel')
        Proxy = module('vrp', 'lib/Proxy')
        vRP = Proxy.getInterface('vRP')
    end
end)

function FrameworkBridge.GetName()
    return FrameworkBridge.name
end

local function getStandaloneBalance(source)
    standaloneBalances[source] = standaloneBalances[source] or 5000
    return standaloneBalances[source]
end

local function getVRPUserId(source)
    if not vRP then return nil end
    return vRP.getUserId({source})
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

    elseif FrameworkBridge.name == 'vrp' then
        local user_id = getVRPUserId(source)
        if not user_id then return 0 end

        if Config.MoneyType == 'bank' then
            return vRP.getBankMoney({user_id}) or 0
        else
            return vRP.getMoney({user_id}) or 0
        end

    else
        return getStandaloneBalance(source)
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

    elseif FrameworkBridge.name == 'vrp' then
        local user_id = getVRPUserId(source)
        if not user_id then return false end

        if Config.MoneyType == 'bank' then
            local bankBalance = vRP.getBankMoney({user_id}) or 0
            if bankBalance < amount then return false end
            return vRP.tryWithdraw({user_id, amount})
        else
            local wallet = vRP.getMoney({user_id}) or 0
            if wallet < amount then return false end
            return vRP.tryPayment({user_id, amount})
        end

    else
        local balance = getStandaloneBalance(source)
        if balance < amount then return false end
        standaloneBalances[source] = balance - amount
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

    elseif FrameworkBridge.name == 'vrp' then
        local user_id = getVRPUserId(source)
        if not user_id then return false end

        if Config.MoneyType == 'bank' then
            local currentBank = vRP.getBankMoney({user_id}) or 0
            vRP.setBankMoney({user_id, currentBank + amount})
            return true
        else
            vRP.giveMoney({user_id, amount})
            return true
        end

    else
        standaloneBalances[source] = getStandaloneBalance(source) + amount
        return true
    end
end

AddEventHandler('playerDropped', function()
    standaloneBalances[source] = nil
end)
