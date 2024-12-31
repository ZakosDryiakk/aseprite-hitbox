-- Setting dialog box for Character parameters to be included
local dlg = Dialog()
dlg:entry{ id="character", label="Character Name:", text="Character" }
dlg:button{ id="confirm", text="Confirm" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()

-- Asking the user for dialog box character name
local character
local data = dlg.data
if data.confirm then
    character = data.character
end

-- Declaring parameters for code generation
local tags = app.sprite.tags
local hitCont = 1
local lastFrame = 0
local currTag
local parameters
local center
for _, layer in ipairs(app.sprite.layers) do
    if(layer.isGroup and layer.name == "Parameters") then
        parameters = layer
        for _, layers in ipairs(parameters.layers) do
            if layers.name == "Center" then
                center = layers:cel(1)
                break
            end
        end
        break
    end
end

-- Processing parameters to print the code on the aseprite console
--
-- Printing base parameters
print(
    "\n#define " .. string.upper(character) .. "_SPRITE_CENTER_X " .. string.format("%.1ff", center.bounds.x + ((center.bounds.width-1)/2)) ..
    "\n#define " .. string.upper(character) .. "_SPRITE_CENTER_Y " .. string.format("%.1ff", center.bounds.y + ((center.bounds.height-1)/2)) ..
    --
    "\n\n#define " .. string.upper(character) .. "_SPRITE_OFFSET_X (" .. string.upper(character) .. "_SPRITE_CENTER_X - " .. string.upper(character) ..
        "_SIZEX)" ..
    "\n#define " .. string.upper(character) .. "_SPRITE_OFFSET_Y (" .. string.upper(character) .. "_SPRITE_CENTER_Y - " .. string.upper(character) ..
        "_SIZEY) // Offset is the difference between the center of the sprite and the 0,0 point of the sprite" ..
    --
    "\n// S- Start of animation" ..
    "\n// E- End of animation" ..
    --
    "\n#define " .. string.upper(character) .. "_SPRITE \"resources/" .. character:sub(1,1):upper()..character:sub(2):lower() .. ".png\"" ..
    "\n#define " .. string.upper(character) .. "_SPRITE_COL " .. tostring(math.ceil(math.sqrt(#app.sprite.frames))) ..
    "\n#define " .. string.upper(character) .. "_SIZEX " .. string.format("%d", (app.sprite.width-2)) ..
    "\n#define " .. string.upper(character) .. "_SIZEY " .. string.format("%d", (app.sprite.height-2))
    )

-- Checking hitbox and hurtbox parameters per frame
print("\n\n// Animation/Sprite values\n//\n//\n")
for _, frame in ipairs(app.sprite.frames) do
    for _, layer in ipairs(parameters.layers) do
        for _, tag in ipairs(tags) do
            if frame.frameNumber >= tag.fromFrame.frameNumber and frame.frameNumber <= tag.toFrame.frameNumber then
                if currTag ~= tag then
                    currTag = tag
                    hitCont = 0

                    print(
                        "#define " .. string.upper(character) .. "_" .. string.upper(currTag.name) .. "_S " .. tostring(tag.fromFrame.frameNumber -1)
                        .."\n#define " .. string.upper(character) .. "_" .. string.upper(currTag.name) .. "_E " .. tostring(tag.toFrame.frameNumber -1)
                        .."\n#define " .. string.upper(character) .. "_" .. string.upper(currTag.name) .. "_END " .. tostring(tag.toFrame.frameNumber - tag.fromFrame.frameNumber + 1)
                        .."\n")
                end
            end
        end
    end
end

print("\n\n// Hitboxes \n//\n// First number is the n-th hitbox of the move, and the second is hitbox layer, from lowest-positioned to highest\n//")
for _, frame in ipairs(app.sprite.frames) do
    for _, layer in ipairs(parameters.layers) do
        -- Checking which frames have contents on the Hitbox layer
        if layer:cel(frame) ~= nil and string.find(layer.name, "(Hitbox)") ~= nil then
            --print(lastFrame.. " and ".. frame.frameNumber)
            --
            --Checking if the the next hitbox detected in is the same Move tag
            if tostring(frame.frameNumber) ~= tostring(lastFrame) then
                hitCont = hitCont + 1
            end

            lastFrame = frame.frameNumber

            -- Checking if the hitbox detected is in the same tag group as saved in buffer
            for _, tag in ipairs(tags) do
                if frame.frameNumber >= tag.fromFrame.frameNumber and frame.frameNumber <= tag.toFrame.frameNumber then
                    if currTag ~= tag then
                        currTag = tag
                        hitCont = 1
                        print("\n")
                        --
                        arr = {}
                        for i = tag.fromFrame.frameNumber-1, tag.toFrame.frameNumber-1 do arr[i] = 0 end
                        fList = table.concat(arr, ", ", tag.fromFrame.frameNumber-1, tag.toFrame.frameNumber-1)

                    end
                end
            end

            local cel = layer:cel(frame)
            local posOffsetX = cel.bounds.x + cel.bounds.width/2 - math.floor(app.sprite.width/2)
            local boxHalfWidth = cel.bounds.width/2
            local posOffsetY = cel.bounds.y - app.sprite.height

            if posOffsetX >= 0 then
                print(
                    "#define " .. string.upper(character) .. "_" .. string.upper(currTag.name) .. "_HIT" .. hitCont .. "_" .. string.sub(layer.name, -1)
                    .. " (Rectangle){player->position.x + " .. string.format("(%.1ff", posOffsetX) .. "*player->side) - " .. string.format("%.1ff,", boxHalfWidth)
                    .. string.format(" %+.1ff ", cel.bounds.y - app.sprite.height) .. "+ player->position.y - " .. string.upper(character) .. "_SPRITE_OFFSET_Y, "
                    .. string.format(" %.1ff,", cel.bounds.width)
                    .. string.format(" %.1ff", cel.bounds.height)
                    .. "}")
            else
                print("#define " .. string.upper(character) .. "_" .. string.upper(currTag.name) .. "_HIT" .. hitCont .. "_" .. string.sub(layer.name, -1)
                    .. " (Rectangle){player->position.x - " .. string.format("(%.1ff", -posOffsetX) .. "*player->side) - " .. string.format("%.1ff,", boxHalfWidth) 
                    .. string.format(" %+.1ff ", cel.bounds.y - app.sprite.height) .. "+ player->position.y - " .. string.upper(character) .. "_SPRITE_OFFSET_Y, "
                    .. string.format(" %.1ff,", cel.bounds.width)
                    .. string.format(" %.1ff", cel.bounds.height)
                    .. "}")
            end
        end
    end
end

print("\n\n// Hurtboxes \n//\n//First number is the hurtbox layer, from lowest-positioned hurtbox to highest, second number is the step\n//")

for _, layer in ipairs(parameters.layers) do
    if string.find(layer.name, "(Hurtbox)") ~= nil then
        for _, tag in ipairs(tags) do
            print("\n#define " .. string.upper(character) .. "_" .. string.upper(tag.name) .. "_HURT" .. string.sub(layer.name, -1) .. " { \\")
            for i = tag.fromFrame.frameNumber, tag.toFrame.frameNumber do
                print(string.upper(character) .. "_" .. string.upper(tag.name) .. "_HURT" .. string.sub(layer.name, -1) .. "_" .. tostring(i - tag.fromFrame.frameNumber + 1) .. ", \\")
            end
            print("}\n")
        end
    end
end

for _, frame in ipairs(app.sprite.frames) do
    for _, layer in ipairs(parameters.layers) do
        if layer:cel(frame) ~= nil and string.find(layer.name, "(Hurtbox)") ~= nil then
            for _, tag in ipairs(tags) do
                if frame.frameNumber >= tag.fromFrame.frameNumber and frame.frameNumber <= tag.toFrame.frameNumber then
                    if currTag ~= tag then
                        currTag = tag
                        print("\n")
                    end
                end
            end

            local cel = layer:cel(frame)
            local posOffsetX = cel.bounds.x + cel.bounds.width/2 - math.floor(app.sprite.width/2)
            local boxHalfWidth = cel.bounds.width/2
            local posOffsetY = cel.bounds.y - app.sprite.height

            if posOffsetX >= 0 then
                print(
                    "#define " .. string.upper(character) .. "_" .. string.upper(currTag.name) .. "_HURT" .. string.sub(layer.name, -1) .. "_" .. frame.frameNumber - currTag.fromFrame.frameNumber
                    .. " (Rectangle){player->position.x + " .. string.format("(%.1ff", posOffsetX) .. "*player->side) - " .. string.format("%.1ff,", boxHalfWidth)
                        .. string.format(" %+.1ff ", cel.bounds.y - app.sprite.height) .. "+ player->position.y - " .. string.upper(character) .. "_SPRITE_OFFSET_Y, "
                        .. string.format(" %.1ff,", cel.bounds.width)
                        .. string.format(" %.1ff", cel.bounds.height)
                    .. "}")
            else
                print("#define " .. string.upper(character) .. "_" .. string.upper(currTag.name) .. "_HURT" .. string.sub(layer.name, -1) .. "_" .. frame.frameNumber - currTag.fromFrame.frameNumber
                    .. " (Rectangle){player->position.x - " .. string.format("(%.1ff", -posOffsetX) .. "*player->side) - " .. string.format("%.1ff,", boxHalfWidth) 
                        .. string.format(" %+.1ff ", cel.bounds.y - app.sprite.height) .. "+ player->position.y - " .. string.upper(character) .. "_SPRITE_OFFSET_Y, "
                        .. string.format(" %.1ff,", cel.bounds.width)
                        .. string.format(" %.1ff", cel.bounds.height)
                    .. "}")
            end
        end
    end
end
