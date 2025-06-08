# turtleResourceManager-lib

manages the Turtle-Inventory with Ender-Chests

Places the Ender-Chest, pulls / dumps item to / from said chest and picks it back up again.

---
## How to use

with default settings, slot 16 should be output-chest, slot 15 (untested) should be input chest


### manageSpace

```lua
---@param minEmpty: number -> how many Slots should be empty
---@param keepFunction: function|nil -> can item be removed from inventory? first parameter is the current item, next one(s) is arg, unpacked
---@return status: <number>
---@return errorReason: <string>
TurtleResourceManager:manageSpace(minEmpty: <number>, keepFunction: <function|nil>, ...)
```

### suckItem UNTESTED

```lua
---@param item: <function | string | nil> -> type function = compareFunction which returns <boolean>
---@param args: <any> -> Parameter for the compareFunction
---@return status: <number>
---@return errorReason: <string>
TurtleResourceManager:suckItem(item: <function|string|nil>, ... : any) : status, errorReason
```



### Status:

- 1 = Success
- 2 = Error
- 3 = Critical Error (Cant pick up Chest again)

## Examples

---

```lua
trm = require('TurtleResourceManager')

-- tries to clear up to n slots in the turtleinventory
local status, err = trm.manageSpace(minEmpty, keepFunction, ...)
if status ~= 1 then
    -- errorhandling
    return
end

-- untested
-- Tries to suck an item out of the EnderChest in InventorySlot.
status, err = trm.suckItem('minecraft:charcoal')

-- Tries to dump Items into the EnderChest in InventorySlot until x slots are free
```
