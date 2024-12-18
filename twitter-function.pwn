// save twitter thread
SaveTwitterThread()
{
	foreach(new id : Iter_Twitter)
	{
		new
			query[2500]; // ukuran nya bisa di perbesar lagi

		mysql_format(handle, query, sizeof query, "INSERT INTO `twitter-thread` (ID, Author, Title, Info) VALUES ('%d', '%s', '%s', '%s')", 
			id, Twitter_Data(id, Author), Twitter_Data(id, Title), Twitter_Data(id, Info));

		mysql_tquery(handle, query, "OnTwitterThreadSaved");
	}
	return 1;
}

ResetTwitterThread(id) 
{
	Twitter_Data(id, Title) = Twitter_Data(id, Info) = EOS;
	return 1;
}

IsPlayerHaveTwitterAccount(playerid)
{
	return (strlen(Twitter_Player(playerid, UserName)) != 0) ? 1 : 0;
}

ShowTwitterThreads(playerid)
{
	new 
		fmt[1024];

	strcat(fmt, "#\tAuthor\tTitle\tInfo\n");
	foreach(new i : Iter_Twitter)
	{
		format(fmt, sizeof(fmt), "%s%d\t%s\t%s\t%s\n", fmt, i, Twitter_Data(i, Author), Twitter_Data(i, Title), Twitter_Data(i, Info));
		Dialog_Show(playerid, DialogTMP, DIALOG_STYLE_TABLIST_HEADERS, "Twitter - Thread list", fmt, "Ok", "");
	}
	return 1;
}

ShowDialogCreateThreads(playerid)
{
	new
		fmt[250],
		id = Iter_Free(Iter_Twitter);

	strcat(fmt, "Type\tInformation\n");

	format(fmt, sizeof(fmt), "%sTitle\t%s\n", fmt, Twitter_Data(id, Title));
	format(fmt, sizeof(fmt), "%sInfo\t%s\n", fmt, Twitter_Data(id, Info));
	format(fmt, sizeof(fmt), "%s>> Posting", fmt);

	Dialog_Show(playerid, Twitter_CreateThread, DIALOG_STYLE_TABLIST_HEADERS, "Twitter - Create Thread", fmt, "Select", "Close");
	return 1;
}

ShowPlayerDialogTwitter(playerid, type)
{
	new 
		fmt[400];
	switch(type)
	{
		case 1: 
		{
			strcat(fmt, "Data\tInformaton\n");

			format(fmt, sizeof(fmt), "%sUsername\t%s\nFollower\t%d Followers\n", fmt, Twitter_Player(playerid, UserName), Twitter_Player(playerid, Follower));
			format(fmt, sizeof(fmt), "%sFollowing\t%d Followings\nCreated Thread\t%d Threads\n", fmt, Twitter_Player(playerid, Following), Twitter_Player(playerid, TotalThread));
			format(fmt, sizeof(fmt), "%sDescription\t%s", fmt, Twitter_Player(playerid, Description));

			Dialog_Show(playerid, DialogTMP, DIALOG_STYLE_TABLIST_HEADERS, "Twitter - My Profile", fmt, "Close", "");
		}
		case 2: Dialog_Show(playerid, Twitter_SearchUser, DIALOG_STYLE_INPUT, "Twitter - Serach user", "Masukan username dari account twitter yang ingin di cari (min: 3 karakter)", "Find", "Cancel");
		case 3: ShowTwitterThreads(playerid);
		case 4: ShowDialogCreateThreads(playerid);
		case 5: Dialog_Show(playerid, Twitter_FollowUser, DIALOG_STYLE_INPUT, "Twitter - Follow user", "Masukan username twitter yang ingin kamu follow", "Follow", "Cancel");
	}
	return 1;
}


Add_TwitterFollower(playerid, username[])
{
	foreach(new i : Player)
	{
		if(!strcmp(username, Twitter_Player(i, UserName))) 
		{
			Twitter_Player(playerid, Following)++;
			Twitter_Player(i, Follower)++;
		}
		else return  Dialog_Show(playerid, Twitter_FollowUser, DIALOG_STYLE_INPUT, "Twitter - Follow user", "Masukan username twitter yang ingin kamu follow", "Follow", "Cancel");
	}
	return 1;
}



// dialogs
Dialog:Twitter_FollowUser(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(!strlen(inputtext) || strlen(inputtext) < 3)
			return Dialog_Show(playerid, Twitter_FollowUser, DIALOG_STYLE_INPUT, "Twitter - Follow user", "Masukan username twitter yang ingin kamu follow", "Follow", "Cancel");


		Add_TwitterFollower(playerid, inputtext);		
	}
	return 1;
}

