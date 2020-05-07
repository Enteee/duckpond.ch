---
layout: post
categories: [python, bash]
keywords: [pandas, DataFrame, to_csv, encoding, utf-8, latin, monkey patch]
title: Support Binary File Objects for pandas.DataFrame.to_csv
---

`pandas.DataFrame.to_csv` does not support writing to binary file objects [^1].
This causes confusion [^2][^3][^4][^5] and makes the function difficult to work
with. In this article I will first illustrate the problem with an example.
Then, I will present a monkey patch for `pandas.DataFrame.to_csv` which mitigates
the known pitfall.

Let us write two files containing the names of three beautiful Swiss cities (in descending order).
```python
data = ["Bern", "Genève", "Zürich"]
```

The files we will write are `cities-utf-8.csv` which is in `utf-8` encoding
an `cities-latin.csv` in `ISO/IEC 8859-1 (latin)`.
```python
DataFrame(data).to_csv("cities-utf-8.csv", index=False)
DataFrame(data).to_csv("cities-latin.csv", encoding="latin", index=False)
```

Everything works as expected and the files are written in `utf-8` and `latin`
encoding respectively.

```sh
$ file cities-*.csv
cities-latin.csv: ISO-8859 text
cities-utf-8.csv: UTF-8 Unicode text
$ hexdump -C cities-latin.csv
00000000  30 0a 42 65 72 6e 0a 47  65 6e e8 76 65 0a 5a fc  |0.Bern.Gen.ve.Z.|
00000010  72 69 63 68 0a                                    |rich.|
00000015
$ hexdump -C cities-utf-8.csv
00000000  30 0a 42 65 72 6e 0a 47  65 6e c3 a8 76 65 0a 5a  |0.Bern.Gen..ve.Z|
00000010  c3 bc 72 69 63 68 0a                              |..rich.|
00000017
```

So far so good. But what if we want to write those to a file object instead?

```python
with open("cities-utf-8.csv", mode="w") as fd:
  DataFrame(data).to_csv(fd, index=False)

with open("cities-latin.csv", mode="w") as fd:
  DataFrame(data).to_csv(fd, encoding="latin", index=False)
```

Both files look suddenly very similar:

```python
$ file cities-*.csv
cities-latin.csv: UTF-8 Unicode text
cities-utf-8.csv: UTF-8 Unicode text
$ hexdump -C cities-latin.csv
00000000  30 0a 42 65 72 6e 0a 47  65 6e c3 a8 76 65 0a 5a  |0.Bern.Gen..ve.Z|
00000010  c3 bc 72 69 63 68 0a                              |..rich.|
00000017
$ hexdump -C cities-utf-8.csv
00000000  30 0a 42 65 72 6e 0a 47  65 6e c3 a8 76 65 0a 5a  |0.Bern.Gen..ve.Z|
00000010  c3 bc 72 69 63 68 0a                              |..rich.|
00000017
```

In fact, they are exactly the same.
```
$ sha256sum cities-*.csv
ab401dff37c00f4d22e4ab2aa70fa2d67d89bd042787cb9e643bea7eeb5ee577  cities-latin.csv
ab401dff37c00f4d22e4ab2aa70fa2d67d89bd042787cb9e643bea7eeb5ee577  cities-utf-8.csv
```

Well, obviously. In order to be able to write a different encoding than `utf-8`
we have to open the files in binary mode:
```python
with open("cities-utf-8.csv", mode="wb") as fd:
  DataFrame(data).to_csv(fd, index=False)

with open("cities-latin.csv", mode="wb") as fd:
  DataFrame(data).to_csv(fd, encoding="latin", index=False)
```

