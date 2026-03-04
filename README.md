# Chipi Lust - WoW Retail Addon

A World of Warcraft retail addon that plays sounds and displays images when your character gains fatigue debuffs.

## Author
Shelinka

## License
MIT

## Description
Chipi Lust monitors your character for fatigue-related debuffs and triggers audio-visual reactions. When the player gains any of the following debuffs **while alive and freshly applied (540-600 seconds remaining)**, the addon will play your selected sound and display your selected image:

- **Exhaustion** (Spell IDs: 57723, 390435)
- **Sated** (Spell ID: 57724)
- **Temporal Displacement** (Spell ID: 80354)
- **Hunter Pet Insanity** (Spell ID: 95809)
- **Hunter Pet Fatigued** (Spell IDs: 160455, 264689)

## Features
- ✅ Detects fatigue debuffs automatically when freshly applied
- ✅ Profile system - create multiple profiles with different settings
- ✅ Select specific sounds to play from your Media/Sounds folder
- ✅ Select specific images to display from your Media/Images folder
- ✅ Customizable image size and position on screen
- ✅ Test button to preview your settings
- ✅ Effects last up to 40 seconds or until you die
- ✅ Smart detection - won't trigger on login with existing debuffs
- ✅ Fully customizable via in-game options panel
- ✅ Only triggers when player is alive
- ✅ Prevents spam by tracking triggered debuffs

## Installation
1. Copy the entire "Chipi Lust" folder to your WoW AddOns directory:
   - `World of Warcraft/_retail_/Interface/AddOns/Chipi Lust`
2. Restart World of Warcraft
3. Enable the addon in the AddOns menu
4. Access settings through **Game Menu > Options > AddOns > Chipi Lust**

## Configuration
Open the options panel through the WoW AddOns menu (**Game Menu > Options > AddOns > Chipi Lust**) to configure:

### Profile Settings
- **Profile Selector**: Choose or create different profiles with unique settings
- **Enable Chipi Lust**: Toggle the addon on/off for the current profile

### Sound & Image Settings
- **Play Sounds**: Enable/disable sound playback
- **Select Sound**: Choose which sound file to play from your Media/Sounds folder
- **Show Images**: Enable/disable image display
- **Select Image**: Choose which image to display from your Media/Images folder

### Image Position & Size
- **Test Effect**: Preview your current settings without needing a debuff
- **Image Size**: Adjust the size of the displayed image (64-512 pixels)
- **Image Position**: Choose from 9 preset positions (Center, Top, Bottom, etc.)
- **X/Y Offset**: Fine-tune the exact position with offset sliders (-500 to +500)

## Media Files

### Sounds
Located in `Media/Sounds/`:
- `chipichipi_BL.mp3`
- `spinningsong.mp3`

You can select which sound to play in the addon options.

### Images
Located in `Media/Images/`:
- `chipi.tga`
- `spinningcat.tga`

You can select which image to display in the addon options.

## File Structure
```
Chipi Lust/
├── Chipi Lust.toc          (Addon manifest)
├── Core.lua                (Main addon logic)
├── Options.lua             (Settings panel)
└── Media/
    ├── Sounds/
    │   ├── chipichipi_BL.mp3
    │   └── spinningsong.mp3
    └── Images/
        ├── chipi.tga
        └── spinningcat.tga
```

## Adding Custom Media

### Adding Sounds
1. Place MP3 files in the `Media/Sounds/` folder
2. Edit `Core.lua` and add your sound to the `ChipiLust_AvailableSounds` table:
```lua
ChipiLust_AvailableSounds = {
    {name = "Chipi Chipi", file = "chipichipi_BL.mp3"},
    {name = "Spinning Song", file = "spinningsong.mp3"},
    {name = "Your Sound Name", file = "yoursound.mp3"},  -- Add this line
}
```
3. Reload UI and select your new sound in the addon options

### Adding Images
1. Place TGA or PNG files in the `Media/Images/` folder
2. Edit `Core.lua` and add your image to the `ChipiLust_AvailableImages` table:
```lua
ChipiLust_AvailableImages = {
    {name = "Chipi", file = "chipi.tga"},
    {name = "Spinning Cat", file = "spinningcat.tga"},
    {name = "Your Image Name", file = "yourimage.tga"},  -- Add this line
}
```
3. Reload UI and select your new image in the addon options

**Important Note About Animated Images:**
- TGA and PNG files do NOT support animation in World of Warcraft
- For animated textures, you would need to use BLP format with animation frames
- The current addon displays static images only
- If you want animated effects, consider using external tools to create animated BLP files

## Troubleshooting

**Sounds not playing?**
- Check that sound files are in `Media/Sounds/` folder
- Verify Master channel volume is turned up in WoW sound settings
- Check the "Play Sounds" option is enabled in addon settings
- Make sure you've selected a sound in the dropdown

**Images not showing?**
- Check that image files are in `Media/Images/` folder
- Verify the "Show Images" option is checked in addon settings
- Make sure you've selected an image in the dropdown
- Use the Test button to preview your settings
**Debuff not triggering?**
- Make sure the addon is enabled in addon settings
- Verify you're getting the correct debuff ID
- Check that you're alive when the debuff is applied
- **Important**: The addon only triggers when a debuff is freshly applied (540-600 seconds remaining)
- If you log in with an existing debuff (under 540 seconds), it will NOT trigger to prevent false activations

**Effect triggered on login?**
- This should no longer happen - the addon now checks debuff duration
- It only triggers for freshly applied debuffs (540-600 seconds remaining)
- Existing debuffs with less time remaining are ignored

## Version History
- **1.0.0** - Initial release

## Notes
- The addon only triggers when your character is alive and debuff is freshly applied
- Effects last up to 40 seconds or until you die
- Prevents triggering on login with existing debuffs (must have 540-600 seconds remaining)
- All settings are saved globally (account-wide) in profiles
- Each profile can have different sounds, images, sizes, and positions

---
For issues or suggestions, contact the author or check for updates.
