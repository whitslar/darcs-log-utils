
Fs = require 'fs'
Path = require 'path'

GitLogUtils = require('../src/git-log-utils')
expectedCommits = require './lib/fiveCommitsExpected'

debugger

describe "GitUtils", ->

  describe "when loading file history for known file in git", ->

    beforeEach ->
      testFileName = Path.join __dirname, 'lib', 'fiveCommits.txt'
      @testdata = GitLogUtils.getCommitHistory testFileName

    it "should have 5 commits", ->
      @testdata.length.should.equal(5)

    it "first 5 commits should match last known good", ->
      expect(@testdata).toHaveKnownValues(expectedCommits)
      # for expectedCommit, index in expectedCommits
      #   actualCommit = @testdata[index]
      #   expect(actualCommit).toHaveKnownValues(expectedCommit)
