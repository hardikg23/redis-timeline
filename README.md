redis-timeline
===========

[![Build Status](https://travis-ci.org/felixclack/redis-timeline.png?branch=master)](https://travis-ci.org/felixclack/redis-timeline)

Redis backed timelines in your app.

<a href="mailto:felixclack+pairwithme@gmail.com" title="Pair program with me!">
  <img src="http://pairprogramwith.me/badge.png"
        alt="Pair program with me!" />
</a>

Features
--------

* store your timeline in Redis.

Examples
--------

The simple way...

    class PostsController < ApplicationController
      include Timeline::ControllerHelper

    end

Instead doing on the callback we explicity mention when we want to track the activity

You can specify these options ...

    class PostsController < ApplicationController
      include Timeline::ControllerHelper
      belongs_to :author, class_name: "User"
      belongs_to :post

      track :new_comment,
        actor: :author,
        followers: :post_participants,
        object: [:body],
        on: :update,
        target: :post

      delegate :participants, to: :post, prefix: true
      def create
      @post=Post.new(params[:post])
        respond_to do |format|
          if @post.save!
            track_timeline_activity(:new_post,actor: current_user,followers: current_user.followers,target: @post.comment,object: @post) 
            format.html { redirect_to(posts_path , :notice => 'Post was successfully created.') }
          else
            format.html { redirect_to(posts_path , :notice => @post.errors.full_messages) }
            format.json { render json: @post.errors, status: :unprocessable_entity }
          end

        end
      end
    end

Parameters
----------

`track` accepts the following parameters...

the first param is the verb name.

The rest all fit neatly in an options hash.

* `actor:` [the method that specifies the object that took this action]
  In the above example, comment.author is this object.
  

* `object:` defaults to self, which is good most of the time.
  You can override it if you need to

* `target:` [related to the `:object` method above. In the example this is the post related to the comment]
  default: nil

* `followers:` [who should see this story in their timeline. This references a method on the actor]
  Defaults to the method `followers` defined by Timeline::Actor.


Display a timeline
------------------

To retrieve a timeline for a user...

    class User < ActiveRecord::Base
      include Timeline::Actor
    end

The timeline objects are just hashes that are extended by [Hashie](http://github.com/intridea/hashie) to provide method access to the keys.

    user = User.find(1)
    user.timeline # => [<Timeline::Activity verb='new_comment' ...>]

Requirements
------------

* redis
* active_support
* hashie

Install
-------

Install redis.

Add to your Gemfile:

    gem 'redis-timeline'

Or install it by hand:

    gem install redis-timeline

Setup your redis instance. For a Rails app, something like this...

    # in config/initializers/redis.rb

    Timeline.redis = "localhost:6379/timeline"

Author
------

Original author: Felix Clack

License
-------

(The MIT License)

Copyright (c) 2012 Felix Clack

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
