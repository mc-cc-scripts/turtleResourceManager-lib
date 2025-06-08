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
_G.textutils = require("textutils")

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
    placeAble = false,
    maxcount = 64
}
local itemPickAxe = {
    name = "minecraft:diamond_pickaxe",
    count = 1,
    equipable = true,
    placeAble = false,
    maxcount = 64
}
local itemChunkLoad = {
    name = "advancedperipherals:chunk_controller",
    count = 1,
    equipable = true,
    placeAble = false,
    maxcount = 16
}
local itemLog = {
    name = "minecraft:oak_log",
    count = 64,
    equipable = false,
    placeAble = true,
    maxcount = 64
}
---@type Item
local itemEnderChest = {
    name = "enderchests:ender_chest",
    count = 1,
    equipable = false,
    placeAble = true,
    maxcount = 64
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
        local dumpInto, suckFrom, errorReason = turtleResourceManager:checkSetup()
        assert.are.same({Missing = {"Output", "Input"}, Settings = {}}, errorReason)
        assert.is_false(dumpInto)
        assert.is_false(suckFrom)
    end)
    -- TODO: More tests
end)

describe("Clean Inventory", function()
    local inputChest, outputChest
    before_each(function ()
        beforeEach()
        local tmpItem
        for i = 3, 13, 1 do
            tmpItem = helperFunctions.deepCopy(itemStone) --[[@as Item]]
            turtle.addItemToInventory(tmpItem, i)
        end
        tmpItem = helperFunctions.deepCopy(itemEnderChest) --[[@as Item]]
        turtle.addItemToInventory(tmpItem, 16)
        outputChest = turtleEmulator:addInventoryToItem(tmpItem)
    end)
    it("CheckSetup", function()
        local dumpInto, suckFrom, errorReason = turtleResourceManager:checkSetup()
        assert.are.same({Settings = {}, Missing = {"Input"}}, errorReason)
        assert.is_true(dumpInto)
        assert.is_false(suckFrom)
    end)
    it("clear up all", function()
        local status, reason = turtleResourceManager:manageSpace(15, nil)
        assert.are.same(nil, reason)
        assert.are.equal(1, status)
        for i = 1, 15, 1 do
            assert.is.falsy(turtle.getItemDetail(i))
        end
    end)
    it("Clear up default filter", function()
        local tmpItem = helperFunctions.deepCopy(itemEnderChest) --[[@as Item]]
        turtle.addItemToInventory(tmpItem, 1)
        local status, reason = turtleResourceManager:manageSpace(14, nil)
        assert.are.same(nil, reason)
        assert.are.equal(1, status)
        assert.are.same("enderchests:ender_chest", turtle.getItemDetail(1).name)
        for i = 2, 15, 1 do
            assert.is.falsy(turtle.getItemDetail(i))
        end
    end)
    it("Clear up default filter + custom filter string", function()
        local tmpItem = helperFunctions.deepCopy(itemEnderChest) --[[@as Item]]
        turtle.addItemToInventory(tmpItem, 1)
        tmpItem = helperFunctions.deepCopy(itemPickAxe)
        turtle.addItemToInventory(tmpItem, 2)
        local filterFunction = function (item)
            return string.find(item.name, "pickaxe") == nil
        end
        local status, reason = turtleResourceManager:manageSpace(13, filterFunction)
        assert.are.same(nil, reason)
        assert.are.equal(1, status)
        assert.are.same("enderchests:ender_chest", turtle.getItemDetail(1).name)
        assert.are.same("minecraft:diamond_pickaxe", turtle.getItemDetail(2).name)
        for i = 3, 15, 1 do
            assert.is.falsy(turtle.getItemDetail(i))
        end
    end)
end)

