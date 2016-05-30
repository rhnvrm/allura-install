
#allura-install
1. Set up your [digital ocean](http://digitalocean.com) account and spin up a new `Ubuntu 14.04` droplet.
2. SSH into your droplet's root `ssh root@<DO_id>` and
clone the repository using `git clone https://rhnvrm@forge-allura.apache.org/git/u/rhnvrm/allura-install`
3. Change your working directory into the cloned repository. `cd allura-install`
4. Install `git` and `make` using `apt-get install git make`
5. Run `make install`
