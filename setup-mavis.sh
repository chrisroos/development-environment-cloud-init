set -x


# Setup dotfiles
cd ~
git clone git@github.com:chrisroos/dotfiles
cd dotfiles
./install


# Explicitly add mise shims to PATH
export PATH="$HOME/.local/share/mise/shims:$PATH"


# Setup MAVIS
cd ~
git clone git@github.com:NHSDigital/manage-vaccinations-in-schools

cd ~/manage-vaccinations-in-schools
git checkout next

## Install mise dependencies
mise install

## Setup the app
bin/setup

## Download and import gias data in mavis to run tests against local Rails app
bin/mavis gias download
RAILS_ENV=end_to_end rails db:setup
RAILS_ENV=end_to_end bin/mavis gias import


# Setup Mavis testing
cd ~
git clone git@github.com:NHSDigital/manage-vaccinations-in-schools-testing
cd ~/manage-vaccinations-in-schools-testing

## Install mise dependencies
mise install

## Update project environment
uv sync

## Configure .env
cp .env.generic .env
## Set http basic auth and password for qa.mavistesting.com

## Install playwright browsers with all required dependencies
uv run playwright install --with-deps


# Setup Mavis reporting
cd ~
git clone git@github.com:NHSDigital/manage-vaccinations-in-schools-reporting.git

cd manage-vaccinations-in-schools-reporting/

mise trust

mise install
