# hubot-reviewer-lotto
Hubot assigns a random reviewer for pull request on behalf of you.

# preparation
* create a reviewer team in your github organization

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
