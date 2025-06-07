---@class are
---@field same function
---@field equal function
---@field equals function

---@class is
---@field truthy function
---@field falsy function
---@field not_true function
---@field not_false function

---@class has
---@field error function
---@field errors function

---@class assert
---@field are are
---@field is is
---@field are_not are
---@field is_not is
---@field has has
---@field has_no has
---@field True function
---@field False function
---@field has_error function
---@field is_false function
---@field is_true function
---@field equal function
assert = assert

package.path = "libs/?.lua;"
    .. "libs/inventory/?.lua;"
    .. "libs/peripherals/?.lua;"
    .. package.path

_G.settings = require("settings")
_G.vector = require("vector")

---@type HelperFunctions
local helperFunctions = require("helperFunctions")

---@type TurtleEmulator
local turtleEmulator = require("turtleEmulator")

---@type TurtleResourceManager
local turtleResourceManager = require("turtleResourceManager")

--#region Items

local itemStone = {
    name = "minecraft:stone",
    count = 64,
    equipable = false,
    placeAble = false
}
local itemPickAxe = {
    name = "minecraft:diamond_pickaxe",
    count = 1,
    equipable = true,
    placeAble = false
}
local itemChunkLoad = {
    name = "advancedperipherals:chunk_controller",
    count = 1,
    equipable = true,
    placeAble = false
}
local itemLog = {
    name = "minecraft:oak_log",
    count = 64,
    equipable = false,
    placeAble = true
}
---@type Item
local itemEnderChest = {
    name = "enderchests:ender_chest",
    count = 1,
    equipable = false,
    placeAble = true,
}


--#endregion

local function beforeEach()

    turtleEmulator:clearBlocks()
    turtleEmulator:clearTurtles()
    _G.turtle = turtleEmulator:createTurtle()
    _G.peripheral = turtle:getPeripheralModule()

end 

describe("Check Errors", function()
    before_each(function()
        beforeEach()
    end)
    it("CheckSetup", function()
    end)
end)

describe("Clean Inventory", function()
    local inputChest, outpuChest
    before_each(function ()
        beforeEach()
        local tmpItem
        for i = 2, 13, 1 do
            tmpItem = helperFunctions.deepCopy(itemStone) --[[@as Item]]
            turtle.addItemToInventory(tmpItem, i)
        end
        tmpItem = helperFunctions.deepCopy(itemStone) --[[@as Item]]
        turtle.addItemToInventory(tmpItem, 15)
        inputChest = turtleEmulator:addInventoryToItem(tmpItem)
        tmpItem = helperFunctions.deepCopy(itemStone) --[[@as Item]]
        turtle.addItemToInventory(tmpItem, 16)
        outpuChest = turtleEmulator:addInventoryToItem(tmpItem)
    end)
    it("CheckSetup", function()
        local dumpInto, suckFrom, errorReason = turtleResourceManager:checkSetup()
        assert.are.equal({}, errorReason)
        assert.is_true(dumpInto)
        assert.is_true(suckFrom)
    end)
end)

