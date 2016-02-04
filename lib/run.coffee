require("./environment")

_        = require("lodash")
cp       = require("child_process")
path     = require("path")
argsUtil = require("./util/args")

currentlyRunningElectron = ->
  process.versions and process.versions.electron

runGui = (options) ->
  ## if we have the electron property on versions
  ## that means we're already running in electron
  ## like in production and we shouldn't spawn a new
  ## process
  if currentlyRunningElectron()
    ## just run the gui code directly here
    ## and pass our options directly to main
    require("./gui/main")(options)
  else
    ## we are in dev mode and can just run electron
    ## in our gui folder which kicks things off
    cp.spawn("electron", [path.join(__dirname, "gui")], {
      ## we are going to pass the options as CYPRESS_ARGS
      ## for our electron process to avoid doing this again
      env: _.extend({}, process.env, {CYPRESS_ARGS: JSON.stringify(options)})
      stdio: "inherit"
    })

runServer = (options) ->
  switch options.env
    when "development"
      args = {}

      if not options.project
        throw new Error("Missing path to project:\n\nPlease pass 'npm start -- --project path/to/project'\n\n")

      if options.debug
        args.debug = "--debug"

      _.extend(args, {
        script:  "lib/cypress.coffee"
        watch:  ["--watch", "lib"]
        ignore: ["--ignore", "lib/public"]
        verbose: "--verbose"
        exts:   ["-e", "coffee,js"]
        args:   ["--", options.project]
      })

      args = _.chain(args).values().flatten().value()

      cp.spawn("nodemon", args, {stdio: "inherit"})

      if options.debug
        cp.spawn("node-inspector", [], {stdio: "inherit"})

        require("open")("http://127.0.0.1:8080/debug?ws=127.0.0.1:8080&port=5858")

    when "production"
      console.log "production"

    else
      throw new Error("Missing 'options.env'. This value is required to run Cypress server!")

module.exports = (argv) ->
  options = argsUtil.toObject(argv)

  ## if we are in smokeTest mode
  ## then just output the pong's value
  ## and exit
  if options.smokeTest
    process.stdout.write(options.pong + "\n")
    return process.exit()

  ## if we are in returnPackage mode
  ## then just output our package's value
  ## and exist
  if options.returnPkg
    manifest = JSON.stringify(App.config.getManifest())
    process.stdout.write(manifest + "\n")
    return process.exit()

  switch options.mode
    when "gui"
      ## run the gui headed
      runGui(options)

    when "headless"
      ## run the gui headlessly
      options.headless = true
      runGui(options)

    when "server"
      ## run the server without gui
      runServer(options)

    when "ci"
      ## run the server in CI mode
      options.ci = true
      runServer(options)

    else
      throw new Error("Missing 'options.mode'. This value is required to run Cypress.")
