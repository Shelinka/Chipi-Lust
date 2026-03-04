local ADDON_NAME = "Chipi Lust"

-- Create the main options panel
local panel = CreateFrame("Frame", "ChipiLustOptionsPanel")
panel.name = ADDON_NAME

-- Create scroll frame for scrollable content
local scrollFrame = CreateFrame("ScrollFrame", "ChipiLustScrollFrame", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -32, 0)

-- Create scroll child (content container)
local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(400, 2000)  -- Large height to accommodate all content
scrollFrame:SetScrollChild(scrollChild)

-- Helper function to get current profile
local function GetCurrentProfile()
    if not ChipiLustDB or not ChipiLustDB.selectedProfile then
        return nil
    end
    return ChipiLustDB.profiles[ChipiLustDB.selectedProfile]
end

-- ===========================
-- Title and Description
-- ===========================
local title = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Chipi Lust Settings")

local subtitle = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
subtitle:SetJustifyH("LEFT")
subtitle:SetText("Configure sounds and images that play when you gain fatigue debuffs. Effects stop if you die within 40 seconds.")

-- ===========================
-- Profile Selection
-- ===========================
local profileLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
profileLabel:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
profileLabel:SetText("Profile:")

local profileDropdown = CreateFrame("Frame", "ChipiLustProfileDropdown", scrollChild, "UIDropDownMenuTemplate")
profileDropdown:SetPoint("TOPLEFT", profileLabel, "BOTTOMLEFT", -16, -4)

-- Initialize profile dropdown
local function InitializeProfileDropdown(self, level)
    if not ChipiLustDB or not ChipiLustDB.profiles then return end
    
    for profileName, _ in pairs(ChipiLustDB.profiles) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = profileName
        info.value = profileName
        info.func = function()
            ChipiLustDB.selectedProfile = profileName
            UIDropDownMenu_SetText(profileDropdown, profileName)
            -- Refresh panel to show new profile settings
            if panel.refresh then
                panel.refresh()
            end
            -- Update image frame settings
            if ChipiLust_UpdateImageSettings then
                ChipiLust_UpdateImageSettings()
            end
        end
        info.checked = (ChipiLustDB.selectedProfile == profileName)
        UIDropDownMenu_AddButton(info, level)
    end
    -- Add "New Profile" option
    local info = UIDropDownMenu_CreateInfo()
    info.text = "Create New Profile..."
    info.notCheckable = true
    info.func = function()
        StaticPopup_Show("CHIPILUST_NEW_PROFILE")
    end
    UIDropDownMenu_AddButton(info, level)
end

UIDropDownMenu_Initialize(profileDropdown, InitializeProfileDropdown)
UIDropDownMenu_SetWidth(profileDropdown, 150)
UIDropDownMenu_SetText(profileDropdown, ChipiLustDB and ChipiLustDB.selectedProfile or "Global")

