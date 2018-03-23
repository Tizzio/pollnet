var aid = ds_map_find_value(async_load, "id");
var status = ds_map_find_value(async_load, "status");
if (status == 1) 
{ 
	show_debug_message("WAITING: Status Receiving packets!");
	exit; 
} 
	
var r_str = ds_map_find_value(async_load, "result");
 

#region process messages
if (aid == global.pn_request_message)
{
	if(status < 0)
	{
		pn_on_error(1, "empty result from message request"); 
		exit;
	}
	
	var line, wd, ld; 
	
	var split = string_pos(sep_mess, r_str);
	var r_players = string_copy(r_str, 1, split - 1);
	var r_message = string_delete(r_str, 1, split);
	
	#region split players 
	
	var player_id, player_name;
	
	ld = string_pos(sep_line, r_players);
	while(ld)
	{
		line = string_copy(r_players, 1, ld - 1);
		r_players = string_delete(r_players, 1, ld);
		ld = string_pos(sep_line, r_players);
		
		// id
		wd = string_pos(sep_word, line);
		player_id = real(string_copy(line, 1, wd - 1));
		line = string_delete(line, 1, wd);
	  
		// name
		wd = string_pos(sep_word, line);
		player_name = string_copy(line, 1, wd - 1); 
		line = string_delete(line, 1, wd);
		
		ds_map_add(global.pn_players_checkmap, player_id, player_name); 
		//new player joined
		if(!ds_map_exists(global.pn_players_map, player_id))
		{
			ds_map_add(global.pn_players_map, player_id, player_name);
			ds_list_add(global.pn_players_list, player_id);
			pn_on_player_join(player_id, player_name);
		}
	}
	
	//players who quit
	for(var i = 0; i < ds_list_size(global.pn_players_list); i++)
	{
		var p = global.pn_players_list[| i];
		if(!ds_map_exists(global.pn_players_checkmap, p))
		{
			pn_on_player_quit(p, global.pn_players_map[? p]);
			ds_list_delete(global.pn_players_list, i--);
			ds_map_delete(global.pn_players_map, p);
		}
	}
	ds_map_clear(global.pn_players_checkmap);
	
	#endregion
	
	#region split messages 
	
	var from, to, message, packet, type, msg_id, pos, len, val;
	
	ld = string_pos(sep_line, r_message); 
	while(ld)
	{
		line = string_copy(r_message, 1, ld - 1);
		r_message = string_delete(r_message, 1, ld);
		ld = string_pos(sep_line, r_message); 
	
		// date
		wd = string_pos(sep_word, line);
		global.pn_last_date = string_copy(line, 1, wd - 1);
		line = string_delete(line, 1, wd);
	  
		// from
		wd = string_pos(sep_word, line);
		from = real(string_copy(line, 1, wd - 1)); 
		line = string_delete(line, 1, wd);
	 
		// to
		wd = string_pos(sep_word, line);
		to = string_length(string_copy(line, 1, wd - 1)) > 0; 
		line = string_delete(line, 1, wd);
	 
		// message
		wd = string_pos(sep_word, line);
		packet = string_copy(line, 1, wd - 1); 
		line = string_delete(line, 1, wd);
		
		//server message
		if(packet == "pollnet_game_started")
		{
			pn_on_game_start();	
		}
		//game message, decode it
		else
		{
			//id
			pos = string_pos(chr(10), packet);
			msg_id = string_copy(packet, 1, pos - 1);
			packet = string_delete(packet, 1, pos);   
		
			//type
			type = real(string_char_at(packet, 1));
			packet = string_delete(packet, 1, 1);
		
			switch(type)
			{
				case 0: 
					show_debug_message("TYPE ARRAY");
					//get array length
					pos = string_pos(chr(10), packet);
					len = real(string_copy(packet, 1, pos - 1));
					packet = string_delete(packet, 1, pos);
			
					// fill array
					message = array_create(len);
					for(var i = 0; i < len; i++)
					{
						type = string_char_at(packet, 1);
						packet = string_delete(packet, 1, 1);
					 
						pos = string_pos(chr(10), packet);
						val = string_copy(packet, 1, pos - 1);
						packet = string_delete(packet, 1, pos);
					
						if(type == "0") 
							val = string(val); 
						
						else if(type == "1") 
							val = real(val); 
						
						else
						{ 
							pn_on_error(2, "decode: unknown packet type");
							exit;
						}
					
						message[i] = val;
					}
				 
					break;
			
				case 1:
					show_debug_message("TYPE STRING");
					message = packet;
					break;
			
				case 2:
					show_debug_message("TYPE REAL");
					message = real(packet);
					break;
			
				default:
					pn_on_error(3, "decode: unknown packet type (2)"); 
					exit;
					break;
			}
			
			pn_on_receive(global.pn_last_date, from, to, msg_id, message);
		}
	}
	#endregion
	
    alarm[0] = receive_interval * room_speed;
} 
#endregion
  
