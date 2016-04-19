#
# $ phantomjs qx-phantom.js [Namespace] [URL]
#

system = require('system')

####### Configuration #######

# URL of Test Runner (Console View)
RUNNER = ""

# Include passing tests
VERBOSE = true

# Show the browser's console output, useful when debugging
CONSOLE = false

#############################

# First argument (optional): Scope tests to namespace
testClasses = system.args[1]

# Second argument (optional): The URL of the Test Runner
runnerUrl = if RUNNER? and RUNNER != ""
  system.args[2] || RUNNER
else
  system.args[2]

throw new Error("No URL configured or given") unless runnerUrl?

# Bring in some colors
phantom.injectJs "colors.js"

url = if testClasses then "#{runnerUrl}?testclass=#{testClasses}" else "#{runnerUrl}"
page = new WebPage()

# Attach the web pages console to the system console
page.onConsoleMessage = (msg) ->
  console.log "CONSOLE: #{msg}" if CONSOLE

# Attach error logging
page.onError = (msg, trace) ->
  msgStack = ["ERROR: #{msg}"]

  if (trace && trace.length)
    msgStack.push "TRACE:"
    trace.forEach (t) ->
      functionContent = ""
      functionContent = "(in function '#{t.function}')" if t.function
      msgStack.push " -> #{t.file}: #{t.line} #{functionContent}"

  #console.error(msgStack.join("\n"))
  return

# For reasons unknown, onLoadFinished is called twice
loadedBefore = false

page.open url, (status) ->
  if status isnt "success"
    console.log "Unable to load page"
    phantom.exit 1

  # We have been here before, do not handle onLoadFinished again
  if loadedBefore
    return

  # Remember onLoadFinished was handled
  loadedBefore = true

  # Run watch dog and close process when test suite is not running
  window.setTimeout ->
    testSuiteState = page.evaluate ->
      qx.core.Init.getApplication().runner.getTestSuiteState()

    switch testSuiteState
      when "init", "loading", "ready"
        console.log "Unable to start test suite";
        phantom.exit 1;

  , 120000 # 2 minutes 

  # Run tests
  page.evaluate ->
    if typeof qx == "undefined"
      console.log "qooxdoo not found"
      return

    runner = qx.core.Init.getApplication().runner

    if runner.getTestSuiteState() isnt "ready"
      runner.addListener "changeTestSuiteState", (e) ->
        state = e.getData()

        if state == "ready"
          runner.view.run()
    else
      runner.view.run()


  processTestResults = ->

    getRunnerStateAndResults = ->
      page.evaluate ->
        try
          runner = qx.core.Init.getApplication().runner
          state = runner.getTestSuiteState()
        catch error
          console.log "Error while getting the test runners state and results"
          return [null, null]

        if state == "finished"
          return [state, runner.view.getTestResults()]
        else
          return [state, null]

    [state, results] = getRunnerStateAndResults()

    # Error getting state
    if not state
      return

    # Erroneous state
    if state == "error"
      console.log "Error running tests"
      phantom.exit 1

    # Finished running tests
    if state == "finished"

      success = []
      skip = []
      error = []

      for testName of results
        test = results[testName]

        if test.state == "success"
          success.push testName
          console.log "PASS".green + " #{testName}" if VERBOSE

        if test.state == "skip"
          skip.push testName
          console.log "SKIP".yellow + " #{testName}" if VERBOSE

        if test.state == "error" || test.state == "failure"
          error.push testName
          console.log "FAIL".red + " #{testName}"
          for exception in test.messages
            # Remove trailing new line
            exception = exception.replace(/\n$/, "")
            # Indent stack trace
            exception = exception.replace(/\n/g, "\n  ")
            console.log ">>>> #{exception}"

      console.log "Finished running test suite."
      console.log "(#{success.length} succeeded, " +
                  "#{skip.length} skipped, " +
                  "#{error.length} failed)"

      # != 0 is considered an error in Unix environment
      phantom.exit(error.length)

  # Periodically query and process (when ready) test results
  window.setInterval processTestResults, 500

