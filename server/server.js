var express = require("express");
var bodyParser = require("body-parser");
var Pusher = require("pusher");

var app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

require("dotenv").config();

var users = [];

var pusher = new Pusher({
  // connect to pusher
  appId: process.env.APP_ID,
  key: process.env.APP_KEY,
  secret: process.env.APP_SECRET,
  cluster: process.env.APP_CLUSTER
});

app.get("/", function (req, res) {
  // for testing if the server is running
  res.send("all green...");
});

app.post("/pusher/auth", function(req, res) {
  var socketId = req.body.socket_id;
  var channel = req.body.channel_name;
  var username = req.body.username;
  var auth = pusher.authenticate(socketId, channel);
  res.send(auth);

  users.push(username);
  console.log(username + " logged in");

  if (users.length === 2) {
    var unique_users = users.filter((value, index, self) => {
    return self.indexOf(value) === index;
  });

    var player_one = unique_users[0];
    var player_two = unique_users[1];
    users = [];

    console.log("opponent found: " + player_one + " and " + player_two);

    pusher.trigger(
      ["private-user-" + player_one, "private-user-" + player_two],
      "opponent-found",
      {
        player_one: player_one,
        player_two: player_two
      }
    )
  }
});

var port = process.env.PORT || 3000;
app.listen(port);
