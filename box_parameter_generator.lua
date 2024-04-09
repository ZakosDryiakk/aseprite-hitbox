local dlg = Dialog()
dlg:entry{ id="character", label="Character Name:", text="Character" }
dlg:button{ id="confirm", text="Confirm" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()
local character
local data = dlg.data
if data.confirm then
    character = data.character
end
local tags = app.sprite.tags
local hitCont = 1
local lastFrame = 0
local tagName = ""
for _, frame in ipairs(app.sprite.frames) do
    for _, layer in ipairs(app.sprite.layers) do
        if layer:cel(frame) ~= nil and string.find(layer.name, "(Hitbox)") ~= nil then

            --print(lastFrame.. " and ".. frame.frameNumber)
            if tostring(frame.frameNumber) ~= tostring(lastFrame) then
                hitCont = hitCont + 1
            end

            lastFrame = frame.frameNumber

            for _, tag in ipairs(tags) do
                if frame.frameNumber >= tag.fromFrame.frameNumber and frame.frameNumber <= tag.toFrame.frameNumber then
                    if tagName ~= tag.name then
                        tagName = tag.name
                        hitCont = 1
                        print("\n")
                    end
                end
            end

            local cel = layer:cel(frame)
            print("#define " .. string.upper(character) .. "_" .. string.upper(tagName) .. "_HIT" .. hitCont .. "_" .. string.sub(layer.name, -1)
                .. " (Rectangle){player->position.x + player->box.x/2 " .. string.format("%+.1ff", cel.bounds.x - math.floor(app.sprite.width/2)) .. string.format(" %+.1ff,", cel.bounds.width/2) 
                .. string.format(" %+.1ff ", cel.bounds.y - app.sprite.height) .. "+ player->position.y + player->box.y, "
                .. string.format(" %.1ff,", cel.bounds.width)
                .. string.format(" %.1ff", cel.bounds.height)
                .. "}")

        end
    end
end
