---
layout: post
categories: []
keywords: []
---

With [git-sync-mirror], migrating a git repository is a piece of cake. But there
are additional steps needed, when when the migrated git repository references
submodules.

# The Problem

When mirroring git repositires, submodule references are not updated. As an
example, imagine you want to mirror the [githubtraining/example-dependency]
repository to [Enteee/example-dependency].

Using [git-sync-mirror] this is simple:

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
This submodule references the [githubtraining/example-submodule] repository.

```sh
$ git clone https://github.com/githubtraining/example-dependency.git
Cloning into 'example-dependency'...
remote: Enumerating objects: 39, done.
remote: Counting objects: 100% (39/39), done.
remote: Compressing objects: 100% (30/30), done.
remote: Total 39 (delta 5), reused 39 (delta 5), pack-reused 0
Unpacking objects: 100% (39/39), done.
$ cat example-dependency/.gitmodules
[submodule "js"]
  path = js
  url = https://github.com/githubtraining/example-submodule.git
````

For a full migration we now also have to mirror [githubtraining/example-submodule]
to [Enteee/example-submodule]. We can do this exactly the same way as we did it
before with [githubtraining/example-dependency].

But since we were creating 1:1 mirrors, the first repository [Enteee/example-dependency]
still points to [githubtraining/example-submodule]. Which is probably not what we
want. The repository [Enteee/example-dependency] should point to [Enteee/example-submodule]
instead.

# The Solution: [git-submodule-url-rewrite]

[git-submodule-url-rewrite] is a simple git command that let's you rewrite git
submodule urls.

Installation of the command is as simple as copying the script somewhere to
your `${PATH}` and making it executable.

```sh
$ cd /usr/local/bin
$ curl \
  --output git-submodule-url-rewrite \
  https://raw.githubusercontent.com/Enteee/git-submodule-url-rewrite/master/git-submodule-url-rewrite
$ chmod a+x git-submodule-url-rewrite
```

Now, [git-submodule-url-rewrite] should be available as a git command.

```sh
$ git submodule-url-rewrite -h
usage: git submodule-url-rewrite [-h|--help] [-v|--verbose] [-q|--quiet] [-r|--recursive] [-s|--no-stage] [-u|--no-update] sed-command

Rewrites all submodule urls using the given sed-script

options:
  -h|--help       Print this help
  -v|--verbose    Make this script verbose
  -q|--quiet      Don't print anything
  -r|--recursive  Also rewrite submodules of submodules
  -s|--no-stage   Don't stage changed .gitmodule files for commit
  -u|--no-update  Don't run 'git submodule --quiet update --init' in each submodule

sed-command: A sed command used to transform urls.
```

Using this command we can now simply rewrite all urls in [Enteee/example-dependency].
```sh
$ git submodule-url-rewrite 's|githubtraining|Enteee|'
rewrite url for submodule 'js' in '/tmp/example-dependency' from 'https://github.com/githubtraining/example-submodule.git' to 'https://github.com/Enteee/example-submodule.git'
```

`git commit && git push`, done!

[git-sync-mirror]:https://hub.docker.com/r/enteee/git-sync-mirror
[githubtraining/example-dependency]:https://github.com/githubtraining/example-dependency.git
[githubtraining/example-submodule]:https://github.com/githubtraining/example-submodule/tree/c3c588713233609f5bbbb2d9e7f3fb4a660f3f72
[Enteee/example-dependency]:https://github.com/Enteee/example-dependency.git
[Enteee/example-submodule]:https://github.com/Enteee/example-submodule.git

[git-submodule-url-rewrite]:https://github.com/Enteee/git-submodule-url-rewrite
