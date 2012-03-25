###!
  Cakefile for jQuery Rondell
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  
  Usage:
    
    Recompile coffeescript and sass when files change:
      cake watch
    
    Build minified plugin files for production:
      cake -v x.x.x minify
###

pluginName = "rondell"
{spawn, exec} = require "child_process"
fs = require "fs"
jade = require "jade"

watching =
  sass: true
  coffee: true
  jade: true

src =
  sass: "src/scss"
  coffee: "src/coffee"
  jade: "src/jade"

out =
  css: "css"
  js: "js"
  html: "examples"

notify = (source, message) ->
  message = message.trim()
  # Default output to console
  console.log "#{source} - #{message}"
  # Check if growlnotify is enabled and use that if available
  exec "type growlnotify >/dev/null 2>&1 && { growlnotify -m \"#{source}: #{message}\"; }"

compileJade = (filename, callback) ->
  try
    fn = jade.compile fs.readFileSync("#{src.jade}/#{filename}", 'utf8'),
      pretty: true
      filename: "#{src.jade}/#{filename}"
  catch e
    notify "JADE", e.toString()
    return

  result = "Bad compile on #{filename} jade template!"

  if fn
    fs.writeFileSync "#{out.html}/#{filename}".replace(".jade", ".html"), fn()
    result = "#{filename} successfully compiled!"

  notify "JADE", result

watchJadeFile = (filename) ->
  fs.watchFile "#{src.jade}/#{filename}", (curr, prev) ->
    if curr.mtime > prev.mtime
      compileJade filename

task 'watch', 'Watch sass, coffee and haml files for changes and recompile from src folders', ->
  
  if watching.coffee
    notify "Watcher", "Watching #{src.coffee} folder for changes in coffee scripts."

    coffeeProcess = spawn 'coffee', ['--join', "#{out.js}/jquery.#{pluginName}.js", '--watch', '--compile', src.coffee]
    coffeeProcess.stdout.on 'data', (data) -> 
      notify "coffeescript", data.toString()


  if watching.sass
    notify "Watcher", "Watching #{src.sass} folder for changes in sass files."
        
    sassProcess = spawn 'sass', ['--style', 'expanded', '--watch', "#{src.sass}:#{out.css}"]
    sassProcess.stdout.on 'data', (data) -> 
      notify "SASS", data.toString()

  if watching.jade
    if fs and jade
      notify "Watcher", "Watching #{src.jade} folder for changes in jade files."

      jadeFiles = fs.readdir src.jade, (err, files) ->
        throw err if err
        for filename in files 
          watchJadeFile filename if filename?.indexOf(".jade") > 0
    else
      notify "Watcher", "Jade not installed. Unable to compile jade files."


option '-v', '--version [VERSION_STRING]', 'set the output files version for `minify`'
task 'minify', 'Minify the plugins *.js and *.css before release', (options) ->
  
  return notify "Minify", "Please provide a version string" unless options.version?
  
  exec "java -jar \"/Applications/yuicompressor.jar\" -o #{out.js}/jquery.#{pluginName}-#{options.version}.min.js js/jquery.#{pluginName}.js", (err, stdout, stderr) ->
    throw err if err
    notify "yuicompressor", stdout + stderr
    notify "yuicompressor", "Created minified js file"
    
  exec "sass --style compressed #{src.sass}/jquery.#{pluginName}.scss #{out.css}/jquery.#{pluginName}-#{options.version}.min.css", (err, stdout, stderr) ->
    throw err if err
    notify "SASS", stdout + stderr
    notify "SASS", "Created compressed css file"
