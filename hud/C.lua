--[[
    Zoli's playground
    f2es mozgatás rész ai generated
]]


addEventHandler("onClientResourceStart", resourceRoot,
    function()
        showPlayerHudComponent("all", false)
    end
)

local maxBlipDistance = 500 



local renderData = {
    lastBarValue = {},
    barInterpolation = {},
    interpolationStartValue = {}
}

function getPlayerMoney()
    return getElementData(localPlayer, "money") or 0
end
----SARP CODE
function dxDrawFiveBar(x, y, w, h, borderSize, activeColor, value, name, amountOfSegments, bgColor, borderColor, postGUI)
    bgColor = bgColor or tocolor(0, 0, 0, 100)
    borderColor = borderColor or tocolor(0, 0, 0, 140)
    amountOfSegments = 3

    w = math.ceil(w) - 2 * (amountOfSegments - 1)
    h = math.ceil(h)
    w = w / amountOfSegments

    if value > 100 then
        value = 100
    end

    local interpolation = false

    if name then
        if renderData.lastBarValue[name] then
            if renderData.lastBarValue[name] ~= value then
                renderData.barInterpolation[name] = getTickCount()
                renderData.interpolationStartValue[name] = renderData.lastBarValue[name]
                renderData.lastBarValue[name] = value
            end
        else
            renderData.lastBarValue[name] = value
        end

        if renderData.barInterpolation[name] then
            interpolation = interpolateBetween(renderData.interpolationStartValue[name], 0, 0, value, 0, 0, (getTickCount() - renderData.barInterpolation[name]) / 500, "OutQuad")
        end
    end

    if interpolation then
        value = interpolation
    end

    local progressPerSegment = 100 / amountOfSegments
    local remainingProgress = value % progressPerSegment
    local segmentsFull = math.floor(value / progressPerSegment)
    local segmentsInUse = math.ceil(value / progressPerSegment)

    local doubleBorder = borderSize * borderSize

    for i = 1, amountOfSegments do
        local x2 = x + (w + 2) * (i - 1)

        if borderSize ~= 0 then
            dxDrawRectangle(x2, y, w, borderSize, borderColor, postGUI)
            dxDrawRectangle(x2, y + h - borderSize, w, borderSize, borderColor, postGUI)
            dxDrawRectangle(x2, y + borderSize, borderSize, h - doubleBorder, borderColor, postGUI)
            dxDrawRectangle(x2 + w - borderSize, y + borderSize, borderSize, h - doubleBorder, borderColor, postGUI)
        end

        dxDrawRectangle(x2 + borderSize, y + borderSize, w - doubleBorder, h - doubleBorder, bgColor, postGUI)

        if i <= segmentsFull then
            dxDrawRectangle(x2 + borderSize, y + borderSize, w - doubleBorder, h - doubleBorder, activeColor, postGUI)
        elseif i == segmentsInUse and remainingProgress > 0 then
            dxDrawRectangle(x2 + borderSize, y + borderSize, (w - doubleBorder) / progressPerSegment * remainingProgress, h - doubleBorder, activeColor, postGUI)
        end
    end
end
------------

local maxOffset = 50 
local baseReturnSpeed = 0.1 
local currentXOffset = 0
local currentYOffset = 0 

local isDraggingHealthBar = false
local isDraggingArmorBar = false
local offsetX, offsetY = 0, 0
local healthBarX, healthBarY = 0, 0
local armorBarX, armorBarY = 0, 0

local screenWidth, screenHeight = guiGetScreenSize()
local defaultHealthBarX, defaultHealthBarY = screenWidth - 220, 20
local defaultArmorBarX, defaultArmorBarY = screenWidth - 220, 44

