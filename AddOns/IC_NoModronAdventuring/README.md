# No Modron Adventuring
## Description:
This is a slight modification of antilectual's [No Modron Adventuring](https://github.com/antilectual/IC_Addons/tree/main/IC_Addons/IC_NoModronAdventuring_Extra) addon.

Please see the original addon for instructions.

There are four additional features:

## Wall Resetting

You should see a new checkbox that starts with `Reset at Wall`. When turned on while the script is running - this will reset the adventure if you reach a zone and cannot progress further - your wall.

The script determines whether it's your wall simply by how long you've remained on your highest zone. This time is determined by the edit box in the setting. Default is 5 minutes (300,000 ms).

This does **NOT** supersede the original Reset Zone setting. If you reach the reset zone you've set then you will restart there instead of at your wall.

## Zone Alert Popup

The next checkbox added starts with `Popup after zone`. Simply put - it will send a message box popup when you have reached the input zone.

The idea behind this is that it will alert you when you've reached the completion zone of an adventure so you can swap over and start another. Helpful if you get caught up doing other things and forget to check on the game.

## Choose Specialisations

The third will determine whether the script chooses specialisations or not. I found that once I had a modron with automation I didn't need the script to do so any more - but I still needed the script to level champions because of a lack of familiars.

## Ignore Ultimates

The last feature includes a few checkboxes next to the `Fire Ultimates` setting which allows it to optionally ignore firing Selise / Havilar / NERDs ultimates - as doing so can sometimes be problematic.