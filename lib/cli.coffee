_         = require("lodash")
commander = require("commander")
updater   = require("update-notifier")
human     = require("human-interval")
pkg       = require("../package.json")

## check for updates every hour
updater({pkg: pkg, updateCheckInterval: human("one hour")}).notify()

parseOpts = (opts) ->
  _.pick(opts, "spec", "reporter", "path", "destination", "port", "env", "cypressVersion", "config")

descriptions = {
  destination: "destination path to extract and install Cypress to"
  spec:        "runs a specific spec file. defaults to 'all'"
  reporter:    "runs a specific mocha reporter. pass a path to use a custom reporter. defaults to 'spec'"
  port:        "runs Cypress on a specific port. overrides any value in cypress.json. defaults to '2020'"
  env:         "sets environment variables. separate multiple values with a comma. overrides any value in cypress.json or cypress.env.json"
  config:      "sets configuration values. separate multiple values with a comma. overrides any value in cypress.json."
  version:     "installs a specific version of Cypress"
  noLaunch:      "disable automatically launching your project and opening Chrome"
}

text = (d) ->
  descriptions[d] ? throw new Error("Could not find description for: #{d}")

module.exports = ->
  ## instantiate a new program for
  ## easier testability
  program = new commander.Command()

  exit = ->
    process.exit(0)

  displayVersion = ->
    require("./commands/version")()
    .then(exit)
    .catch(exit)

  program.option("-v, --version", "output the version of the cli and desktop app", displayVersion)

  program
    .command("install")
    .description("Installs Cypress")
    .option("-d, --destination <path>", text("destination"))
    .option("--cypress-version <version>", text("version"))
    .action (opts) ->
      require("./commands/install")(parseOpts(opts))

  program
    .command("update")
    .description("Updates Cypress to the latest version")
    .option("-d, --destination <path>", text("destination"))
    .action (opts) ->
      require("./commands/install")(parseOpts(opts))

  program
    .command("run [project]")
    .usage("[project] [options]")
    .description("Runs Cypress Tests Headlessly")
    .option("-s, --spec <spec>",         text("spec"))
    .option("-r, --reporter <reporter>", text("reporter"))
    .option("-p, --port <port>",         text("port"))
    .option("-e, --env <env>",           text("env"))
    .option("-c, --config <config>",     text("config"))
    .action (project, opts) ->
      require("./commands/run")(project, parseOpts(opts))

  program
    .command("ci [key]")
    .usage("[key] [options]")
    .description("Runs Cypress in CI Mode")
    .option("-r, --reporter <reporter>", text("reporter"))
    .option("-p, --port <port>",         text("port"))
    .option("-e, --env <env vars>",      text("env"))
    .option("-c, --config <config>",     text("config"))
    .action (key, opts) ->
      require("./commands/ci")(key, parseOpts(opts))

  program
    .command("open [project]")
    .usage("[project] [options]")
    .description("Opens Cypress as a regular application. If your current pwd matches an existing Cypress project, that project will automatically open and Chrome will be launched.")
    .option("-p, --port <port>",         text("port"))
    .option("-e, --env <env>",           text("env"))
    .option("-c, --config <config>",     text("config"))
    .option("--no-auto-launch",          text("noLaunch"))
    .action (project, opts) ->
      require("./commands/open")(project, parseOpts(opts))

  program
    .command("get:path")
    .description("Returns the default path of the Cypress executable")
    .action (key, opts) ->
      require("./commands/path")()

  program
    .command("get:key [project]")
    .description("Returns your Project's Secret Key for use in CI")
    .action (project) ->
      require("./commands/key")(project)

  program
    .command("new:key [project]")
    .description("Generates a new Project Secret Key for use in CI")
    .action (project) ->
      require("./commands/key")(project, {reset: true})

  program
    .command("remove:ids [project]")
    .description("Removes test IDs generated by Cypress in versions earlier than 0.14.0")
    .action (project) ->
      require("./commands/ids")(project)

  program
    .command("verify")
    .description("Verifies that Cypress is installed correctly and executable")
    .action ->
      require("./commands/verify")()

  program
    .command("version")
    .description("Outputs both the CLI and Desktop App versions")
    .action(displayVersion)

  program.parse(process.argv)

  ## if the process.argv.length
  ## is less than or equal to 2
  if process.argv.length <= 2
    ## then display the help
    program.help()

  return program