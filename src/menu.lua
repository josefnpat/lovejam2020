local menu = {}

function menu:enter()
  self.index = 1
end

function menu:draw()
  effect(function()
    love.graphics.setColor(colors.bg)
    love.graphics.rectangle("fill",0,0,1280,720)
    love.graphics.setColor(colors.primary)
    love.graphics.setFont(fonts.title)
    love.graphics.printf("LöveFM", 0, 192, 1280, "center")
    love.graphics.setFont(fonts.game)
    love.graphics.printf("A terrible game by @josefnpat for lovejam2020", 0, 256+64, 1280, "center")
    love.graphics.setFont(fonts.menu)
    for i,v in pairs(data.difficulty) do
      local pre,post
      if i == self.index then
        pre,post = "> "," <"
        love.graphics.setColor(colors.selected)
      else
        pre,post = "",""
        love.graphics.setColor(colors.unselected)
      end
      love.graphics.printf(pre..v.title..post, 0, 256 + 64 + i*48, 1280, "center")
    end
  end)
end

function menu:keyreleased(key, code)
  if key == "escape" then
    love.event.quit()
  elseif key == "up" then
    self.index = self.index - 1
    if self.index < 1 then
      self.index = #data.difficulty
    end
  elseif key == "down" then
    self.index = self.index + 1
    if self.index > #data.difficulty then
      self.index = 1
    end
  elseif key == 'return' then
    difficulty = self.index
    libs.gamestate.switch(gamestates.game)
  end
end

return menu
