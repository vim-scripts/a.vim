" Copyright (c) 1998-2004
" Michael Sharpe <feline@irendi.com>
"
" We grant permission to use, copy modify, distribute, and sell this
" software for any purpose without fee, provided that the above copyright
" notice and this text are not removed. We make no guarantee about the
" suitability of this software for any purpose and we are not liable
" for any damages resulting from its use. Further, we are under no
" obligation to maintain or extend this software. It is provided on an
" "as is" basis without any expressed or implied warranty.

" Directory enhancements added by Bindu Wavell

if exists("loaded_alternateFile")
    finish
endif
let loaded_alternateFile = 1

" setup the default set of alternate extensions. The user can override in thier
" .vimrc if the defaults are not suitable. To override in a .vimrc simply set a
" g:alternateExtensions_<EXT> variable to a comma separated list of alternates,
" where <EXT> is the extension to map.
" E.g. let g:alternateExtensions_CPP = "inc,h,H,HPP,hpp"


" Function : AddAlternateExtensionMapping (PRIVATE)
" Purpose  : simple helper function to add the default alternate extension
"            mappings.
" Args     : extension -- the extension to map
"            alternates -- comma separated list of alternates extensions
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
function! <SID>AddAlternateExtensionMapping(extension, alternates)
   let varName = "g:alternateExtensions_" . a:extension
   if (!exists(varName))
      let g:alternateExtensions_{a:extension} = a:alternates
   endif
endfunction

" Add all the default extensions
" Mappings for C and C++
call <SID>AddAlternateExtensionMapping('h',"c,cpp,cxx,cc,CC")
call <SID>AddAlternateExtensionMapping('H',"C,CPP,CXX,CC")
call <SID>AddAlternateExtensionMapping('hpp',"cpp,c")
call <SID>AddAlternateExtensionMapping('HPP',"CPP,C")
call <SID>AddAlternateExtensionMapping('c',"h")
call <SID>AddAlternateExtensionMapping('C',"H")
call <SID>AddAlternateExtensionMapping('cpp',"h,hpp")
call <SID>AddAlternateExtensionMapping('CPP',"H,HPP")
call <SID>AddAlternateExtensionMapping('cc',"h")
call <SID>AddAlternateExtensionMapping('CC',"H,h")
call <SID>AddAlternateExtensionMapping('cxx',"h")
call <SID>AddAlternateExtensionMapping('CXX',"H")
" Mappings for PSL7
call <SID>AddAlternateExtensionMapping('psl',"ph")
call <SID>AddAlternateExtensionMapping('ph',"psl")
" Mappings for ADA
call <SID>AddAlternateExtensionMapping('adb',"ads")
call <SID>AddAlternateExtensionMapping('ads',"adb")
" Mappings for lex and yacc files
call <SID>AddAlternateExtensionMapping('l',"y,yacc,ypp")
call <SID>AddAlternateExtensionMapping('lex',"yacc,y,ypp")
call <SID>AddAlternateExtensionMapping('lpp',"ypp,y,yacc")
call <SID>AddAlternateExtensionMapping('y',"l,lex,lpp")
call <SID>AddAlternateExtensionMapping('yacc',"lex,l,lpp")
call <SID>AddAlternateExtensionMapping('ypp',"lpp,l,lex")


" Function : AddAlternateSearchPath (PRIVATE)
" Purpose  : simple helper function to add the default search paths
" Args     : pathSpec -- path to add to search list
" Returns  : nothing
" Author   : Bindu Wavell <bindu@wavell.net>
function! <SID>AddAlternateSearchPath(pathSpec)
   if (exists("g:alternateSearchPath") && strlen(g:alternateSearchPath) > 0)
      let g:alternateSearchPath = g:alternateSearchPath . "," . a:pathSpec
   else
      let g:alternateSearchPath = a:pathSpec
   endif
endfunction

" Add the default file search paths
call <SID>AddAlternateSearchPath("sfr:../src")
call <SID>AddAlternateSearchPath("sfr:../include")

" Function : GetNthItemFromList (PRIVATE)
" Purpose  : Suppor reading items from a comma seperated list
"            Used to iterate all the extensions in an extension spec
"            Used to iterate all path prefixes
" Args     : list -- the list (extension spec, file paths) to iterate
"            n -- the extension to get
" Returns  : the nth item (extension, path) from the list (extension 
"            spec), or "" for failure
" Author   : Michael Sharpe <feline@irendi.com>
" History  : Renamed from GetNthExtensionFromSpec to GetNthItemFromList
"            to reflect a more generic use of this function. -- Bindu
function! <SID>GetNthItemFromList(list, n) 
   let itemStart = 0
   let itemEnd = -1
   let pos = 0
   let item = ""
   let i = 0
   while (i != a:n)
      let itemStart = itemEnd + 1
      let itemEnd = match(a:list, ",", itemStart)
      let i = i + 1
      if (itemEnd == -1)
         if (i == a:n)
            let itemEnd = strlen(a:list)
         endif
         break
      endif
   endwhile 
   if (itemEnd != -1) 
      let item = strpart(a:list, itemStart, itemEnd - itemStart)
   endif
   return item 
