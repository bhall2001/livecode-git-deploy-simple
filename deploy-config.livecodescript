script "deploy-config"
deploy-config.livecodescript
/**
* Deployment configuration
*
* It's preferable to configure the script using this file instead of directly.
*
* Rename this file to `deploy-config.lc` and edit the
* configuration options here instead of directly in `deploy.lc`.
* That way, you won't have to edit the configuration again if you download the
* new version of `deploy.lc`.
*
* @version 0.0.1
*/
global gConfigA

/**
* Protect the script from unauthorized access by using a secret access token.
* If it's not present in the access URL as a GET variable named `sat`
* e.g. deploy.lc?sat=Bett...s the script is not going to deploy.
*
* @var string
*/
put "BetterChangeMeNowOrSufferTheConsequences" into gConfigA["SECRET_ACCESS_TOKEN"]

/**
* The address of the remote Git repository that contains the code that's being
* deployed.
* If the repository is private, you'll need to use the SSH address.
*
* @var string
*/
put "https://github.com/bhall201/simple-livecode-git-deploy.git" into gConfigA["REMOTE_REPOSITORY"]

/**
* The branch that's being deployed.
* Must be present in the remote repository.
*
* @var string
*/
put "master" into gConfigA["BRANCH"]

/**
* The location that the code is going to be deployed to.
* Don't forget the trailing slash!
*
* @var string Full path including the trailing slash
*/
put "/tmp/simple-livecode-git-deploy/" into gConfigA["TARGET_DIR"]

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
put false into gConfigA["DELETE_FILES"]

/**
* The directories and files that are to be excluded when updating the code.
* Normally, these are the directories containing files that are not part of
* code base, for example user uploads or server-specific configuration files.
* Use rsync exclude pattern syntax for each element.
*
* @var serialized array of strings
*/
put ".git" into gConfigA["EXCLUDE"][1]

/**
* Temporary directory we'll use to stage the code before the update. If it
* already exists, script assumes that it contains an already cloned copy of the
* repository with the correct remote origin and only fetches changes instead of
* cloning the entire thing.
*
* @var string Full path including the trailing slash
*/
/*define('TMP_DIR', '/tmp/spgd-'.md5(REMOTE_REPOSITORY).'/');*/
put "/tmp/slgd-" & md5Digest(gConfigA["REMOTE_REPOSITORY"]) into gConfigA["TMP_DIR"]

/**
* Whether to remove the TMP_DIR after the deployment.
* It's useful NOT to clean up in order to only fetch changes on the next
* deployment.
*/
/*define('CLEAN_UP', true);*/
put true into gConfigA["CLEAN_UP"]

/**
* Output the version of the deployed code.
*
* @var string Full path to the file name
*/
/*define('VERSION_FILE', TMP_DIR.'VERSION');*/
put TMP_DIR & "VERSION" into gConfigA["VERSION_FILE"]

/**
* Time limit for each command.
*
* @var int Time in seconds
*/
/*define('TIME_LIMIT', 30);*/
put 30 into gConfigA["TIME_LIMIT"]

/**
* OPTIONAL
* Backup the TARGET_DIR into BACKUP_DIR before deployment.
*
* @var string Full backup directory path e.g. `/tmp/`
*/
/*define('BACKUP_DIR', false);*/
put false into gConfigA["BACKUP_DIR"]

/**
* OPTIONAL
* Email address to be notified on deployment failure.
*
* @var string A single email address, or comma separated list of email addresses
*      e.g. 'someone@example.com' or 'someone@example.com, someone-else@example.com, ...'
*/
/*define('EMAIL_ON_ERROR', false);*/
put false into gConfigA["EMAIL_ON_ERROR"]
