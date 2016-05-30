#allura-install

## Create new user and user group

First, create a new usergroup and add a new user to it named allura.

```bash
groupadd allura
useradd -G allura allura
```

Set password for new user allura and 
TODO

Clone the repository anywhere, then run ``sudo make all`` to install Allura.

