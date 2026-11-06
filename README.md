# Roblox Junkyard Simulator Script

Junkyard Simulator is a Roblox script project for a simple junkyard collection game, with collectible scrap, carry-bag upgrades, selling, cash tracking, a player HUD, and saved cash and upgrade levels.

## Install

1. In Roblox Studio, create or open a place with a `SpawnLocation`.
2. Add a Script to `ServerScriptService`, name it `JunkyardServer.server.lua`, and paste in the server script provided with this project.
3. Add a LocalScript to `StarterPlayer > StarterPlayerScripts`, name it `JunkyardClient.client.lua`, and paste in the client script provided with this project.
4. Publish the experience and enable Studio Access to API Services under Game Settings > Security if you want to test DataStore saving in Studio.

## Use

1. Press Play. The scripts create the junkyard scrap area, collection prompts, remotes, and HUD.
2. Walk to a scrap item and use its Collect prompt to pick it up.
3. Select SELL in the HUD to turn carried scrap into cash.
4. Select BAG to buy an upgrade that increases carry capacity by 10.
5. Select TOOL to buy a tracked, priced upgrade. Tool upgrades currently do not affect gameplay.
6. Cash and upgrade levels are saved when players leave, using Roblox DataStore.

---

More Roblox script projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/bd437ce5-7aef-4f28-bd30-60541234bb5c?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=bd437ce5-7aef-4f28-bd30-60541234bb5c
