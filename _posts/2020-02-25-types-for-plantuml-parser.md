---
title: Types for PlantUML Parser
layout: post
categories: [plantuml-parser, javascript]
keywords: [PlantUML parser, plantuml-parser, TypeScript, JavaScript, Type declarations, Open Source Software]
image: /static/posts/types-for-plantuml-parser/bob-leaves-alice.png
---
[`plantuml-parser`][plantuml-parser] 0.0.12 introduces TypeScript declarations.
Now you can parse PlantUML and get a fully typed result. PlantUML diagrams are awesome!
In this post I first give a brief introduction into PlantUML. Then I
will show how you can use [`plantuml-parser`][plantuml-parser] with TypeScript
to make the most out of your diagrams.

![Bob leaves Alice](/static/posts/types-for-plantuml-parser/bob-leaves-alice.png)
*She wouldn't be my type either*

{::options parse_block_html="true" /}
<details>
  <summary markdown="span" class="center">Show source</summary>
```
@startuml
actor Alice
actor Bob

Alice -> Bob: Tells Bob that\n she does not like\ntypes
Bob --> Alice: Leaves her
@enduml
```
</details>
{::options parse_block_html="true" /}
<details>
  <summary markdown="span" class="center">Show parser result</summary>
```
[
  {
    "elements": [
      {
        "left": "Alice",
        "right": "Bob",
        "leftType": "Unknown",
        "rightType": "Unknown",
        "leftArrowHead": "",
        "rightArrowHead": ">",
        "leftArrowBody": "-",
        "rightArrowBody": "-",
        "leftCardinality": "",
        "rightCardinality": "",
        "label": "Tells Bob that\\n she does not like\\ntypes",
        "hidden": false
      },
      {
        "left": "Bob",
        "right": "Alice",
        "leftType": "Unknown",
        "rightType": "Unknown",
        "leftArrowHead": "",
        "rightArrowHead": ">",
        "leftArrowBody": "-",
        "rightArrowBody": "-",
        "leftCardinality": "",
        "rightCardinality": "",
        "label": "Leaves her",
        "hidden": false
      }
    ]
  }
]
```
</details>

## Table of Contents
{:.no_toc}

* entries
{:toc}

## Why you should use PlantUML

