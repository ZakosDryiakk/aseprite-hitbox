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
                        
                        arr = {}
                        for i = tag.fromFrame.frameNumber-1, tag.toFrame.frameNumber-1 do arr[i] = 0 end
                        fList = table.concat(arr, ", ", tag.fromFrame.frameNumber-1, tag.toFrame.frameNumber-1)

                        print(
                            "\n\n#define " .. string.upper(character) .. "_" .. string.upper(tagName) .. "_S " .. tostring(tag.fromFrame.frameNumber -1)
                            .."\n#define " .. string.upper(character) .. "_" .. string.upper(tagName) .. "_E " .. tostring(tag.toFrame.frameNumber -1)
                            .."\n#define " .. string.upper(character) .. "_" .. string.upper(tagName) .. "_END " .. tostring(tag.toFrame.frameNumber - tag.fromFrame.frameNumber + 1)
                            .."\n")
                    end
                end
            end

            local cel = layer:cel(frame)
            local posOffsetX = cel.bounds.x + cel.bounds.width/2 - math.floor(app.sprite.width/2)
            local boxHalfWidth = cel.bounds.width/2
            local posOffsetY = cel.bounds.y - app.sprite.height

            if posOffsetX >= 0 then
                print("#define " .. string.upper(character) .. "_" .. string.upper(tagName) .. "_HIT" .. hitCont .. "_" .. string.sub(layer.name, -1)
                    .. " (Rectangle){player->position.x + player->box.x/2 + " .. string.format("(%.1ff", posOffsetX) .. "*player->side) - " .. string.format("%.1ff,", boxHalfWidth) 
                    .. string.format(" %+.1ff ", cel.bounds.y - app.sprite.height) .. "+ player->position.y + player->box.y, "
                    .. string.format(" %.1ff,", cel.bounds.width)
                    .. string.format(" %.1ff", cel.bounds.height)
                    .. "}")
            else
                print("#define " .. string.upper(character) .. "_" .. string.upper(tagName) .. "_HIT" .. hitCont .. "_" .. string.sub(layer.name, -1)
                    .. " (Rectangle){player->position.x + player->box.x/2 - " .. string.format("(%.1ff", -posOffsetX) .. "*player->side) - " .. string.format("%.1ff,", boxHalfWidth) 
                    .. string.format(" %+.1ff ", cel.bounds.y - app.sprite.height) .. "+ player->position.y + player->box.y, "
                    .. string.format(" %.1ff,", cel.bounds.width)
                    .. string.format(" %.1ff", cel.bounds.height)
                    .. "}")
            end


        end
    end
end
