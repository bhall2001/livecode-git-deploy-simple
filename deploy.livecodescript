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
global gConfigA

local sConfigFile
local sOutput
local sFilename
local sHeaderA
local sHeaderIndex
local sCommandA
local sCommandIndex
local sPort = 42142



on libraryStack
   write "Starting deploy.livecodescript" & CRLF to stdout
   
   put "thisisatest" into gGlobalsA["$_GET"]["sat"]
   
   executeDeploy
end libraryStack


command executeDeploy
    local tFilepath, tBasename
    local x
    
    put "" into sCommandA
    put 1 into sCommandIndex
    
    // =========================================[ Configuration start ]===
    
    /**
    * It's preferable to configure the script using `deploy-config.lc` file.
    *
    * Rename `deploy-config.example.lc` to `deploy-config.lc` and edit the
    * configuration options there instead of here. That way, you won't have to edit
    * the configuration again if you download the new version of `deploy.lc`.
    */
    /*if (file_exists(basename(__FILE__, '.php').'-config.php')) {
    define('CONFIG_FILE', basename(__FILE__, '.php').'-config.php');
    require_once CONFIG_FILE;
    } else {
    define('CONFIG_FILE', __FILE__);
    }
    */
    # set the defaultFolder to the folder containing the script
    set the itemDelimiter to slash
    get the effective filename of this stack
    put it into sFilename
    put item 1 to -2 of sFilename & "/" into tFilepath
    put the short name of this stack into tBasename
    
    if there is a file (tFilePath & tBasename & "-config.livecodescript") then
        put tFilePath & tBasename & "-config.livecodescript" into sConfigFile
        start using stack sConfigFile
    else
        throw "404"
    end if
    
    /**
    * Protect the script from unauthorized access by using a secret access token.
    * If it's not present in the access URL as a GET variable named `sat`
    * e.g. deploy.php?sat=Bett...s the script is not going to deploy.
    *
    * @var string
    */
    /*
    if (!defined('SECRET_ACCESS_TOKEN')) define('SECRET_ACCESS_TOKEN', 'BetterChangeMeNowOrSufferTheConsequences');
    */
    if gConfigA["SECRET_ACCESS_TOKEN"] is empty then
        put "BetterChangeMeNowOrSufferTheConsequences" into gConfigA["SECRET_ACCESS_TOKEN"]
    end if
    
    /**
    * The address of the remote Git repository that contains the code that's being
    * deployed.
    * If the repository is private, you'll need to use the SSH address.
    *
    * @var string
    */
    /*
    if (!defined('REMOTE_REPOSITORY')) define('REMOTE_REPOSITORY', 'https://github.com/markomarkovic/simple-php-git-deploy.git');
    */
    if gConfigA["REMOTE_REPOSITORY"] is empty then
        put "https://github.com/bhall2001/simple-livecode-git-deploy.git" into gConfigA["REMOTE_REPOSITORY"]
    end if
    
    /**
    * The branch that's being deployed.
    * Must be present in the remote repository.
    *
    * @var string
    */
    /*
    if (!defined('BRANCH')) define('BRANCH', 'master');
    */
    if gConfigA["BRANCH"] is empty then
        put "master" into gConfigA["BRANCH"]
    end if
    
    /**
    * The location that the code is going to be deployed to.
    * Don't forget the trailing slash!
    *
    * @var string Full path including the trailing slash
    */
    /*
    if (!defined('TARGET_DIR')) define('TARGET_DIR', '/tmp/simple-php-git-deploy/');
    */
    if gConfigA["TARGET_DIR"] is empty then
        put "/tmp/simple-livecode-git-deploy/" into gConfigA["TARGET_DIR"]
    end if
    
    /**
    * Whether to delete the files that are not in the repository but are on the
    * local (server) machine.
    *
    * !!! WARNING !!! This can lead to a serious loss of data if you're not
    * careful. All files that are not in the repository are going to be deleted,
    * except the ones defined in EXCLUDE section.
    * BE CAREFUL!
    *
    * @var boolean
    */
    /*
    if (!defined('DELETE_FILES')) define('DELETE_FILES', false);
    */
    if gConfigA["DELETE_FILES"] is empty then
        put false into gConfigA["DELETE_FILES"]
    end if
    
    /**
    * The directories and files that are to be excluded when updating the code.
    * Normally, these are the directories containing files that are not part of
    * code base, for example user uploads or server-specific configuration files.
    * Use rsync exclude pattern syntax for each element.
    *
    * @var serialized array of strings
    */
    /*
    if (!defined('EXCLUDE')) define('EXCLUDE', serialize(array(
    '.git',
    )));
    */
    if gConfigA["EXCLUDE"] is empty then
        put ".git" into gConfigA["EXCLUDE"][1]
    end if
    
    /**
    * Temporary directory we'll use to stage the code before the update. If it
    * already exists, script assumes that it contains an already cloned copy of the
    * repository with the correct remote origin and only fetches changes instead of
    * cloning the entire thing.
    *
    * @var string Full path including the trailing slash
    */
    /*
    if (!defined('TMP_DIR')) define('TMP_DIR', '/tmp/spgd-'.md5(REMOTE_REPOSITORY).'/');
    */
    if gConfigA["TMP_DIR"] is empty then
        put "/tmp/slgd-" & base64Encode(md5Digest(gConfigA["REMOTE_REPOSITORY"])) & "/" into gConfigA["TMP_DIR"]
    end if
    
    /**
    * Whether to remove the TMP_DIR after the deployment.
    * It's useful NOT to clean up in order to only fetch changes on the next
    * deployment.
    */
    /*
    if (!defined('CLEAN_UP')) define('CLEAN_UP', true);
    */
    if gConfigA["CLEAN_UP"] is empty then
        put true into gConfigA["CLEAN_UP"]
    end if
    
    /**
    * Output the version of the deployed code.
    *
    * @var string Full path to the file name
    */
    /*
    if (!defined('VERSION_FILE')) define('VERSION_FILE', TMP_DIR.'VERSION');
    */
    if gConfigA["VERSION_FILE"] is empty then
        put gConfigA["TMP_DIR"] & "VERSION" into gConfigA["VERSION_FILE"]
    end if
    
    /**
    * Time limit for each command.
    *
    * @var int Time in seconds
    */
    /*
    if (!defined('TIME_LIMIT')) define('TIME_LIMIT', 30);
    */
    if gConfigA["TIME_LIMIT"] is empty then
        put 30 into gConfigA["TIME_LIMIT"]
    end if
    
    /**
    * OPTIONAL
    * Backup the TARGET_DIR into BACKUP_DIR before deployment.
    *
    * @var string Full backup directory path e.g. `/tmp/`
    */
    /*
    if (!defined('BACKUP_DIR')) define('BACKUP_DIR', false);
    */
    if gConfigA["BACKUP_DIR"] is empty then
        put false into gConfigA["BACKUP_DIR"]
    end if
    
    /**
    * OPTIONAL
    * Email address to be notified on deployment failure.
    *
    * @var string A single email address, or comma separated list of email addresses
    *      e.g. 'someone@example.com' or 'someone@example.com, someone-else@example.com, ...'
    */
    /*
    if (!defined('EMAIL_ON_ERROR')) define('EMAIL_ON_ERROR', false);
    */
    if gConfigA["EMAIL_ON_ERROR"] is empty then
        put false into gConfigA["EMAIL_ON_ERROR"]
    end if
    
    /*
    // ===========================================[ Configuration end ]===
    
    // If there's authorization error, set the correct HTTP header.
    if (!isset($_GET['sat']) || $_GET['sat'] !== SECRET_ACCESS_TOKEN || SECRET_ACCESS_TOKEN === 'BetterChangeMeNowOrSufferTheConsequences') {
    header($_SERVER['SERVER_PROTOCOL'] . ' 403 Forbidden', true, 403);
    }
    ob_start();
    
    ?>
    */
    
    obStart
    
    if (gGlobalsA["$_GET"]["sat"] is empty) \
          or (gGlobalsA["$_GET"]["sat"] is not gConfigA["SECRET_ACCESS_TOKEN"]) \
          or (gConfigA["SECRET_ACCESS_TOKEN"] is "BetterChangeMeNowOrSufferTheConsequences" ) then
        obHeader gGlobalsA["$_SERVER"]["SERVER_PROTOCOL"] & "403 Forbidden", true, 403
    end if
    
    put obMergeFile(tFilePath & "htmlHeader.lc")
    
    if (gGlobalsA["$_GET"]["sat"] is empty) \
          or (gGlobalsA["$_GET"]["sat"] is not gConfigA["SECRET_ACCESS_TOKEN"]) then
        obPut "<h2>ACCESS DENIED!</h2>"
        exit to top
    end if
    
    -- Dope slap if default access token used...
    if gConfigA["SECRET_ACCESS_TOKEN"] is "BetterChangeMeNowOrSufferTheConsequences" then
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
    if gConfigA["BACKUP_DIR"] is not empty then
        put "tar" into tRequiredBinA[3]
        
        set the defaultFolder to gConfigA["BACKUP_DIR"]
        //obWrite (item 10 of the detailed folders)
        
        -- now also check that the backup directory exists and is write-able
        if (there is not a folder gConfigA["BACKUP_DIR"])  then
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
    obPut "Using configuration defined in" && sConfigFile
    
    obPut "Deploying" && gConfigA["REMOTE_REPOSITORY"] & ";" & gConfigA["BRANCH"]
    obPut "to       " && gConfigA["TARGET_DIR"] 
    
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
    
    if there is not a folder gConfigA["TMP_DIR"] then
        addCommand "git clone --depth=1 --branch" && gConfigA["BRANCH"] && \
              gConfigA["REMOTE_REPOSITORY"] && \
              gConfigA["TMP_DIR"]
    else
        addCommand "git --git-dir=" & gConfigA["TMP_DIR"] & ".git" && \
              "--work-tree=" & gConfigA["TMP_DIR"] && \
              "fetch --tags origin" && gConfigA["BRANCH"]
        
        addCommand "git --git-dir=" & gConfigA["TMP_DIR"] & ".git" && \
              "--work-tree=" & gConfigA["TMP_DIR"] && \
              "reset --hard FETCH_HEAD"
    end if
    
    /*
    // Update the submodules
    $commands[] = sprintf(
    'git submodule update --init --recursive'
    );
    */
    if (gConfigA["UPDATE_SUBMODULES"]) then
        addCommand "git submodule update --init --recursive"
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
    if gConfigA["VERSION_FILE"] is not empty then
        addCommand "git --git-dir=" & gConfigA["TMP_DIR"] & ".git" && \
              "--work-tree=" & gConfigA["TMP_DIR"] &&  \
              "describe --always >" &&  gConfigA["VERSION_FILE"]
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
    if (gConfigA["BACKUP_DIR"] is not false) and (gConfigA["BACKUP_DIR"] is not empty) then
        local tTargetBase, tDate, tOutputDate
        
        set the itemDelimiter to "/"
        put item -1 of gConfigA["TARGET_DIR"] into tTargetBase
        put the internet date into tDate
        convert tDate to dateitems
        set the itemDelimiter to ","
        put item 1 of tDate & format("%02s", item 2 of tDate) & format("%02s", item 3 of tDate) & \
              format("%02s", item 4 of tDate) & format("%02s", item 5 of tDate) & format("%02s", item 6 of tDate) into tOutputDate
        
        addCommand "tar -zcvf" && gConfigA["BACKUP_DIR"] & tTargetBase & "-" & \
              base64Encode(md5Digest(gConfigA["TARGET_DIR"])) & "-" & tOutputDate & ".tar.gz" && \
              gConfigA["TARGET_DIR"]
        --exclude=" & gConfigA["BACKUP_DIR"] & "*" && "
        
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
    repeat for each element excludeMe in gConfigA["EXCLUDE"]
        put " --exclude=" & excludeMe into tExclude
    end repeat
    
    if (gConfigA["DELETE_FILES"]) then
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
    addCommand "rsync -rltgoDzvO" && gConfigA["TMP_DIR"] && gConfigA["TARGET_DIR"] && \
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
    if gConfigA["CLEAN_UP"] then
        local tCleanupCommand
        put "rm -rf" && gConfigA["TMP_DIR"] into tCleanupCommand
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


command addCommand pCommand
    put pCommand into sCommandA[sCommandIndex]
    add 1 to sCommandIndex
end addCommand


command obHeader pHeader, pInit, pCode
  if pInit then
    put "" into sHeaderA
    put 0 into sHeaderIndex
  end if
  
  add 1 to sHeaderIndex
  put pHeader into sHeaderA[sHeaderIndex]
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
