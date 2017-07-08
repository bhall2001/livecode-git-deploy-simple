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
local sOutput
local sHeaderA
local sCommandA
local sPort = 42142


on libraryStack
   put "" into sCommandA
    
   put "thisisatest" into gGlobalsA["$_GET"]["sat"]
   
   executeDeploy
end libraryStack


command executeDeploy
   local tFilepath, tFilename, tBasename
   local tConfigFile
   local x
   
   /*=================[ Configuration start ]=================*/
   
   -- set the defaultFolder to the folder containing the script
   set the itemDelimiter to slash
   put the effective filename of this stack into tFilename
   put item 1 to -2 of tFilename & "/" into tFilepath
   put the short name of this stack into tBasename
   put tFilePath & tBasename & "-config.livecodescript" into tConfigFile
   
   -- load configuration file
   if there is a file tConfigFile then
      ##start using stack sConfigFile
      insert the script of stack tConfigFile into back
      put getConfigs() into sConfigA
   else
      throw "404"
   end if
   
   /*=================[ Configuration end ]=================*/
   
   -- initialize Output Buffer
   obStart
   
   if (gGlobalsA["$_GET"]["sat"] is empty) \
         or (gGlobalsA["$_GET"]["sat"] is not sConfigA["SECRET_ACCESS_TOKEN"]) \
         or (sConfigA["SECRET_ACCESS_TOKEN"] is "BetterChangeMeNowOrSufferTheConsequences" ) then
      obHeader gGlobalsA["$_SERVER"]["SERVER_PROTOCOL"] & "403 Forbidden", true, 403
   end if
   
   obPut obMergeFile(tFilePath & "htmlHeader.lc")
   
   if (gGlobalsA["$_GET"]["sat"] is empty) \
         or (gGlobalsA["$_GET"]["sat"] is not sConfigA["SECRET_ACCESS_TOKEN"]) then
      obPut "<h2>ACCESS DENIED!</h2>"
      exit to top
   end if
   
   -- Dope slap if default access token used...
   if sConfigA["SECRET_ACCESS_TOKEN"] is "BetterChangeMeNowOrSufferTheConsequences" then
      obPut "<h2>You're suffering the consequences!<br>Change the SECRET_ACCESS_TOKEN from it's default value!</h2>"
      exit to top
   end if
   
   /*
   <?lc
   if (!isset($_GET['sat']) || $_GET['sat'] !== SECRET_ACCESS_TOKEN) {
   header($_SERVER['SERVER_PROTOCOL'] . ' 403 Forbidden', true, 403);
   die('<h2>ACCESS DENIED!</h2>');
   }
   if (SECRET_ACCESS_TOKEN === 'BetterChangeMeNowOrSufferTheConsequences') {
   header($_SERVER['SERVER_PROTOCOL'] . ' 403 Forbidden', true, 403);
   die("<h2>You're suffering the consequences!<br>Change the SECRET_ACCESS_TOKEN from it's default value!</h2>");
   }
   
   ?>
   */
   
   obPut "<pre>"
   obPut "Checking the environment..."
   obPut "Running as <b>" & shelly("whoami") & "</b>."
   obFlush
   
   /*
   <?lc
   // Check if the required programs are available
   $requiredBinaries = array('git', 'rsync');
   if (defined('BACKUP_DIR') && BACKUP_DIR !== false) {
   $requiredBinaries[] = 'tar';
   if (!is_dir(BACKUP_DIR) || !is_writable(BACKUP_DIR)) {
   header($_SERVER['SERVER_PROTOCOL'] . ' 500 Internal Server Error', true, 500);
   die(sprintf('<div class="error">BACKUP_DIR `%s` does not exists or is not writeable.</div>', BACKUP_DIR));
   }
   }
   if (defined('USE_COMPOSER') && USE_COMPOSER === true) {
   $requiredBinaries[] = 'composer --no-ansi';
   }
   foreach ($requiredBinaries as $command) {
   $path = trim(shell_exec('which '.$command));
   if ($path == '') {
   header($_SERVER['SERVER_PROTOCOL'] . ' 500 Internal Server Error', true, 500);
   die(sprintf('<div class="error"><b>%s</b> not available. It needs to be installed on the server for this script to work.</div>', $command));
   } else {
   $version = explode("\n", shell_exec($command.' --version'));
   printf('<b>%s</b> : %s'."\n"
   , $path
   , $version[0]
   );
   }
   }
   
   ?>
   */
   local tRequiredBinA, tPath
   put "git" into tRequiredBinA[1]
   put "rsync" into tRequiredBinA[2]
   
   -- check if we are backing up the directory
   if sConfigA["BACKUP_DIR"] is not empty then
      put "tar" into tRequiredBinA[3]
      
      set the defaultFolder to sConfigA["BACKUP_DIR"]
      //obWrite (item 10 of the detailed folders)
      
      -- now also check that the backup directory exists and is write-able
      if (there is not a folder sConfigA["BACKUP_DIR"])  then
         ## TODO
      end if
   end if
   
   repeat for each element aCommand in tRequiredBinA
      put shell("which" && aCommand) into tPath
      if tPath is empty then
         obPut "Command" && aCommand && "not installed"
         exit to top
      else
         obPut (shelly((aCommand && "--version")))
      end if
      obFlush
   end repeat
   
   obPut "Environment OK."
   obPut "Using configuration defined in" && tConfigFile
   
   obPut "Deploying" && sConfigA["REMOTE_REPOSITORY"] & ";" & sConfigA["BRANCH"]
   obPut "to       " && sConfigA["TARGET_DIR"] 
   
   /*
   <?lc
   // The commands
   $commands = array();
   
   // ========================================[ Pre-Deployment steps ]===
   
   if (!is_dir(TMP_DIR)) {
   // Clone the repository into the TMP_DIR
   $commands[] = sprintf(
   'git clone --depth=1 --branch %s %s %s'
   , BRANCH
   , REMOTE_REPOSITORY
   , TMP_DIR
   );
   } else {
   // TMP_DIR exists and hopefully already contains the correct remote origin
   // so we'll fetch the changes and reset the contents.
   $commands[] = sprintf(
   'git --git-dir="%s.git" --work-tree="%s" fetch --tags origin %s'
   , TMP_DIR
   , TMP_DIR
   , BRANCH
   );
   $commands[] = sprintf(
   'git --git-dir="%s.git" --work-tree="%s" reset --hard FETCH_HEAD'
   , TMP_DIR
   , TMP_DIR
   );
   }
   */
   
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
   
   /*
   // Update the submodules
   $commands[] = sprintf(
   'git submodule update --init --recursive'
   );
   */
   if (sConfigA["UPDATE_SUBMODULES"]) then
      _AddCommand "git submodule update --init --recursive"
   end if
   
   /*
   // Describe the deployed version
   if (defined('VERSION_FILE') && VERSION_FILE !== '') {
   $commands[] = sprintf(
   'git --git-dir="%s.git" --work-tree="%s" describe --always > %s'
   , TMP_DIR
   , TMP_DIR
   , VERSION_FILE
   );
   }
   */
   if sConfigA["VERSION_FILE"] is not empty then
      _AddCommand "git --git-dir=" & sConfigA["TMP_DIR"] & ".git" && \
            "--work-tree=" & sConfigA["TMP_DIR"] &&  \
            "describe --always >" &&  sConfigA["VERSION_FILE"]
   end if
   
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
   if (sConfigA["BACKUP_DIR"] is not false) and (sConfigA["BACKUP_DIR"] is not empty) then
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
      --exclude=" & sConfigA["BACKUP_DIR"] & "*" && "
      
   end if
   
   /*  
   // ==================================================[ Deployment ]===
   
   // Compile exclude parameters
   $exclude = '';
   foreach (unserialize(EXCLUDE) as $exc) {
   $exclude .= ' --exclude='.$exc;
   }
   */
   local tExclude, tDelete
   repeat for each element excludeMe in sConfigA["EXCLUDE"]
      put " --exclude=" & excludeMe into tExclude
   end repeat
   
   if (sConfigA["DELETE_FILES"]) then
      put "--delete-after" into tDelete
   else
      put "" into tDelete
   end if
   
   /*
   // Deployment command
   $commands[] = sprintf(
   'rsync -rltgoDzvO %s %s %s %s'
   , TMP_DIR
   , TARGET_DIR
   , (DELETE_FILES) ? '--delete-after' : ''
   , $exclude
   );
   */
   _AddCommand "rsync -rltgoDzvO" && sConfigA["TMP_DIR"] && sConfigA["TARGET_DIR"] && \
         tDelete && tExclude
   
   /*
   // =======================================[ Post-Deployment steps ]===
   
   // Remove the TMP_DIR (depends on CLEAN_UP)
   if (CLEAN_UP) {
   $commands['cleanup'] = sprintf(
   'rm -rf %s'
   , TMP_DIR
   );
   }
   
   // =======================================[ Run the command steps ]===
   $output = '';
   foreach ($commands as $command) {
   */
   local tResponse
   repeat with i = 1 to number of elements of sCommandA
      put shelly(sCommandA[i]) into tResponse
      
      obPut "<span class='prompt'>$</span> <span class='command'>" & sCommandA[i] & "</span>"
      obWrite "<div class='output'>" & tResponse & "</div>"
      obFlush
      
   end repeat
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
   
   /*
   if (CLEAN_UP) {
   $tmp = shell_exec($commands['cleanup']);
   printf('
   
   
   Cleaning up temporary files ...
   
   <span class="prompt">$</span> <span class="command">%s</span>
   <div class="output">%s</div>
   '
   , htmlentities(trim($commands['cleanup']))
   , htmlentities(trim($tmp))
   );
   }
   */
   if sConfigA["CLEAN_UP"] then
      local tCleanupCommand
      put "rm -rf" && sConfigA["TMP_DIR"] into tCleanupCommand
      put shelly(tCleanupCommand) into tResponse
      
      obPut "Cleaning up Temporary files..."
      obPut "<span class='prompt'>$</span> <span class='command'>" & tCleanupCommand & "</span>"
      obWrite "<div class='output'>" & tResponse & "</div>"
      obFlush
   end if
   
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
   
   obUpdateBR
end obWrite


command obPut pData
   put pData & return after sOutput
   
   obUpdateBR
end obPut


command obFlush
   -- write the output buffer to stdout
   write sOutput to stdout
   
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


function obMergeFile pFilePath
   local tPageBuffer, tBuffer
   
   put URL format("binfile:%s", pFilePath) into tPageBuffer
   if the result <> empty then
      throw "ERROR: Failed to read file!"
   end if
   
   put merge(tPageBuffer) into tBuffer
   obWrite tBuffer
   
   return tBuffer
   
end obMergeFile


function shelly pCommand
    return char 1 to -2 of (shell(pCommand))
end shelly