Dialog:Twitter_SearchUser(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(!strlen(inputtext) || strlen(inputtext) < 3)
			return Dialog_Show(playerid, Twitter_SearchUser , DIALOG_STYLE_INPUT, "Twitter - Search User", "Masukkan username dari akun Twitter yang ingin dicari (min: 3 karakter)", "Find", "Cancel");

		new
			query[100],
			fmt[300],
			result[300],
			followers;

		mysql_format(handle, query, sizeof(query), "SELECT * FROM `twitter-account` WHERE UserName LIKE '%%%s%%'", inputtext);
		mysql_query(handle, query);

		strcat(result, "Username\tFollowers\n");
		if(!cache_num_rows())
			return Dialog_Show(playerid, DialogTMP, DIALOG_STYLE_MSGBOX, "Twitter - Search User", "Tidak ada username ditemukan dalam database dengan nama tersebut", "Ok", "");

		for(new i; i < cache_num_rows(); i++) 
		{
			cache_get_value(i, "UserName", fmt);
			cache_get_value_int(i, "Follower", followers);

			format(result, sizeof(result), "%s%s\t%d Follower\n", result, fmt, followers);
		}			
		Dialog_Show(playerid, DialogTMP, DIALOG_STYLE_TABLIST_HEADERS, "Twitter - Search List", result, "Close", "");
	}
	return 1;
}

Dialog:Twitter_CreateThread(playerid, response, listitem, inputtext[])
{
	new id = Iter_Free(Iter_Twitter);
	if(response)
	{
		switch(listitem)
		{
			case 0: Dialog_Show(playerid, Twitter_ThreadTitle, DIALOG_STYLE_INPUT, "Thread - Title", "Buatlah title untuk thread yang ingin kamu post (max: 12 char)", "Done", "Cancel");
			case 1: Dialog_Show(playerid, Twitter_ThreadInfo, DIALOG_STYLE_INPUT, "Thread - Info", "Buatlah info untuk thread yang ingin kamu post (max: 24 char)", "Done", "Cancel");
			case 2: 
			{
				if(id == -1)
					return SendClientMessage(playerid, -1, "Twitter Thread telah mencapai limit");

				if(!strlen(Twitter_Data(id, Info)) || !strlen(Twitter_Data(id, Title)))
					return ShowDialogCreateThreads(playerid);

				format(Twitter_Data(id, Author), 20, "%s", Twitter_Player(playerid, UserName));
				Iter_Add(Iter_Twitter, id);
			}
		}
	}
	else ResetTwitterThread(id);
	return 1;
}

Dialog:Twitter_ThreadTitle(playerid, response, listitem, inputtext[])
{
	new id = Iter_Free(Iter_Twitter);
	if(response)
	{
		if(!strlen(inputtext) || strlen(inputtext) > 15)
			return Dialog_Show(playerid, Twitter_ThreadTitle, DIALOG_STYLE_INPUT, "Thread - Title", "Buatlah title untuk thread yang ingin kamu post (max: 12 char)", "Done", "Cancel");

		format(Twitter_Data(id, Title), 15, inputtext);
		ShowDialogCreateThreads(playerid);
	}
	else ResetTwitterThread(id);
	return 1;
}
Dialog:Twitter_ThreadInfo(playerid, response, listitem, inputtext[])
{
	new id = Iter_Free(Iter_Twitter);
	if(response)
	{
		if(!strlen(inputtext) || strlen(inputtext) > 30)
			return Dialog_Show(playerid, Twitter_ThreadInfo, DIALOG_STYLE_INPUT, "Thread - Info", "Buatlah info untuk thread yang ingin kamu post (max: 24 char)", "Done", "Cancel");

		format(Twitter_Data(id, Info), 30, inputtext);
		ShowDialogCreateThreads(playerid);
	}
	else ResetTwitterThread(id);
	return 1;
}


forward OnTwitterCreated(playerid);
public OnTwitterCreated(playerid)
{
	Twitter_Player(playerid, TotalThread)++;
	SendClientMessage(playerid, -1, "Thread Twitter has been successfully created");
	return 1;
}

forward OnTwitterFollowing(playerid);
public OnTwitterFollowing(playerid)
{
	Twitter_Player(playerid, Following)++;
	SendClientMessage(playerid, -1, "Kamu berhasil mengikuti player ini");
	return 1;
}

forward OnTwitterThreadSaved();
public OnTwitterThreadSaved()
{
	print("Twitter Thread | All thread has been saved");
	return 1;
}