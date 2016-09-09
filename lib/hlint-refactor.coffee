{CompositeDisposable, BufferedProcess} = require 'atom'

module.exports = Refactor =
  subscriptions: null
  config:
    hlintPath:
      type: 'string'
      default: 'hlint'
      description: 'Path to hlint executable'
    refactorPath:
      type: 'string'
      default: 'refactor'
      description: 'Path to refactor executable'
  runCmd: (path,opts,bufferText, title) ->
    chunks = []
    rpath=atom.config.get 'hlint-refactor.refactorPath'
    new Promise (resolve) ->
      bp = new BufferedProcess
        command: path
        args: opts.concat(['--refactor', "--with-refactor=#{rpath}"])
        stderr: (chunk) ->
          chunks.push chunk
        stdout: (chunk) ->
          chunks.push chunk
        exit: (code) -> resolve
          text: chunks.join('')
          exitCode: code
          title: title
      bp.process.stdin.write(bufferText)
      bp.process.stdin.end()

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'refactor:Apply All Suggestions': => @applyAll()
    @subscriptions.add atom.commands.add 'atom-workspace', 'refactor:Apply One Suggestion': => @applyOne()

  deactivate: ->
    @subscriptions.dispose()


  applyOne: ->
    buffer =atom.workspace.getActiveTextEditor()
    pos = buffer.getCursorBufferPosition()
    @applyGen ["--refactor-options=--pos\ #{pos.row + 1},#{pos.column + 1}"]

  applyAll: -> @applyGen []

  applyGen: (os) ->
    buffer =atom.workspace.getActiveTextEditor()
    pos = buffer.getCursorBufferPosition()
    hlintPath =atom.config.get 'hlint-refactor.hlintPath'
    @runCmd(hlintPath,['-'].concat(os),buffer.getText(), "hlint-refact")
    .then (res) =>
      if res.exitCode == 0
        buffer.getBuffer().setTextViaDiff(res.text)
        buffer.setCursorBufferPosition(pos)
      else
        atom.notifications.addError(res.text)
