LootStats = LibStub("AceAddon-3.0"):NewAddon("LootStats", "AceConsole-3.0", "AceEvent-3.0")

local LINELIMIT = 10

function LootStats:OnInitialize()
    self.seen = {}
    self.tsSeen = {}
    local cleanDB = {
        global = {
            version = 2,
            loots = {
                ['*'] = {
                    count = 0,
                    money = 0,
                    items = {},
                    currencies = {},
                    sortedItems = {},
                    sortedCurrencies = {},
                    skinned = {},
                    sortedSkinned = {},
                    mined = {},
                    sortedMined = {},
                    herbed = {},
                    sortedHerbed = {},
                    engineered = {},
                    sortedEngineered = {}
                }
            },
            itemNames = {},
            itemLinks = {}
        }
    }
    self.db = LibStub("AceDB-3.0"):New("LootStatsDB", cleanDB)

    if self.db.global.version < 2 then
        self:UpgradeDBVersion()
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(self)
        LootStats:ShowTooltip(self)
    end)
end

function LootStats:OnEnable()
    self:RegisterEvent("LOOT_READY")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function LootStats:OnDisable()

end

function LootStats:LOOT_READY()
    local guid = UnitGUID("target")
    if not guid then
        return
    end

    -- Do not process twice
    if self.skinning or self.mining or self.herbing or self.engineering then
        if self.tsSeen[guid] then
            return
        end
        self.tsSeen[guid] = true
    else -- Not tradeskill, ie normal loot
        if self.seen[guid] then
            return
        end
        self.seen[guid] = true
    end

    local name = UnitName("target")
    if not name then
        return
    end

    if not UnitCanAttack("player", "target") then
        return
    end
    if UnitIsPlayer("target") then
        return
    end
    if not UnitIsDead("target") then
        return
    end

    local numItems = GetNumLootItems()
    local slot
    local lootList = {} -- to be indexed by guid

    for slot = 1, numItems do
        local lootIcon, lootName, lootQuantity, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(
            slot)
        local lsType = GetLootSlotType(slot)

        local id
        local link = GetLootSlotLink(slot)
        if link then
            _, _, id = string.find(link, "|cff%x+|H%a+:(%d+)")
            self.db.global.itemNames[id] = lootName
            self.db.global.itemLinks[id] = link
        end

        local sources = {GetLootSourceInfo(slot)}

        local guid
        for n, v in pairs(sources) do
            if (n % 2) == 1 then -- source guid
                guid = v
                if not lootList[guid] then
                    lootList[guid] = {
                        items = {},
                        currencies = {}
                    }
                end
            else -- count for source
                if lsType == Enum.LootSlotType.Money then
                    lootList[guid].money = v -- coppers
                elseif lsType == Enum.LootSlotType.Item then
                    lootList[guid].items[id] = v
                elseif lsType == Enum.LootSlotType.Currency then
                    lootList[guid].currencies[id] = v
                end
            end
        end -- loop for sources for loot slot
    end -- loop through loot slots

    -- Now we iterate through the GUIDs
    for guid, loot in pairs(lootList) do
        self:Push(guid, loot)
    end
end

function LootStats:Push(guid, loot)
    local id = self:GUIDtoID(guid)

    self.db.global.loots[id].count = self.db.global.loots[id].count + 1

    local loots = self.db.global.loots[id]
    if loot.money then
        loots.money = loots.money + loot.money
    end

    -- iterate through items
    for itemId, amount in pairs(loot.items) do
        if not loots.items[itemId] then
            loots.items[itemId] = amount
            table.insert(loots.sortedItems, {itemId, amount})
        else
            loots.items[itemId] = loots.items[itemId] + amount
            for i, item in pairs(loots.sortedItems) do
                if item[1] == itemId then
                    item[2] = loots.items[itemId]
                    break
                end
            end
        end -- loots.items[itemId]
    end

    -- iterate through currencies
    for currencyId, amount in pairs(loot.currencies) do
        if not loots.currencies[currencyId] then
            loots.currencies[currencyId] = amount
            table.insert(loots.sortedCurrencies, {currencyId, amount})
        else
            loots.currencies[currencyId] = loots.currencies[currencyId] + amount
            for i, curr in pairs(loots.sortedCurrencies) do
                if curr[1] == currencyId then
                    curr[2] = loots.currencies[currencyId]
                    break
                end
            end
        end -- loots.currencies[currencyId]
    end

    -- sort tables
    local function compareValue(a, b)
        return a[2] > b[2]
    end

    table.sort(loots.sortedItems, compareValue)
    table.sort(loots.sortedCurrencies, compareValue)
end

function LootStats:GUIDtoID(guid)
    -- '-' is a magic character, so this regex is ugly
    local _, _, id = guid:find('^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-')

    return tonumber(id)
end

function LootStats:ShowTooltip(tooltip)
    local name, unit = tooltip:GetUnit()

    if not unit then
        return
    end
    if not UnitCanAttack("player", unit) then
        return
    end
    if UnitIsPlayer(unit) then
        return
    end

    local id = self:GUIDtoID(UnitGUID(unit))

    local loots = self.db.global.loots[id]

    loots.name = GetUnitName(unit)

    tooltip:AddLine('Looted ' .. loots.count .. ' times')

    if loots.money > 0 then
        tooltip:AddDoubleLine('Money', GetCoinTextureString(loots.money))
    end

    local count = 0

    for _, item in pairs(loots.sortedItems) do
        if count >= LINELIMIT then
            break
        end
        tooltip:AddDoubleLine(self:ItemLink(item[1]), item[2])
        count = count + 1
    end
    tooltip:Show()
end

function LootStats:ItemName(guid)
    if self.db.global.itemNames[guid] then
        return self.db.global.itemNames[guid]
    else
        return guid
    end
end

function LootStats:ItemLink(guid)
    if self.db.global.itemLinks[guid] then
        return self.db.global.itemLinks[guid]
    else
        return self:ItemName(guid)
    end
end

function LootStats:UpgradeDBVersion()
    if self.db.global.version == 1 then
        self:Print("Upgrading DB to version 2")
        -- Compute sorted lists
        local function compareValue(a, b)
            return a[2] > b[2]
        end
        for guid, loot in pairs(self.db.global.loots) do
            loot.sortedItems = {}
            for guid, amount in pairs(loot.items) do
                table.insert(loot.sortedItems, {guid, amount})
            end
            table.sort(loot.sortedItems, compareValue)

            loot.sortedCurrencies = {}
            for guid, amount in pairs(loot.currencies) do
                table.insert(loot.sortedCurrencies, {guid, amount})
            end
            table.sort(loot.sortedCurrencies, compareValue)
        end
    end
    self.db.global.version = 2
end

function LootStats:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, rank, lineId, spellId)
    if not unit == player then
        return
    end
    --  self:Print(string.format("%s (%d/%d)", name, lineId, spellId))
    if spellId == 192125 then -- Skinning
        self.skinning = true
    end
end
