# FiveM Fight Club

A configurable FiveM fight club resource for arena-based melee matches with queue entry fees, winner payouts, solo debug testing, and a bridge-based economy layer for ESX, QBCore, vRP, and standalone use.[1][2][3][4]

## Current pack contents

This final pack includes the following files:

```text
fivem-fightclub/
├─ fxmanifest.lua
├─ config.lua
├─ bridge.lua
├─ server.lua
└─ client.lua
```

FiveM resources are defined by an `fxmanifest.lua` file, which controls shared, server, and client script loading order.[1]

## What this resource does

- Creates a fight club arena with a marker and join prompt.
- Lets players pay an entry fee before joining the queue.
- Starts a countdown when enough players are queued.
- Forces melee-only fights during the match.
- Pays the configured reward to the winner through the framework bridge.
- Includes solo debug commands for testing without a second player.[1][2][5][4]

## Framework support in this pack

| Framework | Status | Notes |
|---|---|---|
| ESX | Supported | Uses modern ESX shared object access and xPlayer account methods such as `getAccount`, `removeAccountMoney`, and `addAccountMoney`.[2][6][7] |
| QBCore | Supported | Uses `exports['qb-core']:GetCoreObject()` and player money functions like `GetMoney`, `RemoveMoney`, and `AddMoney`.[3][5] |
| Qbox | Compatible direction | Qbox documentation states QB compatibility is available, so this pack is intended to work through the QB bridge path and should be verified on a live Qbox server before public claims of full support.[8] |
| vRP | Supported with caution | Uses the proxy/interface pattern documented in vRP proxy guides, but some forks differ, especially around bank helpers.[4] |
| Standalone | Supported | Includes a local fallback balance for development and framework-free testing. |

## Important note about the manifest

The safest universal release approach is to avoid a hard `dependency 'vrp'` in the manifest, because FiveM dependencies are treated as required resources rather than optional compatibility targets.[1]

If you want the resource to load on ESX, QBCore, Qbox, standalone, and vRP servers without forcing vRP to exist, use this safer universal `fxmanifest.lua`:

```lua
fx_version 'cerulean'
game 'gta5'

author 'AbsoluteNoobStudio'
description 'Standalone/framework-compatible FiveM fight club script'
version '1.2.1'

shared_script 'config.lua'

server_scripts {
    'bridge.lua',
    'server.lua'
}

client_script 'client.lua'
```

This is the recommended manifest for release because it prevents unnecessary startup failures on non-vRP servers.[1]

## Included config

The current pack uses this configuration structure:

```lua
Config = {}

Config.Debug = true

Config.Framework = 'auto' -- auto, esx, qbcore, vrp, standalone
Config.MoneyType = 'cash' -- cash or bank where supported

Config.Arena = {
    coords = vector3(-277.05, -1919.17, 29.95),
    radius = 15.0,
    joinDistance = 3.0
}

Config.Match = {
    minPlayers = 2,
    countdown = 5
}

Config.Economy = {
    entryFee = 500,
    winnerPayout = 1000
}
```

### Config field guide

| Key | Purpose |
|---|---|
| `Config.Debug` | Enables debug output in the bridge layer. |
| `Config.Framework` | Chooses `auto`, `esx`, `qbcore`, `vrp`, or `standalone`. |
| `Config.MoneyType` | Selects the money source, usually `cash` or `bank` where supported.[2][5][4] |
| `Config.Arena.coords` | Sets the fight arena center. |
| `Config.Arena.radius` | Sets the arena boundary radius. |
| `Config.Arena.joinDistance` | Controls how close the player must be to join. |
| `Config.Match.minPlayers` | Minimum queued players before match start. |
| `Config.Match.countdown` | Countdown length in seconds. |
| `Config.Economy.entryFee` | Amount taken when a player joins the queue. |
| `Config.Economy.winnerPayout` | Amount paid to the winner. |

## How the bridge works

The resource uses a framework bridge so `server.lua` can call generic money functions without hardcoding framework-specific economy logic into the match system.