local function loadBarPositions()
    local file = xmlLoadFile("bar_positions.xml")
    if file then
        local healthNode = xmlFindChild(file, "healthBar", 0)
        if healthNode then
            healthBarX = tonumber(xmlNodeGetAttribute(healthNode, "x"))
            healthBarY = tonumber(xmlNodeGetAttribute(healthNode, "y"))
        end

        local armorNode = xmlFindChild(file, "armorBar", 0)
        if armorNode then
            armorBarX = tonumber(xmlNodeGetAttribute(armorNode, "x"))
            armorBarY = tonumber(xmlNodeGetAttribute(armorNode, "y"))
        end

        xmlUnloadFile(file)
    else
        local screenWidth, screenHeight = guiGetScreenSize()
        healthBarX = screenWidth - 220
        healthBarY = 20
        armorBarX = screenWidth - 220
        armorBarY = 44
    end
end

local function saveBarPositions()
    local file = xmlCreateFile("bar_positions.xml", "positions")
    if file then
        local healthNode = xmlCreateChild(file, "healthBar")
        xmlNodeSetAttribute(healthNode, "x", healthBarX)
        xmlNodeSetAttribute(healthNode, "y", healthBarY)

        local armorNode = xmlCreateChild(file, "armorBar")
        xmlNodeSetAttribute(armorNode, "x", armorBarX)
        xmlNodeSetAttribute(armorNode, "y", armorBarY)

        xmlSaveFile(file)
        xmlUnloadFile(file)
    end
end

loadBarPositions()

function drawHUD()

    local screenWidth, screenHeight = guiGetScreenSize()
    local health = getElementHealth(getLocalPlayer())
    local armor = getPedArmor(getLocalPlayer())

    local targetXOffset = 0
    local targetYOffset = 0
    local returnSpeed = baseReturnSpeed

    if isPedInVehicle(getLocalPlayer()) then
        local vehicle = getPedOccupiedVehicle(getLocalPlayer())
        local _, _, rotationZ = getElementRotation(vehicle) 
        local speedX, speedY, speedZ = getElementVelocity(vehicle) 
        local speed = (speedX^2 + speedY^2 + speedZ^2)^(0.5) * 180

        local controller = getVehicleController(vehicle)
        local isReversing = getPedControlState(controller, "brake_reverse")
        local isTurningLeft = getPedControlState(controller, "vehicle_left")
        local isTurningRight = getPedControlState(controller, "vehicle_right")

        if speed < 1 then
            targetXOffset = 0
            targetYOffset = 0
        else
            if isTurningLeft then
                targetXOffset = maxOffset
            elseif isTurningRight then
                targetXOffset = -maxOffset
            else
                targetXOffset = math.random(-1, 1) * (speed / 20)
            end

            if isReversing then
                targetYOffset = -maxOffset / 2
            else
                targetYOffset = 0 
            end

            targetXOffset = math.min(maxOffset, math.max(-maxOffset, targetXOffset))
            targetYOffset = math.min(maxOffset / 2, math.max(-maxOffset / 2, targetYOffset))
            
            returnSpeed = baseReturnSpeed * (speed / 100)
        end
    else
        targetXOffset = 0
        targetYOffset = 0
    end

    currentXOffset = currentXOffset + (targetXOffset - currentXOffset) * returnSpeed
    currentYOffset = currentYOffset + (targetYOffset - currentYOffset) * returnSpeed

    if not getElementData(localPlayer,"hideHud") then
    dxDrawFiveBar(healthBarX + currentXOffset, healthBarY + currentYOffset, 200, 20, 2, tocolor(245, 143, 143, 150), health, "healthBar", 3, tocolor(0, 0, 0,70), tocolor(0, 0, 0, 130), false)
    end
    if not getElementData(localPlayer,"hideHud") then
        dxDrawFiveBar(armorBarX + currentXOffset, armorBarY + currentYOffset, 200, 20, 2, tocolor(255, 255, 255, 150), armor, "armorBar", 3, tocolor(0, 0, 0,70), tocolor(0, 0, 0, 130), false)
    end
    end

addEventHandler("onClientRender", root, drawHUD)

