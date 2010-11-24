#!/usr/bin/env coffee
#
# CoffeeApp - coffee-script wrapper for CouchApp
# Copyright 2010 Andrzej Sliwa (andrzej.sliwa@i-tool.eu)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


# fast way to imports using pattern matching
{existsSync, join, extname} = require 'path'
{mkdirSync, readdirSync, writeFileSync, readFileSync, statSync} = require 'fs'
{compile} = require 'coffee-script'
{exec}  = require 'child_process'
{print, gets} = require 'util'
{log} = console

#### Command wrapping configuration.
commandWraps = [
  {
    name: 'push',
    type: 'before',
    callback: -> grindCoffee()
  },
  {
    name: 'help',
    type: 'after',
    desc: '     show this message',
    callback: -> help()
  },
  {
    name: 'cgenerate',
    type: 'before',
    desc: '[ view | list | show | filter ] generate .coffee versions',
    callback: -> generate()
  },
  {
    name: 'destroy',
    type: 'before',
    desc: '  [ view | list | show | filter ] destroy (remove directory/files also .js files).',
    callback: -> destroy()
  },
  {
    name: 'prepare',
    type: 'before',
    desc: '  prepare (.gitignore...)',
    callback: -> prepare()
  },
  {
    name: 'clean',
    type: 'before',
    desc: '    remove .releases directory'
    callback: -> clean()
  }
]

#### File templates

# .gitignore
gitIgnore = '''
.DS_Store
.couchapprc
.releases/*
.releases/**/*
'''

# map function
mapCoffee = '''
(doc) ->
  ...
'''

# reduce function
reduceCoffee = '''
(keys, values, rereduce) ->
  ...
'''

# list function
listCoffee = '''
(head, req) ->
  ...
'''

# show function
showCoffee = '''
(doc, req) ->
  ...
'''

# filter function
filterCoffee = '''
(doc, req) ->
  ...
'''

#### Helper Methods

getVersion = ->
  readFileSync(join(__dirname, '..', 'package.json')).toString().match(/"version"\s*:\s*"([\d.]+)"/)[1]

showGreatings = ->
# Shows greatings ...
  log "CoffeeApp (#{getVersion()}) - simple coffee-script wrapper for CouchApp (http://couchapp.org)"
  log 'http://github.com/andrzejsliwa/coffeeapp\n'


# Zero padding for format '0x'
padTwo = (number) ->
  result = if number < 10 then '0' else ''
  "#{result}#{number}"

# Timestamp string based on current date
getTimestamp = ->
  date = new Date
  date.getFullYear() + padTwo(date.getMonth() + 1) +
  padTwo(date.getDate()) + padTwo(date.getHours() + 1) +
  padTwo(date.getMinutes() + 1) + padTwo(date.getSeconds() + 1)

# Display outputs if presents
printOutput = (error, stdout, stderr) ->
  log stdout if stdout && stdout.length > 0
  log stderr if stderr && stderr.length > 0
  if error != null
    log "exec error: #{error}"

#### Main Methods

# Process directory recursivly, normal files
# are copied, directories are recreated and .coffee
# files are "compiled" to javascript
processRecursive = (currentDir, destination) ->
  fileList = readdirSync currentDir
  isError = false
  for fileName in fileList
    filePath = join currentDir, fileName
    destFilePath = join destination, filePath
    if statSync(filePath).isDirectory()
      unless fileName[0] == '.'
        mkdirSync destFilePath, 0700
        isError = true unless processRecursive filePath, destination
    else
      # if it's coffee-script file
      if extname(filePath) == '.coffee'
        log " * processing #{filePath}..."
        try
          writeFileSync destFilePath.replace(/\.coffee$/, '.js'),
            compile(readFileSync(filePath, 'utf8'), bare: yes), 'utf8'
        catch error
          log "Compilation Error: #{error.message}\n"
          isError = true
      # if it's other files
      else
        writeFileSync destFilePath, readFileSync(filePath, 'binary'), 'binary'
  !isError



#### Grinding of coffee

