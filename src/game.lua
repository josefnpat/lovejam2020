local game = {}

function game:enter()
  local padding = 32
  self.events = {}
  self.state = {
    deck = {},
  }
  self.newEvent = 7-(difficulty-1)*3
  self.newEventDt = 0

  self.deadAir = 10
  self.deadAirDt = -10

  self.lastAd = 240
  self.lastAdDt = 0

  self.lastSong = 60
  self.lastSongDt = 0

  self.tracksPlayed = 0
  self.gameOver = false
  self.pause = false

  self.critics = {
    moreAds = 0,
    tooManyAds = 0,
    betterGenre = 0,
    deadAir = 0,
    missedCalls = 0,
  }
  self.criticsStrings = {
    moreAds = "You didn't play enough ads!",
    tooManyAds = "You played too many ads!",
    betterGenre = "Your genres didn't match!",
    deadAir = "You had too much dead air!",
    missedCalls = "You missed too many calls!",
  }

  table.insert(self.events,{
    text = "Welcome to LoveFM, the only place for love.",
    color = colors.system,
  })
  table.insert(self.events,{
    text = "Press keys when prompted, to see if you have what it takes to be the best DJ.",
    color = colors.system,
  })

end

function game:update(dt)
  if self.gameOver then return end
  if self.pause then return end

  for i,v in pairs(self.critics) do
    if v > 3 then
      self.gameOver = true
      table.insert(self.events,{
        text = "You're fired! "..self.criticsStrings[i],
        color = colors.system,
      })
      table.insert(self.events,{
        text = "You managed to play "..self.tracksPlayed.." songs before you were dragged out of the LoveFM radio station.",
        color = colors.system,
      })
      table.insert(self.events,{
        text = "Score: "..(self.tracksPlayed*difficulty*10),
        color = colors.system,
      })
      table.insert(self.events,{
        text = "Press ESCAPE to return to the main menu.",
        color = colors.system,
      })
      return
    end
  end

  for i,event in pairs(self.events) do
    if event.update then
      event.update(event,dt,self.events,self.critics)
    end
  end

  self.newEventDt = self.newEventDt + dt
  if self.newEventDt > self.newEvent then
    self.newEventDt = 0
    self:newevent()
  end

  self.lastAdDt = self.lastAdDt + dt
  if self.lastAdDt > self.lastAd then
    self.lastAdDt = 0
    table.insert(self.events,{
      text = "You're not playing enough ads.",
      color = colors.danger,
    })
    self.critics.moreAds = self.critics.moreAds + 1
  end

  self.lastSongDt = self.lastSongDt + dt
  if self.lastSongDt > self.lastSong then
    self.lastSongDt = 0
    table.insert(self.events,{
      text = "You're not playing enough songs.",
      color = colors.danger,
    })
    self.critics.moreAds = self.critics.moreAds + 1
  end

  if self.state.currentTrack == nil then
    self.state.currentTrack = table.remove(self.state.deck,1)
    if self.state.currentTrack then
      self.tracksPlayed = self.tracksPlayed + 1
      table.insert(self.events,{
        text = "Now playing "..self.state.currentTrack.name,
      })

      if self.state.lastTrack then
        local genre_good = false
        -- transition from an ad
        if self.state.currentTrack.genre1 == nil and self.state.currentTrack.genre1 == nil then
          genre_good = true
        end
        -- check for matching genre
        if self.state.lastTrack.genre1 == self.state.currentTrack.genre1 then
          genre_good = true
        end
        if self.state.lastTrack.genre1 == self.state.currentTrack.genre2 then
          genre_good = true
        end
        if self.state.lastTrack.genre2 == self.state.currentTrack.genre1 then
          genre_good = true
        end
        if self.state.lastTrack.genre2 == self.state.currentTrack.genre2 then
          genre_good = true
        end
        if not genre_good then
          table.insert(self.events,{
            text = "You're playing completely different genres!",
            color = colors.danger,
          })
          self.critics.betterGenre = self.critics.betterGenre + 1
        end
      end

    end
    self.deadAirDt = self.deadAirDt + dt
    if self.deadAirDt > self.deadAir then
      self.deadAirDt = 0
      table.insert(self.events,{
        text = "You're playing nothing but dead air!",
        color = colors.danger,
      })
      self.critics.deadAir = self.critics.deadAir + 1
    end
  else
    self.deadAirDt = 0
    self.state.currentTrack.length = self.state.currentTrack.length - dt
    if self.state.currentTrack.length < 0 then
      self.state.lastTrack = self.state.currentTrack
      self.state.currentTrack = nil
      if #self.state.deck == 0 then
        table.insert(self.events,{
          text = "Deck is empty.",
        })
      else
        table.insert(self.events,{
          text = "Loading next track from deck.",
        })
      end
    end
  end
end

function game:newevent()
  local new_event = data.events[math.random(#data.events)]()
  local found_dupe = false
  for i,event in pairs(self.events) do
    if event.keypress == new_event.keypress then
      found_dupe = true
      break
    end
  end
  if not found_dupe then
    table.insert(self.events,new_event)
  end
end

function game:draw()
  effect(function()
    love.graphics.setColor(colors.bg)
    love.graphics.rectangle("fill",0,0,1280,720)
    if debug_mode then
      love.graphics.setColor({1,1,1})
      local s = ""
      for i,v in pairs(self.critics) do
        s = s .. i .. ": "..v .. "\n"
      end
      love.graphics.printf(s,0,0,1280,"right")
    end
    love.graphics.setFont(fonts.game)
    local offset = #self.events*fonts.game:getHeight()-720+64
    for i,event in pairs(self.events) do
      love.graphics.setColor(event.color or {1,1,1})
      local key = event.keypress and ("["..event.keypress.."] ") or ""
      love.graphics.print(key..event.text,32,32+(i-1)*fonts.game:getHeight()-offset)
    end
  end)
end

function game:keypressed(key)
  if key == "`" and love.keyboard.isDown("lshift") then
    debug_mode = not debug_mode
  end
  if key == "escape" then
    libs.gamestate.switch(gamestates.menu)
  end
  if self.gameOver then return end
  if key == "p" then
    self.pause = not self.pause
    table.insert(self.events,{
      text = "Game is "..(self.pause and "" or "un").."paused.",
      color = colors.system,
    })
  end
  for i,event in pairs(self.events) do
    if tostring(event.keypress) == key then
      event.onKeypress(event,self.state,self.events)
      event.keypress = nil
      break
    end
  end
end

return game
