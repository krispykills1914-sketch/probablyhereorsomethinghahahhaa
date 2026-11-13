local Base = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/refs/heads/main/"
local ok, src = pcall(game.HttpGet, game, Base .. "script.lua")
if not ok or type(src) ~= "string" or #src < 100 then
    error("[Tapology] failed to download script module nigger :X: " .. tostring(src))
end
local fn, err = loadstring(src, "@tapology")
if not fn then
    error("[Tapology] script compile failed or maybe retard ( error waiting after this shit nigga ): " .. tostring(err))
end
fn()
