desc: NextVariation
version: 1.0
author: Sauli Lehtinen / Demoji
about:
  Sets content of selected audio item to next variation found. Perfect for sound designers working with recordings containing multiple variations in single file.

  Uses built-in transient detection, which can be configured with action "Transient decetion sensitivity/threshold: Adjust..."

  Usage example:
  - Add audio file containing multiple variations of sound into timeline
  - Trim item to contain only first variation
  - Select item and run script
  - Item should now have next variation

  1.0 release highlights:
  - Supports multiple selected items at a same time
  - Uses separate tracks for item manipulation, so shouldn't mess with unselected track content
  - Loops through item content, if Loop source is enabled
  - Preserves item fade information
  - Smarter UI update disabling, which gives huge performance boost

  Known issues and workaround:
  - Built-in transient detection is not content aware and therefor you often have to choose between getting false positives or not finding the next variation. False positives are not really a big issue, since you can just run the script again (using keyboard shortcut strongly recommended). Sensitivity 35%, Threshold -24db settings seem to work fine (= a bit too false positive happy, but not missing anything) with most audio content. 
changelog:
  First public release

  newItemList = {}
  
  function SaveSelectedItems(t)
    local t = t or {}
    for i = 0, reaper.CountSelectedMediaItems(0)-1 do
      t[i+1] = reaper.GetSelectedMediaItem(0, i)
    end
    return t
  end
  
  function RestoreSelectedItems( items )
    for i, item in ipairs( newItemList ) do
      reaper.SetMediaItemSelected( item, true )
    end
  end
  
  
  
   
  -- Main function
  function Main()
    for i, item in ipairs(init_sel_items) do
       
     reaper.SelectAllMediaItems(0, false) 
      selectedItem = item
      itemLength = reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH" )
      itemPosition = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION" )
      itemFadeInCurve = reaper.GetMediaItemInfo_Value(selectedItem, "C_FADEINSHAPE" )
      itemFadeInLength = reaper.GetMediaItemInfo_Value(selectedItem, "D_FADEINLEN" )
      itemTrack = reaper.GetMediaItemTrack(selectedItem)
      reaper.SetMediaItemSelected(selectedItem, 1 )
      reaper.SetOnlyTrackSelected(itemTrack)
      reaper.SetMediaItemInfo_Value(selectedItem, "D_LENGTH", 1000)
      reaper.SetEditCurPos(itemPosition,0,0)
      
      -- Create new item for empty track to prevent other items messing up the process
      reaper.Main_OnCommand(40001,0) -- insert track
      newTrack=reaper.GetSelectedTrack(0, 0) 
      reaper.MoveMediaItemToTrack(selectedItem,newTrack)
      reaper.SetEditCurPos(itemPosition,0,0)
      reaper.Main_OnCommand(40375,0) -- move cursor to next transient
      reaper.Main_OnCommand(40012,0) -- split
      newItem=reaper.GetSelectedMediaItem(0,0)
      reaper.SetMediaItemInfo_Value(newItem, "D_LENGTH", itemLength)
      reaper.SetMediaItemInfo_Value(newItem, "D_POSITION", itemPosition)
      reaper.SetMediaItemInfo_Value(newItem, "C_FADEINSHAPE", itemFadeInCurve)
      reaper.SetMediaItemInfo_Value(newItem, "D_FADEINLEN", itemFadeInLength)
                  
      reaper.MoveMediaItemToTrack(newItem,itemTrack)
      reaper.DeleteTrack(newTrack)
      table.insert(newItemList, reaper.GetSelectedMediaItem(0, 0))
  
    end
  
  end
  
  
  -- INIT
  function Init()
  cursorPosition= reaper.GetCursorPosition()
    
    -- See if there is items selected
    count_sel_items = reaper.CountSelectedMediaItems(0)
    if count_sel_items == 0 then return false end
    reaper.PreventUIRefresh(1) 
    reaper.Undo_BeginBlock()
    init_sel_items = SaveSelectedItems()
    Main()
    RestoreSelectedItems(init_sel_items)
    reaper.Undo_EndBlock("NextVariation", -1)
    reaper.SetEditCurPos(cursorPosition,1,0)
    reaper.PreventUIRefresh(-1) 
    reaper.UpdateArrange()
  end
  function wait(seconds)
      local start = os.time()
      repeat until os.time() > start + seconds
  end
  if not preset_file_init then
    Init() 
  end
  
