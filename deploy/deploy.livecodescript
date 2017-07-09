script "deploy"
/**
* Simple Livecode Git deploy script
*
* Automatically deploy using Livecode and Git.
*
* @version 0.0.1
* @link    https://github.com/bhall2001/simple-livecode-git-deploy/
*/
global gGlobalsA

local sConfigA
local sCommandA


on libraryStack
   put "" into sCommandA
           
   executeDeploy
end libraryStack


command executeDeploy
   local tFilepath, tFilename, tBasename
   local tConfigFile
   local x
   
   /*=================[ Configuration start ]=================*/
   
   -- set the defaultFolder to the folder containing the script
   local tOldDelim
   
   put the itemDelimiter into tOldDelim
   set the itemDelimiter to slash
   put the effective filename of this stack into tFilename
   put item 1 to -2 of tFilename & "/" into tFilepath
   put the short name of this stack into tBasename
   put tFilePath & tBasename & "-config.livecodescript" into tConfigFile
   set the itemDelimiter to tOldDelim
   
   -- load out buffer library
   insert the script of stack (tFilePath & "outBuffer.livecodescript") into back
   
   -- load configuration file
   if there is a file tConfigFile then
      insert the script of stack tConfigFile into back
      put getConfigs() into sConfigA
   else
      ### TODO HANDLE EXPCEPTION
      ###throw "404"
   end if
   
   /*=================[ Configuration end ]=================*/
   
   -- initialize Output Buffer
   obStart
   
   if (gGlobalsA["$_GET"]["sat"] is empty) \
         or (gGlobalsA["$_GET"]["sat"] is not sConfigA["SECRET_ACCESS_TOKEN"]) \
         or (sConfigA["SECRET_ACCESS_TOKEN"] is "BetterChangeMeNowOrSufferTheConsequences" ) then
      obHeader gGlobalsA["$_SERVER"]["SERVER_PROTOCOL"] & "403 Forbidden", true, 403
   end if
   
   -- merge in HTML header content
   obMergeFile tFilePath & "htmlHeader.lc"
   
   if (gGlobalsA["$_GET"]["sat"] is empty) \
         or (gGlobalsA["$_GET"]["sat"] is not sConfigA["SECRET_ACCESS_TOKEN"]) then
      obPut "<h2>ACCESS DENIED!</h2>"
      obFlush
      exit to top
   end if
   
   -- Dope slap if default access token used...
   if sConfigA["SECRET_ACCESS_TOKEN"] is "BetterChangeMeNowOrSufferTheConsequences" then
      obPut "<h2>You're suffering the consequences!<br>Change the SECRET_ACCESS_TOKEN from it's default value!</h2>"
      obFlush
      exit to top
   end if
   
   obPut "<pre>"
   obPut "Checking the environment..."
   obPut "Running as <b>" & shelly("whoami") & "</b>."
   obFlush
   
   -- Check if the required programs are available
   local tRequiredBinA, tBinPath
   
   put "git" into tRequiredBinA[1]
   put "rsync" into tRequiredBinA[2]
   
   -- check if we are backing up the directory
   if sConfigA["BACKUP_DIR"] is not empty then
      put "tar" into tRequiredBinA[3]
      
      set the defaultFolder to sConfigA["BACKUP_DIR"]
      
      -- now also check that the backup directory exists and is write-able
      if (there is not a folder sConfigA["BACKUP_DIR"])  then
         ## TODO
      end if
   end if
   
   -- check that binaries we need exist
   repeat for each element aCommand in tRequiredBinA
      put shell("which" && aCommand) into tBinPath
      if tBinPath is empty then
         -- binary not found so exit
         obPut "Command" && aCommand && "not installed"
         exit to top
      else
         obPut (shelly((aCommand && "--version")))
      end if
      obFlush
   end repeat
   
   -- everything looks good. Let's go!
   obPut "Environment OK."
   obPut "Using configuration defined in" && tConfigFile
   
   obPut "Deploying" && sConfigA["REMOTE_REPOSITORY"] & ";" & sConfigA["BRANCH"]
   obPut "to       " && sConfigA["TARGET_DIR"] 
   
   // ===========[ Pre-Deployment steps ]===========
   
   -- Check if initial deployment or updating an existing one
   if there is not a folder sConfigA["TMP_DIR"] then
      _AddCommand "git clone --depth=1 --branch" && sConfigA["BRANCH"] && \
            sConfigA["REMOTE_REPOSITORY"] && \
            sConfigA["TMP_DIR"]
   else
      _AddCommand "git --git-dir=" & sConfigA["TMP_DIR"] & ".git" && \
            "--work-tree=" & sConfigA["TMP_DIR"] && \
            "fetch --tags origin" && sConfigA["BRANCH"]
      
      _AddCommand "git --git-dir=" & sConfigA["TMP_DIR"] & ".git" && \
            "--work-tree=" & sConfigA["TMP_DIR"] && \
            "reset --hard FETCH_HEAD"
   end if
   
   -- Update the submodules
   if (sConfigA["UPDATE_SUBMODULES"]) then
      _AddCommand "git submodule update --init --recursive"
   end if
   
   -- Describe the deployed version
   if sConfigA["VERSION_FILE"] is not empty then
      _AddCommand "git --git-dir=" & sConfigA["TMP_DIR"] & ".git" && \
            "--work-tree=" & sConfigA["TMP_DIR"] &&  \
            "describe --always >" &&  sConfigA["VERSION_FILE"]
   end if
   
   ## TODO Handle Exclude in Backup
   /*
   // Backup the TARGET_DIR
   // without the BACKUP_DIR for the case when it's inside the TARGET_DIR
   if (defined('BACKUP_DIR') && BACKUP_DIR !== false) {
   $commands[] = sprintf(
   "tar --exclude='%s*' -czf %s/%s-%s-%s.tar.gz %s*"
   , BACKUP_DIR
   , BACKUP_DIR
   , basename(TARGET_DIR)
   , md5(TARGET_DIR)
   , date('YmdHis')
   , TARGET_DIR // We're backing up this directory into BACKUP_DIR
   );
   }
   */
   if (sConfigA["BACKUP_DIR"] is not "") then
      local tTargetBase, tDate, tOutputDate
      
      set the itemDelimiter to "/"
      put item -1 of sConfigA["TARGET_DIR"] into tTargetBase
      put the internet date into tDate
      convert tDate to dateitems
      set the itemDelimiter to ","
      put item 1 of tDate & format("%02s", item 2 of tDate) & format("%02s", item 3 of tDate) & \
            format("%02s", item 4 of tDate) & format("%02s", item 5 of tDate) & format("%02s", item 6 of tDate) into tOutputDate
      
      _AddCommand "tar -zcvf" && sConfigA["BACKUP_DIR"] & tTargetBase & "-" & \
            base64Encode(md5Digest(sConfigA["TARGET_DIR"])) & "-" & tOutputDate & ".tar.gz" && \
            sConfigA["TARGET_DIR"]
      --exclude=" & sConfigA["BACKUP_DIR"] & "*" && "...
      
   end if
   
   // ===========[ Deployment ]===========
   
   -- Assemble exclude parameters
   local tExclude, tDelete
   repeat for each element excludeMe in sConfigA["EXCLUDE"]
      put " --exclude=" & excludeMe into tExclude
   end repeat
   
   if (sConfigA["DELETE_FILES"]) then
      put "--delete-after" into tDelete
   else
      put "" into tDelete
   end if
   
   -- Deployment command
   _AddCommand "rsync -rltgoDzvO" && sConfigA["TMP_DIR"] && sConfigA["TARGET_DIR"] && \
         tDelete && tExclude
   
   // ===========[ Run the commands ]===========
   local tResponse
   repeat with i = 1 to number of elements of sCommandA
      put shelly(sCommandA[i]) into tResponse
      
      obPut "<span class='prompt'>$</span> <span class='command'>" & sCommandA[i] & "</span>"
      obWrite "<div class='output'>" & tResponse & "</div>"
      obFlush
   end repeat
   
   ### TODO TIMELIMIT?
   /*
   set_time_limit(TIME_LIMIT); // Reset the time limit for each command
   if (file_exists(TMP_DIR) && is_dir(TMP_DIR)) {
   chdir(TMP_DIR); // Ensure that we're in the right directory
   }
   $tmp = array();
   exec($command.' 2>&1', $tmp, $return_code); // Execute the command
   // Output the result
   printf('
   <span class="prompt">$</span> <span class="command">%s</span>
   <div class="output">%s</div>
   '
   , htmlentities(trim($command))
   , htmlentities(trim(implode("\n", $tmp)))
   );
   $output .= ob_get_contents();
   ob_flush(); // Try to output everything as it happens
   
   
   ### TODO ERROR HANDLING
   // Error handling and cleanup
   if ($return_code !== 0) {
   header($_SERVER['SERVER_PROTOCOL'] . ' 500 Internal Server Error', true, 500);
   printf('
   <div class="error">
   Error encountered!
   Stopping the script to prevent possible data loss.
   CHECK THE DATA IN YOUR TARGET DIR!
   </div>
   '
   );
   */
   
   // ===========[ Post-Deployment steps ]===========
   
   -- Remove the TMP_DIR (depends on CLEAN_UP)
   if sConfigA["CLEAN_UP"] then
      obPut "Cleaning up Temporary files..."
      local tCleanupCommand
      put "rm -rf" && sConfigA["TMP_DIR"] into tCleanupCommand
      put shelly(tCleanupCommand) into tResponse
      
      obPut "<span class='prompt'>$</span> <span class='command'>" & tCleanupCommand & "</span>"
      obWrite "<div class='output'>" & tResponse & "</div>"
      obFlush
   end if
   
   ### TODO EMAIL RESULTS
   /*
   $error = sprintf(
   'Deployment error on %s using %s!'
   , $_SERVER['HTTP_HOST']
   , __FILE__
   );
   error_log($error);
   if (EMAIL_ON_ERROR) {
   $output .= ob_get_contents();
   $headers = array();
   $headers[] = sprintf('From: Simple PHP Git deploy script <simple-php-git-deploy@%s>', $_SERVER['HTTP_HOST']);
   $headers[] = sprintf('X-Mailer: PHP/%s', phpversion());
   mail(EMAIL_ON_ERROR, $error, strip_tags(trim($output)), implode("\r\n", $headers));
   }
   break;
   }
   }
   
   ?>
   */
   obPut "Done."
   obPut "</pre>"
   obPut "</body>"
   obPut "</html>"
   obFlush
end executeDeploy


private command _AddCommand pCommand
   local tIndex
   
   put the number of elements of sCommandA + 1 into tIndex
   put pCommand into sCommandA[tIndex]
end _AddCommand


function shelly pCommand
    return char 1 to -2 of (shell(pCommand))
end shelly