-- New Profile Dialog
StaticPopupDialogs["CHIPILUST_NEW_PROFILE"] = {
    text = "Enter a name for the new profile:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self)
        local profileName = self.editBox:GetText()
        if profileName and profileName ~= "" then
            if not ChipiLustDB.profiles[profileName] then
                ChipiLustDB.profiles[profileName] = {
                    enabled = true,
                    playSounds = true,
                    showImages = true,
                    selectedSound = "chipichipi_BL.mp3",
                    selectedImage = "chipi.tga",
                    imageSize = 256,
                    imagePoint = "CENTER",
                    imageX = 0,
                    imageY = 0,
                }
                ChipiLustDB.selectedProfile = profileName
                UIDropDownMenu_SetText(profileDropdown, profileName)
                if panel.refresh then
                    panel.refresh()
                end
                -- Update image frame settings
                if ChipiLust_UpdateImageSettings then
                    ChipiLust_UpdateImageSettings()
                end
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- ===========================
-- Enable Addon Checkbox
-- ===========================
local enabledCheckbox = CreateFrame("CheckButton", "ChipiLustEnabledCheck", scrollChild, "InterfaceOptionsCheckButtonTemplate")
enabledCheckbox:SetPoint("TOPLEFT", profileDropdown, "BOTTOMLEFT", 16, -16)
enabledCheckbox.Text:SetText("Enable Chipi Lust")
enabledCheckbox.tooltipText = "Enable or disable the Chipi Lust addon for this profile"

enabledCheckbox:SetScript("OnClick", function(self)
    local profile = GetCurrentProfile()
    if profile then
        profile.enabled = self:GetChecked()
    end
end)

-- ===========================
-- Play Sounds Checkbox
-- ===========================
local soundsCheckbox = CreateFrame("CheckButton", "ChipiLustSoundsCheck", scrollChild, "InterfaceOptionsCheckButtonTemplate")
soundsCheckbox:SetPoint("TOPLEFT", enabledCheckbox, "BOTTOMLEFT", 0, -8)
soundsCheckbox.Text:SetText("Play Sounds")
soundsCheckbox.tooltipText = "Enable or disable sound playback when debuffs trigger"

soundsCheckbox:SetScript("OnClick", function(self)
    local profile = GetCurrentProfile()
    if profile then
        profile.playSounds = self:GetChecked()
    end
end)

-- ===========================
-- Sound Selection Dropdown
-- ===========================
local soundLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
soundLabel:SetPoint("TOPLEFT", soundsCheckbox, "BOTTOMLEFT", 20, -12)
soundLabel:SetText("Select Sound:")

local soundDropdown = CreateFrame("Frame", "ChipiLustSoundDropdown", scrollChild, "UIDropDownMenuTemplate")
soundDropdown:SetPoint("TOPLEFT", soundLabel, "BOTTOMLEFT", -16, -4)

local function InitializeSoundDropdown(self, level)
    if not ChipiLust_AvailableSounds then return end
    
    for _, soundData in ipairs(ChipiLust_AvailableSounds) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = soundData.name
        info.value = soundData.file
        info.func = function()
            local profile = GetCurrentProfile()
            if profile then
                profile.selectedSound = soundData.file
                UIDropDownMenu_SetText(soundDropdown, soundData.name)
            end
        end
        local profile = GetCurrentProfile()
        info.checked = (profile and profile.selectedSound == soundData.file)
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_Initialize(soundDropdown, InitializeSoundDropdown)
UIDropDownMenu_SetWidth(soundDropdown, 150)

-- ===========================
-- Show Images Checkbox
-- ===========================
local imagesCheckbox = CreateFrame("CheckButton", "ChipiLustImagesCheck", scrollChild, "InterfaceOptionsCheckButtonTemplate")
imagesCheckbox:SetPoint("TOPLEFT", soundDropdown, "BOTTOMLEFT", 16, -8)
imagesCheckbox.Text:SetText("Show Images")
imagesCheckbox.tooltipText = "Enable or disable image display when debuffs trigger"

imagesCheckbox:SetScript("OnClick", function(self)
    local profile = GetCurrentProfile()
    if profile then
        profile.showImages = self:GetChecked()
    end
end)

-- ===========================
-- Image Selection Dropdown
-- ===========================
local imageLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
imageLabel:SetPoint("TOPLEFT", imagesCheckbox, "BOTTOMLEFT", 20, -12)
imageLabel:SetText("Select Image:")

local imageDropdown = CreateFrame("Frame", "ChipiLustImageDropdown", scrollChild, "UIDropDownMenuTemplate")
imageDropdown:SetPoint("TOPLEFT", imageLabel, "BOTTOMLEFT", -16, -4)

local function InitializeImageDropdown(self, level)
    if not ChipiLust_AvailableImages then return end
    
    for _, imageData in ipairs(ChipiLust_AvailableImages) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = imageData.name
        info.value = imageData.file
        info.func = function()
            local profile = GetCurrentProfile()
            if profile then
                profile.selectedImage = imageData.file
                UIDropDownMenu_SetText(imageDropdown, imageData.name)
            end
        end
        local profile = GetCurrentProfile()
        info.checked = (profile and profile.selectedImage == imageData.file)
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_Initialize(imageDropdown, InitializeImageDropdown)
UIDropDownMenu_SetWidth(imageDropdown, 150)

-- ===========================
-- Test Button
-- ===========================
local testButton = CreateFrame("Button", "ChipiLustTestButton", scrollChild, "UIPanelButtonTemplate")
testButton:SetPoint("TOPLEFT", imageDropdown, "BOTTOMLEFT", 16, -16)
testButton:SetSize(120, 25)
testButton:SetText("Test Effect")
testButton:SetScript("OnClick", function()
    if ChipiLust_TestEffect then
        ChipiLust_TestEffect()
    else
        print("Test function not available yet. Try reloading UI.")
    end
end)

local testButtonLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
testButtonLabel:SetPoint("LEFT", testButton, "RIGHT", 8, 0)
testButtonLabel:SetText("Preview current settings")

-- ===========================
-- Image Size Slider
-- ===========================
local sizeLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
sizeLabel:SetPoint("TOPLEFT", testButton, "BOTTOMLEFT", 0, -20)
sizeLabel:SetText("Image Size:")

local sizeSlider = CreateFrame("Slider", "ChipiLustSizeSlider", scrollChild, "OptionsSliderTemplate")
sizeSlider:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 8, -8)
sizeSlider:SetMinMaxValues(64, 512)
sizeSlider:SetValueStep(16)
sizeSlider:SetObeyStepOnDrag(true)
sizeSlider:SetWidth(200)

