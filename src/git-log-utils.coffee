
ChildProcess = require "child_process"
Path = require "path"
Fs = require "fs"

_ = require('underscore')
moment = require('moment')


module.exports = class DarcsLogUtils 


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
  @getCommitHistory: (fileName)->
    logItems = []
    lastCommitObj = null
    rawLog = @_fetchFileHistory(fileName)
    console.log rawLog
    # return @_parseGitLogOutput(rawLog)
    return @_parseDarcsChanges(rawLog)
    
  
  # Implementation

  # This works!!
  # @_parseDarcsChanges: (output) ->
  #   logLines = output.split("\n")
  #   lastCommitObject = JSON.parse("{}")
  #   logItems = JSON.parse("[]")

  #   for line in logLines
  #     if(line.split(' ')[0] == 'patch')
  #       # lastCommitObj = JSON.parse('{ "hash":"' + line.split('patch')[1].trim() + '" }')
  #       # console.log lastCommitObj
  #       # console.log line.split('patch')[1].trim()
  #       lastCommitObject.hash = @_sanitize_line(line.split('patch')[1].trim())
  #     else if(line.split(' ')[0] == 'Author:')
  #       # console.log line.split('Author:')[1].trim()
  #       lastCommitObject.authorName = @_sanitize_line(line.split('Author:')[1].trim())
  #     else if(line.split(' ')[0] == 'Date:')
  #       # console.log line.split('Date:')[1].trim()
  #       # needs to be 1459120070
  #       lastCommitObject.authorDate = moment(line.split('Date:')[1].trim(), "ddd MMM DD HH:mm:ss zz YYYY").unix()
  #       console.log moment(line.split('Date:')[1].trim(), "ddd MMM DD HH:mm:ss zz YYYY").unix()
  #     else if(line.indexOf('  *') > -1)
  #       # console.log line.split('  *')[1].trim()
  #       lastCommitObject.message = @_sanitize_line(line.split('  *')[1].trim())
  #       logItems.push lastCommitObject
  #       lastCommitObject = JSON.parse("{}")
  #   console.log JSON.stringify(logItems)
  #   return logItems

  # Trying to get add/removed lines
  @_parseDarcsChanges: (output) ->
    logLines = output.split("\n")
    lastCommitObject = JSON.parse("{}")
    logItems = JSON.parse("[]")
    blankLine = 0

    # remove first two lines, may be unneccessary
    logLines.shift()
    logLines.shift()

    for line in logLines
      if(line.split(' ')[0] == 'patch')
        # lastCommitObj = JSON.parse('{ "hash":"' + line.split('patch')[1].trim() + '" }')
        # console.log lastCommitObj
        # console.log line.split('patch')[1].trim()
        lastCommitObject.hash = @_sanitize_line(line.split('patch')[1].trim())
      else if(line.split(' ')[0] == 'Author:')
        # console.log line.split('Author:')[1].trim()
        lastCommitObject.authorName = @_sanitize_line(line.split('Author:')[1].trim())
      else if(line.split(' ')[0] == 'Date:')
        # console.log line.split('Date:')[1].trim()
        # needs to be 1459120070
        lastCommitObject.authorDate = moment(line.split('Date:')[1].trim(), "ddd MMM DD HH:mm:ss zz YYYY").unix()
        # console.log moment(line.split('Date:')[1].trim(), "ddd MMM DD HH:mm:ss zz YYYY").unix()
      else if(line.indexOf('  *') > -1)
        # console.log line.split('  *')[1].trim()
        lastCommitObject.message = @_sanitize_line(line.split('  *')[1].trim())
        # logItems.push lastCommitObject
        # lastCommitObject = JSON.parse("{}")
      else if(sign = line.match(/\-|\+/))
        # console.log line.match(/\-|\+/)[0]
        if(sign[0] == '-' && line.split('-')[1][0] != '>')
          lastCommitObject.linesDeleted = (lastCommitObject.linesDeleted || 0) + Number.parseInt(line.split('-')[1].split(' ')[0])
          if(line.split('-')[1].match(/\-|\+/))
            lastCommitObject.linesAdded = (lastCommitObject.linesAdded || 0) + Number.parseInt(line.split('+')[1])
        else if (sign[0] == '+')
          lastCommitObject.linesAdded = (lastCommitObject.linesAdded || 0) + Number.parseInt(line.split('+')[1])
      else if(line == '' || line == '\n' || line == ' ')
        blankLine = blankLine + 1
      if(blankLine == 2 && (line == '' || line == '\n' || line == ' '))
        logItems.push lastCommitObject
        lastCommitObject = JSON.parse("{}")
        blankLine = 0

    console.log JSON.stringify(logItems)
    return logItems       
  
  @_fetchFileHistory: (fileName) ->
    format = ("""{"id": "%H", "authorName": "%an", "relativeDate": "%cr", "authorDate": %at, """ +
      """ "message": "%s", "body": "%b", "hash": "%h"}""").replace(/\"/g, "#/dquotes/")
    flags = " --pretty=\"format:#{format}\" --topo-order --date=local --numstat"
    
    fstats = Fs.statSync fileName
    if fstats.isDirectory() 
      directory = fileName
      fileName = ""
    else 
      directory = Path.dirname(fileName)
      
    fileName = Path.normalize(@_escapeSpacesInPath(fileName))
    
    # cmd = "git log#{flags} #{fileName}"

    cmd = "cd /Users/kerismith/salonlofts_com; DARCS_ALWAYS_COLOR=0 DARCS_DO_COLOR_LINES=0 darcs changes --summary " + fileName;
    console.log cmd
    console.log '$ ' + cmd if process.env.DEBUG == '1'
    return ChildProcess.execSync(cmd,  {stdio: 'pipe', cwd: directory}).toString()
    

  @_parseGitLogOutput: (output) ->
    lastCommitObject = null
    logItems = []
    logLines = output.split("\n")
    for line in logLines
      if line[0] == '{' && line[line.length-1] == '}'
        lastCommitObj = @_parseCommitObj(line)
        logItems.push lastCommitObj if lastCommitObj
      else if line[0] == '{'
        # this will happen when there are newlines in the commit message
        lastCommitObj = line
      else if _.isString(lastCommitObj)
        lastCommitObj += line
        if line[line.length-1] == '}'
          lastCommitObj = @_parseCommitObj(lastCommitObj)
          logItems.push lastCommitObj if lastCommitObj
      else if lastCommitObj? && (matches = line.match(/^(\d+)\s*(\d+).*/))
        # console.log "lastCommitObj", lastCommitObj
        # git log --num-stat appends line stats on separate lines
        lastCommitObj.linesAdded = (lastCommitObj.linesAdded || 0) + Number.parseInt(matches[1])
        lastCommitObj.linesDeleted = (lastCommitObj.linesDeleted || 0) + Number.parseInt(matches[2])

    return logItems

  @_sanitize_line: (line) ->
    encLine = line.replace(/\t/g, '  ') # tabs mess with JSON parse
    .replace(/\"/g, "'")           # sorry, can't parse with quotes in body or message
    .replace(/(\n|\n\r)/g, '<br>')
    .replace(/\r/g, '<br>')
    .replace(/\#\/dquotes\//g, '"')
    return encLine

  @_parseCommitObj: (line) ->
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
      
  ###
    See nodejs Path.normalize().  This method extends Path.normalize() to add:
    - escape of space characters 
  ###
  @_escapeSpacesInPath: (filePath) ->
    spaceReplacement = if process.platform == 'win32' then '^ ' else '\\ '
    return filePath.replace(/ /g, spaceReplacement)
