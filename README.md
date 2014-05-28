# hubot-reviewer-lotto
Hubot assigns a random reviewer for pull request on behalf of you.

# preparation

## create a team in your github organization

![image](https://cloud.githubusercontent.com/assets/81522/3102957/76422e2c-e64e-11e3-91ee-7e4075d0f685.png)

members of this organization are candidate reviewers.


## grab a github access token
* open https://github.com/settings/tokens/new
* select scopes: `repo` & `public_repo` & `read:org`

# installation
* install this npm package to your hubot repo
    * `npm i --save hubot-reviewer-lotto`
* add `"hubot-reviewer-lotto"` to your `external-scripts.json`
* set the following env vars on heroku
  <table>
      <tr>
          <th>`HUBOT_GITHUB_TOKEN`</th>
          <td>required. the access token you created above.</td>
      </tr>
      <tr>
          <th>`HUBOT_GITHUB_ORG`</th>
          <td>required. name of your github organization.</td>
      </tr>
      <tr>
          <th>`HUBOT_GITHUB_REVIEWER_TEAM`</th>
          <td>required. the reviewer team id you created above.</td>
      </tr>
      <tr>
          <th>`HUBOT_GITHUB_WITH_AVATAR`</th>
          <td>optional. assignee's avatar image will be posted if this var is set to "1".</td>
      </tr>
  </table>

# usage
* `hubot reviewer for <repo> <pull>`
* e.g. `hubot reviewer for our-webapp 345`

## example

on hipchat

![image](https://cloud.githubusercontent.com/assets/81522/3103001/1085dc68-e64f-11e3-8b17-c8a0741c1b51.png)

on github

![image](https://cloud.githubusercontent.com/assets/81522/3102996/f5d1364c-e64e-11e3-8af7-297c10d92208.png)


# get involved

1. fork it ( https://github.com/sakatam/hubot-reviewer-lotto/fork )
2. create your feature branch (`git checkout -b my-new-feature`)
3. commit your changes (`git commit -am 'Add some feature'`)
4. push to the branch (`git push origin my-new-feature`)
5. create new pull request