# Starts wrapping push command of couchapps
#
# each deploy is moved to .releases/[timestamp] directory
# with processing coffee-script files and then pushed from
# deploy directory.
grindCoffee = ->
  log "Wrapping 'push' of couchapp"
  releasesDir = '.releases'
  unless existsSync releasesDir
    log "initialize #{releasesDir} directory"
    mkdirSync releasesDir, 0700
  releasePath = join releasesDir, getTimestamp()
  log "preparing #{releasePath} release:"
  mkdirSync releasePath, 0700
  if processRecursive '.', releasePath
    [options..., database] = process.argv[1..]
    options = (options || []).join ' '
    process.chdir releasePath
    database = "" if database == undefined
    exec "couchapp push #{options} #{database}", printOutput
    process.cwd()

# Shows available options.
help = ->
  log "Wrapping 'help' of couchapp\n"
  showGreatings()
  for command in commandWraps
    if command.desc
      log "#{command.name}        #{command.desc}"

# generate file from template verbosly
generateFile = (path, template) ->
  log " * creating #{path}..."
  if existsSync path
    log "File #{path} already exist!"
  else
    writeFileSync path, template, 'utf8'


# cgenerate and destory handling
generate = -> operateOn('generate')
destroy = -> operateOn('destroy')

# common handling for cgenerate/destroy
operateOn = (command) ->
  generator = process.argv[1]
  unless generator
    log "missing name of #{command} - [ view | list | show | filter ]"
    return
  name = process.argv[2]
  unless name
    log 'missing name of element'
    return
  print "Running #{generator} #{command}: "
  fun = switch generator
    when 'view'
      handleView
    when 'show'
      handleShow
    when 'list'
      handleList
    when 'filter'
      handleFilter
    else
      (_, _) -> log "unknown #{command}"
  log 'done.' if fun(command, name)

# handling view generate/destroy
handleView = (method, name) ->
  unless existsSync 'views'
    mkdirSync 'views', 0700

  viewDirPath = "views/#{name}"
  [mapFilePath, reduceFilePath] = [join(viewDirPath, "map.coffee"), join(viewDirPath, "reduce.coffee")]
  switch method
    when 'generate'
      if existsSync viewDirPath
        log "directory '#{viewDirPath}' already exist!"
        false
      else
        mkdirSync viewDirPath, 0700
        generateFile mapFilePath, mapCoffee
        generateFile reduceFilePath, reduceCoffee
        true
    when 'destroy'
      if existsSync viewDirPath
        log "'#{viewDirPath}'."
        exec "rm -r #{viewDirPath}", printOutput
        true
      else
        log "there is no view '#{name}' ('#{viewDirPath}') !!!"
        false
    else
      throw 'unknown method'

# handling generic generate/destroy of file
handleFile = (method, folder, template, name) ->
  filePathCoffee = join folder, "#{name}.coffee"
  filePathJS = join folder, "#{name}.js"
  switch method
    when 'generate'
      unless existsSync folder
        mkdirSync folder, 0700
      generateFile filePathCoffee, template
      true
    when 'destroy'
      if existsSync filePathCoffee
        log "'#{filePathCoffee}'."
        exec "rm #{filePathCoffee}", printOutput
        true
      else if existsSync filePathJS
        log "'#{filePathJS}'."
        exec "rm #{filePathJS}", printOutput
        true
      else
        log "there is no '#{name}' ('#{filePathJS}' or '#{filePathCoffee}') !!!"
        false
    else
      throw 'unknown method'

# shortcuts of handling generate/destroy
handleShow = (method, name) -> handleFile(method, 'shows', showCoffee, name)
handleList = (method, name) -> handleFile(method, 'lists', listCoffee, name)
handleFilter = (method, name) -> handleFile(method, 'filters', filterCoffee, name)

# make clean up
clean = ->
  log "cleaning up:"
  log " * remove '.releases' ..."
  exec 'rm -r .releases'
  log "done."

# prepare project
prepare = ->
  log "preparing project:"
  generateFile '.gitignore', gitIgnore
  log "done."

# Handle wrapping
handleCommand = (type) ->
  handled = false
  for cmd in commandWraps
    if cmd.type == type && cmd.name == process.argv[0]
      handled = true
      cmd.callback()
  handled


#### Well, let's dance baby
exports.run = ->
  showGreatings()
  unless handleCommand('before')
    # convert options back to string
    options = process.argv.join(' ')
    log "Calling couchapp"
    # execute couchapp command
    exec "couchapp #{options}", (error, stdout, stderr) ->
      printOutput(error, stdout, stderr)
      handleCommand('after')

