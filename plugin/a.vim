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

if exists("loaded_alternateFile")
    finish
endif
let loaded_alternateFile = 1

" setup the default set of alternate extensions. The user can override in thier
" .vimrc if the defaults are not suitable.
if (!exists("g:alternateExtensions_h"))
   let alternateExtensions_{'h'} = "c,cpp,cxx,cc,CC"
endif

if (!exists("g:alternateExtensions_H"))
   let alternateExtensions_{'H'} = "C,CPP,CXX,CC"
endif

if (!exists("g:alternateExtensions_hpp"))
   let alternateExtensions_{'hpp'} = "cpp,c"
endif

if (!exists("g:alternateExtensions_HPP"))
   let alternateExtensions_{'HPP'} = "CPP,C"
endif

if (!exists("g:alternateExtensions_c"))
   let alternateExtensions_{'c'} = "h"
endif

if (!exists("g:alternateExtensions_C"))
   let alternateExtensions_{'C'} = "H"
endif

if (!exists("g:alternateExtensions_cpp"))
   let alternateExtensions_{'cpp'} = "h,hpp"
endif

if (!exists("g:alternateExtensions_CPP"))
   let alternateExtensions_{'CPP'} = "H,HPP"
endif

if (!exists("g:alternateExtensions_cc"))
   let alternateExtensions_{'cc'} = "h"
endif

if (!exists("g:alternateExtensions_CC"))
   let alternateExtensions_{'CC'} = "H,h"
endif

if (!exists("g:alternateExtensions_cxx"))
   let alternateExtensions_{'cxx'} = "h"
endif

if (!exists("g:alternateExtensions_CXX"))
   let alternateExtensions_{'CXX'} = "H"
endif

if (!exists("g:alternateExtensions_psl"))
   let alternateExtensions_{'psl'} = "ph"
endif

if (!exists("g:alternateExtensions_ph"))
   let alternateExtensions_{'ph'} = "psl"
endif

if (!exists("g:alternateExtensions_adb"))
   let alternateExtensions_{'adb'} = "ads"
endif

if (!exists("g:alternateExtensions_ads"))
   let alternateExtensions_{'ads'} = "adb"
endif

" Function : GetNthExtensionFromSpec (PRIVATE)
" Purpose  : Use to iterate all the extensions in an extension spec
" Args     : extSpec -- the extension spec to iterate
"            n -- the extension to get
" Returns  : the nth extension from the extension spec, or "" for failure
" Author   : Michael Sharpe <feline@irendi.com>
function! <SID>GetNthExtensionFromSpec(extSpec, n) 
   let extStart = 0
   let extEnd = -1
   let pos = 0
   let ext = ""
   let i = 0
   while (i != a:n)
      let extStart = extEnd + 1
      let extEnd = match(a:extSpec, ",", extStart)
      let i = i + 1
      if (extEnd == -1)
         if (i == a:n)
            let extEnd = strlen(a:extSpec)
         endif
         break
      endif
   endwhile 
   if (extEnd != -1) 
      let ext = strpart(a:extSpec, extStart, extEnd - extStart)
   endif
   return ext 
endfunction

" Function : AlternateFile (PUBLIC)
" Purpose  : Opens a new buffer by looking at the extension of the current
"            buffer and finding the corresponding file. E.g. foo.c <--> foo.h
" Args     : accepts one argument. If present it used the argument as the new
"            extension.
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
function! AlternateFile(splitWindow, ...)
  let newFilename = ""
  let baseName = expand("%<")
  if (a:0 != 0)
     let newFilename = baseName . "." . a:1
  else
     let currentFile = expand("%")
     let extension = fnamemodify(currentFile,":e")

     let extSpec = ""
     silent! let extSpec = g:alternateExtensions_{extension}
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
endfunction

comm! -nargs=? A call AlternateFile("", <f-args>)
comm! -nargs=? AS call AlternateFile("h", <f-args>)
comm! -nargs=? AV call AlternateFile("v", <f-args>)


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
"                            ("v", "h", "") 
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
function! <SID>FindOrCreateBuffer(filename, doSplit)
  " Check to see if the buffer is already open before re-opening it.
  let bufName = bufname(a:filename)
  if (bufName == "")
     " Buffer did not exist....create it
     if (a:doSplit == "h")
        execute ":split " . a:filename
     elseif (a:doSplit == "v")
        execute ":vsplit " . a:filename
     else
        execute ":e " . a:filename
     endif
  else
     " Buffer was already open......check to see if it is in a window
     let bufWindow = bufwinnr(a:filename)
     if (bufWindow == -1) 
        if (a:doSplit == "h")
           execute ":sbuffer " . a:filename
        elseif (a:doSplit == "v")
           execute ":vert sbuffer " . a:filename
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
              if (a:doSplit == "h")
		 execute ":split " . a:filename
              elseif (a:doSplit == "v")
		 execute ":vsplit " . a:filename
	      else
		 execute ":e " . a:filename
	      endif
	   endif
        endif
     endif
  endif
endfunction
