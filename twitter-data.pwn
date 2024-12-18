#include <YSI_Coding\y_hooks>

// data 
#define MAX_TWITTER				50 //jumlah maximal dari keseluruhan thread

enum E_TWITTER_DATA
{
	Author[20],
	Title[15],
	Info[30]
};
new g_TwitterData[E_TWITTER_DATA][MAX_TWITTER],
	Iterator:Iter_Twitter<MAX_TWITTER>;


enum E_TWITTER_PLAYER
{
	UserName[20],
	Description[32], 
	Follower,
	Following,
	TotalThread
};
new g_TwitterPlayer[MAX_PLAYERS][E_TWITTER_PLAYER];



// macro
#define Twitter_Player(%1,%2)			g_TwitterPlayer[%1][%2]
#define Twitter_Data(%1,%2)				g_TwitterData[%1][%2]



//include
#include "Module\twitter-function.pwn"
#include "Module\twitter-cmd.pwn"


// load thread
forward OnThreadLoaded();
public OnThreadLoaded()
{
	new 
		id,
		rows = cache_num_rows();

	if(rows)
	{
		for(new i; i < rows; i++) 
		{
			cache_get_value_int(i, "ID", id);
			cache_get_value(i, "Author", Twitter_Data(id, Author));
			cache_get_value(i, "Title", Twitter_Data(id, Title));
			cache_get_value(i, "Info", Twitter_Data(id, Info));

			Iter_Add(Iter_Twitter, id);
		}
		printf("Twitter Thread | %d Loaded", rows);
	}
	return 1;
}

// callbacks
hook OnGameModeInit()
{
	mysql_tquery(handle, "SELECT * FROM `twitter-thread`", "OnThreadLoaded");
	return 1;
}


hook OnGameModeExit()
{
	SaveTwitterThread();
	return 1;
}


hook OnPlayerConnect(playerid)
{
	new 
		query[120],
		rows;

	mysql_format(handle, query, sizeof query, "SELECT * FROM `twitter-account` WHERE `CharName`='%s'", GetName(playerid));
	mysql_query(handle, query);

	rows = cache_num_rows();
	if(rows)
		cache_get_value(0, "UserName", Twitter_Player(playerid, UserName));

	return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
	new
		query[250];

	mysql_format(handle, query, sizeof query, "UPDATE `twitter-account` SET `Follower`='%d', `Following`='%d', `TotalThread`='%d' WHERE `UserName`='%s'",
		Twitter_Player(playerid, Follower), Twitter_Player(playerid, Following), Twitter_Player(playerid, TotalThread), Twitter_Player(playerid, UserName));

	mysql_tquery(handle, query);
	return 1;
}