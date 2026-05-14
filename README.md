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

### Setup Mavis

```
ssh nhs-dev

cd ~
git clone git@github.com:NHSDigital/manage-vaccinations-in-schools

cd ~/manage-vaccinations-in-schools
git checkout next

# Install dependencies
mise install

# Setup the app
bin/setup
```

### Setup Mavis testing

```
ssh nhs-dev

cd ~
git clone git@github.com:NHSDigital/manage-vaccinations-in-schools-testing
cd ~/manage-vaccinations-in-schools-testing

# Install mise dependencies
mise install

# Update project environment
uv sync

# Configure .env
cp .env.generic .env
# Set http basic auth and password for qa.mavistesting.com

# Install playwright browsers with all required dependencies
uv run playwright install --with-deps

# Run smoke tests against qa
uv run pytest -m smoke

# Download and import gias data in mavis to run tests against local Rails app
cd ~/manage-vaccinations-in-schools
bin/mavis gias download
RAILS_ENV=end_to_end bin/rails db:setup
RAILS_ENV=end_to_end bin/mavis gias import

# Run smoke tests against local Rails app
bin/e2e -m smoke
```

### Setup Mavis reporting

```
git clone git@github.com:NHSDigital/manage-vaccinations-in-schools-reporting.git
cd manage-vaccinations-in-schools-reporting/
mise trust
mise install
```