_G[sizeSlider:GetName() .. "Low"]:SetText("64")
_G[sizeSlider:GetName() .. "High"]:SetText("512")
_G[sizeSlider:GetName() .. "Text"]:SetText("Image Size")

sizeSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    local profile = GetCurrentProfile()
    if profile then
        profile.imageSize = value
        _G[self:GetName() .. "Text"]:SetText("Image Size: " .. value .. "px")
        -- Update image frame in real-time
        if ChipiLust_UpdateImageSettings then
            ChipiLust_UpdateImageSettings()
        end
    end
end)

-- ===========================
-- Image Position
-- ===========================
local positionLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
positionLabel:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", -8, -20)
positionLabel:SetText("Image Position:")

-- Position preset dropdown
local positionDropdown = CreateFrame("Frame", "ChipiLustPositionDropdown", scrollChild, "UIDropDownMenuTemplate")
positionDropdown:SetPoint("TOPLEFT", positionLabel, "BOTTOMLEFT", -16, -4)

local POSITION_PRESETS = {
    {name = "Center", point = "CENTER"},
    {name = "Top", point = "TOP"},
    {name = "Bottom", point = "BOTTOM"},
    {name = "Left", point = "LEFT"},
    {name = "Right", point = "RIGHT"},
    {name = "Top Left", point = "TOPLEFT"},
    {name = "Top Right", point = "TOPRIGHT"},
    {name = "Bottom Left", point = "BOTTOMLEFT"},
    {name = "Bottom Right", point = "BOTTOMRIGHT"},
}

local function InitializePositionDropdown(self, level)
    for _, preset in ipairs(POSITION_PRESETS) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = preset.name
        info.value = preset.point
        info.func = function()
            local profile = GetCurrentProfile()
            if profile then
                profile.imagePoint = preset.point
                UIDropDownMenu_SetText(positionDropdown, preset.name)
                -- Update image frame in real-time
                if ChipiLust_UpdateImageSettings then
                    ChipiLust_UpdateImageSettings()
                end
            end
        end
        local profile = GetCurrentProfile()
        info.checked = (profile and profile.imagePoint == preset.point)
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_Initialize(positionDropdown, InitializePositionDropdown)
UIDropDownMenu_SetWidth(positionDropdown, 150)

-- X Offset slider
local xOffsetLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
xOffsetLabel:SetPoint("TOPLEFT", positionDropdown, "BOTTOMLEFT", 16, -8)
xOffsetLabel:SetText("X Offset:")

local xOffsetSlider = CreateFrame("Slider", "ChipiLustXOffsetSlider", scrollChild, "OptionsSliderTemplate")
xOffsetSlider:SetPoint("TOPLEFT", xOffsetLabel, "BOTTOMLEFT", 8, -8)
xOffsetSlider:SetMinMaxValues(-500, 500)
xOffsetSlider:SetValueStep(10)
xOffsetSlider:SetObeyStepOnDrag(true)
xOffsetSlider:SetWidth(200)

_G[xOffsetSlider:GetName() .. "Low"]:SetText("-500")
_G[xOffsetSlider:GetName() .. "High"]:SetText("500")
_G[xOffsetSlider:GetName() .. "Text"]:SetText("X Offset")

xOffsetSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    local profile = GetCurrentProfile()
    if profile then
        profile.imageX = value
        _G[self:GetName() .. "Text"]:SetText("X Offset: " .. value)
        -- Update image frame in real-time
        if ChipiLust_UpdateImageSettings then
            ChipiLust_UpdateImageSettings()
        end
    end
end)

-- Y Offset slider
local yOffsetLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
yOffsetLabel:SetPoint("TOPLEFT", xOffsetSlider, "BOTTOMLEFT", -8, -20)
yOffsetLabel:SetText("Y Offset:")

