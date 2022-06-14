--[[
* Addons - Copyright (c) 2022 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.

* Based on Omen addon for Windower by Braden, Sechs.
--]]

addon.name    = 'Omen'
addon.author  = 'flanagak'
addon.version = '1.0'
addon.desc    = 'Omen is an addon that creates a window that tracks the current floor\'s Primary and Secondary objectives.';

require('common');
local fonts = require('fonts');
local settings = require('settings');

--[[
* Default font settings.
--]]
local fontSettings = T{
	visible = false,
	font_family = 'Arial',
	font_height = 12,
	color = 0xFFFFFFFF,
	position_x = 100,
	position_y = 100,
	background = T{
		visible = true,
		color = 0x80000000,
	}
};

--[[
* Omen local variables.
--]]
local omen = T{
    zoneId = 292,
	font = nil,
    settings = settings.load(fontSettings),
	omens = 0,
	obj_time = 0,
	floor_obj = 'Waiting for objectives...',
	floor_cleared = false,
	objectives = T{},
	success_color = 'FF00FF00',
	failed_color = 'FFFF0000',
	hide_timer = T{'Kin','Gin','Kei','Kyou','Fu','Ou','Craver','Gorger','Thinker','Treasure','Waiting'},
	messages = T{
	[1] = {id='1',long='Weapon Skill Damage',short='WS Damage',check='%d+%su',
	init='%d: Reduce your foe\'s HP by %a*%s*%a*%s*%d+ using a single weapon skill.',
	eval='%d: You have reduced your foe\'s HP by %a*%s*%a*%s*%d+ using a single weapon skill.',
	fail='%d: You have failed to reduce your foe\'s HP by %a*%s*%a*%s*%d+ using a single weapon skill.'},
	[2] = {id='2',long='Magic Burst Damage',short='MB Damage',check='%d+%su',
	init='%d: Reduce your foe\'s HP by %a*%s*%a*%s*%d+ using a single magic burst.',
	eval='%d: You have reduced your foe\'s HP by %a*%s*%a*%s*%d+ using a single magic burst.',
	fail='%d: You have failed to reduce your foe\'s HP by %a*%s*%a*%s*%d+ using a single magic burst.'},
	[3] = {id='3',long='Non-MB Nuke Damage',short='Non-MB Nuke',check='%d+%su',
	init='%d: Reduce your foe\'s HP by %a*%s*%a*%s*%d+ using a single magic attack without performing a magic burst.',
	eval='%d: You have reduced your foe\'s HP by %a*%s*%a*%s*%d+ using a single magic attack without performing a magic burst.',
	fail='%d: You have failed to reduce your foe\'s HP by %a*%s*%a*%s*%d+ using a single magic attack without performing a magic burst.'},
	[4] = {id='4',long='Auto-attack Damage',short='Melee Round',check='%d+%si',
	init='%d: Reduce your foe\'s HP by %a*%s*%a*%s*%d+ in a single auto%-attack.',
	eval='%d: You have reduced your foe\'s HP by %a*%s*%a*%s*%d+ in a single auto%-attack.',
	fail='%d: You have failed to reduce your foe\'s HP by %a*%s*%a*%s*%d+ in a single auto%-attack.'},
	[5] = {id='5',long='Kills',short='Kills',check='%d+%sf',
	init='%d: Vanquish %d+ %a+.',
	eval='%d: You have vanquished %d+ %a+.',
	fail='%d: You have failed to vanquish %d+ %a+.'},
	[6] = {id='6',long='Critical Hits',short='Critical Hits',check='%d+%sc',
	init='%d: Deal %d+ critical %a+ to your foes.',
	eval='%d: You have dealt %d+ critical %a+ to your foes.',
	fail='%d: You have failed to deal %d+ critical %a+ to your foes.'},
	[7] = {id='7',long='Abilities',short='Abilities',check='%d+%sa',
	init='%d: Use %d+ %a+ on your foes.',
	eval='%d: You have used %d+ %a+ on your foes.',
	fail='%d: You have failed to use %d+ %a+ on your foes.'},
	[8] = {id='8',long='Spells',short='Spells',check='%d+%ss',
	init='%d: Cast %d+ %a+ on your foes.',
	eval='%d: You have cast %d+ %a+ on your foes.',
	fail='%d: You have failed to cast %d+ %a+ on your foes.'},
	[9] = {id='9',long='Magic Bursts',short='Magic Bursts',check='%d+%sm',
	init='%d: Perform %d+ magic %a+ on your foes.',
	eval='%d: You have performed %d+ magic %a+ on your foes.',
	fail='%d: You have failed to perform %d+ magic %a+ on your foes.'},
	[10] = {id='10',long='Consecutive SCs',short='Skillchains',check='%d+%ss',
	init='%d: Execute %d+ %a+ using weapon %a+ on your foes!',
	eval='%d: You have executed %d+ %a+ using weapon %a+ on your foes!',
	fail='%d: You have failed to execute %d+ %a+ using weapon %a+ on your foes!'},
	[11] = {id='11',long='All Weapon Skills',short='All WS',check='%d+%sw',
	init='%d: Use %d+ weapon %a+ on your foes.',
	eval='%d: You have used %d+ weapon %a+ on your foes.',
	fail='%d: You have failed to use %d+ weapon %a+ on your foes.'},
	[12] = {id='12',long='Physical Weapon Skills',short='Physical WS',check='%d+%sp',
	init='%d: Use %d+ physical weapon %a+ on your foes.',
	eval='%d: You have used %d+ physical weapon %a+ on your foes.',
	fail='%d: You have failed to use %d+ physical weapon %a+ on your foes.'},
	[13] = {id='13',long='Magical Weapon Skills',short='Magic WS',check='%d+%se',
	init='%d: Use %d+ elemental weapon %a+ on your foes.',
	eval='%d: You have used %d+ elemental weapon %a+ on your foes.',
	fail='%d: You have failed to use %d+ elemental weapon %a+ on your foes.'},
	[14] = {id='14',long='Heals for 500 HP',short='500 HP Cures',check='%d+%st',
	init='%d: Restore at least 500 HP %d+ %a+.',
	eval='%d: You have restored at least 500 HP %d+ %a+.',
	fail='%d: You have failed to restore at least 500 HP %d+ %a+.'}
	}
};

