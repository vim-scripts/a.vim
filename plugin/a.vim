" Copyright (c) 1998-2001
" Michael Sharpe <feline@irendi.com>
"
" We grant permission to use, copy modify, distribute, and sell this
" software for any purpose without fee, provided that the above copyright
" notice and this text are not removed. We make no guarantee about the
" sutability of this software for any purpose and we are not liable
" for any damages resulting from its use. Further, we are under no
" obligation to maintain or extend this software. It is provided on an
" "as is" basis without any express or implied warranty.

if exists("loaded_alternateFile")
    finish
endif
let loaded_alternateFile = 1

" Allow the list of extensions to be overriden in the .vimrc
if (!exists("g:alternateExtensions"))
   " The format of the alternateExtensions variable is as follows. 
   " alternateExtensions = <EXTENSIONS>
   " <EXTENSIONS> = | <EXTSPEC> | EXTSPEC| ....
   " <EXTSPEC> = <EXT> : <ALT1>, <ALT2>,...
   " <EXT> = the extension to match.
   " <ALTn> = the alternate extension to swap to.
   " e.g. h:c,cpp,cxx indicates that if the current file extension is .h, then
   "      the alternate is .c or .cpp or .cxx. Each extension is tried in order
   "      for a match file/buffer. If no match is found the first extension is
   "      used and if necessary the buffer is created.
   let alternateExtensions = "|h:c,cpp,cxx,cc,CC|H:C,CPP,CXX,CC|hpp:cpp,c|HPP:CPP:C|c:h|C:H|cpp:h,hpp|CPP:H:HPP|cc:h|CC:H|cxx:h|CXX:H|CC:h,H|psl:ph|ph:psl|adb:ads|ads:adb|"
endif


" Function : FindExtensionSpec (PRIVATE)
" Purpose  : Finds the extension spec corresponding to the specified extension
" Args     : extension -- the extension to look for
" Returns  : the extension spec found or "" for failure
" Author   : Michael Sharpe <feline@irendi.com>
func! <SID>FindExtensionSpec(extension)
   let extSpec=""
   let extMatch = "|".a:extension.":"
   let startSpec = match(g:alternateExtensions, extMatch, 0)
   if (startSpec != -1)
      let endSpec = match(g:alternateExtensions, "|", startSpec + 1)
      if (endSpec != -1) 
         let len = endSpec - startSpec - 1
      else
         let len = 999
      endif
      let extSpec = strpart(g:alternateExtensions, startSpec + 1, len)
   endif
   return extSpec
endfunc

" Function : GetNthExtensionFromSpec (PRIVATE)
" Purpose  : Use to iterate all the extensions in an extension spec
" Args     : extSpec -- the extension spec to iterate
"            n -- the extension to get
" Returns  : the nth extension from the extension spec, or "" for failure
" Author   : Michael Sharpe <feline@irendi.com>
func! <SID>GetNthExtensionFromSpec(extSpec, n) 
   let extStart = 0
   let extEnd = match(a:extSpec, ":", 0)
   let pos = 0
   let ext = ""
   let i = 0
   while (i != a:n)
      let extStart = extEnd + 1
      let extEnd = match(a:extSpec, ",", pos)
      let i = i + 1
      if (extEnd == -1)
         if (i == a:n)
            let extEnd = strlen(a:extSpec)
         endif
         break
      endif
      let pos = extEnd + 1
   endwhile 
   if (extEnd != -1) 
      let ext = strpart(a:extSpec, extStart, extEnd - extStart)
   endif
   return ext 
endfunc

" Function : AlternateFile (PUBLIC)
" Purpose  : Opens a new buffer by looking at the extension of the current
"            buffer and finding the corresponding file. E.g. foo.c <--> foo.h
" Args     : accepts one argument. If present it used the argument as the new
"            extension.
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
func! AlternateFile(splitWindow, ...)
  let newFilename = ""
  let baseName = expand("%<")
  if (a:0 != 0)
     let newFilename = baseName . "." . a:1
  else
     let currentFile = expand("%")
     let extension = fnamemodify(currentFile,":e")

     let extSpec = <SID>FindExtensionSpec(extension)
     if (extSpec != "") 
        let firstFilename = ""
        let foundMatch = 0
        let n = 1
        while (!foundMatch)
           let ext = <SID>GetNthExtensionFromSpec(extSpec, n)
           if (ext != "") 
              let newFilename = baseName . "." . ext
              let existsCheck = <SID>BufferOrFileExists(newFilename)
              if (existsCheck == 1) 
                 let foundMatch = 1
              elseif (n == 1)
                 " save the first for posible later use
                 let firstFilename = newFilename
              endif
           else
              break
           endif
           let n = n + 1
        endwhile
        if (foundMatch == 0 && firstFilename != "") 
           let newFilename = firstFilename
        endif
     endif
  endif
  if (newFilename != "")
     call <SID>FindOrCreateBuffer(newFilename, a:splitWindow)
  else
     echo "No alternate file available"
  endif
endfunc
comm! -nargs=? A call AlternateFile(0, <f-args>)
comm! -nargs=? AS call AlternateFile(1, <f-args>)
comm! -nargs=? AV call AlternateFile(2, <f-args>)


" Function : BufferOrFileExists (PRIVATE)
" Purpose  : determines if a buffer or a readable file exists
" Args     : name (IN) - name of the buffer/file to check
" Returns  : TRUE if it exists, FALSE otherwise
" Author   : Michael Sharpe <feline@irendi.com>
function! <SID>BufferOrFileExists(name)
   let result = bufexists(a:name) || filereadable(a:name)
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
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
function! <SID>FindOrCreateBuffer(filename, doSplit)
   " Check to see if the buffer is already open before re-opening it.
   let bufName = bufname(a:filename)
   if (bufName == "")
      " Buffer did not exist....create it
      if (a:doSplit == 2)
         execute ":vert split " . a:filename
      elseif (a:doSplit == 1)
         execute ":split " . a:filename
      else
         execute ":e " . a:filename
      endif
   else
      " Buffer was already open......check to see if it is in a window
      let bufWindow = bufwinnr(a:filename)
      if (bufWindow == -1) 
         if (a:doSplit == 2)
            execute ":vert sbuffer " . a:filename
         elseif (a:doSplit == 1)
            execute ":sbuffer " . a:filename
         else
            execute ":buffer " . a:filename
         endif
      else
         " search the windows for the target window
         if bufWindow != winnr()
            " only search if the current window does not contain the buffer
            execute "normal \<C-W>b"
            let winNum = winnr()
            while (winNum != bufWindow && winNum > 0)
               execute "normal \<C-W>k"
               let winNum = winNum - 1
            endwhile
            if (0 == winNum) 
               " something wierd happened...open the buffer
               if (a:doSplit == 2)
                  execute ":vert split " . a:filename
               elseif (a:doSplit == 1)
                  execute ":split " . a:filename
               else
                  execute ":e " . a:filename
               endif
            endif
         endif
      endif
   endif
endfunction