endfunction

" Function : ExpandAlternatePath (PRIVATE)
" Purpose  : Expand path info.  A path with a prefix of "wdr:" will cause 
"            be treated as relative to the working directory (i.e. the 
"            directory where vim was started.) A path prefix of "abs:" will 
"            be treated as absolute. No prefix or "sfr:" will result in the 
"            path being treated as relative to the source file (see sfPath 
"            argument).
" Args     : pathSpec -- path component
"            sfPath -- source file path
" Returns  : a path that can be used by AlternateFile()
" Author   : Bindu Wavell <bindu@wavell.net>
function! <SID>ExpandAlternatePath(pathSpec, sfPath) 
   let prfx = strpart(a:pathSpec, 0, 4)
   if (prfx == "wdr:" || prfx == "abs:")
      let path = strpart(a:pathSpec, 4)
   else
      let path = a:pathSpec
      if (prfx == "sfr:")
         let path = strpart(path, 4)
      endif
      let path = a:sfPath . "/" . path
   endif
   return path
endfunction

" Function : FindFileInSearchPath (PRIVATE)
" Purpose  : Searches for a file in the search path list
" Args     : filename -- name of the file to search for
"            pathList -- the path list to search
"            relPathBase -- the path which relative paths are expanded from
" Returns  : An expanded filename if found, the empty string otherwise
" Author   : Michael Sharpe (feline@irendi.com)
" History  : inline code written by Bindu Wavell originally
function! <SID>FindFileInSearchPath(filename, pathList, relPathBase)
   let filepath = ""
   let m = 1
   let pathListLen = strlen(a:pathList)
   if (pathListLen > 0)
      while (1)
         let pathSpec = <SID>GetNthItemFromList(a:pathList, m) 
         if (pathSpec != "")
            let path = <SID>ExpandAlternatePath(pathSpec, a:relPathBase)
            let fullname = path . "/" . a:filename
            let foundMatch = <SID>BufferOrFileExists(fullname)
            if (foundMatch)
               let filepath = fullname
               break
            endif
         else
            break
         endif
         let m = m + 1
      endwhile
   endif
   return filepath
endfunction

" Function : EnumerateFilesByExtension (PRIVATE)
" Purpose  : enumerates all files by a particular list of alternate extensions.
" Args     : path -- path of a file (not including the file)
"            baseName -- base name of the file to be expanded
"            extension -- extension whose alternates are to be enumerated
" Returns  : comma separated list of files with extensions
" Author   : Michael Sharpe <feline@irendi.com>
function! EnumerateFilesByExtension(path, baseName, extension)
   let enumeration = ""
   let extSpec = ""
   silent! let extSpec = g:alternateExtensions_{a:extension}
   if (extSpec != "") 
      let n = 1
      let done = 0
      while (!done)
         let ext = <SID>GetNthItemFromList(extSpec, n)
         if (ext != "")
            if (a:path != "")
               let newFilename = a:path . "/" . a:baseName . "." . ext
            else
               let newFilename =  a:baseName . "." . ext
            endif
            if (enumeration == "")
               let enumeration = newFilename
            else
               let enumeration = enumeration . "," . newFilename
            endif
         else
            let done = 1
         endif
         let n = n + 1
      endwhile
   endif
   return enumeration
endfunction

" Function : EnumerateFilesByExtensionInPath (PRIVATE)
" Purpose  : enumerates all files by expanding the path list and the extension
"            list.
" Args     : baseName -- base name of the file
"            extension -- extension whose alternates are to be enumerated
"            pathList -- the list of paths to enumerate
"            relPath -- the path of the current file for expansion of relative
"                       paths in the path list.
" Returns  : A comma separated list of paths with extensions
" Author   : Michael Sharpe <feline@irendi.com>
function! EnumerateFilesByExtensionInPath(baseName, extension, pathList, relPathBase)
   let enumeration = ""
   let filepath = ""
   let m = 1
   let pathListLen = strlen(a:pathList)
   if (pathListLen > 0)
      while (1)
         let pathSpec = <SID>GetNthItemFromList(a:pathList, m) 
         if (pathSpec != "")
            let path = <SID>ExpandAlternatePath(pathSpec, a:relPathBase)
            let pe = EnumerateFilesByExtension(path, a:baseName, a:extension)
            if (enumeration == "")
               let enumeration = pe
            else
               let enumeration = enumeration . "," . pe
            endif
         else
            break
         endif
         let m = m + 1
      endwhile
   endif
   return enumeration
endfunction