--[[
* Registers a callback for the settings to monitor for character switches.
--]]
settings.register('settings', 'settings_update', function (s)
	-- Update the settings table..
    if (s ~= nil) then
        omen.settings = s;
    end

    -- Apply the font settings..
    if (omen.font ~= nil) then
        omen.font:apply(omen.settings);
    end

    -- Save the current settings..
    settings.save();
end);

--[[
* event: load
* desc : Event called when the addon is being loaded.
--]]
ashita.events.register('load', 'load_cb', function ()
    omen.FontObject = fonts.new(omen.settings);
	omen.FontObject.text = omen.floor_obj;
	omen.reset_objectives();
	
	local currentzone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
	if (currentzone == omen.zoneId) then 
		omen.FontObject.visible = true;
	else
		omen.FontObject.visible = false;
	end
end);

--[[
* event: unload
* desc : Event called when the addon is being unloaded.
--]]
ashita.events.register('unload', 'unload_cb', function ()
    if (omen.FontObject ~= nil) then
		omen.FontObject:destroy();
	end
	
	ashita.events.unregister('d3d_present', 'omen_present_cb');
	ashita.events.unregister('d3d_beginscene', 'beginscene_cb');
	ashita.events.unregister('text_in', 'text_in_cb');
	ashita.events.unregister('load', 'load_cb');
	
	settings.save();
end);

--[[
* event: text_in
* desc : Event called when the addon is processing incoming text.
--]]
ashita.events.register('text_in', 'text_in_cb', function (e)
	if (e.mode ~= nil) then
		local original = e.message;
		local mode = e.mode;
		local objective = nil;
		if (mode == 673) then -- Omen messages are 161 color, except total time extension messages which are 121 and irrelevant
			objective = omen.objectives[tonumber(original:match("^%d+"))];
			if (string.match(original,"^%d")) then
				for k,v in pairs (omen.messages) do
					if (string.find(original,v.init)) then
						if (objective.mes ~= tonumber(v.id)) then -- New Objective
							objective.amt = 0;
						end
						objective.mes = tonumber(v.id);
						objective.req = tonumber(string.sub(original:match(v.check),1,-2));
					elseif (string.find(original,v.eval)) then
						objective.amt = tonumber(string.sub(original:match(v.check),1,-2));
						if (objective.mes == 0) then -- if loading mid-floor
							objective.mes = tonumber(v.id);
							objective.req = -1;
						end
					end
					omen.refresh();
				end
			elseif (string.find(original,"%d+ omen")) then
				omen.omens = original:match("%d+");
				omen.refresh();
			elseif (string.find(original,"You have %d+ seconds remaining.")) then
				if omen.obj_time == 0 then
					omen.obj_time = tonumber(original:match("%d+"));
					omen.end_time = os.time() + omen.obj_time;
					omen.refresh();
				end
			elseif (string.find(original,"A spectral light flares up.")) then
				omen.floor_cleared = true;
				omen.refresh();
			elseif (string.find(original,"A faint light twinkles into existence.")) then
				--windower.play_sound(windower.addon_path..'small_clear.wav')
			elseif (string.find(original,"Vanquish") or string.find(original,"Open %d treasure portent")) then
				local str1 = string.gsub(original,string.char(0x7f).."1","");
				local str1 = string.gsub(str1,"%p","")	;		
				local str1 = string.gsub(str1,"(%s%a)",string.upper);
				omen.floor_obj = string.gsub(str1,"The","the");
				if (omen.floor_cleared) then
					omen.reset_objectives();
				end
				omen.refresh();
			elseif (string.find(original,"The light shall come even if you fail to obey.")) then
				omen.floor_obj = "Free Floor!";
				if (omen.floor_cleared) then
					omen.reset_objectives();
				end
				omen.refresh();
			end
		end
	end
end);