Which gives us a lovely: `TypeError: a bytes-like object is required, not 'str'`.
Turns out that `pandas.DataFrame.to_csv` can not write to a binary file object.
As a work around [people have suggest just wrapping the file object in a `io.TextIOWrapper`](https://github.com/pandas-dev/pandas/issues/23854#issuecomment-440910802):

```python
with open("cities-utf-8.csv", mode="wb") as fd:
  DataFrame(data).to_csv(TextIOWrapper(fd), index=False)

with open("cities-latin.csv", mode="wb") as fd:
  DataFrame(data).to_csv(TextIOWrapper(fd), encoding="latin", index=False)
```

Which runs, but does not work because it also discards the encoding. On top of
that, `TextIOWrapper` closes `fd` if we don't call `TextIOWrapper.detach` before
the wrapper is freed. Which brings us back to square one.

The best solution to this bug (or [documentation issue](https://github.com/pandas-dev/pandas/issues/23854#issuecomment-440910802)) would be to create a pull request which implements
support for binary file objects. Sadly, updating `pandas` is just not an viable
option for me right now. Therefore I had to implement the following hackish
solution which monkey patches `pandas.DataFrame.to_csv` so that the function
supports binary file objects.

```python
from contextlib import contextmanager
from threading import Semaphore

MONKEY_PATCH_DATAFRAME_TO_CSV = Semaphore()

@contextmanager
def monkey_patch__DataFrame_to_csv():
    """Monkey patch pandas.DataFrame.to_csv to make the function work with binary file objects.

    This is here because to work around the following issues:
      - https://github.com/pandas-dev/pandas/issues/9712
      - https://github.com/pandas-dev/pandas/issues/19827
      - https://github.com/pandas-dev/pandas/issues/13068
      - https://github.com/pandas-dev/pandas/issues/23854
    """

    import pandas as pd
    _DataFrame_to_csv_orig = pd.DataFrame.to_csv

    def _DataFrame_to_csv(self, path_or_buf, *args, **kwargs):
        from io import RawIOBase, BufferedIOBase, StringIO

        # Test if binary: https://stackoverflow.com/a/44584871
        if isinstance(path_or_buf, (RawIOBase, BufferedIOBase)):
            # Set line terminator of StringIO objec to DataFrame.to_csv's
            # default for line_termnator
            if int(pd.__version__.split(".")[1]) < 24:
                # the default was changed in pandas 0.24 version
                default_line_termnator = "\n"
            else:
                from os import linesep

                default_line_termnator = linesep

            # Note: Other than to_csv, StringIO will reject uncommon line terminators
            # by throwing an exception. But I think that's a good thing.
            sio = StringIO(
                newline=kwargs.get("line_terminator", default_line_termnator)
            )

            ret = _DataFrame_to_csv_orig(
                self,
                sio,
                *args,
                **{
                    **kwargs,
                    **{
                        # enforce utf-8, this is currently ignored because of:
                        # https://github.com/pandas-dev/pandas/issues/13068
                        # but if that issue ever gets fixed we prevent
                        # double-encoding with this.
                        "encoding": "utf-8",

                        # enforce mode, this is currently ignored because of:
                        # https://github.com/pandas-dev/pandas/issues/19827
                        # but if that issue ever gets fixed we our patch
                        # should still work.
                        "mode": "w",

                        # always use Unix-style line_terminators. The conversion
                        # line_teminator will happen on StringIO.write
                        "line_terminator": "\n",
                    },
                }
            )

            path_or_buf.write(
                sio.getvalue().encode(
                    # encode to the specified encoding or fall back
                    # to pandas documented default
                    kwargs.get("encoding", "utf-8")
                )
            )
            return ret

        return _DataFrame_to_csv_orig(self, path_or_buf, *args, **kwargs)

    # apply monkey patch
    pd.DataFrame.to_csv = _DataFrame_to_csv

    # Since we are patching in global scope, we have to
    # ensure here that only one thread runs at the time.
    # Otherwise monkey patching and reverting the patch
    # can go really wrong...
    with MONKEY_PATCH_DATAFRAME_TO_CSV:
      try:
        yield _DataFrame_to_csv
      finally:
        # restore original to_csv
        pd.DataFrame.to_csv = _DataFrame_to_csv_orig
```

If we now use this monkey patch, we can finally generate the files
```python
with __monkey_patch__DataFrame_to_csv():

  with open("cities-utf-8.csv", mode="wb") as fd:
    DataFrame(data).to_csv(fd, index=False)

  with open("cities-latin.csv", mode="wb") as fd:
    DataFrame(data).to_csv(fd, encoding="latin", index=False)
```

... and get the expected content:
```sh
$ file cities-*.csv
cities-latin.csv: ISO-8859 text
cities-utf-8.csv: UTF-8 Unicode text
$ hexdump -C cities-latin.csv
00000000  30 0a 42 65 72 6e 0a 47  65 6e e8 76 65 0a 5a fc  |0.Bern.Gen.ve.Z.|
00000010  72 69 63 68 0a                                    |rich.|
00000015
$ hexdump -C cities-utf-8.csv
00000000  30 0a 42 65 72 6e 0a 47  65 6e c3 a8 76 65 0a 5a  |0.Bern.Gen..ve.Z|
00000010  c3 bc 72 69 63 68 0a                              |..rich.|
00000017
```

[^1]: `pandas.__version__ == "1.0.3"`
[^2]:[to_csv and bytes on Python 3][pandas-issue-9712]
[^3]:[Python 3 writing to_csv file ignores encoding argument][pandas-issue-13068]
[^4]:[df.to_csv() ignores encoding when given a file object or any other filelike object][pandas-issue-23854]
[^5]:[File mode in `to_csv` is ignored, when passing a file object instead of a path][pandas-issue-19827]

[pandas-issue-9712]:https://github.com/pandas-dev/pandas/issues/9712
[pandas-issue-19827]:https://github.com/pandas-dev/pandas/issues/19827
[pandas-issue-13068]:https://github.com/pandas-dev/pandas/issues/13068
[pandas-issue-23854]:https://github.com/pandas-dev/pandas/issues/23854
