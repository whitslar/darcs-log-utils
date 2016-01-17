
ChildProcess = require "child_process"
Path = require "path"
Fs = require "fs"

_ = require('underscore');

module.exports = class GitUtils 
  

###
  returns an array of javascript objects representing the commits that effected the requested file
  with line stats, that looks like this:
    [{
      "id": "1c41d8f647f7ad30749edcd0a554bd94e301c651",
      "authorName": "Bee Wilkerson",
      "relativeDate": "6 days ago",
      "authorDate": 1450881433,
      "message": "docs all work again after refactoring to bumble-build",
      "body": "",
      "hash": "1c41d8f",
      "linesAdded": 2,
      "linesDeleted": 2
    }, {
      ...
    }]
###  
GitUtils.getFileCommitHistory = (fileName)->
  logItems = []
  lastCommitObj = null
  rawLog = GitUtils._fetchFileHistory(fileName)
  return GitUtils._parseGitLogOutput(rawLog)
  

# Implementation

GitUtils._parseGitLogOutput = (output) ->
  lastCommitObject = null
  logItems = []
  logLines = output.split("\n")
  for line in logLines
    if line[0] == '{' && line[line.length-1] == '}'
      lastCommitObj = GitUtils._parseCommitObj(line)
      logItems.push lastCommitObj if lastCommitObj
    else if line[0] == '{'
      # this will happen when there are newlines in the commit message
      lastCommitObj = line
    else if _.isString(lastCommitObj)
      lastCommitObj += line
      if line[line.length-1] == '}'
        lastCommitObj = GitUtils._parseCommitObj(lastCommitObj)
        logItems.push lastCommitObj if lastCommitObj
    else if lastCommitObj? && (matches = line.match(/^(\d+)\s*(\d+).*/))
      # git log --num-stat appends line stats on separate line
      lastCommitObj.linesAdded = Number.parseInt(matches[1])
      lastCommitObj.linesDeleted = Number.parseInt(matches[2])

  return logItems


GitUtils._parseCommitObj = (line) ->
  encLine = line.replace(/\t/g, '  ') # tabs mess with JSON parse
  .replace(/\"/g, "'")           # sorry, can't parse with quotes in body or message
  .replace(/(\n|\n\r)/g, '<br>')
  .replace(/\r/g, '<br>')
  .replace(/\#\/dquotes\//g, '"')
  try
    return JSON.parse(encLine)
  catch
    console.warn "failed to parse JSON #{encLine}"
    return null


GitUtils._fetchFileHistory = (fileName) ->
  format = ("""{"id": "%H", "authorName": "%an", "relativeDate": "%cr", "authorDate": %at, """ +
    """ "message": "%s", "body": "%b", "hash": "%h"}""").replace(/\"/g, "#/dquotes/")

  return ChildProcess.execSync "git -C #{path.dirname(fileName)} log --pretty=format:#{format} --topo-order --date=local --numstat #{fileName}"
