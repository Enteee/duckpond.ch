---
layout: post
categories: []
keywords: []
---

With [git-sync-mirror], migrating or mirroring a git repository is a piece of
cake. But there are additional steps needed, when when the git repository
references submodules.

# The Problem

They key problem is that when mirroring git repositires submodule references
are not updated. This is because those references are tracked in a `.gitmodules`
file inside the repository. Which is not changed during the migration process.

As an example, imagine you want to mirror the [githubtraining/example-dependency]
repository to [Enteee/example-dependency]. Using [git-sync-mirror] this is simple:

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

[git-submodule-url-rewrite] is a simple git command that lets you rewrite git
submodule urls. Installation of the command is as simple as copying the script
somewhere to your `${PATH}` and making it executable.

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
$ cd example-dependency/
$ git submodule-url-rewrite 's|githubtraining|Enteee|'
rewrite url for submodule 'js' in '/tmp/example-dependency' from 'https://github.com/githubtraining/example-submodule.git' to 'https://github.com/Enteee/example-submodule.git'
```

`git commit && git push`, done!

## Why should I use this?

In this section I try to answer a few common questions. Keep in mind that
[git-submodule-url-rewrite] is a simple `git` command I found useful in the past
and decided to open source. Nobody forces you to use the command and if you find
good reasons not to, then don't. I would still be interested in those reasons.
Why not sharing them here?

> Rewriting a a submodule url is a simple as:
```sh
$ git config --file .gitmodules submodule.js.url 'https://github.com/Enteee/example-submodule.git'
$ git submodule sync
```
> why should I use [git-submodule-url-rewrite]?
>
> -- unknown git user

This is exactly what [git-submodule-url-rewrite] does. No magic there. But
additionaly [git-submodule-url-rewrite] does provide the convenience of regex
and a recursive (`-r`) switch. Using this recursion you can simply rewrite
submodules of submodules of submodules of ... You get the idea.

> But I can just implement the same recursion with
`git submodule foreach --recursive 'git config ...'`.
>
> -- the same unknown git user

Yes. Almost. Please note that `git submodule foreach` evaluates an arbitrary
shell command in each **checked out submodule** [^1]. This means you have to run
`git submodule update --init --recursive` first. Which will connect and clone
to the originally referenced repository. This was not possible in my environment.
Hence I had to implement [a looping mechanism](https://github.com/Enteee/git-submodule-url-rewrite/blob/3d52c605330bebe48c5373fcb5b13dfe8e2264c0/git-submodule-url-rewrite#L109) which does
not rely on `git submodule foreach`.


[^1]: From the [manpage](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-foreach--recursiveltcommandgt)

[git-sync-mirror]:https://hub.docker.com/r/enteee/git-sync-mirror
[githubtraining/example-dependency]:https://github.com/githubtraining/example-dependency.git
[githubtraining/example-submodule]:https://github.com/githubtraining/example-submodule/tree/c3c588713233609f5bbbb2d9e7f3fb4a660f3f72
[Enteee/example-dependency]:https://github.com/Enteee/example-dependency.git
[Enteee/example-submodule]:https://github.com/Enteee/example-submodule.git

[git-submodule-url-rewrite]:https://github.com/Enteee/git-submodule-url-rewrite
