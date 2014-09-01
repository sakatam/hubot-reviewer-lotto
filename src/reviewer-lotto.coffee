# Description:
#   assigns random reviewer for a pull request.
#
# Configuration:
#   HUBOT_GITHUB_TOKEN (required)
#   HUBOT_GITHUB_ORG (required)
#   HUBOT_GITHUB_REVIEWER_TEAM (required)
#     github team id. this script randomly picks a reviewer from this team members.
#
# Commands:
#   hubot reviewer for <repo> <pull> - assigns random reviewer for pull request
#   hubot reviewer show stats - proves the lotto has no bias
#
# Author:
#   sakatam

_         = require "underscore"
async     = require "async"
GitHubApi = require "github"
weighted  = require "weighted"

module.exports = (robot) ->
  ghToken       = process.env.HUBOT_GITHUB_TOKEN
  ghOrg         = process.env.HUBOT_GITHUB_ORG
  ghReviwerTeam = process.env.HUBOT_GITHUB_REVIEWER_TEAM
  ghWithAvatar  = process.env.HUBOT_GITHUB_WITH_AVATAR
  debug         = process.env.HUBOT_REVIEWER_LOTTO_DEBUG in ["1", "true"]

  STATS_KEY     = 'reviewer-lotto-stats'

  # draw lotto - weighted random selection
  draw = (reviewers, stats = null) ->
    max = if stats? then (_.max _.map stats, (count) -> count) else 0
    arms = {}
    sum = 0
    for {login} in reviewers
      weight = Math.exp max - (stats?[login] || 0)
      arms[login] = weight
      sum += weight
    # normalize weights
    for login, weight of arms
      arms[login] = if sum > 0 then weight / sum else 1
    if debug
      robot.logger.info 'arms: ', arms

    selected = weighted.select arms
    _.find reviewers, ({login}) -> login == selected

  if !ghToken? or !ghOrg? or !ghReviwerTeam?
    return robot.logger.error """
      reviewer-lottery is not loaded due to missing configuration!
      #{__filename}
      HUBOT_GITHUB_TOKEN: #{ghToken}
      HUBOT_GITHUB_ORG: #{ghOrg}
      HUBOT_GITHUB_REVIEWER_TEAM: #{ghReviwerTeam}
    """

  robot.respond /reviewer reset stats/i, (msg) ->
    robot.brain.set STATS_KEY, {}
    msg.reply "Reset reviewer stats!"

  robot.respond /reviewer show stats$/i, (msg) ->
    stats = robot.brain.get STATS_KEY
    msgs = ["login, percentage, num assigned"]
    total = 0
    for login, count of stats
      total += count
    for login, count of stats
      percentage = Math.floor(count * 100.0 / total)
      msgs.push "#{login}, #{percentage}%, #{count}"
    msg.reply msgs.join "\n"

  robot.respond /reviewer for ([\w-\.]+) (\d+)( polite)?$/i, (msg) ->
    repo = msg.match[1]
    pr   = msg.match[2]
    polite = msg.match[3]?
    prParams =
      user: ghOrg
      repo: repo
      number: pr

    gh = new GitHubApi version: "3.0.0"
    gh.authenticate {type: "oauth", token: ghToken}

    # mock api if debug mode
    if debug
      gh.issues.createComment = (params, cb) ->
        robot.logger.info "GitHubApi - createComment is called", params
        cb null
      gh.issues.edit = (params, cb) ->
        robot.logger.info "GitHubApi - edit is called", params
        cb null

    async.waterfall [
      (cb) ->
        # get team members
        params =
          id: ghReviwerTeam
          per_page: 100
        gh.orgs.getTeamMembers params, (err, res) ->
          return cb "error on getting team members: #{err.toString()}" if err?
          cb null, {reviewers: res}

      (ctx, cb) ->
        # check if pull req exists
        gh.pullRequests.get prParams, (err, res) ->
          return cb "error on getting pull request: #{err.toString()}" if err?
          ctx['issue'] = res
          ctx['creator'] = res.user
          ctx['assignee'] = res.assignee
          cb null, ctx

      (ctx, cb) ->
        # pick reviewer
        {reviewers, creator, assignee} = ctx
        reviewers = reviewers.filter (r) -> r.login != creator.login
        # exclude current assignee from reviewer candidates
        if assignee?
          reviewers = reviewers.filter (r) -> r.login != assignee.login

        ctx['reviewer'] = draw reviewers, robot.brain.get(STATS_KEY)
        cb null, ctx

      (ctx, cb) ->
        # post a comment
        {reviewer} = ctx
        body = "@#{reviewer.login} please review this" + if polite then " :bow::bow::bow::bow:" else "."
        params = _.extend { body }, prParams
        gh.issues.createComment params, (err, res) -> cb err, ctx

      (ctx, cb) ->
        # change assignee
        {reviewer} = ctx
        params = _.extend { assignee: reviewer.login }, prParams
        gh.issues.edit params, (err, res) -> cb err, ctx

      (ctx, cb) ->
        {reviewer, issue} = ctx
        messages = []
        msg.reply "#{reviewer.login} has been assigned for #{issue.html_url} as a reviewer"
        if ghWithAvatar
          url = reviewer.avatar_url
          url = "#{url}t=#{Date.now()}" # cache buster
          url = url.replace(/(#.*|$)/, '#.png') # hipchat needs image-ish url to display inline image
          msg.send url

        # update stats
        stats = (robot.brain.get STATS_KEY) or {}
        stats[reviewer.login] or= 0
        stats[reviewer.login]++
        robot.brain.set STATS_KEY, stats

        cb null, ctx

    ], (err, res) ->
      if err?
        msg.reply "an error occured.\n#{err}"
