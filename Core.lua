local ADDON_NAME = "Chipi Lust"
local ADDON_VERSION = "1.0.0"

-- Debuff IDs to watch for
local FATIGUE_DEBUFFS = {
    [57723] = true,   -- Exhaustion
    [390435] = true,  -- Exhaustion (alt)
    [57724] = true,   -- Sated
    [80354] = true,   -- Temporal Displacement
    [95809] = true,   -- Hunter Pet Insanity
    [160455] = true,  -- Hunter Pet Fatigued
    [264689] = true,  -- Hunter Pet Fatigued (alt)
}

local FATIGUE_DEBUFF_IDS = {
    57723,
    390435,
    57724,
    80354,
    95809,
    160455,
    264689,
}

local function NormalizeFatigueSpellId(spellId)
    if spellId == nil then
        return nil
    end

    for i = 1, #FATIGUE_DEBUFF_IDS do
        local knownSpellId = FATIGUE_DEBUFF_IDS[i]
        if spellId == knownSpellId then
            return knownSpellId
        end
    end

    return nil
end

-- Available sound files in Media/Sounds folder
ChipiLust_AvailableSounds = {
    {name = "Chipi Chipi", file = "chipichipi_BL.mp3"},
    {name = "Spinning Song", file = "spinningsong.mp3"},
}

-- Available image files in Media/Images folder
ChipiLust_AvailableImages = {
    {name = "Chipi", file = "chipi.tga"},
    {name = "Spinning Cat", file = "spinningcat.tga"},
}

-- Frame for event handling
local ChipiLust = CreateFrame("Frame")
ChipiLust:RegisterEvent("UNIT_AURA")
ChipiLust:RegisterEvent("PLAYER_ALIVE")
ChipiLust:RegisterEvent("PLAYER_DEAD")

-- Debuffs we've already triggered for (to avoid spam)
local triggered_debuffs = {}

-- Track animation state
local animationTimer = nil
local currentFrameIndex = 0
local countdownTicker = nil
local countdownEndTime = nil

-- Track when effect was triggered (for 40 second death check)
local effectTriggeredTime = nil
local currentSoundHandle = nil
local hideImageTimer = nil

-- Animation configuration (frames per row, total frames per image)
-- Users can set these in their profiles
local animationConfig = {
    ["chipi.tga"] = {framesPerRow = 2, rows = 2, totalFrames = 4, speed = 0.1},
    ["spinningcat.tga"] = {framesPerRow = 4, rows = 8, totalFrames = 32, speed = 0.1},
}

-- Create frame for displaying images
local ImageFrame = CreateFrame("Frame", "ChipiLustImageFrame", UIParent)
ImageFrame:SetSize(256, 256)
ImageFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
ImageFrame:Hide()

local ImageTexture = ImageFrame:CreateTexture(nil, "ARTWORK")
ImageTexture:SetAllPoints()
ImageFrame.texture = ImageTexture

local TimerText = ImageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
TimerText:SetPoint("TOP", ImageFrame, "BOTTOM", 0, -8)
TimerText:SetText("")
TimerText:Hide()
ImageFrame.timerText = TimerText

local function StopCountdown()
    if countdownTicker then
        countdownTicker:Cancel()
        countdownTicker = nil
    end
    countdownEndTime = nil
    ImageFrame.timerText:Hide()
end

local function StartCountdown(duration)
    StopCountdown()
    duration = tonumber(duration) or 40
    countdownEndTime = GetTime() + duration
    ImageFrame.timerText:SetText(tostring(math.ceil(duration)))
    ImageFrame.timerText:Show()

    countdownTicker = C_Timer.NewTicker(0.1, function()
        local remaining = countdownEndTime - GetTime()
        if remaining <= 0 then
            ImageFrame.timerText:SetText("0")
            StopCountdown()
            return
        end
        ImageFrame.timerText:SetText(tostring(math.ceil(remaining)))
    end)
end

-- Function to set texture with specific frame
local function SetTextureFrame(texturePath, frameIndex, config)
    if not config or config.totalFrames <= 1 then
        -- Simple single image, no animation
        ImageFrame.texture:SetTexture(texturePath)
        ImageFrame.texture:SetTexCoord(0, 1, 0, 1)
        return
    end
    
    -- Calculate frame position in grid
    local framesPerRow = config.framesPerRow or 2
    local rows = config.rows or math.ceil(config.totalFrames / framesPerRow)
    local frameWidth = 1 / framesPerRow
    local frameHeight = 1 / rows
    
    local row = math.floor(frameIndex / framesPerRow)
    local col = frameIndex % framesPerRow
    
    local left = col * frameWidth
    local right = left + frameWidth
    local top = row * frameHeight
    local bottom = top + frameHeight
    
    ImageFrame.texture:SetTexture(texturePath)
    ImageFrame.texture:SetTexCoord(left, right, top, bottom)
