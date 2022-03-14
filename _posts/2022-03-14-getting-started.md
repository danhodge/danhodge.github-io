---
layout: post
title:  "Getting Started"
date:   2022-03-14 18:03:45 -0400
categories: tools
tags: jekyll ruby
---
I set this blog up a long time ago but never went any further than that.
When I came back to it last week, my first order of business was updating it to the latest versions of the `github-pages` and `jekyll` gems.
Had I actually updated the theme to a non-stock Jekyll theme, I could have been in trouble, since the standard way to change the theme of your Jekyll site used to be fork the GitHub repository of the theme you want to use and then start tweaking it.
Had I forked a theme that hasn't been updated in six years, upgrading to the latest version of `jekyll` could have broken the custom theme or at least required me to shuffle around files and configuration manually in my fork.

Thankfully, there's a way to add a custom, GitHub-hosted theme _without_ having to fork the theme repository.
It's called [remote themes](https://github.blog/2017-11-29-use-any-theme-with-github-pages/), and it's as simple as adding the [`jekyll-remote-theme`](https://github.com/benbalter/jekyll-remote-theme) gem and setting the `remote_theme` property in your `_config.yml` file to the GitHub repository that contains the theme you want to use.

Once you've installed a new remote theme, there's still a little bit of tweaking required to get everything working, since different themes rely on different Jekyll plugins and different configuration properties.
Unless the theme is extensively documented in the README, your best bet is to read the `_config.yml` for the theme to see which properties and plugins it uses and update your `_config.yml` and `Gemfile` accordingly.

I went with [YAT](https://github.com/jeffreytse/jekyll-theme-yat) (Yet Another Theme), which pretty much just worked out-of-the box.
The main configuration settings that I had to update were `defaults/home/banner` (which is used to set the header image), and `defaults/home/heading` and `defaults/home/subheading`, which are used to set to heading and subheading text that display over the banner image.
I've set them to empty strings for now while I think of something clever.