function givePlayerArmor()
    local player = getLocalPlayer()
    setPedArmor(player, 100)
    outputChatBox("Pajzsot kaptál!", 255, 255, 0)
end

addCommandHandler("faszs", givePlayerArmor)

function setPlayerHealth(command, healthValue)
    local player = getLocalPlayer()
    local health = tonumber(healthValue)

    if health and health >= 0 and health <= 100 then
        setElementHealth(player, health)
        outputChatBox("Az életerőd beállítva: " .. health .. "%", 255, 255, 0)
    else
        outputChatBox("Hibás életerő érték! Használat: /sethealth [0-100]", 255, 0, 0)
    end
end

addCommandHandler("faszom", setPlayerHealth)

local filterEnabled = false
function toggleFilter()
    filterEnabled = not filterEnabled
    if filterEnabled then
        addEventHandler("onClientRender", root, hudeditorfilter)
        showCursor(true)
    else
        removeEventHandler("onClientRender", root, hudeditorfilter)
        showCursor(false)
    end
end
bindKey("F2", "down", toggleFilter)

function hudeditorfilter()
    local screenWidth, screenHeight = guiGetScreenSize()
    dxDrawRectangle(0, 0, screenWidth, screenHeight, tocolor(0,255,0, 30), true)
end

function onClientClick(button, state, absoluteX, absoluteY)
    if button == "left" and state == "down" then
        if absoluteX >= healthBarX and absoluteX <= healthBarX + 200 and absoluteY >= healthBarY and absoluteY <= healthBarY + 20 then
            isDraggingHealthBar = true
            offsetX, offsetY = absoluteX - healthBarX, absoluteY - healthBarY
        elseif absoluteX >= armorBarX and absoluteX <= armorBarX + 200 and absoluteY >= armorBarY and absoluteY <= armorBarY + 20 then
            isDraggingArmorBar = true
            offsetX, offsetY = absoluteX - armorBarX, absoluteY - armorBarY
        end
    elseif button == "left" and state == "up" then
        isDraggingHealthBar = false
        isDraggingArmorBar = false
        saveBarPositions()
    end
end

function onClientCursorMove(_, _, absoluteX, absoluteY)
    if isDraggingHealthBar and filterEnabled then
        healthBarX, healthBarY = absoluteX - offsetX, absoluteY - offsetY
    elseif isDraggingArmorBar and filterEnabled then
        armorBarX, armorBarY = absoluteX - offsetX, absoluteY - offsetY
    end
end

addEventHandler("onClientClick", root, onClientClick)
addEventHandler("onClientCursorMove", root, onClientCursorMove)

addEventHandler("onClientResourceStop", resourceRoot, saveBarPositions)



function togHUD()
    if getElementData(localPlayer, "hideHud") then
        setElementData(localPlayer, "hideHud", false)
    else
        setElementData(localPlayer, "hideHud", true)
    end
end
addCommandHandler("toghud", togHUD)


---MINIMAP --ja meg ezt a gecis minimappot is ai irta 

local blipImages = {
    [4] = "blips/4.png",
    [6] = "blips/6.png",
    [7] = "blips/7.png",
    [8] = "blips/8.png",
    [9] = "blips/9.png",
    [11] = "blips/11.png",
    [13] = "blips/13.png",
    [14] = "blips/14.png",
    [17] = "blips/17.png",
    [22] = "blips/22.png",
    [24] = "blips/24.png",
    [26] = "blips/26.png",
    [27] = "blips/27.png",
    [28] = "blips/28.png",
    [29] = "blips/29.png",
    [30] = "blips/30.png",
    [31] = "blips/31.png",
    [33] = "blips/33.png",
    [40] = "blips/40.png",
    [41] = "blips/41.png",
    [42] = "blips/42.png",
}

local function createCustomBlip(x, y, z, id)
    local blip = createBlip(x, y, z, id)
    setElementData(blip, "customBlipID", id)
    return blip
end

--createCustomBlip(kordi, id) -- Déli


