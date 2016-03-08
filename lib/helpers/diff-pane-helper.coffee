shellescape = require 'shell-escape'
tmp = require 'temporary'
require 'diff2html'

module.exports =
  class DiffPaneHelper

    constructor: (panes) ->
      @diffCmd = 'diff -u --strip-trailing-cr '

      # get active panes text
      @t1 = panes[0].getActiveItem().getText();
      @t2 = panes[1].getActiveItem().getText();

      # diff process
      if @t1[@t1.length - 1] isnt '\n' or @t2[@t2.length - 1] isnt '\n'
        @t1 += '\n'
        @t2 += '\n'

    getHtml: (patch) ->
      patch = 'diff --git a/left b/right\n' +
              'index a..b 100644\n' +
              patch
      Diff2Html.getPrettySideBySideHtmlFromDiff(patch)

    getDiffFiles: ->
      f1 = new tmp.File()
      f1.writeFileSync(@t1)
      f2 = new tmp.File()
      f2.writeFileSync(@t2)
      [f1, f2]

    unlinkTempFiles: (files) ->
      for file in files
        file.unlinkSync()

    execDiffCmd: (files, cb) ->
      cmd = @diffCmd + shellescape([files[0].path, files[1].path])
      exec = require('child_process').exec
      exec cmd, cb

    buildCmd: (files) ->
      if 2 != files.length
        throw "command parameter is invalid"