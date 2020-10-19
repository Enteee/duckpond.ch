---
layout: post
categories: [count]
keywords: [Android, App, Ionic, Count, Analytics, Visualizations, ApexCharts]
---

During COVID-19 times it is vital that we don't gather in big groups.
That puts the burden of tacking people in enclosed spaces onto the ones in
charge. Counting is a lot of work with not much reward.

With [Count][count-github] I am beta Beta-releasing an app which wants to change
that. [Count][count-github] helps you keep tack of things but then also provides
visualizations of the data collected.

![Count](/static/posts/count-beta-release/count.jpg){: width="80%" }

Yes, there are quite a few [^1] other counting apps on the Play Store already.
Some other notable projects are:

* [Thing Counter](https://play.google.com/store/apps/details?id=de.sleak.thingcounter&hl=en)
* [Click Counter](https://play.google.com/store/apps/details?id=com.useless.counter&hl=en)
* [Counter](https://play.google.com/store/apps/details?id=me.tsukanov.counter&hl=en)
* [Strichliste](https://play.google.com/store/apps/details?id=de.cliff.strichliste&hl=en)
* [Tally Counter](https://play.google.com/store/apps/details?id=com.visiativity.tallycounter&hl=en)

But they are all not open source, lack important features (looking at the comment
section) and don't do much with the data they are collecting. This is where
[Count][count-github] steps in.

[Count][count-github] is a simple tally counter with advanced visualizations
based on metadata collected during counting. Every time the counter is changed
the app collects time, location and position of the event. Using this data
we can then provide insight about all different aspects such as frequency and
locality.

Would you like to know when people visit which one of your branches?
[Count][count-github] can tell you that.

![Count Preview](/static/posts/count-beta-release/preview.gif)

With this blog post I am starting the open beta of the app. You can join
now if you have an Android phone.

[![Join Android Beta](https://img.shields.io/badge/Join%20Android%20Beta-NOW!-brightgreen)](https://play.google.com/apps/testing/ch.duckpond.count)

If want to contribute to [Count][count-github] you can do this using the
following channels:

<script async defer src="https://buttons.github.io/buttons.js"></script>

* Tweet: [![Twitter URL](https://img.shields.io/twitter/url?label=%23CountApp&url=https%3A%2F%2Fgithub.com%2FEnteee%2Fcount)](https://twitter.com/intent/tweet?text=Count%2C%20Visualize%2C%20Understand&hashtags=CountApp,Ionic,JavaScript,TypeScript&url=https%3A%2F%2Fgithub.com%2FEnteee%2Fcount)
* Star: <a class="github-button" href="https://github.com/Enteee/count" data-icon="octicon-star" data-show-count="true" aria-label="Star Enteee/count on GitHub">Star</a>
* Resolve: <a class="github-button" href="https://github.com/Enteee/count/issues" data-icon="octicon-issue-opened" data-show-count="true" aria-label="Issue Enteee/count on GitHub">Issue</a>
* Donate: <a class="github-button" href="https://github.com/sponsors/Enteee" data-icon="octicon-heart" aria-label="Sponsor @Enteee on GitHub">Sponsor</a>

Thank you.

[^1]: And by a few I mean a lot

[count-github]:https://github.com/Enteee/count
