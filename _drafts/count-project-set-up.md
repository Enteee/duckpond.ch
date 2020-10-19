---
layout: post
categories: [count]
keywords: [Android, App]
---

During COVID-19 times it is vital that people don't gather in big groups.
That puts the burden of tacking people in enclosed spaces onto the people in
charge of those places. Shop owners, bouncers, bus drivers and conductors have
to constantly keep track of people.

Counting is a lot of work with not much reward for the person
having to carry out the tedious task. With that in mind, the idea was born
for [count][count-github]. [count][count-github] is an app that helps you keep
tack of things but then provides visualizations of the data collected.

![Count](/static/posts/count-project-set-up/count.jpg){: width="80%" }

Yes, there's a quite a few [^1] other counting apps on the playstore already.
Some other notable projects are:

* [Thing Counter](https://play.google.com/store/apps/details?id=de.sleak.thingcounter&hl=en)
* [Click Counter](https://play.google.com/store/apps/details?id=com.useless.counter&hl=en)
* [Counter](https://play.google.com/store/apps/details?id=me.tsukanov.counter&hl=en)
* [Strichliste](https://play.google.com/store/apps/details?id=de.cliff.strichliste&hl=en)
* [Tally Counter](https://play.google.com/store/apps/details?id=com.visiativity.tallycounter&hl=en)

But they are all not open source, lack important features (looking at the comment
section) and don't do much with the data they are collecting. This is where
[count][count-github] steps in. [count][count-github] is a simple tally counter
with advanced visualizations based on metadata collected during counting. Every
time the counter is changed the app collects time, location and position of the
event. Using this data we can then provide insight about all different aspects
such as frequency and locality. Would you like to know when people visit which
one of your branches? [count][count-github] can tell you that.

With this blog post I am starting the open beta of the app. You can join
now if you do have an Android phone: [![Join Android Beta](https://img.shields.io/badge/Join%20Android%20Beta-NOW!-brightgreen)](https://play.google.com/apps/testing/ch.duckpond.count)

If you are interested contributing to [count][count-github] you can do this by
using the following channels:

<script async defer src="https://buttons.github.io/buttons.js"></script>

* Tweet: [![Twitter URL](https://img.shields.io/twitter/url?label=%23CountApp&url=https%3A%2F%2Fgithub.com%2FEnteee%2Fcount)](https://twitter.com/intent/tweet?text=Count%2C%20Visualize%2C%20Understand&hashtags=CountApp,Ionic,JavaScript,TypeScript&url=https%3A%2F%2Fgithub.com%2FEnteee%2Fcount)
* Star: <a class="github-button" href="https://github.com/Enteee/count" data-icon="octicon-star" data-show-count="true" aria-label="Star Enteee/count on GitHub">Star</a>
* Resolve: <a class="github-button" href="https://github.com/Enteee/count/issues" data-icon="octicon-issue-opened" data-show-count="true" aria-label="Issue Enteee/count on GitHub">Issue</a>
* Donate: <a class="github-button" href="https://github.com/sponsors/Enteee" data-icon="octicon-heart" aria-label="Sponsor @Enteee on GitHub">Sponsor</a>

Thank you.

## Table of Contents
{:.no_toc}

* entries
{:toc}

## Where the Project Lives

Like with every good open source project, I spent at least a day choosing a name [^2].
Then I set up a [repository on Github][count-github] and linked it to [IssueHunt][count-issuehunt]
Linking it to [IssueHunt][count-issuehunt] was an important step. I do plan to
release the whole source code open source, but I also want to explore
possible monetization channels which work well for open source development.

For this reason I have planned supporting the following channels:
1. **[IssueHunt][count-issuehunt]** for people interested in supporting one specific feature.
2. **[Liberapay]** for people who would like to support me and my work in general.
3. **In-App purchase** for recurring app users. In order to pay for licenses and infrastructure.

## Choosing a Framework

Not an easy question is the one about which framework to use. There are just so
many these days [^4]. There's already quite a few [^1] framework comparison articles
out there [^3]. Having looked at some of them and consolidating the most important
facts, I would like to share the follwing comparison (definitely non exhaustive).

{:.table}
|     | Android Native | Ionic | React Native | PhoneGap / Cordova |
| --- | -------------- | ----- | ------------ | -------- |
| Language | Java | JavaScript / CSS / HTML / Angular / Vue / React | JavaScript / React | JavaScript / CSS / HTML |
| Costs | Free | Free | Free | Free |
| License | ? | MIT | MIT | Apache License, Version 2.0 |
| iOS-Support | No | Yes | Yes | Yes |
| Speed | ++ | + | ++ | +++ |
| In-App Purchase | | [Cordova Plugin](https://ionicframework.com/docs/native/in-app-purchase) | | |
| Widgets | Yes |  No | Yes | Using Plugins |
| Out of the Box Components | No | Yes | No | No |

The major decision is the one about going native (react native) or cordova based
(ionic, PhonGap). Whilst even native apps can use cordova to render non-native
content, going full non-native promises better integration with existing charting
libraries. Since the charting libraries I know are mostly written or transpiled
to JavaScript. The good looking components and easy integration with advanced
charting libraries are the main reasons why I chose Ionic.

### Charts Library

{:.table}
|     | AnyChart | Chart.js | ApexChart | AMChart |
| --- | -------- | -------- | --------- | ------- |
| Costs | $499 / year | Free | Free | 1200 $ |
| Open Source | Yes | Yes | Yes | - |
| License | BSD | MIT | MIT | [Custom](https://github.com/amcharts/amcharts4/blob/master/dist/script/LICENSE) |
| Maps | Yes | No | No | 600 $ |
| Touch & Mobile | Yes | No | Responsive | Responsive & Touch |
| Export | Yes | No | Yes | Yes |
| Dark Mode | | | Yes | |

Among all of those the only truly free and open source library is ApexChart.
I do believe that open source projects should support each other. Therefore,
I have chose ApexChart.

## Design

Next, I want to share some of my design slides without commenting much on them.

* [Ideas for all different visualizations](/static/posts/count-project-set-up/graph-types.svg)
* [Full screen counting](/static/posts/count-project-set-up/full-screen-count.svg)
* [Another idea for full screen counting](/static/posts/count-project-set-up/full-screen-count2.svg)
* [Create a new counter](/static/posts/count-project-set-up/creat-new-counter.svg)
* [Show counter details](/static/posts/count-project-set-up/counter-details.svg)

[^1]: And by a few I mean a lot
[^2]: The fact that I settled for [count][count-github] gives you an idea about how creative I am.
[^3]: Having studied quite a few of them [^1], they all seem to be super biased.
[^4]: And another one is probably trending right now on Hacker News

[count-github]:https://github.com/Enteee/count
[count-issuehunt]:https://issuehunt.io/r/Enteee/count
[Liberapay]:https://liberapay.com/Ente/
