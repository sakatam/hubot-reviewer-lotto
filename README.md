# hubot-reviewer-lotto
Hubot assigns a random reviewer for pull request on behalf of you.

# preparation

## create a team in your github organization

members of this organization are candidate reviewers.


## grab a github access token
* open https://github.com/settings/tokens/new
* select scopes: `repo` & `public_repo` & `read:org`

# installation
* install this npm package to your hubot repo
    * `npm i --save hubot-reviewer-lotto`
* add `"hubot-reviewer-lotto"` to your `external-scripts.json`
* set up the following env vars on heroku
    * `HUBOT_GITHUB_TOKEN`
    * `HUBOT_GITHUB_ORG` - name of your github organization
    * `HUBOT_GITHUB_REVIEWER_TEAM` - the reviewer team id that you have created above

# usage
* `hubot reviewer for <repo> <pull>`
* e.g. `hubot reviewer for our-webapp 345`

# get involved

1. fork it ( https://github.com/sakatam/hubot-reviewer-lotto/fork )
2. create your feature branch (`git checkout -b my-new-feature`)
3. commit your changes (`git commit -am 'Add some feature'`)
4. push to the branch (`git push origin my-new-feature`)
5. create new pull request
