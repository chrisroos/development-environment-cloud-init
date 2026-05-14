This is a cloud-init config file to create a local development environment using multipass. Copied from the one I've created for development on govuk, but stripped of govuk specific tooling.

Create a multipass instance:

```
./bin/create-multipass-instance
```

Use the following to tail the cloud-init log output while the vm is being provisioned.

```
ssh <ip> sudo tail -f /var/log/cloud-init.log
ssh <ip> sudo tail -f /var/log/cloud-init-output.log
```

---

## NHS Dev

```
bin/create-nhs-multipass-instance

# Get the IP of the new instance and add to /etc/hosts
# Be sure to remove any old entry in /etc/hosts
echo "$(multipass info nhs-dev | grep IPv4 | cut -c17-) nhs-dev" | sudo tee -a /etc/hosts

# Remove old entries from ~/.ssh/known_hosts
ssh-keygen -f '/home/chrisroos/.ssh/known_hosts' -R 'nhs-dev'

# Add the following to ~/.ssh/config
# LocalForward 4000 means that connecting to localhost:4000 will make requests to the Mavis Rails app in the multipass instance
# LocalForward 4001 means that connecting to localhost:4000 will make requests to the Mavis Reporting Python app in the multipass instance
Host nhs-dev
  ForwardAgent yes
  LocalForward 4000 localhost:4000
  LocalForward 4001 localhost:4001
```

### Setup AWS CLI

From https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html#sso-configure-profile-token-auto-sso.

```
# Configure AWS CLI using SSO - https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html#sso-configure-profile-token-auto-sso
aws configure sso
# SSO session name: nhs
# SSO start URL: <from NHS AWS SSO item in 1Password>
# SSO region: <from NHS AWS SSO item in 1Password>
# SSO registration scopes: <accept default of sso:account:access>

# Open the URL in the browser I'm signed in to AWS
# It'll redirect to localhost on a random port.
# Copy this URL and use curl to request it in the dev VM to complete the OAuth flow
curl "<oauth-callback-url>"

# You'll be asked a few more questions
# Name the profile as 'default' so that it's used by default

# Test that I can connect
bin/mavis-server shell test
```

### Setup the apps

```
ssh nhs-dev
cd ~/cloud-init
./setup-mavis.sh
```


### Mavis testing

```
ssh nhs-dev

cd ~/manage-vaccinations-in-schools-testing

# Configure .env
# Set http basic auth and password for qa.mavistesting.com

# Run smoke tests against qa
uv run pytest -m smoke

# Run smoke tests against local Rails app
cd ~/manage-vaccinations-in-schools
bin/e2e -m smoke
```
