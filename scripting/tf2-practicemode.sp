#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf_econ_data>

#define PLUGIN_TAG "[PM]"

enum TF2Quality {
	TF2Quality_Normal = 0, // 0
	TF2Quality_Rarity1,
	TF2Quality_Genuine = 1,
	TF2Quality_Rarity2,
	TF2Quality_Vintage,
	TF2Quality_Rarity3,
	TF2Quality_Rarity4,
	TF2Quality_Unusual = 5,
	TF2Quality_Unique,
	TF2Quality_Community,
	TF2Quality_Developer,
	TF2Quality_Selfmade,
	TF2Quality_Customized, // 10
	TF2Quality_Strange,
	TF2Quality_Completed,
	TF2Quality_Haunted,
	TF2Quality_ToborA
};

enum struct Player {
	bool changeclass;
	bool regen;
	bool stun;
	bool respawn;
	bool give;

	void Init() {
		this.changeclass = true;
		this.regen = true;
		this.stun = true;
		this.respawn = true;
		this.give = true;
	}

	void Clear() {
		this.changeclass = true;
		this.regen = true;
		this.stun = true;
		this.respawn = true;
		this.give = true;
	}

	void Toggle() {
		this.changeclass = !this.changeclass;
		this.regen = !this.regen;
		this.stun = !this.stun;
		this.respawn = !this.respawn;
		this.give = !this.give;
	}

	void Lock() {
		this.changeclass = false;
		this.regen = false;
		this.stun = false;
		this.respawn = false;
		this.give = false;
	}

	void Unlock() {
		this.changeclass = true;
		this.regen = true;
		this.stun = true;
		this.respawn = true;
		this.give = true;
	}
}

Player g_Player[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "[TF2] Practice Mode", 
	author = "Drixevel", 
	description = "A practice mode for Team Fortress 2.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart() {
	RegConsoleCmd("sm_pm", Command_PracticeMode, "Opens up the practice mode main menu.");
	RegConsoleCmd("sm_practicemode", Command_PracticeMode, "Opens up the practice mode main menu.");
	RegConsoleCmd("sm_class", Command_Class, "Allows you to set your own class manually.");
	RegConsoleCmd("sm_regen", Command_Regen, "Regenerate your health and weapons.");
	RegConsoleCmd("sm_stun", Command_Stun, "Automatically stuns yourself on use.");
	RegConsoleCmd("sm_respawn", Command_Respawn, "Respawn yourself.");
	RegConsoleCmd("sm_give", Command_Give, "Give yourself a wearable or weapon.");

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i)) {
			OnClientConnected(i);
		}
	}
}

