--@requires settingsService
---@class SettingsManager
local settingsService = require("./libs/settingsManager");
--@requires log
---@class Log
local log = require("./libs/log")
--@requires helperFunctions
---@class HelperFunctions
local helperFunctions = require("./libs/helperFunctions");
--@requires turtleController
---@class turtleController
local tController = require("./libs/turtleController");



local defaultSlots = {
    DumpInto = 15,
    suckFrom = 16
}

local chestDirection = {
    Down = { suck = turtle.suckDown, drop = turtle.dropDown, place = turtle.placeDown, dig = turtle.digDown },
    Forward = { suck = turtle.suck, drop = turtle.drop, place = turtle.place, dig = turtle.dig },
    Up = { suck = turtle.suckUp, drop = turtle.dropUp, place = turtle.placeUp, dig = turtle.digUp }
}

local defaultItemsToCeep = {
    ["enderstorage:ender_chest"] = true
}

local defaultChestType = "enderstorage:ender_chest"
---@class TurtleResourceManager
--- TODO: Currently can only place block under it
--- ### Settings Used:
---  - FuelChestSlot,
---  - ItemChestSlot,
---  - ChestType,
---  - ItemsToCeep
local TurtleResourceManager = {}


local function errorHandler(content, oldSlot)
    log.ErrorHandler(content, nil, false)
    turtle.select(oldSlot)
end

---If a Fuel-Chest is available, Checks if it contains fuel, takes a stack of it, and puts in into the next empty Slot. Then Picks up Chest again.
---@param item function | string | nil comparefunction(currentSlot, ...)| full itemname. Like minecraft:charcoal | nil = everything is ok
---@return number status 1 = successful, 2 = error, 3 = critical Error (couldnt pickup Chest)
---@return string | nil errorReason
function TurtleResourceManager.suckItem(item, ...)
    local fuelSlot = SettingsService.setget('FuelChestSlot', nil, defaultSlots.suckFrom)
    local currentSlot = turtle.getSelectedSlot()
    turtle.select(fuelSlot)

    if (
        turtle.getItemDetail() ~= nil and
            turtle.getItemDetail().name == SettingsService.setget('ChestType', nil, defaultChestType)) then

        -- TODO: Dynamic?
        local cDirection = chestDirection.Down
        if tController.canBeakblocks == true then
            tController:tryAction("digD")
        end
        do -- Checks
            if tController:findEmptySlot() == nil then
                if TurtleResourceManager.manageSpace(1) ~= 1 then
                    local err = "don`t have the inventory Space for Item!\n"
                    errorHandler(err, currentSlot)
                    return 2, err
                end
            end
            if not cDirection.place() then
                turtle.select(currentSlot)
                local err = "Could not place Chest!\n"
                errorHandler(err, currentSlot)
                return 2, err
            end
            if not cDirection.suck() then
                local err = "Chest does not contain anything!\n"
                if not cDirection.dig() then
                    err = err .. " && Could not pick chest up again!\n"
                    errorHandler(err, currentSlot)
                    return 3, err
                end

                errorHandler(err, currentSlot)
                return 2, err

            end
            if type(item) == "function" then
                if not item(turtle.getItemDetail(), table.unpack(arg)) then
                    local err = "Chest does not (only) contain the required item!\n"
                    if not cDirection.drop() or not cDirection.dig() then
                        err = err .. " && Could not pick chest up again!\n"
                        errorHandler(err, currentSlot)
                        return 3, err
                    end
                    errorHandler(err, currentSlot)
                    return 2, err
                end
                -- end
            elseif type(item) == "string" then
                if not turtle.getItemDetail() == item then
                    local err = "Chest does not (only) contain the required item: " .. item .. "!\n"
                    if not cDirection.drop() or not cDirection.dig() then
                        err = err .. " && Could not pick chest up again!\n"
                        errorHandler(err, currentSlot)
                        return 3, err
                    end
                    errorHandler(err, currentSlot)
                    return 2, err
                end
            end
        end

        local emptySlot = tController:findEmptySlot()
        if emptySlot == nil then
            local err = "How on earth.... I don`t have the inventory Space for new Fuel!\n"
            errorHandler(err, currentSlot)
            return 3, err
        end
        if not turtle.transferTo(emptySlot) then
            local err = "Could not transfer Fuel to Slot!\n"
            errorHandler(err, currentSlot)
            return 3, err
        end
        if not cDirection.dig() then
            local err = "Can not pick up Enderchest!\n"
            errorHandler(err, currentSlot)
            return 3, err
        end


        -- TODO Check if chest picked up again after


    else
        turtle.select(currentSlot)
        local err = 'FuelChest not available!\n'
        errorHandler(err, currentSlot)
        return 2, err
    end
    turtle.select(currentSlot)
    return 1
