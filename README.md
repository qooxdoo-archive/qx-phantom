# qx-phantom

qx-phantom allows you to run qooxdoo unit tests from the command line.

It uses [PhantomJS](https://github.com/ariya/phantomjs), a headless WebKit browser with a JavaScript API.

## Setup

Install PhantomJS and make sure it is in your path.

Build the console view of the Test Runner and write it to a separate path.

    $ ./generate.py test-source \
      -m TESTRUNNER_VIEW:testrunner.view.Console \
      -m BUILD_PATH:test-console

Verify the build was successful by opening the console view in a browser. In the web developer console, after a couple of seconds, you should see something like:

    2619 tests ready. Call qx.core.Init.getApplication().runner.view.run() to start.

At the top of ``qx-phantom.js``, adjust the URL to the Test Runner you built before.

    RUNNER = "http://localhost/<path-to-test-runner>"

## Usage

Tell PhantomJS to run the tests:

    $ phantomjs qx-phantom.js

You can also limit the tests by setting the namespace (here the framework UI tests):

    $ phantomjs qx-phantom.js qx.test.ui

If you encounter any problems, set ``CONSOLE=true`` in ``qx-phantom.js``.

The status code returned by the script is the number of tests that failed. This is especially interesting if you are planning to integrate running unit tests into continuous integration or some kind of automatic workflow, such as commit hooks or reports.

## Known Issues

 * PhantomJS does not expose complete stack traces. See [Bug #240](http://code.google.com/p/phantomjs/issues/detail?id=240)
   and [Bug #226](http://code.google.com/p/phantomjs/issues/detail?id=226).

## Help

 * [qooxdoo-devel](http://qooxdoo.org/community/mailing_lists)
 * [Stack Overflow](http://stackoverflow.com/questions/tagged/qooxdoo)