> PlantUML is an open-source tool allowing users to create UML diagrams from a plain text language. The language of PlantUML is an example of a Domain-specific language. It uses Graphviz software to lay out its diagrams.
>
> -- Source: [wikipedia/PlantUML](https://en.wikipedia.org/wiki/PlantUML)

I use PlantUML daily. A textual description of design diagrams alongside the
source code is my definition of a living document. You know the pain of out
of date documentation. Did you ever ask yourself why this happens? As a software
developer I do reject a tool if it does not make my life easier. Writing sound
and solid source code is already hard enough. Having to deal with a ton of different
documentation formats makes it even harder. Belive me, if design changes can be
documented with a few simple modifications of a text file, I will start doing it.

This has the effect that documentation evolves together with the code. Add version
control to the mix and pull requests suddenly become self-documenting. Furthermore,
switching to Graphviz means no longer spending hours layouting documents. Time
better spent doing actual design work.

With PlantUML you can document without proprietary file mongering software or
an overpriced vector graphic editor. In case you ask yourself what all that fuzz
is about. You create your design documents in PowerPoint and you are
happy with it - Then you should probably ask yourself when things started to go wrong
in you life.

![Learn PlantUML](/static/posts/types-for-plantuml-parser/learn-plantuml.png)
*You will find another Alice*

{::options parse_block_html="true" /}
<details>
  <summary markdown="span" class="center">Show source</summary>
```
@startuml
(*) --> If "Do you know PlantUML?" then
  --> [No] "Learn PlantUML"
  If "" then
    --> [I don't\nhave time] "Leave Alice"
    --> "Learn PlantUML"
  else
    --> [Ok] "Good"
  EndIf
else
--> [Yes] "Good"
EndIf
--> "Parse it"
@enduml
```
</details>

You are now completely convinced and/or you already created a lot of documentation
in PlantUML. Good. But at some point you might like to get even more from that the
language. So why not start parsing it?

## Parsing PlantUML with TypeScript

Parsing the syntax to something machine-processable is easy with the command line
[`plantuml-parser`][plantuml-parser].

{::options parse_block_html="true" /}

<details>
  <summary markdown="span" class="center">Show example</summary>

```shell
$ npm install -g plantuml-parser
$ plantuml-parser <<EOF
> @startuml
> package "Wonderful world without Alice" {
>   file Doc
>   file JSON
>   interface PlantUML
>   component "plantuml-parser" as pp
>
>   Doc -right- PlantUML
>   PlantUML ..> pp
>   pp -left-> JSON
> }
> @enduml
> EOF
[
  {
    "elements": [
      {
        "name": "Wonderful world without Alice",
        "title": "Wonderful world without Alice",
        "type": "package",
        "elements": [
          {
            "name": "PlantUML",
            "title": "PlantUML",
            "members": []
          },
          {
            "name": "pp",
            "title": "plantuml-parser"
          },
          {
            "left": "Doc",
            "right": "PlantUML",
            "leftType": "Unknown",
            "rightType": "Unknown",
            "leftArrowHead": "",
            "rightArrowHead": "",
            "leftArrowBody": "-",
            "rightArrowBody": "-",
            "leftCardinality": "",
            "rightCardinality": "",
            "label": "",
            "hidden": false
          },
          {
            "left": "PlantUML",
            "right": "pp",
            "leftType": "Unknown",
            "rightType": "Unknown",
            "leftArrowHead": "",
            "rightArrowHead": ">",
            "leftArrowBody": ".",
            "rightArrowBody": ".",
            "leftCardinality": "",
            "rightCardinality": "",
            "label": "",
            "hidden": false
          },
          {
            "left": "pp",
            "right": "JSON",
            "leftType": "Unknown",
            "rightType": "Unknown",
            "leftArrowHead": "",
            "rightArrowHead": ">",
            "leftArrowBody": "-",
            "rightArrowBody": "-",
            "leftCardinality": "",
            "rightCardinality": "",
            "label": "",
            "hidden": false
          }
        ]
      }
    ]
  }
]
```
</details>

But today we want to have a look at the programmatic use of the parser. Therefore
I created the following demonstration which shows how easy it is to parse PlantUML
in TypeScript. The demonstration also contains an example on how type guards can
leverage processing of diagrams.

<div class="center">
  <script id="asciicast-8FC3oAI3PCtGdljCISvWVo0o8" src="https://asciinema.org/a/8FC3oAI3PCtGdljCISvWVo0o8.js" async></script>
</div>

## Contribute

If you do like the project and you would like to contribute, there are numerous
ways how you can do so. Even if you do not write source code. Every contribution
counts.

<script async defer src="https://buttons.github.io/buttons.js"></script>

* Tweet: [![Twitter URL](https://img.shields.io/twitter/url?label=%23PlantUMLParser&url=https%3A%2F%2Fgithub.com%2FEnteee%2Fplantuml-parser)](https://twitter.com/intent/tweet?text=Parse%20PlantUML%20with%20JavaScript%20or%20TypeScript%20%F0%9F%9A%80&hashtags=PlantUMLParser,JavaScript,TypeScript&url=https%3A%2F%2Fgithub.com%2FEnteee%2Fplantuml-parser)
* Star: <a class="github-button" href="https://github.com/Enteee/plantuml-parser" data-icon="octicon-star" data-show-count="true" aria-label="Star Enteee/plantuml-parser on GitHub">Star</a>
* Resolve: <a class="github-button" href="https://github.com/Enteee/plantuml-parser/issues" data-icon="octicon-issue-opened" data-show-count="true" aria-label="Issue Enteee/plantuml-parser on GitHub">Issue</a>
* Donate: <a class="github-button" href="https://github.com/sponsors/Enteee" data-icon="octicon-heart" aria-label="Sponsor @Enteee on GitHub">Sponsor</a>

Thank you.

[plantuml-parser]:https://github.com/Enteee/plantuml-parser