local yOffsetSlider = CreateFrame("Slider", "ChipiLustYOffsetSlider", scrollChild, "OptionsSliderTemplate")
yOffsetSlider:SetPoint("TOPLEFT", yOffsetLabel, "BOTTOMLEFT", 8, -8)
yOffsetSlider:SetMinMaxValues(-500, 500)
yOffsetSlider:SetValueStep(10)
yOffsetSlider:SetObeyStepOnDrag(true)
yOffsetSlider:SetWidth(200)

_G[yOffsetSlider:GetName() .. "Low"]:SetText("-500")
_G[yOffsetSlider:GetName() .. "High"]:SetText("500")
_G[yOffsetSlider:GetName() .. "Text"]:SetText("Y Offset")

yOffsetSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    local profile = GetCurrentProfile()
    if profile then
        profile.imageY = value
        _G[self:GetName() .. "Text"]:SetText("Y Offset: " .. value)
        -- Update image frame in real-time
        if ChipiLust_UpdateImageSettings then
            ChipiLust_UpdateImageSettings()
        end
    end
end)

-- ===========================
-- Help Text
-- ===========================
local helpText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
helpText:SetPoint("TOPLEFT", yOffsetSlider, "BOTTOMLEFT", -8, -24)
helpText:SetWidth(500)
helpText:SetJustifyH("LEFT")
helpText:SetText("Triggers on: Exhaustion, Sated, Temporal Displacement, Hunter Pet Insanity, Hunter Pet Fatigued\n\nEffects play for up to 40 seconds or until you die.")

-- ===========================
-- Refresh Function
-- ===========================
local function RefreshPanel()
    if not ChipiLustDB then return end
    
    local profile = GetCurrentProfile()
    if not profile then return end
    
    -- Update profile dropdown
    UIDropDownMenu_SetText(profileDropdown, ChipiLustDB.selectedProfile or "Global")
    
    -- Update checkboxes
    enabledCheckbox:SetChecked(profile.enabled or false)
    soundsCheckbox:SetChecked(profile.playSounds or false)
    imagesCheckbox:SetChecked(profile.showImages or false)
    
    -- Update sound dropdown
    local selectedSoundName = "Unknown"
    if ChipiLust_AvailableSounds then
        for _, soundData in ipairs(ChipiLust_AvailableSounds) do
            if soundData.file == profile.selectedSound then
                selectedSoundName = soundData.name
                break
            end
        end
    end
    UIDropDownMenu_SetText(soundDropdown, selectedSoundName)
    
    -- Update image dropdown
    local selectedImageName = "Unknown"
    if ChipiLust_AvailableImages then
        for _, imageData in ipairs(ChipiLust_AvailableImages) do
            if imageData.file == profile.selectedImage then
                selectedImageName = imageData.name
                break
            end
        end
    end
    UIDropDownMenu_SetText(imageDropdown, selectedImageName)
    
    -- Update size slider
    local size = profile.imageSize or 256
    sizeSlider:SetValue(size)
    _G[sizeSlider:GetName() .. "Text"]:SetText("Image Size: " .. size .. "px")
    
    -- Update position dropdown
    local positionName = "Center"
    for _, preset in ipairs(POSITION_PRESETS) do
        if preset.point == (profile.imagePoint or "CENTER") then
            positionName = preset.name
            break
        end
    end
    UIDropDownMenu_SetText(positionDropdown, positionName)
    
    -- Update X offset slider
    local xOffset = profile.imageX or 0
    xOffsetSlider:SetValue(xOffset)
    _G[xOffsetSlider:GetName() .. "Text"]:SetText("X Offset: " .. xOffset)
    
    -- Update Y offset slider
    local yOffset = profile.imageY or 0
    yOffsetSlider:SetValue(yOffset)
    _G[yOffsetSlider:GetName() .. "Text"]:SetText("Y Offset: " .. yOffset)
end

panel.refresh = RefreshPanel
panel.okay = function() end
panel.cancel = function() RefreshPanel() end
panel.default = function()
    local profile = GetCurrentProfile()
    if profile then
        profile.enabled = true
        profile.playSounds = true
        profile.showImages = true
        profile.selectedSound = "chipichipi_BL.mp3"
        profile.selectedImage = "chipi.tga"
        profile.imageSize = 256
        profile.imagePoint = "CENTER"
        profile.imageX = 0
        profile.imageY = 0
        RefreshPanel()
    end
end

-- ===========================
-- Register Panel with Interface Options
-- ===========================
-- Modern API (Dragonflight+)
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
    Settings.RegisterAddOnCategory(category)
-- Legacy API (Pre-Dragonflight)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end

print("Chipi Lust loaded! Access settings in Game Menu > Options > AddOns > Chipi Lust")
