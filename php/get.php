<?php

if(!isset($_POST["token"]) || ! isset($_POST["date"]))
{
    echo("Error: missing token or date");
    exit;
}
require_once "config.php";
require_once "connection.php";


$token = mysql_real_escape_string($_POST["token"]);
$date = mysql_real_escape_string($_POST["date"]);

$query = "SELECT id, game FROM pollnet_users WHERE token = '$token'";
$result = mysql_query($query) or die(mysql_error());

//only take the first result
if ($row = mysql_fetch_assoc($result)) 
{
    $id = $row["id"];
    $game = $row["game"];

    //update user
    $query = "UPDATE pollnet_users SET date = NOW() WHERE token = '$token'";
    $result = mysql_query($query) or die(mysql_error());

    
    //get players list
    $query = "SELECT id, name FROM pollnet_users WHERE game = '$game' AND token != '$token'";
    $result = mysql_query($query) or die(mysql_error());

    while ($row = mysql_fetch_assoc($result)) 
    { 
        echo $row["id"] . $word_sep . $row["name"] . $word_sep . $line_sep;
    } 

    
    
    echo($msg_sep);
          
    
    //get messages list
    $query = "SELECT date, user_from, user_to, message
    FROM pollnet_messages 
    WHERE user_from <> '$id'
        AND game = '$game' 
        AND (user_to = '$id' OR user_to is NULL)
        AND date > '$date'
    ORDER BY date ASC";
    $result = mysql_query($query) or die(mysql_error());
 
    while ($row = mysql_fetch_assoc($result)) 
    {
        echo $row["date"] . $word_sep . $row["user_from"] . $word_sep . $row["user_to"] . $word_sep . $row["message"] . $word_sep . $line_sep;
    }

}
?>