end

-- Function to start animation
local function StartAnimation(texturePath, config)
    if animationTimer then
        animationTimer:Cancel()
        animationTimer = nil
    end
    
    if not config or config.totalFrames <= 1 then
        -- No animation needed
        SetTextureFrame(texturePath, 0, config)
        return
    end
    
    currentFrameIndex = 0
    local animationSpeed = config.speed or 0.1
    
    -- Create repeating timer for frame animation
    animationTimer = C_Timer.NewTicker(animationSpeed, function()
        if currentFrameIndex >= config.totalFrames then
            currentFrameIndex = 0
        end
        SetTextureFrame(texturePath, currentFrameIndex, config)
        currentFrameIndex = currentFrameIndex + 1
    end)
end

-- Function to stop animation
local function StopAnimation()
    if animationTimer then
        animationTimer:Cancel()
        animationTimer = nil
    end
    currentFrameIndex = 0
end

-- Get current profile
local function GetCurrentProfile()
    if not ChipiLustDB or not ChipiLustDB.selectedProfile then
        return nil
    end
    return ChipiLustDB.profiles[ChipiLustDB.selectedProfile]
end

-- Function to update image frame size and position
local function UpdateImageFrameSettings()
    local profile = GetCurrentProfile()
    if not profile then return end
    
    -- Apply size
    local size = profile.imageSize or 256
    ImageFrame:SetSize(size, size)
    
    -- Apply position
    ImageFrame:ClearAllPoints()
    local point = profile.imagePoint or "CENTER"
    local xOffset = profile.imageX or 0
    local yOffset = profile.imageY or 0
    ImageFrame:SetPoint(point, UIParent, point, xOffset, yOffset)

    local timerSize = profile.timerSize or 24
    local fontPath, _, fontFlags = TimerText:GetFont()
    if fontPath then
        TimerText:SetFont(fontPath, timerSize, fontFlags)
    end
end

