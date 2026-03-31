# BrivGemFarm_LevelUp
## Description:
This Addon will allow to set up maximum champion level settings for the Briv Gem Farm addon.
####
It performs the best using **x100** upgrade settings, although in some cases **x25** is preferred to prevent a champion from getting upgrades that would end up being detrimental to performance.  
####
If you have set upgrade settings to next upgrade mode, Briv may not achieve level 170 in time.  
It is recommended to set his min level to 80 instead at the expense of a small increase in stacks consumption during the first few jumps,
or to check **Level up Briv/Shandie to MinLevel first** under the **General Settings** section.
___
## Briv stacking:
####
During offline stacking, Briv gets more stacks as he is able to survive longer.
Sometimes it is undesirable to get many stacks because the simulation takes longer to complete.
Select a maximum level in the **Briv MinLevel before stacking** dropdown list under **General Settings**, so he won't receive as many health upgrades.
####
If you're setting Briv's min level to less than level 110 so that he gets Unnatural Haste but not Healing Phlo,  
set up **Briv MinLevel before stacking** under **General Settings** to a value under 110.  
Select 170 or more in MaxLevel so that after stacking, Briv will be leveled back to level 170 and gain his MetalBorn upgrade to reduce the amount of stacks lost after every jump.
___
## Settings:
### Menu
![menu](Images/menu.png)
####
Click on one of the menu items to display one or more of the sections below.
#### Min/Max Settings:
![settings](Images/brivgemfarm_levelup_settings.png)
####
Select Q/W/E/M to show saved game formations.
* **Show spoilers** (default: unchecked)   
Show unreleased champions in their respective seat (upgrades/levels may or may not be accurate before release date).
####
**For each champion:**  
* Min level is the minimum level for a champion after a reset before waiting for Shandie dash.  
* Max level is the maximum level for a champion when minimum leveling is complete or after 5s on z1.
___
#### Default Settings:
![settings](Images/default_settings.png)
####
* **Default min level** (default: 0)   
Default min level for champions with no default values.  
0 - Don't initially put the champion on the field |
1 - Put the champion on the field at level 1
####
* **Default max level** (default: 1)  
Default max level for champions with no default values.  
1 - Put the champion on the field and don't level them |
Last upgrade - Level up the champion until soft cap
___
#### General Settings:
![settings](Images/general_settings.png)
####
* **Level up Briv/Ellywick to MinLevel first** (default: checked)   
Level up Briv and Ellywick before other champions after resetting.  
This is useful when using the in-game next upgrade/double arrow setting as leveling champions that multipy the amount of quest items received has a side effect of causing the area to be completed before Briv gets his jump ability at level 80.
####
* **Skip DashWait after Min Leveling** (default: unchecked)  
Skip waiting for Shandie's dash being active after leveling champions to MinLevel. Useful if stacking really early in the run.
####
* **Maximum simultaneous F keys inputs during MinLevel** (default: 4)  
Maximum number of champions being leveled up during the intial leveling to minLevel. This can help if input lag causes champions to be overleveled during the initial leveling.
####
* **Delay (ms)** (default: 60)  
Delay between two consecutive sets of inputs.
####
* **MinLevel timeout (ms)** (default: 5000)  
Timeout before stopping the initial champion leveling. If set to 0, minimum leveling will be skipped.
####
* **z1 formation** (default: Q)  
Initial formation used in z1 or the Ellywait zone.
####
* **Low favor mode** (default: unchecked)  
Level up champions in ascending order of increasing cost.
####
**Click damage**
* **Level click damage to ? on the intial zone** (default: 1)  
Click damage will be leveled up to this level after resetting.
####
* **Spam click damage** (default: unchecked)  
Continously level up click damage. Can steal gold for levelling champs if favor is low.
####
* **Match highest area** (default: checked)   
Level click damage keeping up with the highest zone reach +100 levels.
####
**Briv**
* **Briv MinLevel before stacking (offline)** (default: 1300)  
Briv will be leveled up to this level before attempting to stack **offline**. After stacking is done, leveling will resume up to MaxLevel.
####
* **Briv MinLevel before stacking (online)** (default: 1300)  
Briv will be leveled up to this level before attempting to stack **online**. After stacking is done, leveling will resume up to MaxLevel.
####
* **Minimum area to reach before leveling Briv** (default: 1)  
Minimum area before starting to level up Briv (used to walk at the beginning if using Briv in E formation with the Wasting Haste feat).
####
* **Avoid Briv+Thellora jumping into a boss zone** (default: checked)  
Briv levelling wil be delayed if Thellora+Briv combined jumps would land on a boss zone. Useful when using FeatSwap with formations
that can only jump multiples of 5 zones.
####
* **Briv Min Leveling zones** (default: all)  
Only level up Briv if the current zone matches up the base area (1-50) set in those settings.
___
#### Fail Run Recovery Settings:
![settings](Images/fail_run_recovery_settings.png)
####
* **Level up champions to soft cap after failed conversion** (default: checked)   
Level up champions to soft cap after failed conversion if Briv has lower than 50 Sprint stacks.
####
* **Briv included** (default: unchecked)  
Level up Briv to soft cap after failed conversion if Briv has lower than 50 Sprint stacks.
___
#### GUI Settings:
![settings](Images/gui_settings.png)
####
Select your preferred language in the left dropdown.  Definitions are updated automatically as needed on launch.  
Hover on the text to see when the server file was updated for the last time.