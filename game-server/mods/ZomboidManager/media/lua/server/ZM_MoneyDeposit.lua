--
-- ZM_MoneyDeposit.lua — Reads deposit_requests.json, removes Base.Money/MoneyStack
-- from player inventories, writes deposit_results.json
--

require("ZM_Utils")
require("ZM_InventoryExporter")

ZM_MoneyDeposit = {}

local REQUESTS_FILE = "deposit_requests.json"
local RESULTS_FILE = "deposit_results.json"
local MAX_RESULTS = 200

--- Read existing results file
local function readResults()
    local data = ZM_Utils.readJsonFile(RESULTS_FILE)
    if data then
        return data
    end
    return {version = 1, updated_at = "", results = {}}
end

--- Write results to file, trimming oldest entries if over cap
local function writeResults(results)
    results.updated_at = ZM_Utils.getTimestamp()

    while results.results and #results.results > MAX_RESULTS do
        table.remove(results.results, 1)
    end

    ZM_Utils.writeJsonFile(RESULTS_FILE, results)
end

--- Find online player by username
local function findPlayer(username)
    local players = getOnlinePlayers()
    if not players then
        return nil
    end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p and p:getUsername() == username then
            return p
        end
    end
    return nil
end

--- Count and remove all Money/MoneyStack items from a player's inventory.
--- Two-pass: collect all refs first, then remove.
--- Returns money_count, stack_count
local function countAndRemoveMoney(player)
    local moneyItems = {}
    local stackItems = {}

    -- Collect from main inventory
    local inventory = player:getInventory()
    if inventory then
        local allItems = inventory:getItems()
        if allItems then
            for i = 0, allItems:size() - 1 do
                local item = allItems:get(i)
                if item then
                    local fullType = item:getFullType()
                    if fullType == "Base.Money" then
                        table.insert(moneyItems, {item = item, container = inventory})
                    elseif fullType == "Base.MoneyStack" then
                        table.insert(stackItems, {item = item, container = inventory})
                    end
                end
            end
        end
    end

    -- Collect from backpack
    local backpack = player:getClothingItem_Back()
    if backpack and backpack:getItemContainer() then
        local bagContainer = backpack:getItemContainer()
        local bagItems = bagContainer:getItems()
        if bagItems then
            for i = 0, bagItems:size() - 1 do
                local item = bagItems:get(i)
                if item then
                    local fullType = item:getFullType()
                    if fullType == "Base.Money" then
                        table.insert(moneyItems, {item = item, container = bagContainer})
                    elseif fullType == "Base.MoneyStack" then
                        table.insert(stackItems, {item = item, container = bagContainer})
                    end
                end
            end
        end
    end

    -- Remove collected items
    for _, entry in ipairs(moneyItems) do
        entry.container:removeItemOnServer(entry.item)
    end
    for _, entry in ipairs(stackItems) do
        entry.container:removeItemOnServer(entry.item)
    end

    return #moneyItems, #stackItems
end

--- Process all pending deposit requests
function ZM_MoneyDeposit.process()
    local requests = ZM_Utils.readJsonFile(REQUESTS_FILE)
    if not requests or not requests.requests then
        return 0
    end

    -- Early exit: check if any entries are pending
    local hasPending = false
    for _, req in ipairs(requests.requests) do
        if req.status == "pending" then
            hasPending = true
            break
        end
    end
    if not hasPending then
        return 0
    end

    local results = readResults()
    local processed = 0

    -- Build set of already-processed IDs
    local processedIds = {}
    if results.results then
        for _, r in ipairs(results.results) do
            processedIds[r.id] = true
        end
    end

    for _, req in ipairs(requests.requests) do
        if req.status == "pending" and not processedIds[req.id] then
            local result = {
                id = req.id,
                username = req.username,
                status = "failed",
                money_count = 0,
                stack_count = 0,
                total_coins = 0,
                message = nil,
                processed_at = ZM_Utils.getTimestamp(),
            }

            local player = findPlayer(req.username)
            if not player then
                result.message = "player not online"
            else
                local moneyCount, stackCount = countAndRemoveMoney(player)
                if moneyCount == 0 and stackCount == 0 then
                    result.message = "no money items found"
                else
                    local moneyValue = 1
                    local stackValue = 10
                    local totalCoins = (moneyCount * moneyValue) + (stackCount * stackValue)

                    result.status = "success"
                    result.money_count = moneyCount
                    result.stack_count = stackCount
                    result.total_coins = totalCoins

                    print("[ZomboidManager] Money deposit: " .. req.username .. " deposited " .. moneyCount .. " Money + " .. stackCount .. " MoneyStack = " .. totalCoins .. " coins")

                    -- Re-export inventory so the web reflects the change immediately
                    ZM_InventoryExporter.exportPlayer(player)
                end
            end

            table.insert(results.results, result)
            processed = processed + 1
        end
    end

    if processed > 0 then
        writeResults(results)
    end

    return processed
end

--- Initialize the money deposit system
function ZM_MoneyDeposit.init()
    print("[ZomboidManager] Money deposit system initialized")
end

return ZM_MoneyDeposit
