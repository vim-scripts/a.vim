" Copyright (c) 1998-2002
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
call <SID>AddAlternateExtensionMapping('psl',"ph")
call <SID>AddAlternateExtensionMapping('ph',"psl")
call <SID>AddAlternateExtensionMapping('adb',"ads")
call <SID>AddAlternateExtensionMapping('ads',"adb")

" Function : AddAlternateSearchPath (PRIVATE)
" Purpose  : simple helper function to add the default search paths
" Args     : pathSpec -- path to add to search list
" Returns  : nothing
" Author   : Bindu Wavell <bindu@wavell.net>
function! <SID>AddAlternateSearchPath(pathSpec)
   if ( exists("g:alternateSearchPath") && strlen(g:alternateSearchPath) > 0 )
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
      let path   = a:pathSpec
      if (prfx == "sfr:")
         let path = strpart(path, 4)
      endif
      let path = a:sfPath . "/" . path
   endif
   return path
endfunction

" Function : AlternateFile (PUBLIC)
" Purpose  : Opens a new buffer by looking at the extension of the current
"            buffer and finding the corresponding file. E.g. foo.c <--> foo.h
" Args     : accepts one argument. If present it used the argument as the new
"            extension.
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
" History  : When an alternate can't be found in the same directory as the
"            source file, a search path will be traversed looking for the
"            alternates.
function! AlternateFile(splitWindow, ...)
  let baseName    = expand("%:t:r") " don't want path or ext
  let extension   = expand("%:t:e")
  let currentPath = expand("%:p:h")
  let newFullname = ""

  if (a:0 != 0)
     let newFullname = baseName . "." . a:1
  else
     let extSpec = ""
     silent! let extSpec = g:alternateExtensions_{extension}
     if (extSpec != "") 
        let firstFullname = ""
        let foundMatch = 0
        let n = 1
        while (!foundMatch)
           let ext = <SID>GetNthItemFromList(extSpec, n)
           if (ext != "") 
              let newFilename = baseName . "." . ext
              let newFullname = currentPath . "/" . newFilename
              let existsCheck = <SID>BufferOrFileExists(newFullname)

              if (existsCheck == 1) 
                 let foundMatch = 1
              else

                 if (n == 1)
                    " save the first for posible later use
                    let firstFullname = newFullname
                 endif

                 " see if we can find the file in the search path
                 let foundInPath = 0
                 let m = 1
                 let pathList = g:alternateSearchPath 
                 let pathListLen = strlen(pathList)
                 while (pathListLen > 0 && !foundInPath)
                    let pathSpec = <SID>GetNthItemFromList(pathList, m) 
                    if (pathSpec != "")
                       let path = <SID>ExpandAlternatePath(pathSpec, currentPath)
                       let newFullname = path . "/" . newFilename
                       let existsCheck = <SID>BufferOrFileExists(newFullname)
                       if (existsCheck == 1)
                          let foundInPath = 1
                          let foundMatch  = 1
                       endif
                    else
                       break
                    endif
                    let m = m + 1
                 endwhile

              endif
           else
              break
           endif
           let n = n + 1
        endwhile
        if (foundMatch == 0 && firstFullname != "") 
           let newFullname = firstFullname
        endif
     endif
  endif
  if (newFullname != "")
     call <SID>FindOrCreateBuffer(newFullname, a:splitWindow)
  else
     echo "No alternate file available"
  endif
endfunction

comm! -nargs=? A call AlternateFile("", <f-args>)
comm! -nargs=? AS call AlternateFile("h", <f-args>)
comm! -nargs=? AV call AlternateFile("v", <f-args>)


" Function : BufferOrFileExists (PRIVATE)
" Purpose  : determines if a buffer or a readable file exists
" Args     : fileName (IN) - name of the file to check
" Returns  : TRUE if it exists, FALSE otherwise
" Author   : Michael Sharpe <feline@irendi.com>
" History  : Updated code to handle buffernames using just the
"            filename and not the path.
function! <SID>BufferOrFileExists(fileName)
   let bufName = fnamemodify(a:fileName,":t")
   let result  = bufexists(bufName) || filereadable(a:fileName)
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
"                            ("v", "h", "") 
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
" History  : bufname() was not working very well with the possibly strange
"            paths that can abound with the search path so updated this
"            slightly.  -- Bindu
"            updated window switching code to make it more efficient -- Bindu
function! <SID>FindOrCreateBuffer(filename, doSplit)
  " Check to see if the buffer is already open before re-opening it.
  let bufName = bufname(a:filename)
  if (bufName == "")
     let bufFilename = fnamemodify(a:filename,":t")
     let bufName = bufname(bufFilename)
  endif
  if (bufName == "")
     " Buffer did not exist....create it
     if (a:doSplit == "h")
        execute ":split! " . a:filename
     elseif (a:doSplit == "v")
        execute ":vsplit! " . a:filename
     else
        execute ":e! " . a:filename
     endif
  else
     " Buffer was already open......check to see if it is in a window
     let bufWindow = bufwinnr(bufName)
     if (bufWindow == -1) 
        " Buffer was not in a window so open one
        if (a:doSplit == "h")
           execute ":sbuffer! " . bufName
        elseif (a:doSplit == "v")
           execute ":vert sbuffer " . bufName
        else
           execute ":buffer! " . bufName
        endif
     else
        " Buffer is already in a window so switch to the window
        execute bufWindow."wincmd w"
        if (bufWindow != winnr()) 
           " something wierd happened...open the buffer
           if (a:doSplit == "h")
              execute ":split! " . bufName
           elseif (a:doSplit == "v")
              execute ":vsplit! " . bufName
           else
              execute ":e! " . bufName
           endif
        endif
     endif
  endif
endfunction
