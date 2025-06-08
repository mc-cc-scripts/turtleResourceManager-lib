--@requires helperFunctions
---@type HelperFunctions
local helperFunctions = require("helperFunctions");
--@requires turtleController
---@type turtleController
local tController = require("turtleController");
---@type Config
local config = require("config")

---@class tRMAction
---@field suck function
---@field drop function
---@field place function
---@field dig function

---@type {[string]: tRMAction}
local actionDirection = {
    Down = {
        suck = function(count) return turtle.suckDown(count) end,
        drop = function(count) return turtle.dropDown(count) end,
        place = function() return turtle.placeDown() end,
        dig = function() return turtle.digDown() end 
    },
    Forward = {
        suck = function(count) return turtle.suck(count) end,
        drop = function(count) return turtle.drop(count) end,
        place =function() return turtle.place() end,
        dig = function() return turtle.dig() end
    },
    Up = {
        suck =function(count) return turtle.suckUp(count) end,
        drop =function(count) return turtle.dropUp(count) end,
        place =function() return turtle.placeUp() end,
        dig =function() return turtle.digUp() end
    }
}

local defaultSettings = {
    ["ChestSlots"] = 
        {default = {
            SuckFrom = 15,
            DumpInto = 16
        }
    },
    ["ChestDirection"] = {
        default = "Down"
    }
    ,
    ["ItemsToKeep"] = {
        default = {["enderchests:ender_chest"] = true}
    },
    ["ChestType"] = {default = "enderchests:ender_chest"}
}

---@class TurtleResourceManager
local TurtleResourceManager = {}

config:init(defaultSettings, "@TurtleResourceManager")

--- WIP
--- Intendet to reset the turtle inventory state as far as possible, to the main prog can act accordingly
---@param content any
---@param oldSlot any
local function errorHandler(content, oldSlot)
    turtle.select(oldSlot)
    --TODO Logger
end

---If a Fuel-Chest is available, Checks if it contains fuel, takes a stack of it, and puts in into the next empty Slot. Then Picks up Chest again.
---@param item function | string | nil comparefunction(currentSlot, ...)| full itemname. Like minecraft:charcoal | nil = everything is ok
---@return number status 1 = successful, 2 = error, 3 = critical Error (couldnt pickup Chest)
---@return string | nil errorReason
function TurtleResourceManager:suckItem(item, ...)
    local fuelSlot = config:get("ChestSlots")
    if fuelSlot then
        fuelSlot = fuelSlot.SuckFrom --[[@as number]]
    end
    local currentSlot = turtle.getSelectedSlot()
    turtle.select(fuelSlot)

    if (
        turtle.getItemDetail() ~= nil and
            turtle.getItemDetail().name == config:get('ChestType')) then

        local tmpConfig = config:get("ChestDirection")
        if not tmpConfig or not tmpConfig.selectedSlot or not actionDirection[tmpConfig.selectedSlot] then
            return 2, "Settings broken"
        end
        local actionTable = actionDirection[tmpConfig.selectedSlot] --[[@as tRMAction]]
        if tController.canBreakBlocks == true then
            actionTable.dig()
        end
        do -- Checks before digging?
            if tController:findEmptySlot() == nil then
                if TurtleResourceManager.manageSpace(1) ~= 1 then
                    local err = "don`t have the inventory Space for Item!\n"
                    errorHandler(err, currentSlot)
                    return 2, err
                end
            end
            if not actionTable.place() then
                turtle.select(currentSlot)
                local err = "Could not place Chest!\n"
                errorHandler(err, currentSlot)
                return 2, err
            end
            if not actionTable.suck() then
                local err = "Chest does not contain anything!\n"
                if not actionTable.dig() then
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
                    if not actionTable.drop() or not actionTable.dig() then
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
                    if not actionTable.drop() or not actionTable.dig() then
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
        if not actionTable.dig() then
            local err = "Can not pick up Enderchest!\n"
            errorHandler(err, currentSlot)
            return 3, err
        end
        local tmpItem = turtle.getItemDetail()
        if not tmpItem or tmpItem.name ~= config:get("ChestType") then
            local err = "Did not pickup expected chest!"
            errorHandler(err, currentSlot)
            return 3, err
        end
    else
        turtle.select(currentSlot)
        local err = 'Input Chest not present!\n'
        errorHandler(err, currentSlot)
        return 2, err
    end
    turtle.select(currentSlot)
    return 1
end

