math.randomseed(os.time())

data = require"data"

libs = {
  gamestate = require"gamestate",
  moonshine = require"moonshine",
}

gamestates = {
  menu = require"menu",
  game = require"game",
}

fonts = {
  title = love.graphics.newFont("Rock_Salt/RockSalt-Regular.ttf",64),
  menu = love.graphics.newFont("C64_TrueType_v1.2.1-STYLE/fonts/C64_Pro-STYLE.ttf",32),
  game = love.graphics.newFont("C64_TrueType_v1.2.1-STYLE/fonts/C64_Pro-STYLE.ttf",14),
}

colors = {
  bg = {.333,.333,.333},
  primary = {.995,.331,1},
  selected = {99.9/100,1,25.5/100},
  unselected = {1,1,1},
  system = {35.7/100,1,1},
  danger = {99.4/100,33.4/100,33.4/100},
  event = {35.3/100,1,25.5/100},
}

function love.load()
  libs.gamestate.registerEvents()
  libs.gamestate.switch(gamestates.menu)
  effect = libs.moonshine(libs.moonshine.effects.scanlines)
                    .chain(libs.moonshine.effects.crt)
                    .chain(libs.moonshine.effects.glow)
  effect.scanlines.opacity = 0.25

end
