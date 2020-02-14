---
layout: post
title: Migrate a git Repository with Submodules
categories: [git-submodule-url-rewrite, git-sync-mirror]
keywords: [git, submodule, sync, bash, mirror, migrate]
---

With [git-sync-mirror] migrating or mirroring a `git` repository is a piece of
cake. But when the migrated repository contains submodules additional steps are
required.

## The Problem

Submodule references are not updated when mirroring `git` repositories. This is
because those references are tracked in a file called `.gitmodules` inside the
repository. This file is not changed during migration.

As an example imagine you want to mirror the [githubtraining/example-dependency]
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

The just mirrored [githubtraining/example-dependency] repository contains one
submodule at `js`. This submodule references the [githubtraining/example-submodule]
repository.

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
before with [githubtraining/example-dependency]. But since we were creating 1:1
mirrors, the first repository [Enteee/example-dependency] still points to
[githubtraining/example-submodule]. This is probably not what we want. The
repository [Enteee/example-dependency] should point to [Enteee/example-submodule]
instead.

## The Solution: [git-submodule-url-rewrite]

[git-submodule-url-rewrite] is a `git` command that lets you rewrite submodule
urls. Installing the command is as simple as copying the script somewhere to
your `${PATH}` and making it executable.

```sh
$ cd /usr/local/bin
$ curl \
  --output git-submodule-url-rewrite \
  https://raw.githubusercontent.com/Enteee/git-submodule-url-rewrite/master/git-submodule-url-rewrite
$ chmod a+x git-submodule-url-rewrite
```

Now, [git-submodule-url-rewrite] should be available as a `git` command.

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

Using this command we can now rewrite all urls in [Enteee/example-dependency].
We just have to use a substituting `sed` command (`s`) which replaces all
`githubtraining` strings with `Enteee`. The following command does this:
`'s|githubtraining|Enteee|'`. For more information about `sed` commands I
recommend [this tutorial on computerhope.com](https://www.computerhope.com/unix/used.htm).

```sh
$ cd example-dependency/
$ git submodule-url-rewrite 's|githubtraining|Enteee|'
rewrite url for submodule 'js' in '/tmp/example-dependency' from 'https://github.com/githubtraining/example-submodule.git' to 'https://github.com/Enteee/example-submodule.git'
```

`git commit && git push`, done!

### Why should I use this?

In this section I try to answer a few common questions. Keep in mind that
[git-submodule-url-rewrite] is a very simple `git` command which I found useful
in the past. Hence, I decided to open source it. Nobody forces you to use it.
If you find good reasons not to, then don't. In order to improve
[git-submodule-url-rewrite], I would still be interested in those reasons.
Why not share them here?

> Rewriting a a submodule url is a simple as:
```sh
$ git config --file .gitmodules submodule.js.url 'https://github.com/Enteee/example-submodule.git'
$ git submodule sync
```
> why should I use [git-submodule-url-rewrite]?
>
> -- unknown `git` user

This is exactly what [git-submodule-url-rewrite] does. No magic involved. But
in addition, [git-submodule-url-rewrite] provides the convenience of regex
and a recursive (`[-r|--recursive]`) switch. Using recursion you can simply rewrite submodules
of submodules of submodules of ... You get the idea.

> But I can just implement the same recursion with
`git submodule foreach --recursive 'git config ...'`.
>
> -- the same unknown `git` user

Yes. Almost. Please note that `git submodule foreach` evaluates an arbitrary
shell command in each **checked out submodule** [^1]. This means you have to run
`git submodule update --init --recursive` first. Which will connect and clone
to the originally referenced repository. This was not possible in my environment.
Also, looping over all submodules in a shell script, without `git submodule foreach`,
is not trivial [^2][^3]. Hence, I had to implement [a looping mechanism](https://github.com/Enteee/git-submodule-url-rewrite/blob/3d52c605330bebe48c5373fcb5b13dfe8e2264c0/git-submodule-url-rewrite#L109) which does
not rely on `git submodule foreach`.

By open sourcing [git-submodule-url-rewrite], I do hope I can provide functionality
which maybe does help others. If you find a bug or have a feature request, please
open an issue on GitHub. All comments and thoughts are welcome here on this page.


[^1]: From the [manpage](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-foreach--recursiveltcommandgt)
[^2]: See: [this answer on StackOverflow](https://stackoverflow.com/questions/12641469/list-submodules-in-a-git-repository/56912913#56912913)
[^3]: Maybe I should implement a command that does just that at some point.

[git-sync-mirror]:https://hub.docker.com/r/enteee/git-sync-mirror
[githubtraining/example-dependency]:https://github.com/githubtraining/example-dependency.git
[githubtraining/example-submodule]:https://github.com/githubtraining/example-submodule/tree/c3c588713233609f5bbbb2d9e7f3fb4a660f3f72
[Enteee/example-dependency]:https://github.com/Enteee/example-dependency.git
[Enteee/example-submodule]:https://github.com/Enteee/example-submodule.git

[git-submodule-url-rewrite]:https://github.com/Enteee/git-submodule-url-rewrite
