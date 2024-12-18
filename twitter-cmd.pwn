// semua cmd ini cuma demonstrasi aja, jadi bisa di ganti atau di sesuaikan.

CMD:twitter(playerid)
{
	if(IsPlayerHaveTwitterAccount(playerid))
		Dialog_Show(playerid,Twitter_Menu, DIALOG_STYLE_LIST, "Twitter Menu", "My Profile\nSearch user\nThread List\nCreate Thread\nFollow user", "Select", "Cancel");
	else SendClientMessage(playerid, -1, "Kamu harus memiliki akun twitter terlebih dahulu");

	return 1;
}
Dialog:Twitter_Menu(playerid, response, listitem, inputtext[])
{
	if(response) {
		ShowPlayerDialogTwitter(playerid, listitem + 1);
	}
	return 1;
}


CMD:twittername(playerid, params[])
{
	format(Twitter_Player(playerid, UserName), 14, params);
	new
		query[100];

	/*
		INFO:
				CharName itu buat nyimpan nama ic player kedalam database
				jadi nantinya ketika player login akan mengambil data akun twitter
				dari situ dengan cara mencarinya dengan nama ic yang udah terdaftar.

		function: GetName(playerid)    | Bisa kalian sesuaikan untuk mengambil nama karakter player.
		----------------------------------------------------------------------------------------------- */
	mysql_format(handle, query, sizeof(query), "INSERT INTO `twitter-account` (CharName, UserName) VALUES('%s','%s')", GetName(playerid), params); //function GetName itu sesuain aja buat ngambil nama player
	mysql_tquery(handle, query);

	SendClientMessage(playerid, -1, "Kamu sudah membuat akun twitter baru");
	return 1;
}