-- Stop current effects
local function StopEffects()
    -- Hide image
    ImageFrame:Hide()
    
    -- Stop animation
    StopAnimation()
    StopCountdown()
    
    -- Cancel hide timer if exists
    if hideImageTimer then
        hideImageTimer:Cancel()
        hideImageTimer = nil
    end
    
    -- Stop sound (WoW doesn't provide direct sound stopping, but we mark it)
    currentSoundHandle = nil
    effectTriggeredTime = nil
end

-- Function to trigger the reaction
local function TriggerFatigueReaction()
    local profile = GetCurrentProfile()
    if not profile or not profile.enabled then return end
    
    -- Record when effect was triggered
    effectTriggeredTime = GetTime()
    
    -- Play selected sound
    if profile.playSounds and profile.selectedSound then
        local soundPath = "Interface\\AddOns\\Chipi Lust\\Media\\Sounds\\" .. profile.selectedSound
        local willPlay, soundHandle = PlaySoundFile(soundPath, "Master")
        if willPlay then
            currentSoundHandle = soundHandle
        end
    end
    
    -- Show selected image
    if profile.showImages and profile.selectedImage then
        if hideImageTimer then
            hideImageTimer:Cancel()
            hideImageTimer = nil
        end

        -- Update frame settings before showing
        UpdateImageFrameSettings()
        
        local imagePath = "Interface\\AddOns\\Chipi Lust\\Media\\Images\\" .. profile.selectedImage
        
        -- Get animation config for this image
        local config = animationConfig[profile.selectedImage]
        
        -- Start animation or set static texture
        StartAnimation(imagePath, config)
        ImageFrame:Show()

        if profile.showTimer ~= false then
            StartCountdown(40)
        else
            StopCountdown()
        end
        
        -- Auto-hide image after 40 seconds
        hideImageTimer = C_Timer.NewTimer(40, function()
            ImageFrame:Hide()
            StopAnimation()
            StopCountdown()
            effectTriggeredTime = nil
            currentSoundHandle = nil
            hideImageTimer = nil
        end)
    end
end

-- Global test function (called from options panel)
function ChipiLust_TestEffect()
    TriggerFatigueReaction()
end

-- Global function to update image frame settings (called from options panel)
function ChipiLust_UpdateImageSettings()
    UpdateImageFrameSettings()
end

-- Function to check for fatigue debuffs
local function CheckForFatigueDebuff(unit)
    if unit ~= "player" then return end
    
    -- Check if player is alive
    if UnitIsDead("player") then return end
    
    -- Track active fatigue debuffs so we can clear trigger state only when they expire/remove
    local activeFatigueDebuffs = {}

    -- Check auras for fatigue debuffs
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HARMFUL")
        
        if not auraData then break end
        
        local spellId = auraData.spellId
        local fatigueSpellId = NormalizeFatigueSpellId(spellId)
        
        if fatigueSpellId and FATIGUE_DEBUFFS[fatigueSpellId] then
            activeFatigueDebuffs[fatigueSpellId] = true

            -- Check if this is one of our target debuffs and we haven't already triggered
            if not triggered_debuffs[fatigueSpellId] then
                -- Check debuff duration to prevent triggering on login with existing debuff
                -- Only trigger if debuff has 598-600 seconds remaining (freshly applied)
                local expirationTime = tonumber(auraData.expirationTime) or 0
                local remainingTime = expirationTime - GetTime()

                -- Only trigger if debuff is very fresh (between 598 and 600 seconds remaining)
                if remainingTime >= 598 and remainingTime <= 600 then
                    triggered_debuffs[fatigueSpellId] = true
                    TriggerFatigueReaction()
                end
            end
        end
    end

    -- Clear trigger state only for fatigue debuffs that are no longer active
    for debuffSpellId in pairs(triggered_debuffs) do
        if not activeFatigueDebuffs[debuffSpellId] then
            triggered_debuffs[debuffSpellId] = nil
        end
    end
end

-- Handle player death
local function OnPlayerDead()
    -- If effect was triggered within last 40 seconds, stop it
    if effectTriggeredTime and (GetTime() - effectTriggeredTime) <= 40 then
        StopEffects()
    end
end

-- Initialize database on load
local function OnAddonLoaded(self, event, addonName)
    if addonName ~= ADDON_NAME then return end
    
    -- Set up default settings if not already present
    if not ChipiLustDB then
        ChipiLustDB = {
            selectedProfile = "Global",
            profiles = {
                ["Global"] = {
                    enabled = true,
                    playSounds = true,
                    showImages = true,
                    showTimer = true,
                    timerSize = 24,
                    selectedSound = "chipichipi_BL.mp3",
                    selectedImage = "chipi.tga",
                    imageSize = 256,
                    imagePoint = "CENTER",
                    imageX = 0,
                    imageY = 0,
                }
            }
        }
    end
    
    -- Ensure profile structure exists (for upgrades from old version)
    if not ChipiLustDB.profiles then
        ChipiLustDB.profiles = {
            ["Global"] = {
                enabled = ChipiLustDB.enabled or true,
                playSounds = ChipiLustDB.playSounds or true,
                showImages = ChipiLustDB.showImages or true,
                showTimer = true,
                timerSize = 24,
                selectedSound = "chipichipi_BL.mp3",
                selectedImage = "chipi.tga",
                imageSize = 256,
                imagePoint = "CENTER",
                imageX = 0,
                imageY = 0,
            }
        }
        ChipiLustDB.selectedProfile = "Global"
    end
    
    -- Ensure all profiles have size/position settings (for upgrades)
    for profileName, profile in pairs(ChipiLustDB.profiles) do
        if not profile.imageSize then profile.imageSize = 256 end
        if not profile.imagePoint then profile.imagePoint = "CENTER" end
        if not profile.imageX then profile.imageX = 0 end
        if not profile.imageY then profile.imageY = 0 end
        if profile.showTimer == nil then profile.showTimer = true end
        if not profile.timerSize then profile.timerSize = 24 end
    end
    
    -- Ensure selected profile exists
    if not ChipiLustDB.selectedProfile then
        ChipiLustDB.selectedProfile = "Global"
    end
    
    -- Ensure the selected profile exists in profiles table
    if not ChipiLustDB.profiles[ChipiLustDB.selectedProfile] then
        ChipiLustDB.profiles["Global"] = {
            enabled = true,
            playSounds = true,
            showImages = true,
            showTimer = true,
            timerSize = 24,
            selectedSound = "chipichipi_BL.mp3",
            selectedImage = "chipi.tga",
            imageSize = 256,
            imagePoint = "CENTER",
            imageX = 0,
            imageY = 0,
        }
        ChipiLustDB.selectedProfile = "Global"
    end
    
    -- Apply initial image frame settings
    UpdateImageFrameSettings()
    
    print("Chipi Lust " .. ADDON_VERSION .. " loaded!")
end

-- Event handler
ChipiLust:RegisterEvent("ADDON_LOADED")
ChipiLust:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(self, event, ...)
    elseif event == "UNIT_AURA" then
        local unit = ...
        CheckForFatigueDebuff(unit)
    elseif event == "PLAYER_ALIVE" then
        triggered_debuffs = {}
        StopEffects()
    elseif event == "PLAYER_DEAD" then
        OnPlayerDead()
    end
end)