local screenWidth, screenHeight = guiGetScreenSize()
local defaultMinimapX, defaultMinimapY = screenWidth - screenWidth + 30, screenHeight - 220
local minimapX, minimapY = defaultMinimapX, defaultMinimapY

local isDraggingMinimap = false
local offsetX, offsetY = 0, 0

local minimapSize = 200 
local maxBlipDistance = 500 

local function loadMinimapPosition()
    local file = xmlLoadFile("minimap_position.xml")
    if file then
        local minimapNode = xmlFindChild(file, "minimap", 0)
        if minimapNode then
            minimapX = tonumber(xmlNodeGetAttribute(minimapNode, "x"))
            minimapY = tonumber(xmlNodeGetAttribute(minimapNode, "y"))
        end
        xmlUnloadFile(file)
    else
        minimapX, minimapY = defaultMinimapX, defaultMinimapY
    end
end

local function saveMinimapPosition()
    local file = xmlCreateFile("minimap_position.xml", "positions")
    if file then
        local minimapNode = xmlCreateChild(file, "minimap")
        xmlNodeSetAttribute(minimapNode, "x", minimapX)
        xmlNodeSetAttribute(minimapNode, "y", minimapY)
        xmlSaveFile(file)
        xmlUnloadFile(file)
    end
end
local texture = dxCreateTexture( "files/map.png", "dxt5", true);
local imageWidth, imageHeight = dxGetMaterialSize(texture);


local mapWidth, mapHeight = imageWidth, imageWidth 
local minimapSize = 200 
local maxBlipDistance = 300 
loadMinimapPosition()

local function getMapFromWorldPosition(worldX, worldY)
    local mapX = (worldX + 3000) * (mapWidth / 6000)
    local mapY = (3000 - worldY) * (mapHeight / 6000)
    return mapX, mapY
end

