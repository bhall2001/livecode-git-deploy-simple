script "outBuffer"
local sHeaderA
local sOutput
local sPort

command obHeader pHeader, pInit, pCode
   local tIndex
   
   if pInit then
      put "" into sHeaderA
   end if
   
   put the number of elements of sHeaderA + 1 into tIndex
   put pHeader into sHeaderA[tIndex]
end obHeader


command obWrite pData
   put pData after sOutput
   write pData to stdout
   
   ###obUpdateBR
end obWrite


command obPut pData
   put pData & return after sOutput
   write pData & return to stdout
   
   ##obUpdateBR
end obPut


command obFlush
   -- write the output buffer to stdout
   ###write sOutput to stdout
   
   obUpdateBR
end obFlush


command obUpdateBR
   local tOutputEncoded
   
   -- check if server editor is running and update UI if it is 
   if  "BladeRunner.livecode" is in the stacks then
      send "brUIUpdate" && urlEncode(sOutput) to stack "BladeRunner"
   end if
   
end obUpdateBR


command obStart
   close socket "127.0.0.1:" & sPort
   
   put "" into sOutput
   obUpdateBR
end obStart


command obMergeFile pFilePath
   local tPageBuffer, tBuffer
   
   put URL format("binfile:%s", pFilePath) into tPageBuffer
   if the result <> empty then
      throw "ERROR: Failed to read file!"
   end if
   
   put merge(tPageBuffer) into tBuffer
   obWrite tBuffer
   
   return tBuffer
   
end obMergeFile
