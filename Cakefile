###!
  Cakefile for jQuery Rondell
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  
  Usage:
    
    Recompile coffeescript and sass when files change:
      cake watch
    
    Build minified plugin files for production:
      cake -v x.x.x minify
###

pluginName = 'rondell'
{spawn, exec} = require 'child_process'

notify = (source, message) ->
  message = message.trim()
  # Default output to console
  console.log message
  # Check if growlnotify is enabled and use that if available
  exec "type growlnotify >/dev/null 2>&1 && { growlnotify -m \"#{source}: #{message}\"; }"

task 'watch', 'Watch sass and src folders for changes and recompile from src and scss folders to lib and css', ->
  
  notify "Watcher", "Watching src folder for changes in coffee scripts"

  coffeeProcess = spawn 'coffee', ['--join', "lib/jquery.#{pluginName}.js", '--watch', '--compile', 'src/']
  coffeeProcess.stdout.on 'data', (data) -> 
    notify "coffeescript", data.toString()

  notify "Watcher", "Watching scss folder for changes in sass files"
      
  sassProcess = spawn 'sass', ['--style', 'expanded', '--watch', 'scss:css']
  sassProcess.stdout.on 'data', (data) -> 
    notify "SASS", data.toString()


option '-v', '--version [VERSION_STRING]', 'set the output files version for `minify`'
task 'minify', 'Minify the plugins *.js and *.css before release', (options) ->
  
  return notify "Minify", "Please provide a version string" unless options.version?
  
  exec "java -jar \"/Applications/yuicompressor.jar\" -o lib/jquery.#{pluginName}-#{options.version}.min.js lib/jquery.#{pluginName}.js", (err, stdout, stderr) ->
    throw err if err
    notify "yuicompressor", stdout + stderr
    notify "yuicompressor", "Created minified js file"
    
  exec "sass --style compressed scss/jquery.#{pluginName}.scss css/jquery.#{pluginName}-#{options.version}.min.css", (err, stdout, stderr) ->
    throw err if err
    notify "SASS", stdout + stderr
    notify "SASS", "Created compressed css file"
