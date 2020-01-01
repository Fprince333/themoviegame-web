var express = require("express");
var bodyParser = require("body-parser");
var Pusher = require("pusher");

var app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

require("dotenv").config();

var users = [];
var gameOn = false;

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

app.post("/pusher/auth", function (req, res) {
  var username = req.body.username;
  console.log(username)
  if (users.length < 2 && !gameOn) {
    gameOn = false;
    var player = {
      name: username,
      channel: req.body.channel_name
    }
    users.push(player);
    console.log("users: " + users.length);
    var socketId = req.body.socket_id;
    var channel = req.body.channel_name;
    var auth = pusher.authenticate(socketId, channel);

    res.send(auth);
  }
  if (users.length === 2) {
    var player_one = users.splice(0, 1)[0];
    var player_two = users.splice(0, 1)[0];
    gameOn = true;
    // trigger a message to player one and player two on their own channels
    console.log("triggering game for: ")
    console.log(player_one.name)
    console.log("vs")
    console.log(player_two.name)
    pusher.trigger(
      [player_one.channel, player_two.channel],
      "opponent-found",
      {
        player_one: player_one,
        player_two: player_two
      }
    );
  }
});

var port = process.env.PORT || 3000;
app.listen(port);
