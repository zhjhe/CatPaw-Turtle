CatPaw = {}

function CatPaw_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("ADDON_LOADED")
	SLASH_CATPAW1 = '/catdps'
	SlashCmdList['CATPAW'] = function(msg)

		local _, _, arg1, arg2, arg3 = string.find(msg, "%s?(%w+)%s?(%w+)%s?(%w+)")
		local cmd = string.lower(msg)	
		if cmd == '' then
			cat_dps(false, false)
		end
		if cmd == 'rip' then
			cat_dps(true, false)
		end
	end
end


local function buffed(name, unit)
    unit = unit or 'player'

	local textures = {
		[Clear_Cast] = 'Interface\\Icons\\Spell_Shadow_ManaBurn',
		[Berserk] = 'Interface\\Icons\\Ability_Druid_Berserk',
		[Rip] = 'Interface\\Icons\\Ability_GhoulFrenzy'
	}

    for i = 1, 32 do
        if UnitBuff(unit, i) == textures[name] then 
			return true
		end
    end

	for i = 1, 32 do
        if UnitDebuff(unit, i) == textures[name] then 
			return true
		end
    end

    return false
end

local function cp_get_spell_id(name)
	local i = 0
	local spellName = nil
	while spellName ~= name do
		i = i + 1
		spellName = GetSpellName(i, "spell")
	end
	return i
end

local function cp_spell_ready(spell_name)
	local spell_id = cp_get_spell_id(spell_name)
	if GetSpellCooldown(spell_id, "spell") == 0 then
		return true
	end
	return false
end

local function cp_get_spell_cd(spell)
	local i = cp_get_spell_id(spell)
    local _, dur = GetSpellCooldown(i, "spell")
    return dur
end

local function cp_get_gcd()
	return cp_get_spell_cd(Shred)
end

local function ItemLinkToName(link)
	if link then
   	return string.gsub(link,"^.*%[(.*)%].*$","%1");
	end
end

-- 获取当前装备的神像名称
local function cp_get_idol()
	local idol_link = GetInventoryItemLink("player", 18)
	if idol_link then
		local name = string.lower(idol_link)
		return name
	end
end


local function cp_find_item(item)
	if not item then return end
	item = string.lower(ItemLinkToName(item))
	local link
	local count, bag
	local totalcount = 0;
	for i = 0, NUM_BAG_FRAMES do
		for j = 1, 36 do
			link = GetContainerItemLink(i, j)
			if link then
				if ( item == string.lower(ItemLinkToName(link))) then
					bag, slot = i, j
				end
			end
		end
	end
	return bag, slot
end

local function cp_use_item(item)
	local bag, slot = cp_find_item(item)
	if not bag then return end
	if slot then
		UseContainerItem(bag,slot) -- use, equip item in bag
	else
		UseInventoryItem(bag) -- unequip from body
	end
end

local function use_idol(idol)
	if cp_get_idol() ~= idol then cp_use_item(idol) end 
end

local function select_skill(use_rip, clear_cast, berserk, tiger_fury, cp, energy)
	if clear_cast then return Shred end
	-- if berserk and tiger_fury then return Shred end

	-- 根据连击点选择需要使用的技能
	if cp < 3 then
		--if 40 <= energy and energy < 48 then return Claw end
		if energy >= 48 then return Shred end
	elseif cp == 3 then
		--if 40 <= energy and energy < 48 then return Claw end
		if 35 <= energy and energy < 63 then return Ferocious_Bite end
		if energy >= 63 then return Shred end
	-- 4星时，如果能量大于63则撕碎(此时撕碎后会等2秒回能量打凶猛撕咬)，否则凶猛撕咬
	elseif cp == 4 then 
		if 35<= energy and energy < 63 then return Ferocious_Bite end
		if energy >= 63 then return Shred end
	-- 5星时,能量大于78,可上流血则撕扯，
	elseif cp == 5 then
		if use_rip and (not buffed(Rip, 'target')) and energy >= 78 then return Rip end
		if 35<= energy and energy < 63 then return Ferocious_Bite end
		if energy >= 63 then return Shred end
	end
	return Faerie_Fire_Feal
end


local function ready_to_shift(clear_cast, energy, cp, berserk)
	if clear_cast then return false end
	if cp_get_gcd() > 0.2 then return false end
	if energy >= 28 then return false end
	if cp >= 3 and energy >= 15 then return false end
	-- if berserk then return false end

	return true
end


function cat_dps(use_rip, use_mana_potion)
	local _, _, cat_form = GetShapeshiftFormInfo(3)
	-- 如果当前不是猫,则变猫
	if not cat_form then return CastShapeshiftForm(3) end

	local clear_cast = buffed(Clear_Cast)
	local berserk = buffed(Berserk)
	local cp = GetComboPoints()
	local energy = UnitMana('player')

	if ready_to_shift(clear_cast, energy, cp, berserk) then return CastSpellByName(Cat_Form) end

	use_idol(Idol_Moonfang) 

	local skill = select_skill(use_rip, clear_cast, berserk, tiger_fury, cp, energy)
	if cp_spell_ready(skill) then 
		if skill == Ferocious_Bite or skill == Rip then
			use_idol(Idol_Emerald_Rot)
		end
			return CastSpellByName(skill)
	end
end