---Dumps all Slots into the Items-Chest (Settings), so that [minEmpty] Slots are available.
---@param minEmpty number 1 - 14, as 2 are left for the Chests
---@param keepFunction? fun(item, args): boolean can dump Item? If empty, only the chests stay
---@param ... any Args, which are parsed to the keepFunction
---@return integer 1 = successful, 2 = error, 3 = critical error (could not pick up chest)
---@return string | nil errorReason
function TurtleResourceManager:manageSpace(minEmpty, keepFunction, ...)
    local itemChestSlot = config:get("ChestSlots")
    if not itemChestSlot or not itemChestSlot.DumpInto then
        local err = "Settings not setup => ChestSlots"
        return 2, err
    end
    itemChestSlot = itemChestSlot.DumpInto
    local currentSlot = turtle.getSelectedSlot();
    turtle.select(itemChestSlot)

    if (
        turtle.getItemDetail() ~= nil and
        turtle.getItemDetail().name == config:get("ChestType")) then
        -- TODO: Dynamic?
        local chestDir = config:get("ChestDirection")
        if not chestDir then
            return 2, "settings Missing"
        end
        local actionTable = actionDirection[chestDir]
        do -- Checks

            local startingEmptySlots = 0
            for i = 1, 16 do
                if turtle.getItemDetail(i) == nil then
                    startingEmptySlots = startingEmptySlots + 1
                end
            end

            if minEmpty > startingEmptySlots then

                -- place Chest
                actionTable.dig()
                if not actionTable.place() then
                    turtle.select(currentSlot)
                    local err = "Could not place Chest!\n"
                    errorHandler(err, currentSlot)
                    return 2, err
                end

                local emptySlots = startingEmptySlots
                local itemsToCeep = config:get("ItemsToKeep")
                
                
                -- if item can be dropped, do so
                for i = 1, 16, 1 do
                    local item = turtle.getItemDetail(i)
                    keepFunction = keepFunction or function ()
                        return true
                    end
                    if item ~= nil and itemsToCeep[item.name] == nil and (keepFunction(item, table.unpack(arg))) then
                        turtle.select(i)
                        if not actionTable.drop(turtle.getItemCount()) then
                            turtle.select(itemChestSlot)
                            if not actionTable.dig() then
                                local err = 'Could not Pick up Item-Chest after beeing unable to drop item in slot!\n' .. turtle.getSelectedSlot()
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
                if (not actionTable.dig() or turtle.getItemDetail().name ~= config:get("ChestType")) then
                    local err = 'Could not Pick up Item-Chest after clearing!\n'
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
        local err = 'Output-Chest not available!\n'
        errorHandler(err, currentSlot)
        return 2, err
    end
    turtle.select(currentSlot)
    return 1
end

---checks what chests are given / not given
---@return boolean manageSpace
---@return boolean suckItem
---@return string[] errorReason
function TurtleResourceManager:checkSetup()
    local cT = config:get("ChestType")

    local manageSpace, suckItem = false, false
    local errorReason = {
        Settings = {},
        Missing = {}
    }

    if type(cT) ~= "string" then
        errorReason.Settings = {"Output", "Input"}
        print("Settings not a string")
        return false, false, errorReason
    end
    local chestSlots = config:get("ChestSlots")
    if type(chestSlots) ~= "table" then
        print("ChestSlots not a table", chestSlots)
        errorReason.Settings = {"Output", "Input"}
        return false, false, errorReason
    end


    local manageSpace, suckItem = false, false

    local spaceChest = chestSlots and chestSlots.DumpInto
    if not spaceChest then
        manageSpace = false
        table.insert(errorReason.Settings, "Output")

    elseif (not turtle.getItemDetail(spaceChest) or turtle.getItemDetail(spaceChest).name ~= cT) then
        manageSpace = false
        table.insert(errorReason.Missing, "Output")
    else
            manageSpace = true
    end

    local suckChest = chestSlots and chestSlots.SuckFrom

    if not suckChest then
        suckItem = false
        table.insert(errorReason.Settings, "Input")
    elseif (not turtle.getItemDetail(suckChest) or turtle.getItemDetail(suckChest).name ~= cT) then
        suckItem = false
        table.insert(errorReason.Missing, "Input")
    else
        suckItem = true
    end

    return manageSpace, suckItem, errorReason

end

---sets the Slots for the input / output Chests
---@param slotSettings table<"DumpInto" | "SuckFrom", number>
---@return boolean success
---@return string | nil errorReason
function TurtleResourceManager:setChestSlots(slotSettings)
    local formatText = "Format: {DumpInto = <number | nil>, SuckFrom = <number | nil>}"
    if type(slotSettings) ~= "table" then
        return false, formatText
    end
    local tmpSettings = config:get("ChestSlots")
    if slotSettings.DumpInto then
        tmpSettings.DumpInto = slotSettings.DumpInto
    end
    if slotSettings.SuckFrom then
        tmpSettings.SuckFrom = slotSettings.SuckFrom
    end
    config:set("ChestSlots", tmpSettings)
    return true
end

---sets the direction the Chest gets placed when used
---@param dir "Up" | "Down" | "Forward"
---@return boolean success
---@return string | nil errorReason
function TurtleResourceManager:setChestDirection(dir)
    if type(dir) ~= "string" then
        return false, "Needs a string"
    end
    config:set("ChestDirection", dir)

    return true
end

function TurtleResourceManager:setChestType(type)
    if type(type) ~= "string" then
        return false, "Needs a string"
    end
    config:set("ChestType", type)
    return true
end


return TurtleResourceManager
