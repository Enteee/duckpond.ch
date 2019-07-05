---
layout: post
categories: []
keywords: []
---

With [git-sync-mirror], migrating a git repository is a piece of cake. But
when the migrated git repository contains submodules there are additthere steps
needed.

# The Problem

When mirroring git repositires, submodule references are not updated. As an
example, imagine you want to mirror the [githubtraining/example-dependency] 
repository to [Enteee/example-dependency].

Using [git-sync-mirror] this is as simple as:

```sh
$ GITHUB_USER="Enteee"
$ GITHUB_ACCESS_TOKEN="<hidden>"

$ docker run \
  --rm \
  --env ONCE=true \
  --env SRC_REPO="https://github.com/githubtraining/example-dependency.git" \
  --env DST_REPO=https://${GITHUB_USER}:${GITHUB_ACCESS_TOKEN}@github.com/Enteee/example-dependency.git \
  enteee/git-sync-mirror
```

The just mirrored [githubtraining/example-dependency] repository contains one submodule at `js`.
The [githubtraining/example-submodule] repository.

```sh
$ git clone https://github.com/githubtraining/example-dependency.git
$ git -C example-dependency submodule
-c3c588713233609f5bbbb2d9e7f3fb4a660f3f72 js
````

We now mirror [githubtraining/example-submodule] to [Enteee/example-submodule] the same way.

But since we were creating 1:1 mirrors, [Enteee/example-dependency] still points to [githubtraining/example-submodule].

# The Solution: [git-submodule-url-rewrite]

[git-submodule-url-rewrite] is a simple git command that let's you rewrite git
submodule urls.

Installation of the command is as simple as copying the script somewhere to
your `${PATH}` and making it executable.

```sh
$ cd /usr/local/bin
$ curl \
  https://raw.githubusercontent.com/Enteee/git-submodule-url-rewrite/master/git-submodule-url-rewrite \
  --output git-submodule-url-rewrite 
$ chmod a+x git-submodule-url-rewrite
```

Now, [git-submodule-url-rewrite] should be available as a git command.

```sh
$ git submodule-url-rewrite -h
usage: git submodule-url-rewrite [-h|--help] [-r|--recursive] sed-script

Rewrites all submodule urls using the given sed-script

options:
  -h|--help       Print this help
  -v|--verbose    Make this script verbose
  -r|--recursive  Also rewrite submodules of submodules
  -u|--update     Run 'git submodule update --init' after url rewrite
```

[git-sync-mirror]:https://hub.docker.com/r/enteee/git-sync-mirror
[githubtraining/example-dependency]:https://github.com/githubtraining/example-dependency.git
[githubtraining/example-submodule]:https://github.com/githubtraining/example-submodule/tree/c3c588713233609f5bbbb2d9e7f3fb4a660f3f72
[Enteee/example-dependency]:https://github.com/Enteee/example-dependency.git
[Enteee/example-submodule]:https://github.com/Enteee/example-submodule.git

[git-submodule-url-rewrite]:https://github.com/Enteee/git-submodule-url-rewrite