" Function : AlternateFile (PUBLIC)
" Purpose  : Opens a new buffer by looking at the extension of the current
"            buffer and finding the corresponding file. E.g. foo.c <--> foo.h
" Args     : accepts one argument. If present it used the argument as the new
"            extension.
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
" History  : + When an alternate can't be found in the same directory as the
"              source file, a search path will be traversed looking for the
"              alternates.
"            + Moved some code into a separate function, minor optimization
"            + rework to favor files in memory based on complete enumeration of
"              all files extensions and paths
function! AlternateFile(splitWindow, ...)
  let baseName    = expand("%:t:r") " don't want path or ext
  let extension   = expand("%:t:e")
  let currentPath = expand("%:p:h")
  let newFullname = ""

  if (a:0 != 0)
     let newFullname = baseName . "." . a:1
  else
     let allfiles1 = EnumerateFilesByExtension("", baseName, extension)
     let allfiles2 = EnumerateFilesByExtensionInPath(baseName, extension, g:alternateSearchPath, currentPath)

     if (allfiles1 != "")
        let allfiles = allfiles1 . ',' . allfiles2
     else 
        let allfiles = allfiles2
     endif

     if (allfiles != "") 
        let bestFile = ""
        let bestScore = 0
        let score = 0
        let n = 1
         
        let onefile = <SID>GetNthItemFromList(allfiles, n)
        let bestFile = onefile
        while (onefile != "" && score < 2)
           let score = <SID>BufferOrFileExists(onefile)
           if (score > bestScore)
              let bestScore = score
              let bestFile = onefile
           endif
           let n = n + 1
           let onefile = <SID>GetNthItemFromList(allfiles, n)
        endwhile

        call <SID>FindOrCreateBuffer(bestFile, a:splitWindow)
     else
        echo "No alternate file available"
     endif
   endif
endfunction

comm! -nargs=? -bang A call AlternateFile("n<bang>", <f-args>)
comm! -nargs=? -bang AS call AlternateFile("h<bang>", <f-args>)
comm! -nargs=? -bang AV call AlternateFile("v<bang>", <f-args>)

" Function : BufferOrFileExists (PRIVATE)
" Purpose  : determines if a buffer or a readable file exists
" Args     : fileName (IN) - name of the file to check
" Returns  : 2 if it exists in memory, 1 if it exists, 0 otherwise
" Author   : Michael Sharpe <feline@irendi.com>
" History  : Updated code to handle buffernames using just the
"            filename and not the path.
function! <SID>BufferOrFileExists(fileName)
   let result = 0
   let bufName = fnamemodify(a:fileName,":t")
   let memBufName = bufname(bufName)
   if (memBufName != "")
      let memBufBasename = fnamemodify(memBufName, ":t")
      if (bufName == memBufBasename)
         let result = 2
      endif
   endif

   if (!result)
      let result  = bufexists(bufName) || bufexists(a:fileName) || filereadable(a:fileName)
   endif
   return result
endfunction

" Function : FindOrCreateBuffer (PRIVATE)
" Purpose  : searches the buffer list (:ls) for the specified filename. If
"            found, checks the window list for the buffer. If the buffer is in
"            an already open window, it switches to the window. If the buffer
"            was not in a window, it switches to that buffer. If the buffer did
"            not exist, it creates it.
" Args     : filename (IN) -- the name of the file
"            doSplit (IN) -- indicates whether the window should be split
"                            ("v", "h", "n", "v!", "h!", "n!") 
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
" History  : + bufname() was not working very well with the possibly strange
"            paths that can abound with the search path so updated this
"            slightly.  -- Bindu
"            + updated window switching code to make it more efficient -- Bindu
"            Allow ! to be applied to buffer/split/editing commands for more
"            vim/vi like consistency
"            + implemented fix from Matt Perry
function! <SID>FindOrCreateBuffer(filename, doSplit)
  " Check to see if the buffer is already open before re-opening it.
  let bufName = bufname(a:filename)
  let bufFilename = fnamemodify(a:filename,":t")

  if (bufName == "")
     let bufName = bufname(bufFilename)
  endif

  if (bufName != "")
     let tail = fnamemodify(bufName, ":t")
     if (tail != bufFilename)
        let bufName = ""
     endif
  endif

  let splitType = a:doSplit[0]
  let bang = a:doSplit[1]
  if (bufName == "")
     " Buffer did not exist....create it
     let v:errmsg=""
     if (splitType == "h")
        silent! execute ":split".bang." " . a:filename
     elseif (splitType == "v")
        silent! execute ":vsplit".bang." " . a:filename
     else
        silent! execute ":e".bang." " . a:filename
     endif
     if (v:errmsg != "")
        echo v:errmsg
     endif
  else
     " Buffer was already open......check to see if it is in a window
     let bufWindow = bufwinnr(bufName)
     if (bufWindow == -1) 
        " Buffer was not in a window so open one
        let v:errmsg=""
        if (splitType == "h")
           silent! execute ":sbuffer".bang." " . bufName
        elseif (splitType == "v")
           silent! execute ":vert sbuffer " . bufName
        else
           silent! execute ":buffer".bang." " . bufName
        endif
        if (v:errmsg != "")
           echo v:errmsg
        endif
     else
        " Buffer is already in a window so switch to the window
        execute bufWindow."wincmd w"
        if (bufWindow != winnr()) 
           " something wierd happened...open the buffer
           let v:errmsg=""
           if (splitType == "h")
              silent! execute ":split".bang." " . bufName
           elseif (splitType == "v")
              silent! execute ":vsplit".bang." " . bufName
           else
              silent! execute ":e".bang." " . bufName
           endif
           if (v:errmsg != "")
              echo v:errmsg
           endif
        endif
     endif
  endif
endfunction
