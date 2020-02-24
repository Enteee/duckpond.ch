---
layout: post
categories: []
keywords: [PlantUML parser, plantuml-parser, TypeScript, JavaScript]
---
[`plantuml-parser`][plantuml-parser] 0.0.11 introduces TypeScript declarations.
Now you can parse PlantUML and get a fully typed result. PlantUML diagrams are awesome!
In this post I first give a brief introduction into PlantUML. Then I
will show how [`plantuml-parser`][plantuml-parser] with Typescript to makes the
most out of your diagrams.

![Bob leaves Alice](/static/posts/plantuml-parser/bob-leaves-alice.png)
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

## Table of Contents
{:.no_toc}

* entries
{:toc}

## What is PlantUML?

> PlantUML is an open-source tool allowing users to create UML diagrams from a plain text language. The language of PlantUML is an example of a Domain-specific language. It uses Graphviz software to lay out its diagrams. It has been used to allow blind students to work with UML. PlantUML also helps blind software engineers to design and read UML diagrams.
> 
> -- Source: [wikipedia/PlantUML](https://en.wikipedia.org/wiki/PlantUML)

I use PlantUML daily. A textual description of design diagrams alongside the
source code is my definition of a living document. Belive me if design changes
can be documented with a few simple modifications to a text file, your devs
will start doing it. This will make your documentation evolve together with
the code. Bring version control into the mix and pull requests suddenly become
self-documenting. Switching to Graphviz documentation means no longer spending
hours layouting documents. Time you can use doing actual design work.

You can document without proprietary file mongering software or an overpriced
vector graphic editor. If you now ask yourself what all that fuzz is about,
because you create your design documents in PowerPoint and you are happy with it -
then You should probably ask yourself when things started to go wrong in you life.

![Learn PlantUML](/static/posts/plantuml-parser/learn-plantuml.png)
*You will find another Alice*

{::options parse_block_html="true" /}
<details>
  <summary markdown="span" class="center">Show source</summary>
```
@startuml
(*) --> If "Do you know PlantUML?" then
--> [No] "Learn PlantUML"
  If "" then
    --> [I don't have Time] "Leave Alice"
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

With [`plantuml-parser`][plantuml-parser] parsing the Syntax into something which
is machine-processable is easy. 

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

But today we will see how easy this is to do the same in TypeScript.

[plantuml-parser]:https://github.com/Enteee/plantuml-parser
