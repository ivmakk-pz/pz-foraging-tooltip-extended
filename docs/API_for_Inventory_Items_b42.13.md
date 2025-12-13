# Project Zomboid: API for Inventory Items

Source: https://theindiestone.com/forums/index.php?/topic/88499-modding-migration-guide-4213/ (`Project Zomboid_ API for Inventory Items-1.pdf`)

Document version: **1.0**

## Contents

- [Project Zomboid: API for Inventory Items](#project-zomboid-api-for-inventory-items)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [1. General description](#1-general-description)
  - [2. Timed Action Architecture](#2-timed-action-architecture)
    - [2.1 Modification of the `new` function](#21-modification-of-the-new-function)
    - [2.2 Realisation of the `getDuration` function](#22-realisation-of-the-getduration-function)
    - [2.3 Split of the `perform` function into `perform` and `complete`](#23-split-of-the-perform-function-into-perform-and-complete)
  - [3. Realisation features of the long Timed Actions](#3-realisation-features-of-the-long-timed-actions)
  - [4. The use of `sendClientCommand`](#4-the-use-of-sendclientcommand)
  - [5. Synchronisation of the creation, deletion and modification of items and objects](#5-synchronisation-of-the-creation-deletion-and-modification-of-items-and-objects)

## Introduction

This document is for modders for Project Zomboid. It describes a new system of Inventory Items manipulation, developed to prevent cheating.

All inventory Items processing in multiplayer are transferred to the server side. That means that while it’s still possible to modify the client to create an Inventory Item and put it into the inventory, such an item won’t be available for interaction and will be deleted from the inventory after relogin.

All items should be created on the server side and then transferred to the client. Thus, an Inventory Item will be in the player’s inventory on both client and server sides.

## 1. General description

The main way of Inventory Item creation, deletion, and manipulation is to perform it in a Timed Action. The Inventory Item creation, deletion and modification should be done on the server side, modifying the player’s inventory on the server side. The player’s inventory on the client side is modified subsequently to be identical to the one on the server side.

An alternative way of Inventory Item creation, deletion, and manipulation is to send a command using `sendCommand` or `sendClientCommand`. To do that you have to implement your command processor that will:

- receive the necessary data,
- perform cheating checks,
- create / delete / modify the Inventory Item on the server side, and
- send corresponding packets to clients for synchronisation.

This approach can be useful when dealing with Inventory Item manipulation that doesn’t come from the user's actions (for example, admin powers).

## 2. Timed Action Architecture

The new implementation of Timed Action allows executing a Timed Action on both the server and the client.

To adapt an existing Timed Action to the new architecture:

1. Move the Timed Action file from `media/lua/client` to `media/lua/shared`. This allows the script to be loaded by both the client and the server.
2. Make sure there is a variable of the same name with the same value for each new function argument.
3. Create the `getDuration` function, which returns the execution time of the Timed Action.
4. Split the old `perform` function into `perform` and `complete`:
   - `perform`:
     - performs actions needed only on the client (animation, sound management, UI),
     - **does not** contain manipulations with any items or objects,
     - is performed on the client (and in singleplayer mode).
   - `complete`:
     - contains manipulations with items and objects only,
     - is performed on the server (and in single-player mode),
     - is executed after `perform` in single-player mode.
5. Add calls that send changes to clients into the `complete` function (see section 5).

### 2.1 Modification of the `new` function

When running a Timed Action, the game sends it to the server side and restores the Timed Action Lua object. This is necessary for execution of `getDuration` and `complete` on the server side. The server receives the list of the `new` function arguments and searches for their values in the variables (fields) of the object.

Assume the following code:

```lua
function ISPlaceTrap:new(playerObj, trap, damage, maxTime)
    local o = ISBaseTimedAction.new(self, playerObj);
    o.square = character:getCurrentSquare();
    o.weapon = trap;
    o.damage = damage / 20;
    o.maxTime = maxTime;
    return o;
end
```

Code piece 1 – Example of an incorrect `new` function

The game won’t be able to restore such an object on the server side, because the argument names aren’t the same as the names of the variables in the object.

To fix this (so the server can restore the object):

1. Rename `playerObj` to `character`. The `ISBaseTimedAction.new` function stores the argument in `o.character`.
2. Rename the `trap` argument to `weapon`, because the value is saved into `o.weapon`.
3. Do not overwrite `damage` (keep incoming values unchanged). Otherwise, the constructor may be applied twice (client then server) and the value can be divided twice.
4. Do not transfer execution time as an argument (it’s a cheat vector). Use `getDuration` to calculate execution time on the server side.

Reference implementation of `ISBaseTimedAction:new`:

```lua
function ISBaseTimedAction:new (character)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.stopOnAim = true;
    o.caloriesModifier = 1;
    o.maxTime = -1;
    return o
end
```

Code piece 2 – Implementation of `ISBaseTimedAction:new`

After applying the changes, you should end up with something like:

```lua
function ISPlaceTrap:new(character, weapon)
    local o = ISBaseTimedAction.new(self, character);
    o.square = character:getCurrentSquare();
    o.weapon = weapon;
    o.maxTime = o:getDuration();
    return o;
end
```

Code piece 3 – Example of a correct `new` function implementation

Currently the game supports the following data types for the arguments of the `new` function:

1. BaseVehicle
2. BloodBodyPartType
3. BodyPart
4. Boolean
5. CraftRecipe
6. Double
7. EvolvedRecipe
8. FluidContainer
9. Integer
10. InventoryItem
11. IsoAnimal
12. IsoDeadBody
13. IsoGridSquare
14. IsoHutch.NestBox
15. IsoObject
16. IsoPlayer
17. ItemContainer
18. KahluaTableImpl
19. MultiStageBuilding.Stage
20. PZNetKahluaTableImpl
21. Recipe
22. Resource
23. SpriteConfigManager.ObjectInfo
24. String
25. VehiclePart
26. VehicleWindow
27. null

Serialisation implementation is in the `PZNetKahluaTableImpl` class.

Note: while passing an object, the client sends information to the server to search for the corresponding object on the server side, and the server then uses that object as the argument. For this reason, the game cannot transfer as an argument an object created on the client side.

### 2.2 Realisation of the `getDuration` function

The `getDuration` function is used by the server to fetch the time needed to execute the Timed Action. The client can also use it, e.g. in the `new` function:

```lua
o.maxTime = o:getDuration();
```

Code piece 4 – Using `getDuration` in `new` to set Timed Action duration

The `getDuration` function returns the execution time of the Timed Action in **cycles**.

- To convert seconds to cycles: divide by **0.02**.
  - Example: 1 second → `1 / 0.02 = 50` cycles.
- For instantaneous actions, it is recommended to return `1`.
- For infinite Timed Actions, return `-1`.
- This function should also return `1` if the `TimedActionInstant` cheat is enabled.

Example implementation for a 1-second action:

```lua
function ISPlaceTrap:getDuration()
    if self.character:isTimedActionInstant() then
        return 1;
    end
    return 50
end
```

Code piece 5 – Typical `getDuration` implementation returning 1 second

### 2.3 Split of the `perform` function into `perform` and `complete`

It is necessary to split `perform` into two functions: `perform` and `complete`. Both are executed at the end of Timed Action execution:

- Client executes only `perform`.
- Server executes only `complete`.
- Singleplayer executes `perform`, then `complete`.

The `perform` function must contain code that is not related to modifying items and objects (sounds, animations, UI, etc).

The `complete` function must contain code for items and objects modification only, and it cannot contain code that cannot be called on the server side.

Example using `ISAddFuelAction`.

Obsolete implementation:

```lua
function ISAddFuelAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    self.item:setJobDelta(0.0);
    if self.item:IsDrainable() then
        self.item:Use()
    else
        self.character:removeFromHands(self.item)
        self.character:getInventory():Remove(self.item)
    end
    local cf = self.campfire
    local args = { x = cf.x, y = cf.y, z = cf.z, fuelAmt = self.fuelAmt }
    CCampfireSystem.instance:sendCommand(self.character, 'addFuel', args)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end
```

Code piece 6 – Obsolete `perform` for `ISAddFuelAction`

New `perform` should keep only client-side concerns:

```lua
function ISAddFuelAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    self.item:setJobDelta(0.0);
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end
```

Code piece 7 – New `perform` for `ISAddFuelAction`

Now create a new server-side `complete` and move item/object changes there.

If you look at the handler implementation for the old `'addFuel'` command, it contains logic like:

```lua
function SCampfireSystemCommand(command, player, args)
    if command == 'addFuel' then
        local campfire = campfireAt(args.x, args.y, args.z)
        if campfire then
            campfire:addFuel(args.fuelAmt)
        end
        ...
    end
```

Code piece 8 – `'addFuel'` command handler (server-side)

Previously, the client used:

```lua
CCampfireSystem.instance:sendCommand(self.character, 'addFuel', args)
```

Code piece 9 – Sending the `'addFuel'` command from client to server

In `complete`, because it runs on the server, you can directly perform the work by finding the campfire object and applying changes:

```lua
local campfire = campfireAt(args.x, args.y, args.z)
if campfire then
    campfire:addFuel(args.fuelAmt)
end
```

Code piece 10 – Searching for and modifying the object on the server

And the `campfireAt` function can be implemented as:

```lua
local function campfireAt(x, y, z)
    return SCampfireSystem.instance:getLuaObjectAt(x, y, z)
end
```

Code piece 11 – Implementation of `campfireAt`

Final `complete` implementation example:

```lua
function ISAddFuelAction:complete()
    if self.item:IsDrainable() then
        self.item:UseAndSync()
    else
        self.character:removeFromHands(self.item)
        self.character:getInventory():Remove(self.item)
        sendRemoveItemFromContainer(self.character:getInventory(),self.item)
    end
    local campfire =
        SCampfireSystem.instance:getLuaObjectAt(self.campfire.x, self.campfire.y,
                                               self.campfire.z)
    if campfire then
        campfire:addFuel(self.fuelAmt)
    end
    return true
end
```

Code piece 12 – New `complete` for `ISAddFuelAction`

## 3. Realisation features of the long Timed Actions

To implement Timed Actions that perform actions during execution (for example, pouring liquids or reading books), use an additional Anim Event emulation API.

You need to implement `serverStart`, executed on the server side when the Timed Action starts. In this function, call `emulateAnimEvent` to set up the AnimEvent emulator.

Then implement `animEvent`, which will be called periodically to execute a part of the whole action.

To stop such an action, call server-side `self.netAction:forceComplete()`.

You can use `self.netAction:getProgress()` to get the progress of the action in `animEvent` on the server side.

Example `serverStart`:

```lua
function ISChopTreeAction:serverStart()
    self.axe = self.character:getPrimaryHandItem()
    emulateAnimEvent(self.netAction, 1500, "ChopTree", nil)
end
```

Code piece 13 – Example implementation of `serverStart`

`emulateAnimEvent` arguments:

1. `NetTimedAction` – always `self.netAction`
2. `duration` – period in milliseconds
3. `event` – name sent to `animEvent`
4. `parameter` – stock parameter for `animEvent`

Example `animEvent`:

```lua
function ISChopTreeAction:animEvent(event, parameter)
    if not isClient() then
        if event == 'ChopTree' then
            self.tree:WeaponHit(self.character, self.axe)
            self:useEndurance()
            if self.tree:getObjectIndex() == -1 then
                if isServer() then
                    self.netAction:forceComplete()
                else
                    self:forceComplete()
                end
            end
        end
    else
        if event == 'ChopTree' then
            self.tree:WeaponHitEffects(self.character, self.axe)
        end
    end
end
```

Code piece 14 – Example implementation of `animEvent`

End of Timed Action logic (when the tree is chopped down):

```lua
if isServer() then
    self.netAction:forceComplete()
else
    self:forceComplete()
end
```

Code piece 15 – Ending an infinite Timed Action

## 4. The use of `sendClientCommand`

`sendClientCommand` executes on the client and sends a command whose handler is on the server. In singleplayer, the handler is also called by the game.

Arguments:

1. `IsoPlayer player` – optional, player's object
2. `String module` – module name
3. `String command` – command name
4. `KahluaTable args` – table with arguments

Example (sending `getKey` for the `vehicle` module):

```lua
sendClientCommand(self.player, "vehicle", "getKey", { vehicle = self.vehicle:getId() })
```

Code piece 16 – Sending the `getKey` command

Upon receiving a client command, the server calls an `OnClientCommand` event with arguments: `module, command, player, args`.

Example server-side handler implementation:

```lua
local VehicleCommands = {}
local Commands = {}

function Commands.getKey(player, args)
    local vehicle = getVehicleById(args.vehicle)
    if vehicle and checkPermissions(player, Capability.UseMechanicsCheat) then
        local item = vehicle:createVehicleKey()
        if item then
            player:getInventory():AddItem(item);
            sendAddItemToContainer(player:getInventory(), item);
        end
    else
        noise('no such vehicle id='..tostring(args.vehicle))
    end
end

VehicleCommands.OnClientCommand = function(module, command, player, args)
    if module == 'vehicle' and Commands[command] then
        Commands[command](player, args)
    end
end

Events.OnClientCommand.Add(VehicleCommands.OnClientCommand)
```

Code piece 17 – Example server-side `getKey` handler

This handler:

- checks module name (`'vehicle'`)
- dispatches to a command-specific function from `Commands`
- performs permission checks (example uses `UseMechanicsCheat`)
- creates the item server-side and syncs it back to the client

## 5. Synchronisation of the creation, deletion and modification of items and objects

All object changes made in `complete` should be sent to clients.

Functions used for synchronisation:

1. `sendAddItemToContainer` – adds an `InventoryItem` to the container
2. `sendRemoveItemFromContainer` – deletes the `InventoryItem` from the container
3. `syncItemFields` – synchronises: `condition`, `remoteControlID`, `uses`, `currentAmmoCount`, `haveBeenRepaired`, `taintedWater`, `wetness`, `dirtyness`, `bloodLevel`, `hungChange`, `weight`, `alreadyReadPages`, `customPages`, `customName`, `attachedSlot`, `attachedSlotType`, `attachedToModel`, `fluidContainer`, `moddata`
4. `syncItemModData` – synchronises `moddata`
5. `syncHandWeaponFields` – synchronises: `currentAmmoCount`, `roundChambered`, `containsClip`, `spentRoundCount`, `spentRoundChambered`, `isJammed`, `maxRange`, `minRangeRanged`, `clipSize`, `reloadTime`, `recoilDelay`, `aimingTime`, `hitChance`, `minAngle`, `minDamage`, `maxDamage`, `attachments`, `moddata`
6. `sendItemStats` – synchronises: `uses`, `usedDelta`, `isFood`, `frozen`, `heat`, `cookingTime`, `minutesToCook`, `minutesToBurn`, `hungChange`, `calories`, `carbohydrates`, `lipids`, `proteins`, `thirstChange`, `fluReduction`, `painReduction`, `endChange`, `reduceFoodSickness`, `stressChange`, `fatigueChange`, `unhappyChange`, `boredomChange`, `poisonPower`, `poisonDetectionLevel`, `extraItems`, `alcoholic`, `baseHunger`, `customName`, `tainted`, `fluidAmount`, `isFluidContainer`, `isCooked`, `isBurnt`, `freezingTime`, `name`
7. `transmitCompleteItemToClients` – adds an object to the map
8. `transmitRemoveItemFromSquare` – deletes an object from the map
9. `sync` – synchronises an object change on the map
10. `transmitUpdatedSpriteToClients` – synchronises the changed sprite

Examples:

Adding an `InventoryItem` to inventory:

```lua
local candle = instanceItem("Base.Candle")
self.character:getInventory():AddItem(candle);
sendAddItemToContainer(self.character:getInventory(), candle);
```

Code piece 18 – Adding an `InventoryItem` to inventory

Deleting an `InventoryItem` from inventory:

```lua
self.character:removeFromHands(self.weapon)
self.character:getInventory():Remove(self.weapon);
sendRemoveItemFromContainer(self.character:getInventory(), self.weapon);
```

Code piece 19 – Deleting an `InventoryItem` from inventory

Adding an `IsoObject` to the map:

```lua
local trap = IsoTrap.new(self.weapon, self.square:getCell(), self.square);
self.square:AddTileObject(trap);
trap:transmitCompleteItemToClients();
```

Code piece 20 – Adding an `IsoObject` to the map

Deleting an `IsoObject` from the map:

```lua
self.trap:getSquare():transmitRemoveItemFromSquare(self.trap);
self.trap:removeFromWorld();
self.trap:removeFromSquare();
```

Code piece 21 – Deleting an `IsoObject` from the map

Synchronising an `IsoObject` change on the map:

```lua
self.generator:setActivated(self.activate)
self.generator:sync()
```

Code piece 22 – `IsoObject` synchronisation on the map
