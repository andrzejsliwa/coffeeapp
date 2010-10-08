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

exist = require('path').existsSync
joinPath = require('path').join
extName = require('path').extname
mkDir = require('fs').mkdirSync
readDir = require('fs').readdirSync
writeFile = require('fs').writeFileSync
readFile = require('fs').readFileSync
getStats = require('fs').statSync
coffeeCompile = require('coffee-script').compile
exec  = require('child_process').exec


#### Command wrapping configruation.


commandWraps = [
  {
    name: 'push',
    type: 'before',
    callback: -> grindCoffee()
  },
  {
    name: 'help',
    type: 'after',
    desc: '     show this message'
    callback: -> help()
  },
  {
    name: 'cgenerate',
    type: 'before',
    desc: '[ view | list | show | filter ] generate .coffee versions',
    callback: -> generate()
  }

]

# fast hack.
isError = false

#### File templates

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

showGreatings = ->
# Shows greatings ...
  console.log 'CoffeeApp (v1.0.1) - simple coffee-script wrapper for CouchApp (http://couchapp.org)'
  console.log 'http://github.com/andrzejsliwa/coffeeapp\n'


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
  console.log stdout if stdout.length > 0
  console.log stderr if stderr.length > 0
  if error != null
    console.log "exec error: #{error}"
    isError = true

#### Main Methods

# Process directory recursivly, normal files
# are copied, directories are recreated and .coffee
# files are "compiled" to javascript
processRecursive = (currentDir, destination) ->
  fileList = readDir currentDir
  for fileName in fileList
    filePath = joinPath currentDir, fileName
    destFilePath = joinPath destination, filePath
    if getStats(filePath).isDirectory()
      unless fileName[0] == '.'
        mkDir destFilePath, 0700
        processRecursive filePath, destination
    else
      # if it's coffee-script file and isn't in _attachments (to using it on client side.)
      if extName(filePath) == '.coffee' and filePath.indexOf('_attachments') == -1
        console.log " * processing #{filePath}..."
        try
          writeFile destFilePath.replace(/\.coffee$/, '.js'),
            coffeeCompile(readFile(filePath, encoding = 'utf8'), noWrap: yes).replace(/^\(/,'').replace(/\);$/, ''), encoding = 'utf8'
        catch error
          console.log "Compilation Error: #{error.message}\n"
          isError = true
      # if it's other files
      else
        exec "cp #{filePath} #{destFilePath}", printOutput


#### Grinding of coffee

# Starts wrapping push command of couchapps
#
# each deploy is moved to .releases/[timestamp] directory
# with processing coffee-script files and then pushed from
# deploy directory.
grindCoffee = ->
  console.log "Wrapping 'push' of couchapp"
  releasesDir = '.releases'
  unless exist releasesDir
    console.log "initialize #{releasesDir} directory"
    mkDir releasesDir, 0700
  releasePath = joinPath releasesDir, getTimestamp()
  console.log "preparing #{releasePath} release..."
  mkDir releasePath, 0700
  processRecursive '.', releasePath
  unless isError
    process.chdir releasePath
    console.log "done."
    exec 'couchapp push', printOutput
    process.cwd()

# Shows available options.
help = ->
  console.log "Wrapping 'help' of couchapp\n"
  showGreatings()
  for command in commandWraps
    if command.desc
      console.log "#{command.name}        #{command.desc}"

# Create file verbosly
createFile = (path, template) ->
  console.log " * creating #{path}..."
  writeFile path, template, encoding = 'utf8'


# Runs Generator handling
generate = ->
  generator = process.argv[1]
  unless generator
    console.log 'missing name of generator - [ view | list | show | filter ]'
    return
  console.log "Running CoffeeApp '#{generator}' generator..."
  name = process.argv[2]
  unless name
    console.log 'missing name of element'
    return
  switch generator
    when 'view'
      view_path = "views/#{name}"
      mkDir view_path, 0700
      createFile joinPath(view_path, "map.coffee"), mapCoffee
      createFile joinPath(view_path, "reduce.coffee"), reduceCoffee
    when 'show'
      createFile joinPath('shows', "#{name}.coffee"), showCoffee
    when 'list'
      createFile joinPath('lists', "#{name}.coffee"), listCoffee
    when 'filter'
      createFile joinPath('filters', "#{name}.coffee"), filterCoffee
    else
      console.log 'unknown generator'
  console.log 'done.'



# Handle wrapping
handle = (type) ->
  handled = false
  for cmd in commandWraps
    if cmd.type == type && cmd.name == process.argv[0]
      handled = true
      cmd.callback()
  handled

# Handling shortcuts
handleBefore = -> handle('before')
handleAfter = -> handle('after')



#### Well, let's dance baby
showGreatings()
unless handleBefore()
  # convert options back to string
  options = process.argv.join(' ')
  console.log "Calling couchapp"
  # execute couchapp command
  exec "couchapp #{options}", (error, stdout, stderr) ->
    printOutput(error, stdout, stderr)
    handleAfter()