--[[
* event: packet_in
* desc : Event called when the addon is processing incoming packets.
--]]
ashita.events.register('packet_in', 'packet_in_cb', function (e)
	-- Packet: Zone Enter
    if (e.id == 0x000A) then
        local zid = struct.unpack('H', e.data_modified, 0x30 + 0x01);
		
		if (zid == omen.zoneId) then
			omen.FontObject.visible = true;
		else
			if (omen.FontObject ~= nil) then
				omen.FontObject.visible = false;
				omen.FontObject:destroy();
			end			
		end
        return;
    end
end);

--[[
* event: d3d_beginscene
* desc : Event called when the Direct3D device is beginning a scene.
--]]
ashita.events.register('d3d_beginscene', 'beginscene_cb', function (isRenderingBackBuffer)
    if (not isRenderingBackBuffer) then
        return;
    end
	
	if (omen.obj_time < 1) then return; end
    if (omen.obj_time ~= (omen.end_time - os.time())) then
        omen.obj_time = omen.end_time - os.time();
        omen.refresh();
    end
end);

--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'omen_present_cb', function ()
	-- Update the current settings font position..
    omen.settings.position_x = omen.FontObject.position_x;
    omen.settings.position_y = omen.FontObject.position_y;
end);

--[[
* Clear all bonus objectives and set floor objective to default.
--]]
function omen.reset_objectives()
	omen.objectives = {
    [1] = {id=1,mes=0,amt=0,req=0},
    [2] = {id=2,mes=0,amt=0,req=0},
    [3] = {id=3,mes=0,amt=0,req=0},
    [4] = {id=4,mes=0,amt=0,req=0},
    [5] = {id=5,mes=0,amt=0,req=0},
    [6] = {id=6,mes=0,amt=0,req=0},
    [7] = {id=7,mes=0,amt=0,req=0},
    [8] = {id=8,mes=0,amt=0,req=0},
    [9] = {id=9,mes=0,amt=0,req=0},
    [10] = {id=10,mes=0,amt=0,req=0}
    };
    omen.obj_time = 0;
    omen.floor_cleared = false;
	omen.refresh();
end

--[[
* Refresh the objective display.
--]]
function omen.refresh()
    local header = omen.floor_obj .. '     |     Omens: ' .. omen.omens;
    local body = '\n Bonus Objectives    ' .. os.date('%M:%S', omen.obj_time);
    for k,v in pairs (omen.hide_timer) do
        if (string.find(header,v)) then
            body = '';
			if (omen.floor_cleared) then
				header = omen.colorize('success', header);
			end
			omen.FontObject.text = header;
            return;
        end
    end
	
	if (omen.floor_cleared) then
		header = omen.colorize('success', header);
	end
	
    for v, objective in ipairs(omen.objectives) do
        if (objective.mes ~= 0) then
            local msg = objective.mes;
            local cur = objective.amt;
            local fin = objective.req;
            if (cur == fin) then
                body = body..omen.colorize('success','\n'..omen.messages[msg].short..' ['..cur..'/'..fin..']');
            elseif (omen.obj_time < 1 and cur < fin) then
                body = body..omen.colorize('failed','\n'..omen.messages[msg].short..' ['..cur..'/'..fin..']');
            else
                body = body..'\n '..omen.messages[msg].short..' ['..cur..'/'..fin..']';
            end
        end
    end
    body = string.gsub(body,'%-1','%?%?%?');
    omen.FontObject.text = header..body;
end

--[[
* Colorizes an objective string.
*
* @param {string} state - Success or Failed state of the string to be colorized.
* @param {string} str - The string to be colorized.
* @return {string} The colorized string.
* -- Color Codes: FFFFFF00 = Yellow | FF00FF00 = Green | FFFF0000 = Red
--]]
function omen.colorize(state, str)
    if (state == 'success') then
        return ('|c'..omen.success_color..'|%s|r'):fmt(str);
    elseif (state == 'failed') then
        return ('|c'..omen.failed_color..'|%s|r'):fmt(str);
	else
		return ('|cFFFFFFFF|%s|r'):fmt(str);
    end
end