# Description:
#   assigns random reviewer for a pull request
#
# Configuration:
#   HUBOT_GITHUB_TOKEN (required)
#   HUBOT_GITHUB_ORG (required)
#   HUBOT_GITHUB_REVIEWER_TEAM (required)
#     github team id. this script randomly picks a reviewer from this team members.
#
# Commands:
#   hubot reviewer for <repo> <pull> - assigns random reviewer for pull request
#
# Author:
#   sakatam

_         = require "underscore"
async     = require "async"
GitHubApi = require "github"

module.exports = (robot) ->
  ghToken       = process.env.HUBOT_GITHUB_TOKEN
  ghOrg         = process.env.HUBOT_GITHUB_ORG
  ghReviwerTeam = process.env.HUBOT_GITHUB_REVIEWER_TEAM

  if !ghToken? or !ghOrg? or !ghReviwerTeam?
    return robot.logger.error """
      reviewer-lottery is not loaded due to missing configuration!
      #{__filename}
      HUBOT_GITHUB_TOKEN: #{ghToken}
      HUBOT_GITHUB_ORG: #{ghOrg}
      HUBOT_GITHUB_REVIEWER_TEAM: #{ghReviwerTeam}
    """

  robot.respond /reviewer for ([\w-\.]+) (\d+)$/i, (msg) ->
    repo = msg.match[1]
    pr   = msg.match[2]
    prParams =
      user: ghOrg
      repo: repo
      number: pr

    gh = new GitHubApi version: "3.0.0"
    gh.authenticate {type: "oauth", token: ghToken}

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
        ctx['reviewer'] = _.sample reviewers
        # XXX
        ctx['reviewer'] = {login: "sakatam"}
        cb null, ctx

      (ctx, cb) ->
        # post a comment
        {reviewer} = ctx
        params = _.extend { body: "@#{reviewer.login} please review this :bow:" }, prParams
        gh.issues.createComment params, (err, res) -> cb err, ctx

      (ctx, cb) ->
        # change assignee
        {reviewer} = ctx
        params = _.extend { assignee: reviewer.login }, prParams
        gh.issues.edit params, (err, res) ->
          ctx['issue'] = res
          cb err, ctx

      (ctx, cb) ->
        {reviewer, issue} = ctx
        msg.reply "#{reviewer.login} has been assigned for #{issue.html_url} as a reviewer"
        cb null, ctx

    ], (err, res) ->
      if err?
        msg.reply "an error occured.\n#{err}"