function drawMinimap()
    if getElementData(localPlayer, "hideHud") then
        return
    end

    function getLocationName(x, y)
        local locations = {
            {x = 1000, y = 5000, name = "Város"},
            {x = 2000, y = 6000, name = "Erdő"},
            {x = -1787.82800, y = 1945.50061, name = "Vidék"}
        }
        local closestLocation = nil
        local minDistance = math.huge 

        for _, location in ipairs(locations) do
            local distance = math.sqrt((x - location.x)^2 + (y - location.y)^2)
            if distance < minDistance then
                minDistance = distance
                closestLocation = location.name
            end
        end

        return closestLocation or "Unknown Location"
    end

    local playerX, playerY = getElementPosition(localPlayer)
    local mapX, mapY = getMapFromWorldPosition(playerX, playerY)

    local mapSectionX = math.max(0, mapX - minimapSize / 2)
    local mapSectionY = math.max(0, mapY - minimapSize / 2)
    local mapSectionWidth = math.min(minimapSize, mapWidth - mapSectionX)
    local mapSectionHeight = math.min(minimapSize, mapHeight - mapSectionY)

    if getElementData(localPlayer, "hideHud") then
        return
    end
    dxDrawRectangle(minimapX-3 + currentXOffset, minimapY-3 + currentYOffset, minimapSize+6, minimapSize+6 , tocolor(0, 0, 0, 150))

    local locationName = getLocationName(playerX, playerY) 
    dxDrawImageSection(minimapX + currentXOffset, minimapY + currentYOffset, minimapSize, minimapSize, mapSectionX, mapSectionY, mapSectionWidth, mapSectionHeight, "files/map.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
    dxDrawRectangle(minimapX + currentXOffset, minimapY + currentYOffset, minimapSize, minimapSize / 6, tocolor(0, 0, 0, 80))
    dxDrawText(locationName, 
        minimapX + currentXOffset, 
        minimapY + currentYOffset, 
        minimapX + currentXOffset + minimapSize, 
        minimapY + currentYOffset + minimapSize / 6, 
        textColor, 
        1.5, 
        1.5, 
        "default-bold", 
        "center", 
        "center"
    )
    dxDrawRectangle(minimapX + (mapX - mapSectionX) * (minimapSize / mapSectionWidth) - 2 + currentXOffset, minimapY + (mapY - mapSectionY) * (minimapSize / mapSectionHeight) - 2 + currentYOffset, 4, 4, tocolor(255, 255, 255, 255))

    local blips = getElementsByType("blip")
    for _, blip in ipairs(blips) do
        if getElementData(blip, "customBlipID") and blip ~= localPlayer then
            local blipX, blipY = getElementPosition(blip)
            local distance = getDistanceBetweenPoints2D(playerX, playerY, blipX, blipY)

            if distance <= maxBlipDistance then
                local mapBlipX, mapBlipY = getMapFromWorldPosition(blipX, blipY)

                local blipDrawX = minimapX + (mapBlipX - mapSectionX) * (minimapSize / mapSectionWidth)
                local blipDrawY = minimapY + (mapBlipY - mapSectionY) * (minimapSize / mapSectionHeight)

                local blipID = getElementData(blip, "customBlipID")
                local blipImage = blipImages[blipID] or "blips/0.png"

                dxDrawImage(blipDrawX - 5 + currentXOffset, blipDrawY - 5 + currentYOffset, 15, 15, blipImage, 0, 0, 0, tocolor(255, 255, 255, 255))
            end
        end
    end
end


addEventHandler("onClientRender", root, drawMinimap)

function onClientClick(button, state, absoluteX, absoluteY)
    if button == "left" and state == "down" then
        if absoluteX >= minimapX and absoluteX <= minimapX + minimapSize and absoluteY >= minimapY and absoluteY <= minimapY + minimapSize then
            isDraggingMinimap = true
            offsetX, offsetY = absoluteX - minimapX, absoluteY - minimapY
        end
    elseif button == "left" and state == "up" then
        if isDraggingMinimap then
            isDraggingMinimap = false
            saveMinimapPosition()
        end
    end
end

function onClientCursorMove(_, _, absoluteX, absoluteY)
    if isDraggingMinimap and filterEnabled then
        minimapX, minimapY = absoluteX - offsetX, absoluteY - offsetY
    end
end

addEventHandler("onClientClick", root, onClientClick)
addEventHandler("onClientCursorMove", root, onClientCursorMove)

addEventHandler("onClientResourceStop", resourceRoot, saveMinimapPosition)



local isDraggingMoneyBar = false
local moneyBarX, moneyBarY = 0, 0
local offsetX, offsetY = 0, 0
local screenWidth, screenHeight = guiGetScreenSize()
local defaultMoneyBarX, defaultMoneyBarY = screenWidth - 220, 68

local renderData = {
    lastBarValue = {},
    barInterpolation = {},
    interpolationStartValue = {}
}

local function loadMoneyBarPosition()
    local file = xmlLoadFile("money_bar_position.xml")
    if file then
        local moneyNode = xmlFindChild(file, "moneyBar", 0)
        if moneyNode then
            moneyBarX = tonumber(xmlNodeGetAttribute(moneyNode, "x"))
            moneyBarY = tonumber(xmlNodeGetAttribute(moneyNode, "y"))
        end
        xmlUnloadFile(file)
    else
        moneyBarX = defaultMoneyBarX
        moneyBarY = defaultMoneyBarY
    end
end

local function saveMoneyBarPosition()
    local file = xmlCreateFile("money_bar_position.xml", "positions")
    if file then
        local moneyNode = xmlCreateChild(file, "moneyBar")
        xmlNodeSetAttribute(moneyNode, "x", moneyBarX)
        xmlNodeSetAttribute(moneyNode, "y", moneyBarY)
        xmlSaveFile(file)
        xmlUnloadFile(file)
    end
end

loadMoneyBarPosition()

function dxDrawMoneyBar(x, y, w, h, borderSize, activeColor, value, name, amountOfSegments, bgColor, borderColor, postGUI)
    bgColor = bgColor or tocolor(0, 0, 0, 100)
    borderColor = borderColor or tocolor(0, 0, 0, 140)
    amountOfSegments = 3

    w = math.ceil(w) - 2 * (amountOfSegments - 1)
    h = math.ceil(h)
    w = w / amountOfSegments

    if value > 100 then
        value = 100
    end

    local interpolation = false

    if name then
        if renderData.lastBarValue[name] then
            if renderData.lastBarValue[name] ~= value then
                renderData.barInterpolation[name] = getTickCount()
                renderData.interpolationStartValue[name] = renderData.lastBarValue[name]
                renderData.lastBarValue[name] = value
            end
        else
            renderData.lastBarValue[name] = value
        end

        if renderData.barInterpolation[name] then
            interpolation = interpolateBetween(renderData.interpolationStartValue[name], 0, 0, value, 0, 0, (getTickCount() - renderData.barInterpolation[name]) / 500, "OutQuad")
        end
    end

    if interpolation then
        value = interpolation
    end

    local progressPerSegment = 100 / amountOfSegments
    local remainingProgress = value % progressPerSegment
    local segmentsFull = math.floor(value / progressPerSegment)
    local segmentsInUse = math.ceil(value / progressPerSegment)

    local doubleBorder = borderSize * borderSize

    for i = 1, amountOfSegments do
        local x2 = x + (w + 2) * (i - 1)

        if borderSize ~= 0 then
            dxDrawRectangle(x2, y, w, borderSize, borderColor, postGUI)
            dxDrawRectangle(x2, y + h - borderSize, w, borderSize, borderColor, postGUI)
            dxDrawRectangle(x2, y + borderSize, borderSize, h - doubleBorder, borderColor, postGUI)
            dxDrawRectangle(x2 + w - borderSize, y + borderSize, borderSize, h - doubleBorder, borderColor, postGUI)
        end

        dxDrawRectangle(x2 + borderSize, y + borderSize, w - doubleBorder, h - doubleBorder, bgColor, postGUI)

        if i <= segmentsFull then
            dxDrawRectangle(x2 + borderSize, y + borderSize, w - doubleBorder, h - doubleBorder, activeColor, postGUI)
        elseif i == segmentsInUse and remainingProgress > 0 then
            dxDrawRectangle(x2 + borderSize, y + borderSize, (w - doubleBorder) / progressPerSegment * remainingProgress, h - doubleBorder, activeColor, postGUI)
        end
    end
end

function drawMoneyHUD()
    local playerMoney = getPlayerMoney()
    local font = "default-bold"  -- Válaszd ki a kívánt betűtípust
    local fontSize = 1.3  -- Betűméret
    local textColor = tocolor(131, 191, 139)  -- Pénz színe
    local bgColor = tocolor(99, 99, 99)  -- Háttér színe
    local text =  playerMoney.." $"

    local textWidth = dxGetTextWidth(text, fontSize, font)
    local textHeight = dxGetFontHeight(fontSize, font)
    if not getElementData(localPlayer, "hideHud") then

        dxDrawText(text, moneyBarX + 5+currentXOffset, moneyBarY + 5+currentYOffset, moneyBarX + textWidth + 5+currentXOffset, moneyBarY + textHeight + 5+currentYOffset, textColor, fontSize, font, "left", "top", false, false, false, false, false)    end
end

addEventHandler("onClientRender", root, drawMoneyHUD)

function getPlayerMoney()
    return getElementData(localPlayer, "money") or 0
end

function onClientClick(button, state, absoluteX, absoluteY)
    if button == "left" and state == "down" then
        if absoluteX >= moneyBarX and absoluteX <= moneyBarX + 200 and absoluteY >= moneyBarY and absoluteY <= moneyBarY + 20 then
            isDraggingMoneyBar = true
            offsetX, offsetY = absoluteX - moneyBarX, absoluteY - moneyBarY
        end
    elseif button == "left" and state == "up" then
        isDraggingMoneyBar = false
        saveMoneyBarPosition()
    end
end

function onClientCursorMove(_, _, absoluteX, absoluteY)
    if isDraggingMoneyBar and filterEnabled then
        moneyBarX, moneyBarY = absoluteX - offsetX, absoluteY - offsetY
    end
end

addEventHandler("onClientClick", root, onClientClick)
addEventHandler("onClientCursorMove", root, onClientCursorMove)

addEventHandler("onClientResourceStop", resourceRoot, saveMoneyBarPosition)




function setPlayerMoney(command, amount)
    local player = getLocalPlayer()
    local money = tonumber(amount)
    
    if money then
        if money < 0 then
            outputChatBox("A pénz nem lehet negatív!", 255, 0, 0)
        else
            setElementData(player, "money", money)
            outputChatBox("Pénz beállítva: $" .. money, 255, 255, 0)
        end
    else
        outputChatBox("Hibás pénz érték! Használat: /setmoney [összeg]", 255, 0, 0)
    end
end
addCommandHandler("setmoney", setPlayerMoney)

function addPlayerMoney(command, amount)
    local player = getLocalPlayer()
    local addAmount = tonumber(amount)
    
    if addAmount then
        if addAmount < 0 then
            outputChatBox("A hozzáadott pénz nem lehet negatív!", 255, 0, 0)
        else
            local currentMoney = getElementData(player, "money") or 0
            setElementData(player, "money", currentMoney + addAmount)
            outputChatBox("Pénz hozzáadva: $" .. addAmount, 255, 255, 0)
        end
    else
        outputChatBox("Hibás pénz érték! Használat: /addmoney [összeg]", 255, 0, 0)
    end
end
addCommandHandler("addmoney", addPlayerMoney)


----------------------------------------------------

local isDraggingFoodBar = false
local isDraggingDrinkBar = false
local foodBarX, foodBarY = 0, 0
local drinkBarX, drinkBarY = 0, 0
local offsetX, offsetY = 0, 0
local screenWidth, screenHeight = guiGetScreenSize()
local defaultFoodBarX, defaultFoodBarY = screenWidth - 220, 100
local defaultDrinkBarX, defaultDrinkBarY = screenWidth - 220, 132

local function loadHUDPosition()
    local file = xmlLoadFile("hud_position.xml")
    if file then
        local foodNode = xmlFindChild(file, "foodBar", 0)
        if foodNode then
            foodBarX = tonumber(xmlNodeGetAttribute(foodNode, "x"))
            foodBarY = tonumber(xmlNodeGetAttribute(foodNode, "y"))
        end
        local drinkNode = xmlFindChild(file, "drinkBar", 0)
        if drinkNode then
            drinkBarX = tonumber(xmlNodeGetAttribute(drinkNode, "x"))
            drinkBarY = tonumber(xmlNodeGetAttribute(drinkNode, "y"))
        end
        xmlUnloadFile(file)
    else
        foodBarX = defaultFoodBarX
        foodBarY = defaultFoodBarY
        drinkBarX = defaultDrinkBarX
        drinkBarY = defaultDrinkBarY
    end
end

local function saveMONEYPosition()
    local file = xmlCreateFile("hud_position.xml", "positions")
    if file then
        local foodNode = xmlCreateChild(file, "foodBar")
        xmlNodeSetAttribute(foodNode, "x", foodBarX)
        xmlNodeSetAttribute(foodNode, "y", foodBarY)
        local drinkNode = xmlCreateChild(file, "drinkBar")
        xmlNodeSetAttribute(drinkNode, "x", drinkBarX)
        xmlNodeSetAttribute(drinkNode, "y", drinkBarY)
        xmlSaveFile(file)
        xmlUnloadFile(file)
    end
end

loadHUDPosition()

function drawFoodDrinkHUD()
    local foodPercent = math.floor(getElementData(localPlayer, "food") or 0)
    local drinkPercent = math.floor(getElementData(localPlayer, "drink") or 0)
    
    local font = "default-bold"
    local fontSize = 1.5
    local textColor = tocolor(255, 255, 255)
    local bgColor = tocolor(99, 99, 99)
    local foodText = foodPercent .. " %"
    local drinkText = drinkPercent .. " %"
    
    local foodTextWidth = dxGetTextWidth(foodText, fontSize, font)
    local foodTextHeight = dxGetFontHeight(fontSize, font)
    local drinkTextWidth = dxGetTextWidth(drinkText, fontSize, font)
    local drinkTextHeight = dxGetFontHeight(fontSize, font)
    local iconSize = 24

    if not getElementData(localPlayer, "hideHud") then
        dxDrawImage(foodBarX + 5+currentXOffset, foodBarY + (iconSize - 24) / 2+currentYOffset, 24, 24, "food.png")
        dxDrawText(foodText, foodBarX + 35+currentXOffset, foodBarY + 5+currentYOffset, foodBarX + 35 + foodTextWidth+currentXOffset, foodBarY + 5 + foodTextHeight+currentYOffset, textColor, fontSize, font, "left", "top", false, false, false, false, false)

        dxDrawImage(drinkBarX + 5+currentXOffset, drinkBarY + (iconSize - 24) / 2+currentYOffset, 24, 24, "drink.png")
        dxDrawText(drinkText, drinkBarX + 35+currentXOffset, drinkBarY + 5+currentYOffset, drinkBarX + 35 + drinkTextWidth+currentXOffset, drinkBarY + 5 + drinkTextHeight+currentYOffset, textColor, fontSize, font, "left", "top", false, false, false, false, false)
    end
end

addEventHandler("onClientRender", root, drawFoodDrinkHUD)

function onClientClick(button, state, absoluteX, absoluteY)
    if button == "left" and state == "down" then
        if absoluteX >= foodBarX and absoluteX <= foodBarX + 200 and absoluteY >= foodBarY and absoluteY <= foodBarY + 20 then
            isDraggingFoodBar = true
            offsetX, offsetY = absoluteX - foodBarX, absoluteY - foodBarY
        elseif absoluteX >= drinkBarX and absoluteX <= drinkBarX + 200 and absoluteY >= drinkBarY and absoluteY <= drinkBarY + 20 then
            isDraggingDrinkBar = true
            offsetX, offsetY = absoluteX - drinkBarX, absoluteY - drinkBarY
        end
    elseif button == "left" and state == "up" then
        isDraggingFoodBar = false
        isDraggingDrinkBar = false
        saveMONEYPosition()
    end
end

function onClientCursorMove(_, _, absoluteX, absoluteY)
    if isDraggingFoodBar and filterEnabled then
        foodBarX, foodBarY = absoluteX - offsetX, absoluteY - offsetY
    elseif isDraggingDrinkBar and filterEnabled then
        drinkBarX, drinkBarY = absoluteX - offsetX, absoluteY - offsetY
    end
end

addEventHandler("onClientClick", root, onClientClick)
addEventHandler("onClientCursorMove", root, onClientCursorMove)

addEventHandler("onClientResourceStop", resourceRoot, saveMONEYPosition)


function resetHUD()
    foodBarX, foodBarY = defaultFoodBarX, defaultFoodBarY
    drinkBarX, drinkBarY = defaultDrinkBarX, defaultDrinkBarY
    healthBarX, healthBarY = defaultHealthBarX, defaultHealthBarY
    armorBarX, armorBarY = defaultArmorBarX, defaultArmorBarY
    minimapX, minimapY = defaultMinimapX, defaultMinimapY
    moneyBarX, moneyBarY = defaultMoneyBarX, defaultMoneyBarY
    saveMoneyBarPosition()
    saveMinimapPosition()
    saveBarPositions()
    saveMONEYPosition()
end

addCommandHandler("resethud", resetHUD)
