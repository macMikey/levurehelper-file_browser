script "File Browser DataView Tree Behavior" with behavior "DataView Tree Behavior"
local sRootFolder

/**
Summary: Sets the root folder.

Parameters:
pFolder: The root folder path.

Description:
The contents of the root folder will be displayed in the file browser
when `RenderView` is called.

Example:
answer folder "Select folder to display:"
if it is not empty then
  set the dvRootFolder of group "FileBrowser" to it
end if
*/
setProp dvRootFolder pFolder
  put pFolder into sRootFolder

  _displayFolderInDataView sRootFolder
end dvRootFolder



/**
Summary: Returns the root folder.

Description:
The current root folder will be returned

Example:
get the dvRootFolder of group "FileBrowser"
*/
getProp dvRootFolder
  return sRootFolder
end dvRootFolder




/**
Summary: Sets whether all nodes are expanded when the list is drawn.

Parameters:
pBoolean: true means expand every node, false means collapse every node.

Description:
Property takes effect when the list is drawn.  Individual folders can be expanded or contracted with ToggleRow[pRow]

*/
setProp expandAllNodes pBoolean
  if pBoolean is not in "true,false" then return "Error: expected 'true' or 'false'"

  set the viewProp["expand all nodes"] of me to pBoolean
  return empty
end expandAllNodes



/**
Summary: Limits the display to files with the extensions specified.

Parameters:
pExtensionList: a comma-delimited list of allowed file extensions (suffixes).

Description:
Multiple extensions can be included in the list, separated by commas, with or without spaces

Examples:
set the allowedExtensions to ".pdf,.PDF"
set the allowedExtensions to ".txt"
set the allowedExtensions to "   .gif   , .gif,.jpg"
set the allowedExtensions to ".*" # allows any extension
set the allowedExtensions to empty #don't allow any extensions

*/
setProp allowedExtensions pList
  put pList into tList
  replace space with empty in tList
  set the viewProp["allowed extensions"] of me to tList
  return empty
end allowedExtensions



/**
Summary: Returns the full path to the file or folder associated with pRow.

Returns: Path
*/
getProp dvPathOfRow[pRow]
  return sRootFolder & "/" & GetValueForKeyInRow(pRow, "relative path")
end dvPathOfRow


command DataForNode pNodeA, pRow, @rDataA, @rTemplate
  put pNodeA into rDataA
  put pNodeA["type"] into rTemplate
end DataForNode


command ToggleRow pRow
  if the dvRowIsExpanded[pRow] of me then
    set the dvRowChildren[pRow] of me to empty
    SetRowIsExpanded pRow, empty, false
  else
    local tFolder, tNodesA

    put sRootFolder & "/" & GetValueForKeyInRow(pRow, "relative path") into tFolder
    put _createNodesForFolder(tFolder) into tNodesA
    set the dvRowChildren[pRow] of me to tNodesA
    SetRowIsExpanded pRow, empty, true
  end if
end ToggleRow


/**
Summary: Populate tree with level 1 contents of folder.

Parameters:
pFolder: The folder to display.

Returns: nothing
*/
private command _displayFolderInDataView pFolder
  local tFolders
  local tNodesA

  put pFolder into sRootFolder

  put _createNodesForFolder(pFolder) into tNodesA

  lock screen
  set the dvTree of me to tNodesA
  
  if the viewProp["expand all nodes"] of me then
    put 1 into i
    repeat until i> numberOfRows()
      put getValueForKeyInRow(i,"is leaf") into isLeaf
      if not isLeaf then toggleRow(i) #by default nodes are not expanded, so expand them
      add 1 to i
    end repeat
  end if #the viewProp["expand all nodes"] of me
end _displayFolderInDataView


private function _createNodesForFolder pFolder
  local tRelativeFolder, tFolders, tFiles, tNodeA, tIndex, tNodesA

  put pFolder into tRelativeFolder
  replace sRootFolder with empty in tRelativeFolder
  delete char 1 of tRelativeFolder # strip leading "/"
  if tRelativeFolder is not empty then put "/" after tRelativeFolder

  put _getFoldersInFolder(pFolder) into tFolders
  put _getFilesInFolder(pFolder) into tFiles

  repeat for each line tFolder in tFolders
    put empty into tNodeA
    put tFolder into tNodeA["filename"]
    put tRelativeFolder & tFolder into tNodeA["relative path"]
    put _hashForFile(tNodeA["relative path"]) into tNodeA["id"]
    put "folder" into tNodeA["type"]
    put false into tNodeA["expanded"]
    put false into tNodeA["is leaf"]
    put empty into tNodeA["children"]

    add 1 to tIndex
    put tNodeA into tNodesA[tIndex]
  end repeat

  repeat for each line tFile in tFiles
    put empty into tNodeA
    put tFile into tNodeA["filename"]
    put tRelativeFolder & tFile into tNodeA["relative path"]
    put _hashForFile(tNodeA["relative path"]) into tNodeA["id"]
    put "file" into tNodeA["type"]
    put true into tNodeA["is leaf"]

    add 1 to tIndex
    put tNodeA into tNodesA[tIndex]
  end repeat

  return tNodesA
end _createNodesForFolder


private function _getFoldersInFolder pFolder
  local tFolders

  put folders(pFolder) into tFolders
  filter tFolders without ".*"
  sort tFolders
  return tFolders
end _getFoldersInFolder


private function _getFilesInFolder pFolder
  local tFiles

  put files(pFolder) into tFiles
  filter tFiles without ".*" # i.e. remove anything beginning with a dot
  #<apply any extensions filter specified by the user>
    put the viewProp["allowed extensions"] of me into tAllowedExtensions
    if tAllowedExtensions is not "*" then
      replace comma with "|" in tAllowedExtensions
      #fix for empty     if tAllowedExtensions is empty then put "!." into tAllowedExtensionsRegEx
      put "("&tAllowedExtensions&")$" into tAllowedExtensionsRegEx # e.g. (.pdf|.PDF)$  That means any string terminating with .pdf or .PDF
      filter tFiles with regex tAllowedExtensionsRegEx
    end if #tAllowedExtensions is not "*"
  #</apply any extensions filter specified by the user>
  sort tFiles
  return tFiles
end _getFilesInFolder


private function _hashForFile pFilename
  return _strDigest(sRootFolder & "/" & pFilename)
end _hashForFile


private function _strDigest pString
  local tDigest, tHash
  put md5Digest(pString) into tDigest
  get binarydecode("H*", tDigest, tHash)
  return tHash
end _strDigest