end

---Dumps all Slots into the Items-Chest (Settings), so that [minEmpty] Slots are available.
---@param minEmpty number 1 - 14, as 2 are left for the Chests
---@param keepFunction function| nil can dump Item? If empty, only the settings stay
---@return integer
---@return string | nil errorReason
function TurtleResourceManager.manageSpace(minEmpty, keepFunction, ...)
    local itemChestSlot = SettingsService.setget('ItemChestSlot', nil, defaultSlots.DumpInto)
    local currentSlot = turtle.getSelectedSlot();
    turtle.select(itemChestSlot)

    if (
        turtle.getItemDetail() ~= nil and
            turtle.getItemDetail().name == SettingsService.setget('ChestType', nil, defaultChestType)) then
        -- TODO: Dynamic?
        local cDirection = chestDirection.Down
        do -- Checks

            local startingEmptySlots = 0
            for i = 1, 16 do
                if turtle.getItemDetail(i) == nil then
                    startingEmptySlots = startingEmptySlots + 1
                end
            end
            -- if tController.canBeakblocks == true then
            tController:tryAction("digD")
            -- end
            if not cDirection.place() then
                turtle.select(currentSlot)
                local err = "Could not place Chest!\n"
                errorHandler(err, currentSlot)
                return 2, err
            end

            if startingEmptySlots ~= minEmpty then
                local emptySlots = startingEmptySlots
                local itemsToCeep = SettingsService.setget('ItemsToCeep', nil, defaultItemsToCeep)
                for i = 16, 1, -1 do
                    local item = turtle.getItemDetail(i)
                    -- if ceepFunction ~= func then ceep = true, otherwise exec ceepFunction
                    local keepItemFuncRet = function(itemParameter, parameter)
                        if type(keepFunction) == "function" then
                            return keepFunction(itemParameter, table.unpack(parameter))
                        end
                        return true

                    end
                    if item ~= nil and itemsToCeep[item.name] == nil and keepItemFuncRet(item, arg) then
                        turtle.select(i)
                        if not cDirection.drop() then
                            turtle.select(itemChestSlot)
                            if not cDirection.dig() then
                                local err = 'Could not Pick up Item-Chest!\n'
                                errorHandler(err, currentSlot)
                                return 3, err
                            end
                            local err = 'Could not drop Item into Item-Chest\n'
                            errorHandler(err, currentSlot)
                            return 2, err
                        end
                        emptySlots = emptySlots + 1
                        if emptySlots >= minEmpty then break end
                    end
                end
                turtle.select(itemChestSlot)
                if (turtle.getItemDetail(itemChestSlot) ~= nil) or (not cDirection.dig()) then
                    local err = 'Could not Pick up Item-Chest!\n'
                    errorHandler(err, currentSlot)
                    return 3, err
                end
                if minEmpty > emptySlots then
                    local err = 'Could not free enough slots, only ' .. emptySlots .. ' / ' .. minEmpty .. ' empty!\n'
                    errorHandler(err, currentSlot)
                    return 2, err
                end
            end
        end
    else
        local err = 'Item-Chest not available!\n'
        errorHandler(err, currentSlot)
        return 2, err
    end
    turtle.select(currentSlot)
    return 1
end

return TurtleResourceManager
