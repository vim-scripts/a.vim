" Function : AlternateFile (PUBLIC)
" Purpose  : Opens a new buffer by looking at the extension of the current
"            buffer and finding the corresponding file. E.g. foo.c <--> foo.h
" Args     : accepts one argument. If present it used the argument as the new
"            extension.
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)
func! AlternateFile(splitWindow, ...)
  let baseName = expand("%<")
  " before 5.6 if (a:1 != "") is needed instead of the following...
  if (a:0 != 0)
     let newFilename = baseName . "." . a:1
  else
     let currentFile = expand("%")
     let extension = fnamemodify(currentFile,":e")
     if (extension == "c") 
        let newFilename = baseName.".h"
     elseif (extension == "cpp")
        let newFilename = baseName . ".h"
     elseif (extension == "psl")
        let newFilename = baseName . ".ph"
     elseif (extension == "ph")
        let newFilename = baseName . ".psl"
     elseif (extension == "h")
        let newFilename = baseName . ".c"
        let fileExistsCheck = filereadable(newFilename)
        if (fileExistsCheck == 0)
           let newFilename = baseName . ".cpp"
        endif
     else
        echo "AlternameFile: unknown extension"
        return
     endif
  endif
  call FindOrCreateBuffer(newFilename, a:splitWindow)
endfunc
comm! -nargs=? A call AlternateFile(0, <f-args>)
comm! -nargs=? AS call AlternateFile(1, <f-args>)

" Function : FindOrCreateBuffer (PRIVATE)
" Purpose  : searches the buffer list (:ls) for the specified filename. If
"            found, checks the window list for the buffer. If the buffer is in
"            an already open window, it switches to the window. If the buffer
"            was not in a window, it switches to that buffer. If the buffer did
"            not exist, it creates it.
" Args     : filename (IN) -- the name of the file
"            doSplit (IN) -- indicates whether the window should be split
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)
function! FindOrCreateBuffer(filename, doSplit)
  " Check to see if the buffer is already open before re-opening it.
  let bufName = bufname(a:filename)
  if (bufName == "")
     " Buffer did not exist....create it
     if (a:doSplit != 0)
        execute ":split " . a:filename
     else
        execute ":e " . a:filename
     endif
  else
     " Buffer was already open......check to see if it is in a window
     let bufWindow = bufwinnr(a:filename)
     if (bufWindow == -1) 
        if (a:doSplit != 0)
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
	      if (a:doSplit != 0)
		 execute ":split " . a:filename
	      else
		 execute ":e " . a:filename
	      endif
	   endif
        endif
     endif
  endif
endfunction
