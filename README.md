# Simple Livecode Git Deploy Script
_Automatically deploy code using Livecode and Git._

# STATE OF THE PROJECT

BASIC functionality appears to be working at this time. I am developing on
MacOS 10.12.5 as a reference point ;-) You should be able to deploy
repositories via command line (assuming you have Livecode Server set up
for this on your system) or via a web browser.
  
What's not working?
- email results
- exclude on backup
- exception handling
- timeout on shell commands (could use some help here...)

Also, I have not done any testing yet with Github/Bitbucket yet. It's working
locally. I don't see any reason that this should not work though within the
confines of "What's not working".

If you see an error 23 message from rsync, that's most likely a permissions
issue on the directory you're deploying to.

## Requirements

* `git` and `rsync` are required on the server that's running the script
  (_server machine_).
  - Optionally, `tar` is required for backup functionality (`BACKUP_DIR` option).
* The system user running Livecode Server (e.g. `www-data`) needs to have the necessary access permissions for the `TMP_DIR` and `TARGET_DIR` locations on the _server machine_.
* If the Git repository you wish to deploy is private, the system user running Livecode Server also needs to have the right SSH keys to access the remote repository.

## Usage

 * Configure the script and put it somewhere that's accessible from the
   Internet. The preferred way to configure it is to use `deploy-config.lc` file.
   Rename `deploy-config.example.lc` to `deploy-config.lc` and edit the
   configuration options there. That way, you won't have to edit the configuration
   again if you download the new version of `deploy.lc`.
 * Configure your git repository to call this script when the code is updated.
   The instructions for Git, GitHub (coming soon) and Bitbucket (coming soon) are below.

### GitHub - untested

 1. _(This step is only needed for private repositories)_ Go to
    `https://github.com/USERNAME/REPOSITORY/settings/keys` and add your server
    SSH key.
 1. Go to `https://github.com/USERNAME/REPOSITORY/settings/hooks`.
 1. Click **Add webhook** in the **Webhooks** panel.
 1. Enter the **Payload URL** for your deployment script e.g. `http://example.com/deploy.lc?sat=YourSecretAccessTokenFromDeployFile`.
 1. _Optional_ Choose which events should trigger the deployment.
 1. Make sure that the **Active** checkbox is checked.
 1. Click **Add webhook**.

### Bitbucket - untested

 1. _(This step is only needed for private repositories)_ Go to
    `https://bitbucket.org/USERNAME/REPOSITORY/admin/deploy-keys` and add your
    server SSH key.
 1. Go to `https://bitbucket.org/USERNAME/REPOSITORY/admin/services`.
 1. Add **POST** service.
 1. Enter the URL to your deployment script e.g. `http://example.com/deploy.lc?sat=YourSecretAccessTokenFromDeployFile`.
 1. Click **Save**.

### Generic Git  - untested

 1. Configure the SSH keys.
 1. Add a executable `.git/hooks/post_receive` script that calls the script e.g.

```sh
#!/bin/sh
echo "Triggering the code deployment ..."
wget -q -O /dev/null http://example.com/deploy.lc?sat=YourSecretAccessTokenFromDeployFile
```

## Done!

Next time you push the code to the repository that has a hook enabled, it's
going to trigger the `deploy.lc` script which is going to pull the changes and
update the code on the _server machine_.

For more info, read the source of `deploy.lc`.

## Tips'n'Tricks

 * Because `rsync` is used for deployment, the `TARGET_DIR` doesn't have to be
   on the same server that the script is running e.g. `define('TARGET_DIR',
   'username@example.com:/full/path/to/target_dir/');` is going to work as long
   as the user has the right SSH keys and access permissions.
 * You can have multiple scripts with different configurations. Simply rename
   the `deploy.lc` to something else, for example `deploy_master.lc` and
   `deploy_develop.lc` and configure them separately. In that case, the
   configuration files need to be named `deploy_master-config.lc` and
   `deploy_develop-config.lc` respectively.

## Based on PHP Git deploy script

This project is based on the simple PHP git deploy script by Marko Marković
