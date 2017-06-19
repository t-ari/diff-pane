DiffPaneView = require './diff-pane-view'
DiffPaneHelper = require './helpers/diff-pane-helper'
{CompositeDisposable} = require 'atom'

module.exports = DiffPane =
  diffPaneView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @diffPaneView = new DiffPaneView(state.diffPaneViewState)
    @modalPanel = atom.workspace.addModalPanel(
      item: @diffPaneView.getElement(), visible: false)

    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'diff-pane:execute': => @execute()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @diffPaneView.destroy()

  serialize: ->
    diffPaneViewState: @diffPaneView.serialize()

  execute: ->
    if @modalPanel.isVisible()
      @modalPanel.hide()
      return

    panes = []
    for pane in atom.workspace.getPanes()
      if atom.workspace.isTextEditor(pane.getActiveItem())
        panes.push(pane)

    # check valid pane size
    if 2 != panes.length
      atom.notifications.addWarning('Diff Pane',
        {detail: 'You must have two panes open.'})
      return

    atom.notifications.addInfo('Diff Pane', {detail: 'Start diff...'})

    dpv = @diffPaneView
    mp = @modalPanel

    # diff pane view style
    width = document.body.scrollWidth - 40
    height = document.body.scrollHeight - 30
    dpv.getElement().style.width = '' + width + 'px'
    dpv.getElement().style.height = '' + height + 'px'
    dpv.getElement().style.marginLeft = '-' + (width / 2 - 250) + 'px'

    setTimeout ->
      helper = new DiffPaneHelper(panes)
      files = helper.getDiffFiles()
      if null == files
        atom.notifications.addInfo('Diff Pane', {detail: 'Files are same.'})
        return
      helper.execDiffCmd files, (error, stdout, stderr) ->
        helper.unlinkTempFiles(files)
        html = helper.getHtml(stdout)
        dpv.getElement().innerHTML = html
        mp.show()
    , 100