#region join
if (aid == global.pn_request_join)
{
	
	if(status < 0)
	{
		pn_on_error(4, "empty join result, check php installation");  
		exit;
	}
	
	var token;
	var p = string_pos(sep_word, r_str);
	var token = string_copy(r_str, 1, p - 1);
	var player_id = string_delete(r_str, 1, p);
	
	if(string_length(token) == token_size)
	{
		global.pn_token = token;
		show_debug_message("join token: " + token);
		global.pn_last_date = string(current_year) + "-" + string(current_month) + "-" + string(current_day) + " " +
		string(current_hour) + "-" + string(current_minute) + "-" + string(current_second);
		pn_on_join();
		alarm[0] = 1;
	}
	
	global.pn_player_id = real(player_id);
} 
#endregion
 
 

#region host
if (aid == global.pn_request_host)
{
	if(status < 0)
	{ 
		pn_on_error(5, "empty host result, check php installation"); 
		exit;
	}
	
	var token;
	var p = string_pos(sep_word, r_str);
	var token = string_copy(r_str, 1, p - 1);
	var player_id = string_delete(r_str, 1, p);
	
	if(string_length(token) == token_size)
	{
		global.pn_token = token;
		show_debug_message("host token: " + token);
		
		global.pn_last_date = string(current_year) + "-" + string(current_month) + "-" + string(current_day) + " " +
		string(current_hour) + "-" + string(current_minute) + "-" + string(current_second);
		pn_on_host();
		alarm[0] = 1;
	}
	
	global.pn_player_id = real(player_id);
	global.pn_admin_id = global.pn_player_id;
}
#endregion

#region game start

if (aid == global.pn_request_game_start)
{
	if(status < 0)
	{
		pn_on_error(6, "empty start request result, check php installation"); 
		exit;
	}
	
	pn_on_game_start();
}

#endregion

#region quit
if (aid == global.pn_request_quit)
{
	if(status < 0)
	{ 
		pn_on_error(7, "empty quit request result, check php installation"); 
		exit;
	}
	pn_on_quit();
	 
	for(var i = 0; i < ds_list_size(global.pn_request_send_list); i++)
		ds_list_destroy(global.pn_request_send_list[| i]);
	ds_list_clear(global.pn_request_send_list);
	ds_map_clear(global.pn_players_checkmap);
	ds_map_clear(global.pn_players_map);
	ds_list_clear(global.pn_players_list);
	global.pn_request_create = -1;
	global.pn_request_host = -1;
	global.pn_request_join = -1;
	global.pn_request_game_start = -1;
	global.pn_request_quit = -1;
	global.pn_request_games = -1; 
	global.pn_request_message = -1;
}
#endregion

#region send
for(var i = 0; i < ds_list_size(global.pn_request_send_list); i++)
{
	var msg = global.pn_request_send_list[| i]
	if (aid == msg[| 0])
	{ 
		if(status < 0)
		{ 
			pn_on_error(8, "empty send request result, check php installation");
			exit;
		}
	
		if(string_length(r_str) > 0) 
			pn_on_send(msg[| 1], msg[| 2], msg[| 3]); 
		else
			show_debug_message("error, can't send message: " + string(aid));
		ds_list_destroy(msg);
		ds_list_delete(global.pn_request_send_list, i--);
	}
}
#endregion

#region games
if (aid == global.pn_request_games)
{
	//free games list
	for(var i = 0; i < ds_list_size(global.pn_games_list); i++) 
		ds_list_destroy(global.pn_games_list[| i]); 
	ds_list_clear(global.pn_games_list); 
	
	if(status < 0)
	{ 
		pn_on_error(9, "empty games list result, check php installation");
		exit;
	}
	
	var game, gameid, admin_id, gamename, online_players, max_players;
	
	ld = string_pos(sep_line, r_str); 
	while(ld)
	{ 
		game = ds_list_create();
		line = string_copy(r_str, 1, ld - 1); 
		r_str = string_delete(r_str, 1, ld);
		ld = string_pos(sep_line, r_str);  
	
		// game id
		wd = string_pos(sep_word, line);
		gameid = real(string_copy(line, 1, wd - 1));
		line = string_delete(line, 1, wd);
		ds_list_add(game, gameid);
		 
		// admin id
		wd = string_pos(sep_word, line);
		admin_id = real(string_copy(line, 1, wd - 1));
		line = string_delete(line, 1, wd);
		ds_list_add(game, admin_id);
		
		// game name
		wd = string_pos(sep_word, line);
		gamename = string_copy(line, 1, wd - 1);
		line = string_delete(line, 1, wd);
		ds_list_add(game, gamename);
		
		// online players
		wd = string_pos(sep_word, line);
		online_players = real(string_copy(line, 1, wd - 1));
		line = string_delete(line, 1, wd);
		ds_list_add(game, online_players);
		
		// max players
		wd = string_pos(sep_word, line);
		max_players = real(string_copy(line, 1, wd - 1));
		line = string_delete(line, 1, wd);
		ds_list_add(game, max_players);
		
		ds_list_add(global.pn_games_list, game);
	}
	pn_on_games_list(global.pn_games_list);
}
#endregion

