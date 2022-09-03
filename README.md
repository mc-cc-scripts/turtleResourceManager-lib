# turtleResourceManager-lib

Description: manages the Turtle-Inventory with Ender-Chests

---

### suckItem

```lua
-- [[@param item: <function | string | nil> -> type function = compareFunction which returns <boolean>]]
-- [[@param args: <any> -> Parameter for the compareFunction]]
-- @return status: <number>
-- @return errorReason: <string>
TurtleResourceManager.suckItem(item: <function|string|nil>, ... : any) : status, errorReason
```

### manageSpace

```lua
-- [[@param minEmpty: number -> how many Slots should be empty]]
-- [[@param keepFunction: function|nil -> can item be removed from inventory? first parameter is the current item, next one(s) is arg, unpacked]]
-- @return status: <number>
-- @return errorReason: <string>
TurtleResourceManager.manageSpace(minEmpty: <number>, keepFunction: <function|nil>, ...)
```

## Infos

---

### Status:

- 1 = Success
- 2 = Error
- 3 = Critical Error (Cant pick up Chest again)

## Examples

---

```lua
trm = require('TurtleResourceManager')

-- Tries to suck an item out of the EnderChest in InventorySlot.
local status, err = trm.manageSpace(minEmpty, keepFunction, ...)
if status ~= 1 then
    -- errorhandling
    return
end
status, err = trm.suckItem('minecraft:charcoal')

-- Tries to dump Items into the EnderChest in InventorySlot until x slots are free
```
