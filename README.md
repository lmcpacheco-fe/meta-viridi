# meta-viridi
This repo contains the meta layer for the Viridi platform.

## Build Steps

### Install the Repo Tool

This step can be skipped if repo is already installed.

Feel free to replace `~/bin` with a different directory for storing binaries.

- `mkdir ~/bin`
- `curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo`
- `chmod a+x ~/bin/repo`
- `echo export PATH=~/bin:$PATH >> ~/.bashrc`
- `source ~/.bashrc`

### Initialize the project

- `cd <path-to-projects-directory>`
- `mkdir <project-name>`
- `cd <project-name>`
- `repo init -u https://github.com/nxp-imx/imx-manifest.git -b imx-linux-walnascar -m imx-6.12.20-2.0.0.xml`
- `repo sync`
- `MACHINE=viridi-imx91 DISTRO=fsl-imx-wayland source imx-setup-release.sh -b build`

### Add the Meta Layer

- `cd ../sources`
- `git clone git@github.com:lmcpacheco-fe/meta-viridi.git`
- `bitbake-layers add-layer meta-viridi`

### Build an Image

A custom image should be designed, but for testing the needed recipes can be manually added to `<project-directory>/build/conf/local.conf`. Our configuration files have been copied into this layer as a reference.

- `bitbake core-image-minimal`

If this is done again later, remeber to first:

- `cd <project-directory>`
- `source setup-environment build` 