public Action Command_PracticeMode(int client, int args) {
	if (client < 1) {
		ReplyToCommand(client, "%s You must be in-game to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	OpenMainMenu(client);
	return Plugin_Handled;
}

void OpenMainMenu(int client) {
	Menu menu = new Menu(MenuHandler_Main);
	menu.SetTitle("Practice Mode Menu");

	menu.AddItem("sm_class", "Change your Class");
	menu.AddItem("sm_regen", "Regenerate Yourself");
	menu.AddItem("sm_stun", "Stun Yourself");
	menu.AddItem("sm_respawn", "Respawn Yourself");
	menu.AddItem("sm_give", "Give Yourself an Item");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Main(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sCommand[64];
			menu.GetItem(param2, sCommand, sizeof(sCommand));

			FakeClientCommand(param1, sCommand);
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

public Action Command_Class(int client, int args) {
	if (client < 1) {
		ReplyToCommand(client, "%s You must be in-game to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client)) {
		PrintToChat(client, "%s You must be alive to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!g_Player[client].changeclass) {
		PrintToChat(client, "%s You are not allowed to change your class at this time.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (args > 0) {
		char sClass[16];
		GetCmdArgString(sClass, sizeof(sClass));

		TFClassType class = TF2_GetClass(sClass);

		if (class < TFClass_Scout || class > TFClass_Engineer) {
			PrintToChat(client, "%s You must specify a valid class to switch to.", PLUGIN_TAG);
			return Plugin_Handled;
		}

		TF2_SetPlayerClass(client, class, true, true);
		TF2_RegeneratePlayer(client);
		PrintToChat(client, "%s You have switched your class to '%s'.", PLUGIN_TAG, sClass);

		return Plugin_Handled;
	}

	OpenClassesMenu(client);

	return Plugin_Handled;
}

void OpenClassesMenu(int client) {
	Menu menu = new Menu(MenuHandler_Class);
	menu.SetTitle("Choose a class:");

	menu.AddItem("1", "Scout");
	menu.AddItem("3", "Soldier");
	menu.AddItem("7", "Pyro");
	menu.AddItem("4", "DemoMan");
	menu.AddItem("6", "Heavy");
	menu.AddItem("9", "Engineer");
	menu.AddItem("5", "Medic");
	menu.AddItem("2", "Sniper");
	menu.AddItem("8", "Spy");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Class(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			if (!IsPlayerAlive(param1)) {
				PrintToChat(param1, "%s You must be alive to use this menu.", PLUGIN_TAG);
				OpenClassesMenu(param1);
				return 0;
			}

			if (!g_Player[param1].changeclass) {
				PrintToChat(param1, "%s You are not allowed to change your class at this time.", PLUGIN_TAG);
				return 0;
			}

			char sInfo[16]; char sDisplay[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));

			TFClassType class = view_as<TFClassType>(StringToInt(sInfo));

			TF2_SetPlayerClass(param1, class, true, true);
			TF2_RegeneratePlayer(param1);
			PrintToChat(param1, "%s You have switched your class to '%s'.", PLUGIN_TAG, sDisplay);

			OpenClassesMenu(param1);
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}

	return 0;
}

public void OnClientConnected(int client) {
	g_Player[client].Init();
}

public void OnClientDisconnect_Post(int client) {
	g_Player[client].Clear();
}

public Action Command_Regen(int client, int args) {
	if (client < 1) {
		ReplyToCommand(client, "%s You must be in-game to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client)) {
		PrintToChat(client, "%s You must be alive to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!g_Player[client].changeclass) {
		PrintToChat(client, "%s You are not allowed to regen at this time.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	TF2_RegeneratePlayer(client);
	PrintToChat(client, "%s You have regenerated yourself to full.", PLUGIN_TAG);

	return Plugin_Handled;
}

public Action Command_Stun(int client, int args) {
	if (client < 1) {
		ReplyToCommand(client, "%s You must be in-game to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client)) {
		PrintToChat(client, "%s You must be alive to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!g_Player[client].stun) {
		PrintToChat(client, "%s You are not allowed to stun yourself at this time.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	TF2_StunPlayer(client, 5.0, 1.0, TF_STUNFLAGS_BIGBONK, client);
	PrintToChat(client, "%s You have stunned yourself.", PLUGIN_TAG);

	return Plugin_Handled;
}

public Action Command_Respawn(int client, int args) {
	if (client < 1) {
		ReplyToCommand(client, "%s You must be in-game to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (TF2_GetClientTeam(client) < TFTeam_Red) {
		PrintToChat(client, "%s You must be on a valid team to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!g_Player[client].respawn) {
		PrintToChat(client, "%s You are not allowed to respawn yourself at this time.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	TF2_RespawnPlayer(client);
	PrintToChat(client, "%s You have respawned yourself.", PLUGIN_TAG);

	return Plugin_Handled;
}

public Action Command_Give(int client, int args) {
	if (client < 1) {
		ReplyToCommand(client, "%s You must be in-game to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client)) {
		PrintToChat(client, "%s You must be alive to use this command.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!g_Player[client].give) {
		PrintToChat(client, "%s You are not allowed to give yourself items at this time.", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (args > 0) {
		char classname[64];
		GetCmdArg(1, classname, sizeof(classname));

		char index[64];
		GetCmdArg(2, index, sizeof(index));

		TF2_GiveItem(client, classname, StringToInt(index));

		return Plugin_Handled;
	}

	OpenSlotsMenu(client);

	return Plugin_Handled;
}

void OpenSlotsMenu(int client) {
	Menu menu = new Menu(MenuHandler_Slots);
	menu.SetTitle("Choose a slot:");

	menu.AddItem("-1", "Wearables");
	menu.AddItem("0", "Primary");
	menu.AddItem("1", "Secondary");
	menu.AddItem("2", "Melee");
	menu.AddItem("3", "Grenade");
	menu.AddItem("4", "Building");
	menu.AddItem("5", "PDA");
	menu.AddItem("6", "Item 1");
	menu.AddItem("7", "Item 2");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Slots(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sInfo[16];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			OpenItemsMenu(param1, StringToInt(sInfo));
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

void OpenItemsMenu(int client, int slot) {
	Menu menu = new Menu(MenuHandler_Items);
	menu.SetTitle("Choose %s:", (slot == -1) ? "a Wearable" : "an Item");

	ArrayList items = TF2Econ_GetItemList(OnFilterItems, slot);

	int itemdef; char sItemDef[16]; char name[64];
	for (int i = 0; i < items.Length; i++) {
		itemdef = items.Get(i);
		IntToString(itemdef, sItemDef, sizeof(sItemDef));
		TF2Econ_GetItemName(itemdef, name, sizeof(name));
		menu.AddItem(sItemDef, name);
	}

	if (menu.ItemCount == 0) {
		menu.AddItem("", " :: Empty", ITEMDRAW_DISABLED);
	}

	delete items;

	PushMenuInt(menu, "slot", slot);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public bool OnFilterItems(int itemdef, any data) {
	char name[64];
	TF2Econ_GetItemName(itemdef, name, sizeof(name));

	TFClassType class = TFClass_Scout;

	//-1 = wearables, 0+ = weapons
	// if (data == -1 && StrContains(name, "tf_wearable", false) != 0) {
	// 	return false;
	// } else if (data > -1 && StrContains(name, "tf_weapon", false) != 0) {
	// 	return false;
	// }

	if (TF2Econ_GetItemLoadoutSlot(itemdef, class) != data) {
		return false;
	}

	return true;
}

public int MenuHandler_Items(Menu menu, MenuAction action, int param1, int param2) {
	int slot = GetMenuInt(menu, "slot");

	switch (action) {
		case MenuAction_Select: {
			char sItemDef[16];
			menu.GetItem(param2, sItemDef, sizeof(sItemDef));

			int itemdef = StringToInt(sItemDef);

			char classname[64];
			TF2Econ_GetItemClassName(itemdef, classname, sizeof(classname));

			TF2_GiveItem(param1, classname, itemdef);

			OpenItemsMenu(param1, slot);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack) {
				OpenSlotsMenu(param1);
			}
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

int TF2_GiveItem(int client, char[] classname, int index, TF2Quality quality = TF2Quality_Normal, int level = 0, const char[] attributes = "") {
	char sClass[64];
	strcopy(sClass, sizeof(sClass), classname);
	
	if (StrContains(sClass, "saxxy", false) != -1) {
		switch (TF2_GetPlayerClass(client)) {
			case TFClass_Scout: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_bat");
			}
			case TFClass_Sniper: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_club");
			}
			case TFClass_Soldier: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_shovel");
			}
			case TFClass_DemoMan: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_bottle");
			}
			case TFClass_Engineer: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_wrench");
			}
			case TFClass_Pyro: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_fireaxe");
			}
			case TFClass_Heavy: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_fists");
			}
			case TFClass_Spy: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_knife");
			}
			case TFClass_Medic: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_bonesaw");
			}
		}
	} else if (StrContains(sClass, "shotgun", false) != -1) {
		switch (TF2_GetPlayerClass(client)) {
			case TFClass_Soldier: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_shotgun_soldier");
			}
			case TFClass_Pyro: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_shotgun_pyro");
			}
			case TFClass_Heavy: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_shotgun_hwg");
			}
			case TFClass_Engineer: {
				strcopy(sClass, sizeof(sClass), "tf_weapon_shotgun_primary");
			}
		}
	}
	
	Handle item = TF2Items_CreateItem(PRESERVE_ATTRIBUTES | FORCE_GENERATION);	//Keep reserve attributes otherwise random issues will occur... including crashes.
	TF2Items_SetClassname(item, sClass);
	TF2Items_SetItemIndex(item, index);
	TF2Items_SetQuality(item, view_as<int>(quality));
	TF2Items_SetLevel(item, level);
	
	char sAttrs[32][32];
	int count = ExplodeString(attributes, " ; ", sAttrs, 32, 32);
	
	if (count > 1) {
		TF2Items_SetNumAttributes(item, count / 2);
		
		int i2;
		for (int i = 0; i < count; i += 2) {
			TF2Items_SetAttribute(item, i2, StringToInt(sAttrs[i]), StringToFloat(sAttrs[i + 1]));
			i2++;
		}
	} else {
		TF2Items_SetNumAttributes(item, 0);
	}

	int weapon = TF2Items_GiveNamedItem(client, item);
	delete item;
	
	if (StrEqual(sClass, "tf_weapon_builder", false) || StrEqual(sClass, "tf_weapon_sapper", false)) {
		SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
		SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
	}
	
	if (StrContains(sClass, "tf_weapon_", false) == 0) {
		EquipPlayerWeapon(client, weapon);
	}
	
	return weapon;
}

bool PushMenuInt(Menu menu, const char[] id, int value) {
	if (menu == null || strlen(id) == 0) {
		return false;
	}
	
	char sBuffer[128];
	IntToString(value, sBuffer, sizeof(sBuffer));
	return menu.AddItem(id, sBuffer, ITEMDRAW_IGNORE);
}

int GetMenuInt(Menu menu, const char[] id, int defaultvalue = 0) {
	if (menu == null || strlen(id) == 0) {
		return defaultvalue;
	}
	
	char info[128]; char data[128];
	for (int i = 0; i < menu.ItemCount; i++) {
		if (menu.GetItem(i, info, sizeof(info), _, data, sizeof(data)) && StrEqual(info, id)) {
			return StringToInt(data);
		}
	}
	
	return defaultvalue;
}