The bridge currently exposes framework-aware handling for:
- player balance lookup,
- entry fee removal,
- winner payout,
- standalone fallback balances.[2][5][4]

This architecture is the reason the same fight logic can be reused across ESX, QBCore, vRP, and standalone environments with minimal changes.

## Installation

1. Place the `fivem-fightclub` folder inside your server's `resources` directory.[9]
2. Make sure the folder contains `fxmanifest.lua`, `config.lua`, `bridge.lua`, `server.lua`, and `client.lua`.[1]
3. Add `ensure fivem-fightclub` to your `server.cfg`, or start the resource through txAdmin.
4. Restart the server or restart the resource after changes.

## Recommended framework setup

### ESX

Use `Config.Framework = 'auto'` or `Config.Framework = 'esx'` if you want to force ESX detection during testing. ESX account money handling in this pack follows the xPlayer account method style documented in ESX references.[2][6]

### QBCore

Use `Config.Framework = 'auto'` or `Config.Framework = 'qbcore'`. QBCore money handling uses the documented player money function pattern.[3][5]

### Qbox

Use `Config.Framework = 'qbcore'` if your Qbox setup exposes the QB compatibility path, then test entry fee and payout flow directly on your server before advertising support publicly.[8]

### vRP

For first testing, use `Config.Framework = 'vrp'` and `Config.MoneyType = 'cash'`. vRP proxy guides document the interface/proxy calling pattern, but fork differences mean wallet testing is safer than bank testing as a first pass.[4]

### Standalone

Use `Config.Framework = 'standalone'` when testing without a server framework. The bridge uses a simple local fallback balance so you can validate fight flow without ESX, QBCore, or vRP installed.

## Match flow

1. A player walks to the arena marker.
2. The player presses `E` to join the fight queue.
3. The server checks the configured balance through the bridge.
4. The entry fee is removed if the player has enough money.[2][5][4]
5. Once enough players are queued, a countdown begins.
6. The fight starts and the client enforces melee-only combat.
7. When one player dies, the winner is paid through the bridge layer.[2][5][4]

## Included commands

| Command | Purpose |
|---|---|
| `fighttest` | Starts a local debug countdown and test fight without a second player. |
| `endfighttest` | Ends the debug fight state. |
| `testgun` | Gives a pistol so you can confirm the script forces unarmed state during fights. |
| `mycoords` | Prints your current coordinates for arena setup or relocation. |

## Testing checklist

### Basic local testing

1. Start the resource.
2. Join the server.
3. Move to the configured arena marker.
4. Run `testgun` to confirm you can visibly hold a weapon.
5. Run `fighttest` to confirm the script removes weapons and enforces melee-only mode.
6. Run `endfighttest` to reset the test state.

### Economy testing

- Test queue entry with enough money and with insufficient money.[2][5][4]
- Test winner payout after a real two-player fight.[2][5][4]
- Test disconnect handling so the remaining player receives the configured winner payout through server logic.

### vRP testing notes

- Test wallet mode first using `Config.MoneyType = 'cash'`.[4]
- Test bank mode only after wallet mode works, because bank helper support can vary by fork.[4]
- If your vRP fork does not expose the same bank helpers, adapt the bank branch in `bridge.lua` to your fork's API.[4]

## Known limitations

- Qbox support should be treated as compatibility-targeted until verified on a live Qbox setup.[8]
- vRP support can vary across forks, especially for bank operations.[4]
- Leaving the queue does not refund the entry fee in the current server logic.
- This version focuses on one arena and one active match at a time.

## Recommended release wording

For a public release page, the most accurate wording is:

- Supports ESX and QBCore out of the box.
- Compatible with Qbox through QB bridge setups.
- Supports standard proxy-based vRP setups.
- Includes standalone mode for testing and lightweight use.

This wording is safer than claiming every framework and every fork behaves identically without live verification.[8][4]

## Future upgrades

- Add multiple arena support.
- Add a cleaner NUI or UI notification system.
- Add tournament brackets or ranking logic.
- Improve bank-mode handling for vRP forks.[4]
- Expand framework adapters further if you want broader marketplace compatibility.
